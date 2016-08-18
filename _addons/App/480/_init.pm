#!/bin/perl
package App::480;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;


BEGIN {main::_log("<={LIB} ".__PACKAGE__);}

our $VERSION='1';


use TOM::Template;
use App::020::_init; # data standard 0
use App::301::_init;
use App::480::functions;
#use App::480::a160;
#use App::480::a301;


our $db_name=$App::480::db_name || $TOM::DB{'main'}{'name'};
our $metadata_default=$App::480::metadata_default || qq{
<metatree>
</metatree>
};


1;
