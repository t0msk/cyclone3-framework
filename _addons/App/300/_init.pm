#!/bin/perl
package App::300;
use open ':utf8', ':std';
use Encode;
use encoding 'utf8';
use utf8;
use strict;

use Digest::MD5;
use App::300::session;
use CVML;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


=head1 FUNCTIONS

=cut


=head2 GetGroups(IDhash)

=cut

sub GetGroups
{
	my $IDhash=shift;
	my $t=track TOM::Debug(__PACKAGE__."::GetGroups($IDhash)");
	
	my %env=@_;
	
	my %groups;
	
	my $sql=qq{
		SELECT
			`group`.name,
			`group`.status
		FROM
			TOM.a300_users_group AS `group`,
			TOM.a300_users_rel_group AS `rel`,
			TOM.a300_user AS `user`
		WHERE
			`group`.ID = `rel`.IDgroup AND
			`rel`.IDuser = `user`.IDhash AND
			`user`.IDhash = '$IDhash'
		ORDER BY
			`group`.name
	};
	
	my %sth0=TOM::Database::SQL::execute($sql);
	while (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		$groups{$db0_line{'name'}}{'ID'} = $db0_line{'ID'};
		$groups{$db0_line{'name'}}{'status'} = $db0_line{'status'};
	}
	
	$t->close();
	return %groups;
}



sub UserActivize
{
	my $IDhash=shift;
	my $t=track TOM::Debug(__PACKAGE__."::UserActivize($IDhash)");
	
	
	if (
		$main::DB{'main'}->Query("
		INSERT INTO TOM.a300_users
			SELECT
				*
			FROM TOM.a300_users_arch
			WHERE
				IDhash='$IDhash'
			LIMIT 1
		")
	)
	{
		main::_log("inserted user into active table");
		$main::DB{'main'}->Query("
			DELETE FROM TOM.a300_users_arch
			WHERE
				IDhash='$IDhash'
			LIMIT 1;
		");
		main::_log("deleted user from archive table");
		if (
			$main::DB{'main'}->Query("
			INSERT INTO TOM.a300_users_attrs
				SELECT
					*
				FROM TOM.a300_users_attrs_arch
				WHERE
					IDhash='$IDhash'
				LIMIT 1
			")
		)
		{
			main::_log("inserted user attributes into active table");
			$main::DB{'main'}->Query("
				DELETE FROM TOM.a300_users_attrs_arch
				WHERE
					IDhash='$IDhash'
				LIMIT 1;
			");
			main::_log("inserted user attributes from archive table");
			$t->close();
			return 1;
		}
	}
	
	$t->close();
	return undef;
}



sub UserArchive
{
	my $IDhash=shift;
	my $t=track TOM::Debug(__PACKAGE__."::UserArchive($IDhash)");
	
	
	if (
		$main::DB{'main'}->Query("
		INSERT INTO TOM.a300_users_arch
			SELECT
				*
			FROM TOM.a300_users
			WHERE
				IDhash='$IDhash'
			LIMIT 1
		")
	)
	{
		main::_log("inserted user into archive table");
		$main::DB{'main'}->Query("
			DELETE FROM TOM.a300_users
			WHERE
				IDhash='$IDhash'
			LIMIT 1;
		");
		main::_log("deleted user from active table");
		if (
			$main::DB{'main'}->Query("
			INSERT INTO TOM.a300_users_attrs_arch
				SELECT
					*
				FROM TOM.a300_users_attrs
				WHERE
					IDhash='$IDhash'
				LIMIT 1
			")
		)
		{
			main::_log("inserted user attributes into archive table");
			$main::DB{'main'}->Query("
				DELETE FROM TOM.a300_users_attrs
				WHERE
					IDhash='$IDhash'
				LIMIT 1;
			");
			main::_log("inserted user attributes from active table");
			$t->close();
			return 1;
		}
	}
	
	$t->close();
	return undef;
}



=head2 UserFind()

Find user from a300 tables and return %hash

 my %user=App::300::UserFind
 (
  login => 'XY',
  IDhash => 'XXXXX',
  host => 'domain.tld'
 );

=cut

sub UserFind
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::UserFind()");
	
	$env{'host'}=$tom::H_cookie if not exists $env{'host'};
	
	foreach (sort keys %env){main::_log("input $_='$env{$_}'");}
	
	my $where;
	my %data;
	
	$where.="AND users.login='$env{login}' " if exists $env{'login'};
	$where.="AND users.IDhash='$env{IDhash}' " if exists $env{'IDhash'};
	
	my $sql=qq{
		SELECT
			*
		FROM
			TOM.a300_users AS users
		LEFT JOIN
			TOM.a300_users_attrs AS users_attrs
			ON
			(
				users_attrs.IDhash=users.IDhash
			)
		WHERE
			users.host='$env{host}'
			$where
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	if (%data=$sth0{'sth'}->fetchhash)
	{
		main::_log("user found in active table");
	}
	else
	{
		main::_log("user not found in active table, trying archive");
		my $sql=qq{
			SELECT
				*
			FROM
				TOM.a300_users_arch AS users
			LEFT JOIN
				TOM.a300_users_attrs_arch AS users_attrs
				ON
				(
					users_attrs.IDhash=users.IDhash
				)
			WHERE
				users.host='$env{host}'
				$where
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		if (%data=$sth0{'sth'}->fetchhash)
		{
			main::_log("user found in archive table");
			if ($env{'-activize'})
			{
				main::_log("activizing user from archive to active table");
				App::300::UserActivize($data{'IDhash'});
			}
		}
		else
		{
			main::_log("user not found in archive table");
			$t->close();
			return undef;
		}
	}
	
#	foreach (sort keys %data)
#	{
#		if ($_ eq "pass")
#		{
#			main::_log("output $_='".('*' x length($data{$_}))."'");
#			next;
#		}
#		main::_log("output $_='$data{$_}'");
#	}
	
	main::_log("IDhash='$data{'IDhash'}' login='$data{'login'}' host='$data{'host'}' lng='$data{'lng'}' rqs='$data{'rqs'}'");
	
	$t->close();
	return %data;
}



sub UserGenerate
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::UserGenerate()");
	foreach (sort keys %env)
	{
		if ($_ eq "pass")
		{
			main::_log("output $_='".('*' x length($env{$_}))."'");
			next;
		}
		main::_log("input $_='$env{$_}'");
	}
	my %data;
	
	$env{'IDhash'}=$data{'IDhash'}=GenerateUniqueHash();
	$env{'host'}=$tom::H_cookie unless $env{'host'};
	$env{'regtime'}=$main::time_current;
	$env{'logtime'}=$main::time_current;
	$env{'reqtime'}=$main::time_current;
	
	$env{'pass_md5'}=Digest::MD5::md5_hex(Encode::encode_utf8($env{'pass'})) unless $env{'pass_md5'};
	
	$env{'autolog'}="N" unless $env{'autolog'};
	$env{'active'}="N" unless $env{'active'};
	$env{'lng'}="en" unless $env{'lng'};
	
	$main::DB{main}->Query("
		INSERT INTO TOM.a300_users
		(
			IDhash,
			login,
			pass,
			pass_md5,
			autolog,
			host,
			regtime,
			logtime,
			reqtime,
			lng,
			active
		)
		VALUES
		(
			'$env{IDhash}',
			'$env{login}',
			'$env{pass}',
			'$env{pass_md5}',
			'$env{autolog}',
			'$env{host}',
			'$env{regtime}',
			'$env{logtime}',
			'$env{reqtime}',
			'$env{lng}',
			'$env{active}'
		)
	") || die "can't insert user into TOM.a300_users";
	
	$main::DB{main}->Query("
		INSERT INTO TOM.a300_users_attrs
		(
			IDhash,
			email
		)
		VALUES
		(
			'$env{IDhash}',
			'$env{email}'
		)
	") || die "can't insert user into TOM.a300_users_attrs";
	
	foreach (sort keys %data)
	{
		if ($_ eq "pass")
		{
			main::_log("output $_='".('*' x length($data{$_}))."'");
			next;
		}
		main::_log("output $_='$data{$_}'");
	}
	$t->close();
	return %data;
}



sub GenerateUniqueHash
{
	my $t=track TOM::Debug(__PACKAGE__."::GenerateUniqueHash()");
	
	my $var;
#=head1
	while (1)
	{
		$var=Utils::vars::genhash(8);
		main::_log("trying '$var'");
		my $db0=$main::DB{'main'}->Query("
			(SELECT IDhash FROM TOM.a300_users WHERE IDhash='$var' LIMIT 1)
			UNION ALL
			(SELECT IDhash FROM TOM.a300_users_arch WHERE IDhash='$var' LIMIT 1)
		");
		if (my @db0_line=$db0->FetchRow()){next}
		last;
	}
	main::_log("it's free");
#=cut
	$t->close();
	
	return $var;
}



sub CookieClean
{
	my $t=track TOM::Debug(__PACKAGE__."::CookieClean()");
	
	opendir DIR, '../_data/USRM/';
	foreach my $file(readdir DIR)
	{
		next unless $file=~/cookie/;
		my $old=$main::time_current-(stat "../_data/USRM/".$file)[9];
		main::_log("file '$file' old='$old'");
		unlink "../_data/USRM/".$file if $old>3600;
	}
	
	$t->close();
}


CookieClean();


if ($tom::H_cookie)
{
	# admin is group for administrators
	# editor is group with access into cyclone.domain.tld
	foreach my $group('admin','editor')
	{
		my $sql=qq{
			SELECT *
			FROM TOM.a300_users_group
			WHERE host='$tom::H_cookie' AND name='$group'
			LIMIT 1;
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %db0_line=$sth0{'sth'}->fetchhash();
		if (!$db0_line{'ID'})
		{
			TOM::Database::SQL::execute(
				"INSERT INTO TOM.a300_users_group(host,name,status)
					VALUES ('$tom::H_cookie','$group','L')",
				'quiet'=>1);
		}
		elsif ($db0_line{'status'} ne "L")
		{
			TOM::Database::SQL::execute(
				"UPDATE TOM.a300_users_group SET status='L'
					WHERE ID=$db0_line{'ID'} LIMIT 1",
				'quiet'=>1);
		}
	}
}


1;
