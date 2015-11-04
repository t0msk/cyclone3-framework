#!/bin/perl
package Ext::Heureka;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

=head1 NAME

Extension Heureka

=head1 DESCRIPTION

Library for Czech and Slovak price comparison and e-shop evaluation sites heureka.cz and heureka.sk

=cut

BEGIN
{
	main::_log("<={LIB} ".__PACKAGE__);
	my $dir=(__FILE__=~/^(.*)\//)[0].'/src';
	unshift @INC, $dir;
	
	require OvereneZakaznikmi::HeurekaOverene;
}

BEGIN {shift @INC;}


1;

=head1 AUTHOR

Radomír Laučík

=cut