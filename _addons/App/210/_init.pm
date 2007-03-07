#!/bin/perl
package App::210;

=head1 NAME

App::210

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our $VERSION='$Rev$';

use App::020::_init; # data standard 0
use App::210::SQL;
use App::210::a160;

1;
