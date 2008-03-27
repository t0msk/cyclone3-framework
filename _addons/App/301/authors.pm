#!/bin/perl
package App::301::authors;
use open ':utf8', ':std';
use encoding 'utf8';
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
			*
		FROM
			`TOM`.`a301_user_profile_view`
		WHERE
			ID_user='$ID_user'
		LIMIT 1;
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1,'slave'=>1,'cache'=>600);
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
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1,'slave'=>1,'cache'=>600);
		%{$authors{$ID_user}}=$sth0{'sth'}->fetchhash();
	}
	
	$authors{$ID_user}{'firstname'}=$authors{$ID_user}{'login'}
		unless $authors{$ID_user}{'firstname'};
	
	return %{$authors{$ID_user}};
}



sub add_author
{
	my %env=@_;
	
	my %columns;
	
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
					user.hostname='$tom::H_cookie' AND
					user_profile.firstname LIKE '$env{'author_firstname'}' AND
					user_profile.surname LIKE '$env{'author_surname'}'
				LIMIT 1
			};
			
			my %sth0=TOM::Database::SQL::execute($sql,'log'=>1);
			if ($sth0{'rows'})
			{
				my %author=$sth0{'sth'}->fetchhash();
				main::_log("found user ID_user='$author{'ID_user'}' login='$author{'login'}'");
				my %groups=App::301::functions::user_groups($author{'ID_user'});
				if ($groups{'author'})
				{
					$columns{'ID_author'}=$author{'ID_user'};
				}
				elsif ($groups{'editor'} || $groups{'admin'})
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
				$env{'author_login'}=Int::charsets::encode::UTF8_ASCII(
					$env{'author_firstname'}." ".$env{'author_surname'}
				);
				my $sql=qq{
					SELECT
						*
					FROM
						TOM.a301_user
					WHERE
						hostname='$tom::H_cookie' AND
						login='$env{'author_login'}'
					LIMIT 1
				};
				my %sth0=TOM::Database::SQL::execute($sql,'log'=>1);
				if (!$sth0{'rows'})
				{
					main::_log("creating new author");
					my %user=App::301::functions::user_add(
						'user.login' => $env{'author_login'},
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
					user.hostname='$tom::H_cookie' AND
					user_profile.firstname LIKE '$env{'author_firstname'}' AND
					user_profile.surname IS NULL
				LIMIT 1
			};
			my %sth0=TOM::Database::SQL::execute($sql,'log'=>1);
			if ($sth0{'rows'})
			{
				my %author=$sth0{'sth'}->fetchhash();
				my %groups=App::301::functions::user_groups($author{'ID_user'});
				if ($groups{'author'})
				{
					$columns{'ID_author'}=$author{'ID_user'};
				}
				elsif ($groups{'editor'} || $groups{'admin'})
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
				$env{'author_login'}=Int::charsets::encode::UTF8_ASCII(
					$env{'author_firstname'}
				);
				my $sql=qq{
					SELECT
						*
					FROM
						TOM.a301_user
					WHERE
						hostname='$tom::H_cookie' AND
						login='$env{'author_login'}'
					LIMIT 1
				};
				my %sth0=TOM::Database::SQL::execute($sql);
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
