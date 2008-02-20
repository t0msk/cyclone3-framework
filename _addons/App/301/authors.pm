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






=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
