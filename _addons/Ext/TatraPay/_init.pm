#!/bin/perl
package Ext::TatraPay;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

=head1 NAME

Extension TatraPay

=head1 DESCRIPTION

Library that allow you to use TatraPay system

=cut

BEGIN
{
	main::_log("<={LIB} ".__PACKAGE__);
	my $dir=(__FILE__=~/^(.*)\//)[0].'/src';
	unshift @INC, $dir;
}

BEGIN {
	require Finance::Bank::TB;
	require Finance::Bank::TB_AES;
}

BEGIN {shift @INC;}


1;

=head1 AUTHOR

Roman Fordinal

=cut
