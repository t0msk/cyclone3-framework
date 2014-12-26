#!/bin/perl
package App::110;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


use App::110::SQL;


our $sql_rqs=1;
our $sql_rqslite=100; # every 100-st request will be writed into this table
our $sql_direct=$App::110::sql_direct || 0;

1;
