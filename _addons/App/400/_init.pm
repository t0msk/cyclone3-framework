#!/bin/perl
package App::400;
use App::400::SQL; # pytam si SQL a SQL si pyta vsetko pod nim
use App::400::a160;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our @ISA=("App::400::SQL"); # import SQL prototypov

our $VERSION='$Rev$';

1;
