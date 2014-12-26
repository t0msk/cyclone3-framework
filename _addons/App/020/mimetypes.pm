#!/bin/perl
package App::020::mimetypes;


use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


use App::020::_init;
use HTML::Parser;
use App::020::mimetypes::html;

1;
