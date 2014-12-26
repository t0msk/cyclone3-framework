package TOM::Template::contenttypes;

=head1 NAME

TOM::Template::contenttypes

=head1 DESCRIPTION

Tempalte management Content-Type codes

=cut

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {main::_log("<={LIB} ".__PACKAGE__)}

our $debug=0;

our %trans=(
	'text/xhtml' => 'xhtml',
	'text/html' => 'xhtml',
	'text/xml' => 'xml'
);

sub trans
{
	$_[0]=$trans{$_[0]} if $trans{$_[0]};
	return 1;
}

1;