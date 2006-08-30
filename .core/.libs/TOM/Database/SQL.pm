package TOM::Database::SQL;

=head1 NAME

TOM::Database::SQL

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



sub escape
{
	my $sql=shift;
	$sql=~s|\'|\\'|g;
	return $sql;
}



1;
