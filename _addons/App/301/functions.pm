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
  'login' => "userName",
  'pass' => "password",
  #'status' => "N"
 );

=cut

sub user_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::user_add()");
	
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
	
	$env{'hostname'}=$tom::H_cookie unless $env{'hostname'};
	
	if ($env{'pass'})
	{
		if ($env{'pass'}=~/^(MD5|SHA1):/)
		{
			
		}
		else
		{
			$env{'pass'}='MD5:'.Digest::MD5::md5_hex(Encode::encode_utf8($env{'pass'}));
		}
	}
	
	if ($env{'login'}){$env{'login'}="'".$env{'login'}."'";}
	else {$env{'login'}='NULL';}
	
	if ($env{'pass'}){$env{'pass'}="'".$env{'pass'}."'";}
	else {$env{'pass'}='NULL';}
	
	$env{'autolog'}="N" unless $env{'autolog'};
	$env{'status'}="N" unless $env{'status'};
	
	
	if ($env{'login'} ne 'NULL')
	{
		# try to find this user first
		my $sql=qq{
			SELECT
				*
			FROM
				TOM.a301_user
			WHERE
				hostname='$env{'hostname'}' AND
				login=$env{'login'}
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$t->close();
			return %db0_line;
		}
	}
	
	$env{'ID_user'}=$data{'ID_user'}=user_newhash();
	
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
			'$env{ID_user}',
			$env{login},
			$env{pass},
			'$env{autolog}',
			'$env{hostname}',
			NOW(),
			'$env{status}'
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
