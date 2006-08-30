package TOM::Utils::amount;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

sub IntPlus
{
	my $amount=shift;
	$amount=int($amount);
	
	if    ($amount>=100000){$amount=100000;}
	elsif ($amount>=10000) {$amount=10000;}
	elsif ($amount>=5000)  {$amount=5000;}
	elsif ($amount>=1000)  {$amount=1000;}
	elsif ($amount>=500)   {$amount=500;}
	elsif ($amount>=200)   {$amount=200;}
	elsif ($amount>=100)   {$amount=100;}
	elsif ($amount>=50)    {$amount=50;}
	elsif ($amount>=20)    {$amount=20;}
	elsif ($amount>=10)    {$amount=10;}
	elsif ($amount>=5)     {$amount=5;}
	elsif ($amount>=1)     {$amount=1;}
	else
	{
		$amount="0";
	}
	
	return $amount;
}



1;
