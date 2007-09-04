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
	'unknown-editfunc'=>
	{
		'uri' => ['^/include/editfunc\.inc\.php']
	},
	'unknown-guestbook'=>
	{
		'uri' => ['^/cgi-sys/guestbook\.cgi']
	},
	'unknown-archive'=>
	{
		'uri' => ['/archive/archive\.php']
	},
	'unknown-adminfoot'=>
	{
		'uri' => ['/adminfoot\.php']
	},
	'unknown-mvcw'=>
	{
		'uri' => ['vwar/convert/mvcw\.php']
	},
	'unknown-ezsql'=>
	{
		'uri' => ['/lib/db/ez_sgl\.php']
	},
	'unknown-principal'=>
	{
		'uri' => ['/principal\.php']
	},
	'unknown-lanaicms'=>
	{
		'uri' => ['/lanai-cms']
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
	chmod (0666,$filename);
	
	return 1;
}

# END
1;# DO NOT CHANGE !
