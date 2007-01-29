#!/bin/perl
package Ext::EmailGraph::_init;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

=head1 NAME

Extension EmailGraph

=head1 DESCRIPTION

Extension that creating cool email graphs

=cut

BEGIN
{
	main::_log("<={LIB} ".__PACKAGE__);
	our $DIR=(__FILE__=~/^(.*)\//)[0];
	unshift @INC, $DIR.'/src';
}

BEGIN
{
	use EmailGraph::columns;
}

BEGIN {shift @INC;}

1;
