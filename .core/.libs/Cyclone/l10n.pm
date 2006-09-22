package Cyclone::l10n;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

=head1 NAME

Cyclone::l10n - Cyclone localization

=head1 DESCRIPTION

Lokalizácia, podpora multilanguage, etc...

=cut

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DEPENDS

 use Cyclone::l10n::charset

=cut

use Cyclone::l10n::charset;

=head1 AUTHOR

Roman Fordinal

=cut

return 1;