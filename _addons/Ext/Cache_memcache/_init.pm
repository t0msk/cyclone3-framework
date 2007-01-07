#!/bin/perl
package Ext::Cache_memcache;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

=head1 NAME

Extension Cache_memcache

=head1 DESCRIPTION

Library that uses memory daemon to store data between processes

=cut

BEGIN
{
	main::_log("<={LIB} ".__PACKAGE__);
	my $dir=(__FILE__=~/^(.*)\//)[0].'/src';
	unshift @INC, $dir;
}

BEGIN {require Cache::Memcached::Managed;}

BEGIN {shift @INC;}


1;

=head1 AUTHOR

Roman Fordinal

=cut