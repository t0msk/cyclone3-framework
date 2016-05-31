package TOM::L10n::codes;

=head1 NAME

TOM::L10n::codes

=head1 DESCRIPTION

Localization management language codes

=cut

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {main::_log("<={LIB} ".__PACKAGE__)}

our $debug=0;

# short format language code (639-2?) -> long format language code (https://msdn.microsoft.com/en-us/library/ee825488(v=cs.20).aspx)
our %trans=(
	'en' => 'en-US',
	'sk' => 'sk-SK',
	'cs' => 'cs-CZ',
	'de' => 'de-DE',
	'it' => 'it-IT',
	'uk' => 'uk-UA',
	'ar' => 'ar-SA',
	'hu' => 'hu-HU',
	'fr' => 'fr-FR',
	'pl' => 'pl-PL',
	'it' => 'it-IT',
	
	'ro' => 'ro-RO',
	'sl' => 'sl-SI',
	'es' => 'es-ES',
	'pt' => 'pt-PT',
	'bg' => 'bg-BG',
	'nl' => 'nl-NL',
	'hr' => 'hr-HR',
	'bg' => 'bg-BG'
);

sub trans
{
	$_[0]=$trans{$_[0]} if $trans{$_[0]};
	return 1;
}

1;
