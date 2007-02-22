#!/bin/perl
package App::100;

=head1 NAME

App::100

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


use App::020::_init; # data standard 0
use App::100::SQL;

1;
