#!/bin/perl
package App::910;

=head1 NAME

App::910

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our $VERSION='$Rev$';

use App::020::_init; # data standard 0
use TOM::Utils::currency;

our $currency=$App::910::currency || 'EUR';

1;
