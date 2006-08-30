package Cyclone;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

=head1 NAME

Cyclone

=head1 DESCRIPTION

Nový namespace pre knižnice ktoré môžu byť použité skrz verzie Cyclone. V podstate to znamená že knižnica vytvorená v tomto namespace by mala byť podľa novej achitektúry a zodpovedať novým potrebám - teda aby bola použiteľná i napr. v Cyclone35 (pracovný názov pre cyclone3.5)

=cut

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DEPENDS

knižnice:

 Cyclone::files - správa súborov a adresárovej štruktúry Cyclone

=cut

use Cyclone::files;


# spetna kompatibilita
our $PATH=$TOM::P;

1;
=head1 AUTHOR

Roman Fordinal

=cut