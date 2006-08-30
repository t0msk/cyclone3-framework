#!/bin/perl
package Int::lng;
use ISO::639;
use strict;

our @ISA=("ISO::639");

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1
our %table=
(
	'en'	=>	"english",
	'sk'	=>	"slovensky",
	'de'	=>	"deutsch",
	'cz'	=>	"česky",
	'pl'	=>	"polski",
	'hu'	=>	"magyar",
	'ru'	=>	"русский",
	'nl'	=>	"nederlands",
	'gr'	=>	"ελληνικά",
	'it'	=>	"italiano",
	'pt'	=>	"português",
	'es'	=>	"español",
);
=cut


1;
