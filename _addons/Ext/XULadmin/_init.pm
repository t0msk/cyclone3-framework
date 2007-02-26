#!/bin/perl
package Ext::XULadmin;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

=head1 NAME

Extension xuladmin

=head1 DESCRIPTION

This extension gives support and stores datas to XUL Cyclone3 administration frontend named shortly 'XULadmin'

=cut

BEGIN
{
	main::_log("<={LIB} ".__PACKAGE__);
}

our $DIR=(__FILE__=~/^(.*)\//)[0];

1;

=head1 AUTHOR

Roman Fordinal (roman.fordinal@comsultia.com)

=cut
