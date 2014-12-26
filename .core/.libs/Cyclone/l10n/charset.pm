package Cyclone::l10n::charset;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;


=head1 NAME

Cyclone::l10n::charset

=head1 DESCRIPTION

Kódové stránky

=cut


BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


=head1 VARIABLES

=head2 %list

Zoznam znamych kodovani ktore podporujeme v systeme a v prevodoch

=cut


our %list=
(
	'ASCII' => 1,
	'UTF-8' => 1,
	'UTF-16' => 1,
	'ISO-8859-1' => 1,
	'ISO-8859-2' => 1,
	'CP1250' => 1,
	'852' => 1,
);


=head2 %lng_charset

Prevod jazyka na optimalny charset

=cut


our %lng_charset=
(
	'en' => "ISO-8859-1",
	'sk' => "ISO-8859-2",
	'de' => "ISO-8859-2",
	'cs' => "ISO-8859-2",
);


=head1 AUTHOR

Roman Fordinal

=cut