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
	
	# wait if inkscape is running
	
	waitloop:
	
	my $lock=new TOM::lock("inkscape") || do {
		main::_log("inscape running");
		sleep 1;
		goto waitloop;
	};
	
	
	my $size_1=-s $file1;
	if (-x '/usr/bin/inkscape')
	{
		main::_log("converting svg ($size_1) to png with inkscape");
		#my $out=system("/usr/bin/inkscape $file1 -e=$file2");
		my $out=`/usr/bin/inkscape $file1 -e=$file2`;
		#my $out=system("/usr/bin/inkscape $file1 -e=$file2 >/dev/null 2>/dev/null");
		my $size_2=-s $file2;
		main::_log("output($out) $file2 ($size_2)");
		return 1;
	}
	
	return 1;
}


1;
