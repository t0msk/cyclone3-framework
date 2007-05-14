package TOM::Domain;

=head1 NAME

TOM::Domain

=head1 DESCRIPTION

Initialize domain service if available

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {main::_log("<={LIB} ".__PACKAGE__)}

BEGIN
{
	unshift @INC,$tom::P."/.libs" if $tom::P;
	unshift @INC,$tom::P."/_addons" if $tom::P;
}

1;