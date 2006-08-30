#!/bin/perl
package TOM::System::file;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

sub change
{
	my $file=shift;
	$file=~s/([ \(&\)'\+;\$`\\:])/\\$1/g;
	return $file;
}


1;