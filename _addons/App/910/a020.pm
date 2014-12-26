#!/bin/perl
package App::910::a020;

=head1 NAME

App::910::a020

=cut
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our $debug=1;
our $quiet;$quiet=1 unless $debug;

our $VERSION='1';

=head1 DESCRIPTION

a020 low api functions specific to a910

=cut

=head1 DEPENDS

=over

=item *

L<App::020::_init|app/"020/_init.pm">

=back

=cut



=head2 get_categories_for_entity()

Returns an array of category IDs for this entity. For some applications this will be an array of one. 910 products are multi-categorized
so you get a list of a length >= 1.

=cut

sub get_categories_for_entity
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::get_categories_for_entity()") if $debug;
	
	$env{'db_h'}='main' unless $env{'db_h'};

	my @results;

	if ($env{'table'} eq 'product')
	{
		main::_log('Getting category list for ID_entity='.$env{'ID_entity'}) if $debug;
		
		my $sql = qq{
			SELECT 
				*
			FROM
				`$App::910::db_name`.`a910_product_sym`
			WHERE
				ID_entity = ? AND status != 'T'
		};
		my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>$env{'db_h'},'quiet'=>1, 'bind' => [ $env{'ID_entity'} ]);
	
		if ($sth0{'sth'})
		{
			while (my %db0_line=$sth0{'sth'}->fetchhash())
			{
				push(@results, $db0_line{'ID'}) if ($db0_line{'ID'});
			}
		}
	}

	$t->close() if $debug;;
	return @results;
}

1;