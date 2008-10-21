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
	'unknown-vti_inf'=>
	{
		'uri' => ['^/_vti_inf\.html']
	},
	'unknown-guestbook'=>
	{
		'uri' => ['^/cgi-sys/guestbook\.cgi']
	},
	'unknown-lanaicms'=>
	{
		'uri' => ['/lanai-cms']
	},
	
	'phpbb'=> # PHPBB
	{
		'uri' => ['^/phpbb']
	},
	'forumphp'=>
	{
		'uri' => ['^/forums/index\.php']
	},
	'boardphp'=>
	{
		'uri' => ['^/board/index\.php']
	},
	'phpads'=>
	{
		'uri' => ['adxmlrpc\.php']
	},
	'phpmychat'=>
	{
		'uri' => ['messagesL\.php3']
	},
	
	'horde'=>
	{
		'uri' => ['^/horde\-']
	},
	
	'weblin.com'=>
	{
		'uri' => ['_vpi\.xml']
	},
	
#	'XSS'=>
#	{
#		'uri' => ['>alert\(']
#	},
	
	'crossxml'=>
	{
		'uri' => ['^/cross\*\*\*\*in\.xml']
	},
	
	'awstats'=>
	{
		'uri' => ['awstats\.pl']
	},
	
	'MSA-945713'=> # Microsoft Security Advisory (945713) - Vulnerability in Web Proxy Auto-Discovery (WPAD) Could Allow Information Disclosure
	{
		'uri' => ['wpad\.dat']
	},
	
	'Inktomi' =>
	{
		'uri' => ['mod_ssl:error']
	},
	
	'unknown-php'=> # all unknown php attacks
	{
		'uri' => ['\.php\?']
	},
	'unknown-asp'=> # all unknown asp attacks
	{
		'uri' => ['\.asp\?']
	},
	'unknown-asp'=> # all unknown aspx attacks
	{
		'uri' => ['\.aspx\?']
	},
	'unknown-dll'=> # all unknown dll attacks
	{
		'uri' => ['\.dll\?']
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
	
	open(HCK, ">>".$filename) || return undef;
	print HCK time().":".$IP."\n";
	close (HCK);
	chmod (0666,$filename);
	
	return 1;
}

# END
1;# DO NOT CHANGE !
