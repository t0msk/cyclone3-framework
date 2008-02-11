#!/bin/perl
package App::301::functions;

=head1 NAME

App::301::functions

=head1 DESCRIPTION

Functions to handle basic actions with users.

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 DEPENDS

=over

=item *

L<App::301::_init|app/"301/_init.pm">

=back

=cut

use App::301::_init;


=head1 FUNCTIONS

=cut


=head2 user_add

 my %user=user_add(
  'user.login' => "userName",
  'user.pass' => "password",
  #'user.hostname' => "",
  #'user.status' => "N"
 );

=cut

sub user_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::user_add()");
	
	$env{'user.hostname'}=$tom::H_cookie unless $env{'user.hostname'};
	main::_log("hostname=$env{'user.hostname'}");
	
	my %user;
	if ($env{'user.ID_user'})
	{
		my $sql=qq{
			SELECT
				*
			FROM
				`TOM`.a301_user
			WHERE
				ID_user='$env{'user.ID_user'}'
			LIMIT 1;
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%user=$sth0{'sth'}->fetchhash();
	}
	
	if ($env{'user.login'} && !$env{'user.ID_user'})
	{
		main::_log("search user by login='$env{'user.login'}'");
		my $sql=qq{
			SELECT
				*
			FROM
				`TOM`.a301_user
			WHERE
				login='$env{'user.login'}' AND
				hostname='$env{'user.hostname'}'
			LIMIT 1;
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%user=$sth0{'sth'}->fetchhash();
		$env{'user.ID_user'}=$user{'ID_user'} if $user{'ID_user'};
	}
	
	if (!$env{'user.ID_user'})
	{
		main::_log("!user.ID_user, create new");
		
		$env{'user.ID_user'}=user_newhash();
		
		TOM::Database::SQL::execute(qq{
			INSERT INTO `TOM`.a301_user
			(
				ID_user,
				hostname,
				datetime_register
			)
			VALUES
			(
				'$env{'user.ID_user'}',
				'$env{'user.hostname'}',
				NOW()
			)
		},'quiet'=>1) || return undef;
	}
	
	my %user_profile;
	if (!$env{'user_profile.ID_entity'} && $env{'user.ID_user'})
	{
		main::_log("search user_profile by login='$env{'user.login'}'");
		my $sql=qq{
			SELECT
				*
			FROM
				`TOM`.a301_user_profile
			WHERE
				ID_entity='$env{'user.ID_user'}'
			LIMIT 1;
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%user_profile=$sth0{'sth'}->fetchhash();
		$env{'user_profile.ID_entity'}=$user_profile{'ID_entity'} if $user_profile{'ID_entity'};
		$env{'user_profile.ID'}=$user_profile{'ID'} if $user_profile{'ID'};
		
		if (!$env{'user_profile.ID_entity'})
		{
			$env{'user_profile.ID'}=App::020::SQL::functions::new(
				'db_h' => "main",
				'db_name' => 'TOM',
				'tb_name' => "a301_user_profile",
				'columns' =>
				{
					'ID_entity' => "'$env{'user.ID_user'}'",
				},
				'-journalize' => 1,
			);
			$env{'user_profile.ID_entity'}=$env{'user.ID_user'} if $env{'user_profile.ID'};
		}
		
	}
	if ($env{'user_profile.ID'} && (
		# firstname
		($env{'user_profile.firstname'} && ($env{'user_profile.firstname'} ne $user_profile{'firstname'}))||
		# surname
		($env{'user_profile.surname'} && ($env{'user_profile.surname'} ne $user_profile{'surname'}))||
		# city
		($env{'user_profile.city'} && ($env{'user_profile.city'} ne $user_profile{'city'}))||
		# street
		($env{'user_profile.street'} && ($env{'user_profile.street'} ne $user_profile{'street'}))||
		# ZIP
		($env{'user_profile.ZIP'} && ($env{'user_profile.ZIP'} ne $user_profile{'ZIP'}))||
		# sex
		($env{'user_profile.sex'} && ($env{'user_profile.sex'} ne $user_profile{'sex'}))||
		# education
		($env{'user_profile.education'} && ($env{'user_profile.education'} ne $user_profile{'education'}))||
		# phone
		($env{'user_profile.phone'} && ($env{'user_profile.phone'} ne $user_profile{'phone'}))||
		# phone_mobile
		($env{'user_profile.phone_mobile'} && ($env{'user_profile.phone_mobile'} ne $user_profile{'phone_mobile'}))||
		# date_birth
		($env{'user_profile.date_birth'} && ($env{'user_profile.date_birth'} ne $user_profile{'date_birth'}))||
		# about_me
		($env{'user_profile.about_me'} && ($env{'user_profile.about_me'} ne $user_profile{'about_me'}))
	))
	{
		my %columns;
		$columns{'firstname'}="'".TOM::Security::form::sql_escape($env{'user_profile.firstname'})."'"
			if ($env{'user_profile.firstname'} && ($env{'user_profile.firstname'} ne $user_profile{'firstname'}));
		$columns{'surname'}="'".TOM::Security::form::sql_escape($env{'user_profile.surname'})."'"
			if ($env{'user_profile.surname'} && ($env{'user_profile.surname'} ne $user_profile{'surname'}));
		$columns{'city'}="'".TOM::Security::form::sql_escape($env{'user_profile.city'})."'"
			if ($env{'user_profile.city'} && ($env{'user_profile.city'} ne $user_profile{'city'}));
		$columns{'street'}="'".TOM::Security::form::sql_escape($env{'user_profile.street'})."'"
			if ($env{'user_profile.street'} && ($env{'user_profile.street'} ne $user_profile{'street'}));
		$columns{'ZIP'}="'".TOM::Security::form::sql_escape($env{'user_profile.ZIP'})."'"
			if ($env{'user_profile.ZIP'} && ($env{'user_profile.ZIP'} ne $user_profile{'ZIP'}));
		$columns{'sex'}="'".TOM::Security::form::sql_escape($env{'user_profile.sex'})."'"
			if ($env{'user_profile.sex'} && ($env{'user_profile.sex'} ne $user_profile{'sex'}));
		$columns{'education'}="'".TOM::Security::form::sql_escape($env{'user_profile.education'})."'"
			if ($env{'user_profile.education'} && ($env{'user_profile.education'} ne $user_profile{'education'}));
		$columns{'phone'}="'".TOM::Security::form::sql_escape($env{'user_profile.phone'})."'"
			if ($env{'user_profile.phone'} && ($env{'user_profile.phone'} ne $user_profile{'phone'}));
		$columns{'phone_mobile'}="'".TOM::Security::form::sql_escape($env{'user_profile.phone_mobile'})."'"
			if ($env{'user_profile.phone_mobile'} && ($env{'user_profile.phone_mobile'} ne $user_profile{'phone_mobile'}));
		$columns{'date_birth'}="'".TOM::Security::form::sql_escape($env{'user_profile.date_birth'})."'"
			if ($env{'user_profile.date_birth'} && ($env{'user_profile.date_birth'} ne $user_profile{'date_birth'}));
		$columns{'about_me'}="'".TOM::Security::form::sql_escape($env{'user_profile.about_me'})."'"
			if ($env{'user_profile.about_,e'} && ($env{'user_profile.about_me'} ne $user_profile{'about_me'}));
		App::020::SQL::functions::update(
			'ID' => $env{'user_profile.ID'},
			'db_h' => "main",
			'db_name' => 'TOM',
			'tb_name' => "a301_user_profile",
			'columns' => {%columns},
			'-journalize' => 1
		);
	}
	
	if (
		$env{'user.ID_user'} &&
		(
			$env{'user.login'} ||
			$env{'user.pass'} ||
			$env{'user.email'} ||
			$env{'user.email_verified'}
		)
	)
	{
		my $set;
		# login
		$set.=",login='$env{'user.login'}'"
			if $env{'user.login'};
		# pass
		$set.=",pass='$env{'user.pass'}'"
			if $env{'user.pass'};
		# email
		$set.=",email='$env{'user.email'}'"
			if $env{'user.email'};
		# email_verified
		$set.=",email_verified='$env{'user.email_verified'}'"
			if $env{'user.email_verified'};
		
		TOM::Database::SQL::execute(qq{
			UPDATE `TOM`.a301_user
			SET
				ID_user='$env{'user.ID_user'}'
				$set
			WHERE
				ID_user='$env{'user.ID_user'}'
			LIMIT 1
		},'quiet'=>1) || return undef;
		
	}
	else
	{
		return undef
	}
	
	foreach my $group(@{$env{'groups'}})
	{
		next unless $group;
		main::_log("add to group '$group'");
		
		my $sql=qq{
			SELECT
				ID
			FROM
				TOM.a301_user_group
			WHERE
				name = '$group' AND
				hostname = '$env{'user.hostname'}'
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			my $sql=qq{
				REPLACE INTO TOM.a301_user_rel_group
				(
					ID_user,
					ID_group
				)
				VALUES
				(
					'$env{'user.ID_user'}',
					'$db0_line{'ID'}'
				)
			};
			TOM::Database::SQL::execute($sql,'quiet'=>1);
		}
		
	}
	
	$t->close();
	return %env;
}



=head2 user_new

 my %user=user_new(
  'user.login' => "userName",
  'user.pass' => "password",
  #'user.hostname' => "",
  #'user.status' => "N"
 );

=cut

sub user_new
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::user_new()");
	
	foreach (sort keys %env)
	{
		if ($_ eq "user.pass")
		{
			main::_log("output $_='".('*' x length($env{$_}))."'");
			next;
		}
		main::_log("input $_='$env{$_}'");
	}
	my %data;
	
	$env{'user.hostname'}=$tom::H_cookie unless $env{'user.hostname'};
	
	if ($env{'user.pass'})
	{
		if ($env{'user.pass'}=~/^(MD5|SHA1):/)
		{
			
		}
		else
		{
			$env{'user.pass'}='MD5:'.Digest::MD5::md5_hex(Encode::encode_utf8($env{'user.pass'}));
		}
	}
	
	if ($env{'user.login'}){$env{'user.login'}="'".$env{'user.login'}."'";}
	else {$env{'user.login'}='NULL';}
	
	if ($env{'user.pass'}){$env{'user.pass'}="'".$env{'user.pass'}."'";}
	else {$env{'user.pass'}='NULL';}
	
	$env{'user.autolog'}="N" unless $env{'user.autolog'};
	$env{'user.status'}="N" unless $env{'user.status'};
	
	
	if ($env{'user.login'} ne 'NULL')
	{
		# try to find this user first
		my $sql=qq{
			SELECT
				*
			FROM
				TOM.a301_user
			WHERE
				hostname='$env{'user.hostname'}' AND
				login=$env{'user.login'}
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$t->close();
			return %db0_line;
		}
	}
	
	$env{'user.ID_user'}=$data{'user.ID_user'}=$data{'ID_user'}=user_newhash();
	
	TOM::Database::SQL::execute(qq{
		INSERT INTO TOM.a301_user
		(
			ID_user,
			login,
			pass,
			autolog,
			hostname,
			datetime_register,
			status
		)
		VALUES
		(
			'$env{'user.ID_user'}',
			$env{'user.login'},
			$env{'user.pass'},
			'$env{'user.autolog'}',
			'$env{'user.hostname'}',
			NOW(),
			'$env{'user.status'}'
		)
	}) || die "can't insert user into TOM.a301_user";
	
	
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



=head2 user_newhash()

 my $ID_user=App::301::functions::user_newhash();

=cut

sub user_newhash
{
	my $t=track TOM::Debug(__PACKAGE__."::user_newhash()");
	
	my $var;
	
	while (1)
	{
		$var=TOM::Utils::vars::genhash(8);
		main::_log("trying '$var'");
		my %sth0=TOM::Database::SQL::execute(
			qq{SELECT ID_user FROM TOM.a301_user WHERE ID_user='$var' LIMIT 1}
		,'quiet'=>1);
		if ($sth0{'rows'}){next}
		last;
	}
	
	$t->close();
	
	return $var;
}



sub user_groups
{
	my $ID_user=shift;
	my $t=track TOM::Debug(__PACKAGE__."::user_groups($ID_user)");
	
	my %env=@_;
	
	my %groups;
	
	my $sql=qq{
		SELECT
			`group`.group_name,
			`group`.ID_group
		FROM
			TOM.a301_user_rel_group_view AS `group`
		WHERE
			`group`.ID_user = '$ID_user'
		ORDER BY
			`group`.group_name
	};
	
	my %sth0=TOM::Database::SQL::execute($sql);
	while (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		$groups{$db0_line{'group_name'}}{'ID'} = $db0_line{'ID_group'};
		#$groups{$db0_line{'group_name'}}{'status'} = $db0_line{'status'};
	}
	
	$t->close();
	return %groups;
}







=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
