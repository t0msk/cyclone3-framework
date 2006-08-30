#!/usr/bin/perl

package TOM::Net::HTTP::hacked;
use strict;
use warnings;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



our %table=
(
	'Nimda Virus'=>
	{
		'uri' => ['^/MSOffice/cltreq.asp','^/_vti_bin/owssvr.dll'],
	},
	'Slurp attack'=>
	{
		'uri' => ['^/SlurpConfirm404']
	},
	'Code Red Worm'=>
	{
		'uri' => ['^/_vti_bin/']
	},
	'unknown-mambo'=>
	{
		'uri' => ['^/mambo/index\.php']
	},
	'unknown-vti_inf'=>
	{
		'uri' => ['^/_vti_inf\.html']
	},
	'unknown-desktopdefault.aspx'=>
	{
		'uri' => ['^/desktopdefault\.aspx']
	},
);


sub check
{
	return undef unless $_[0];
	foreach (keys %table)
	{
		foreach my $uri (@{$table{$_}{'uri'}})
		{
			return $_ if $_[0]=~/$uri/;
		}
	}
	return undef;
};


sub add
{
	my $IP=shift;
	
	main::_log("adding IP='$IP' to list of hacked computers");
	
	my $filename=$TOM::P."/_temp/hacked_IP.list";
	
	open(HCK, ">>".$filename) || die "$!";
	print HCK time().":".$IP."\n";
	close (HCK);
	chmod (0660,$filename);
	
	return 1;
}

# END
1;# DO NOT CHANGE !
