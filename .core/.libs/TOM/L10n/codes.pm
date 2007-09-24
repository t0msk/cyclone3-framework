package TOM::L10n::codes;

=head1 NAME

TOM::L10n::codes

=head1 DESCRIPTION

Localization management language codes

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {main::_log("<={LIB} ".__PACKAGE__)}

our $debug=0;

our %trans=(
	'en' => 'en-US',
	'sk' => 'sk-SK'
);

sub trans
{
	$_[0]=$trans{$_[0]} if $trans{$_[0]};
	return 1;
}

1;