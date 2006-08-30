package TOM::Math;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

sub percentage
{
	my $base=shift;
	my $fraction=shift;
	my $float=shift || 2;
	my $koeficient=(10^$float)/10;
	
	return undef unless $base; #Illegal division by zero
	return undef unless $koeficient; #Illegal division by zero
	
	return int(($fraction/($base/100))*$koeficient)/$koeficient;
}





1;
