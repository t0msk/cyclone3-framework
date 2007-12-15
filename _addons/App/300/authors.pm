#!/bin/perl
package App::300::authors;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;



=head1 NAME

App::300::authors

=head1 DESCRIPTION

Cached informations about authors

=cut

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 DEPENDS

=over

=item *

L<App::300::_init|app/"300/_init.pm">

=back

=cut

use App::300::_init;



=head1 FUNCTIONS

=head2 get_author(IDhash)

 my %author=get_author($IDhash)

=cut


our %authors;


sub get_author
{
	my $IDhash=shift;
	
	if (!$authors{$IDhash})
	{
		
		my $sql=qq{
			SELECT
				*
			FROM
				`TOM`.`a300_users_view`
			WHERE
				IDhash='$IDhash'
			LIMIT 1;
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		
		%{$authors{$IDhash}}=$sth0{'sth'}->fetchhash();
		
	}
	
	return %{$authors{$IDhash}};
}






=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
