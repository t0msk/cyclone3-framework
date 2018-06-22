#!/bin/perl
package App::301::authors;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;



=head1 NAME

App::301::authors

=head1 DESCRIPTION

Cached informations about authors

=cut

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 DEPENDS

=over

=item *

L<App::301::_init|app/"301/_init.pm">

=back

=cut

use App::301::_init;



=head1 FUNCTIONS

=head2 get_author(IDhash)

 my %author=get_author($IDhash)

=cut


our %authors;


sub get_author
{
	my $ID_user=shift;
	
	return undef unless $ID_user;
	
	my $sql=qq{
		SELECT
			user.hostname,
			user.ID_user,
			user.posix_owner,
			user.login,
			user.email,
			user.email_verified,
			user.datetime_register,
			YEAR(CURRENT_DATE()) - YEAR(user_profile.date_birth) - (RIGHT(CURRENT_DATE(),5) < RIGHT(user_profile.date_birth,5)) AS age,
			user_profile.*
		FROM
			`TOM`.`a301_user` AS user
		LEFT JOIN `TOM`.`a301_user_profile` AS user_profile ON
		(
			user.ID_user = user_profile.ID_entity
		)
		WHERE
			user.ID_user='$ID_user'
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1,'-slave'=>1,'-cache'=>600);
	%{$authors{$ID_user}}=$sth0{'sth'}->fetchhash();
	
	if (!$authors{$ID_user}{'ID'})
	{
		my $sql=qq{
			SELECT
				*
			FROM
				`TOM`.`a301_user`
			WHERE
				ID_user='$ID_user'
			LIMIT 1;
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1,'-slave'=>1,'-cache'=>600);
		%{$authors{$ID_user}}=$sth0{'sth'}->fetchhash();
	}
	
	$authors{$ID_user}{'firstname'}=$authors{$ID_user}{'login'}
		unless $authors{$ID_user}{'firstname'};
	
	return %{$authors{$ID_user}};
}


sub get_fullname
{
	my %env=@_;
	my $fullname;
	my $shortname;
	
	if ($env{'firstname'} && $env{'surname'})
	{
		$shortname=$env{'surname'}.', '.$env{'firstname'};
		if ($env{'year_birth'})
		{
			$fullname=$env{'surname'}.', '.$env{'firstname'}.' ('.$env{'year_birth'}.')';
		}
		elsif ($env{'login'})
		{
			$fullname=$env{'surname'}.', '.$env{'firstname'}.' (#'.$env{'login'}.')';
		}
		else
		{
			$fullname=$env{'surname'}.', '.$env{'firstname'};
		}
	}
	elsif ($env{'surname'})
	{
		$shortname=$env{'surname'};
		if ($env{'year_birth'})
		{
			$fullname=$env{'surname'}.' ('.$env{'year_birth'}.')';
		}
		elsif ($env{'login'})
		{
			$fullname=$env{'surname'}.' (#'.$env{'login'}.')';
		}
		else
		{
			$fullname=$env{'surname'};
		}
	}
	elsif ($env{'firstname'})
	{
		$shortname=$env{'firstname'};
		if ($env{'year_birth'})
		{
			$fullname=$env{'firstname'}.' ('.$env{'year_birth'}.')';
		}
		elsif ($env{'login'})
		{
			$fullname=$env{'firstname'}.' (#'.$env{'login'}.')';
		}
		else
		{
			$fullname=$env{'firstname'};
		}
	}
	elsif ($env{'login'})
	{
		$shortname=$env{'login'};
		if ($env{'year_birth'})
		{
			$fullname=$env{'login'}.' ('.$env{'year_birth'}.')';
		}
		else
		{
			$fullname=$env{'login'}.' ('.$env{'year_birth'}.')';
		}
	}
	
	return ($fullname,$shortname);
}


sub add_author
{
	my %env=@_;
	
	my %columns;
	
	
	if ($env{'string'})
	{
		main::_log("input string='$env{'string'}'");
		1 while ($env{'string'}=~s|^ ||);
		1 while ($env{'string'}=~s| $||);
		
		# try to find this string in firstname
		my $sql=qq{
			SELECT
				user_profile.ID_entity
			FROM
				`TOM`.`a301_user_profile` AS user_profile
			WHERE
				user_profile.firstname LIKE ?
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'bind'=>[$env{'string'}],'quiet'=>1);
		if ($sth0{'rows'})
		{
			$env{'author_firstname'}=$env{'string'};
		}
		else
		{
			my @keys=split(',',$env{'string'},2);
			$keys[1]=~s/^ //;
			if ($keys[1] && not $keys[1]=~/[, ]/)
			{
				# surname, name
				$env{'author_surname'}=$keys[0];
				$env{'author_firstname'}=$keys[1];
			}
			else
			{
				my @keys2=split(' ',$env{'string'},2);
				$keys2[1]=~s/^ //;
				if ($keys2[1] && not $keys2[1]=~/[, ]/)
				{
					$env{'author_surname'}=$keys2[1];
					$env{'author_firstname'}=$keys2[0];
				}
				else
				{
					$keys2[0]=~s|,$||;
					$env{'author_firstname'}=$env{'string'};
				}
			}
		}
		
		main::_log("firstname='$env{'author_firstname'}' surname='$env{'author_surname'}'");
		
#		return 1;
	}
	
	
	if ($env{'author_login'})
	{
		
		
		
	}
	elsif ($env{'author_firstname'})
	{
		if ($env{'author_surname'})
		{
			my $sql=qq{
				SELECT
					
					user.hostname,
					user.ID_user,
					user.login,
					user.email,
					user.email_verified,
					user_profile.*
					
				FROM
					`TOM`.`a301_user` AS user
				LEFT JOIN `TOM`.`a301_user_profile` AS user_profile ON
				(
					user.ID_user = user_profile.ID_entity
				)
				WHERE
					user.status IN ('Y','N','L','W') AND
					user.hostname='$tom::H_cookie' AND
					user_profile.firstname LIKE ? AND
					user_profile.surname LIKE ?
				LIMIT 1
			};
			
			my %sth0=TOM::Database::SQL::execute($sql,bind=>[$env{'author_firstname'},$env{'author_surname'}],'quiet'=>1);
			if ($sth0{'rows'})
			{
				my %author=$sth0{'sth'}->fetchhash();
				main::_log("found user ID_user='$author{'ID_user'}' login='$author{'login'}'");
				my %groups=App::301::functions::user_groups($author{'ID_user'});
				if ($groups{'author'})
				{
					$columns{'ID_author'}=$author{'ID_user'};
				}
				#elsif ($groups{'editor'} || $groups{'admin'})
				else
				{
					main::_log("adding user into group 'author'");
					App::301::functions::user_add(
						'user.ID_user' => $author{'ID_user'},
						'groups' => ['author']
					);
					$columns{'ID_author'}=$author{'ID_user'};
				}
			}
			if (!$columns{'ID_author'})
			{
#				$env{'author_login'}=Int::charsets::encode::UTF8_ASCII(
#					$env{'author_firstname'}." ".$env{'author_surname'}
#				);
				my $sql=qq{
					SELECT
						*
					FROM
						`$App::301::db_name`.a301_user
					WHERE
						status IN ('Y','N','L','W') AND
						hostname='$tom::H_cookie' AND
						login='$env{'author_login'}'
					LIMIT 1
				};
				my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
				if (!$sth0{'rows'})
				{
					main::_log("creating new author");
					my %user=App::301::functions::user_add(
#						'user.login' => $env{'author_login'},
						'user_profile.firstname' => $env{'author_firstname'},
						'user_profile.surname' => $env{'author_surname'},
						'groups' => ['author']
					);
					$columns{'ID_author'}=$user{'user.ID_user'};
				}
				else
				{
					# conflict!!! - this login already exist
				}
			}
		}
		# only firstname defined
		else
		{
			my $sql=qq{
				SELECT
					user.hostname,
					user.ID_user,
					user.login,
					user.email,
					user.email_verified,
					user_profile.*
				FROM
					`TOM`.`a301_user` AS user
				LEFT JOIN `TOM`.`a301_user_profile` AS user_profile ON
				(
					user.ID_user = user_profile.ID_entity
				)
				WHERE
					user.status IN ('Y','N','L','W') AND
					user.hostname='$tom::H_cookie' AND
					user_profile.firstname LIKE ? AND
					user_profile.surname IS NULL
				LIMIT 1
			};
			my %sth0=TOM::Database::SQL::execute($sql,bind=>[$env{'author_firstname'}],'quiet'=>1);
			if ($sth0{'rows'})
			{
				my %author=$sth0{'sth'}->fetchhash();
				my %groups=App::301::functions::user_groups($author{'ID_user'});
				if ($groups{'author'})
				{
					$columns{'ID_author'}=$author{'ID_user'};
				}
				#elsif ($groups{'editor'} || $groups{'admin'})
				else
				{
					main::_log("adding user into group 'author'");
					App::301::functions::user_add(
						'user.ID_user' => $author{'ID_user'},
						'groups' => ['author']
					);
					$columns{'ID_author'}=$author{'ID_user'};
				}
			}
			if (!$columns{'ID_author'})
			{
#				$env{'author_login'}=Int::charsets::encode::UTF8_ASCII(
#					$env{'author_firstname'}
#				);
				my $sql=qq{
					SELECT
						*
					FROM
						`$App::301::db_name`.a301_user
					WHERE
						status IN ('Y','N','L','W') AND
						hostname='$tom::H_cookie' AND
						login='$env{'author_login'}'
					LIMIT 1
				};
				my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
				if (!$sth0{'rows'})
				{
					main::_log("creating new author");
					my %user=App::301::functions::user_add(
						'user.login' => $env{'author_login'},
						'user_profile.firstname' => $env{'author_firstname'},
						'groups' => ['author']
					);
					$columns{'ID_author'}=$user{'user.ID_user'};
				}
				else
				{
					# conflict!!! - this login already exist
					my %db0_line=$sth0{'sth'}->fetchhash();
					$columns{'ID_author'}=$db0_line{'ID_user'};
				}
			}
		}
	}
	
	return %columns;
	
}



=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
