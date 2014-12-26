#!/bin/perl
package Ext::SVGraph;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

=head1 NAME

Extension SVGraph

=head1 DESCRIPTION

Extension that creating cool SVG graphs

=cut

BEGIN
{
	main::_log("<={LIB} ".__PACKAGE__);
	our $DIR=(__FILE__=~/^(.*)\//)[0];
	unshift @INC, $DIR.'/src';
}

BEGIN
{
	require SVGraph::Core;
	use SVGraph::2D::lines;
	use SVGraph::2D::columns;
	use SVGraph::2D::map;
}

BEGIN {shift @INC;}



1;
