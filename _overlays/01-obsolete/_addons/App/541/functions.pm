#!/bin/perl
package App::541::functions;

=head1 NAME

App::541::functions

=head1 DESCRIPTION



=cut

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 DEPENDS

=over

=item *

L<App::541::_init|app/"541/_init.pm">

=item *

L<TOM::Utils::vars|source-doc/".core/.libs/TOM/Utils/vars.pm">

=back

=cut

use App::541::_init;
use TOM::Utils::vars;



=head1 FUNCTIONS

=head2 file_newhash()

Find new unique not already used for file.

=cut

sub file_newhash
{
	
	my $okay=0;
	my $hash;
	
	while (!$okay)
	{
		
		$hash=TOM::Utils::vars::genhash(64);
		
		my $sql=qq{
			(
				SELECT ID
				FROM
					a541_file
				WHERE
					name_hash LIKE '$hash'
				LIMIT 1
			)
			UNION ALL
			(
				SELECT ID
				FROM
					a541_file_j
				WHERE
					name_hash LIKE '$hash'
				LIMIT 1
			)
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		if (!$sth0{'sth'}->fetchhash())
		{
			$okay=1;
		}
	}
	
	return $hash;
}



=head1 AUTHORS

Roman Fordinal (roman.fordinal@comsultia.com)

=cut


1;
