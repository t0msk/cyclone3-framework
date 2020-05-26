#!/bin/perl
package App::301::a160;

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use App::301::_init;
use App::020::_init;
use App::020::a160;

our $VERSION='1';

sub get_relation_iteminfo
{
	shift;
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::get_relation_iteminfo()");
	
	foreach (sort keys %env) {main::_log("input '$_'='$env{$_}'") if defined $env{$_}};
	
	# if db_name is undefined, use local name
	$env{'r_db_name'}=$App::301::db_name unless $env{'r_db_name'};
	
	my $lng_in;
	
	my %info;
	
	if ($env{'r_table'} eq "user")
	{
		my $sql=qq{
			SELECT
				a301_user.ID_user,
				a301_user.login,
				a301_user_profile.firstname,
				a301_user_profile.surname
			FROM
				`$App::301::db_name`.a301_user
			LEFT JOIN `$App::301::db_name`.a301_user_profile ON
			(
				a301_user_profile.ID_entity = a301_user.ID_user
			)
			WHERE
				ID_user='$env{'r_ID_entity'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>'main');
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			my $fullname;
			
			if ($db0_line{'surname'})
			{
				$fullname=$db0_line{'surname'};
				$fullname.=", ".$db0_line{'firstname'} if ($db0_line{'firstname'} && ($db0_line{'firstname'} ne $db0_line{'surname'}));
				$fullname=~s|^, ||;
			}
			else
			{
				$fullname=$db0_line{'firstname'};
				$fullname.=" ".$db0_line{'surname'} if ($db0_line{'surname'} && ($db0_line{'firstname'} ne $db0_line{'surname'}));
				$fullname=~s|^ ||;
			}
			
			if ($db0_line{'year_birth'})
			{
				$fullname.=" (".$db0_line{'year_birth'}.")";
			}
			
			$info{'name'}=$fullname;
			$info{'ID'}=$db0_line{'ID_user'};
			$info{'lng'}=$db0_line{'lng'};
			main::_log("returning name='$info{'name'}'");
			$t->close();
			return %info;
		}
	}
	elsif ($env{'r_table'} eq "contact")
	{
		my $sql=qq{
			SELECT
				a301_user.ID_user,
				a301_user.login,
				a301_user_profile.firstname,
				a301_user_profile.surname
			FROM
				`$App::301::db_name`.a301_user
			LEFT JOIN `$App::301::db_name`.a301_user_profile ON
			(
				a301_user_profile.ID_entity = a301_user.ID_user
			)
			WHERE
				ID_user='$env{'r_ID_entity'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>'main');
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			my $fullname;
			
			if ($db0_line{'surname'})
			{
				$fullname=$db0_line{'surname'};
				$fullname.=", ".$db0_line{'firstname'} if ($db0_line{'firstname'} && ($db0_line{'firstname'} ne $db0_line{'surname'}));
				$fullname=~s|^, ||;
			}
			else
			{
				$fullname=$db0_line{'firstname'};
				$fullname.=" ".$db0_line{'surname'} if ($db0_line{'surname'} && ($db0_line{'firstname'} ne $db0_line{'surname'}));
				$fullname=~s|^ ||;
			}
			
			if ($db0_line{'year_birth'})
			{
				$fullname.=" (".$db0_line{'year_birth'}.")";
			}
			
			$info{'name'}=$fullname;
			$info{'ID'}=$db0_line{'ID_user'};
			$info{'lng'}=$db0_line{'lng'};
			main::_log("returning name='$info{'name'}'");
			$t->close();
			return %info;
		}
	}
	
	$t->close();
	return undef;
}


1;