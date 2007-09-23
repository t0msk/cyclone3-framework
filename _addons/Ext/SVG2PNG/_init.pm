#!/bin/perl
package Ext::SVG2PNG;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

=head1 NAME

Extension SVG2PNG

=head1 DESCRIPTION

Extension which converts SVG to raster PNG images

=cut

BEGIN
{
	main::_log("<={LIB} ".__PACKAGE__);
}


sub convert
{
	my $file1=shift;
	my $file2=shift;
	
	if (-x '/usr/bin/inkscape')
	{
		system("/usr/bin/inkscape $file1 -e=$file2 >/dev/null 2>/dev/null");
		return 1;
	}
	
	return 1;
}


1;
