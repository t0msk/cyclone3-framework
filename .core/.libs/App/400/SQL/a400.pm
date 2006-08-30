#!/bin/perl
package App::400::SQL::a400;
use App::400::SQL::a400::get;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our @PRIMARY=("a400.ID","a400.starttime","a400.active","a400.lng","a400.arch");
our @REQUIRED=("a400.link","a400.arch");











1;
