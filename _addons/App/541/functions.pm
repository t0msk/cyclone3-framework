#!/bin/perl
package App::541::functions;

=head1 NAME

App::541::functions

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use TOM::Utils::vars;


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


1;
