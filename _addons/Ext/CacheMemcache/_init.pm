#!/bin/perl
package Ext::CacheMemcache;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

=head1 NAME

Extension Cache_memcache

=head1 DESCRIPTION

Library that uses memory daemon to store data between processes

=cut

=head1 TESTS

Tested with memcached-1.1.2

=cut

BEGIN
{
	main::_log("<={LIB} ".__PACKAGE__);
	my $dir=(__FILE__=~/^(.*)\//)[0].'/src';
	unshift @INC, $dir;
}

use TOM::System::process;

BEGIN
{
	require Cache::Memcached;
	require Cache::Memcached::Managed;
}

BEGIN {shift @INC;}

our $cache;
#our $cache_available;
our $memory_part=1/5;
our $memory_minimal=1024;
our $memory_maximal=512000;


=head1 FUNCTIONS

=head2 memcached_start()

Start memcached daemon service

=cut

sub memcached_start
{
	my $t=track TOM::Debug(__PACKAGE__."::memcached_start()");
	
	if (memcached_check())
	{
		main::_log("memcached is running");
	}
	else
	{
		main::_log("memcached is not running");
		my $i=0;
		foreach (@{$TOM::CACHE_memcached_servers})
		{
			main::_log("server[$i]='$_'");
			my @def=split(':',$_);
			if ($def[0] eq '127.0.0.1') # we can run localhost
			{
				my $pid=TOM::System::process::start(
					'memcached -d -m 10024 -l '.$def[0].' -p '.$def[1]
				);
				$pid++;
				sleep 1; # waiting to $pid available
				main::_log("real pid='$pid'");
			}
			$i++;
		}
	}
	
	$t->close();
	return 1;
}

=head2 memcached_check()

Check if daemon is running

=cut

sub memcached_check
{
	my $t=track TOM::Debug(__PACKAGE__."::memcached_check()");
	
	my $i=0;
	foreach (@{$TOM::CACHE_memcached_servers})
	{
		main::_log("server[$i]='$_'");
		my @def=split(':',$_);
		my @processes=TOM::System::process::find(
			regex=>['memcached','-l '.$def[0],'-p '.$def[1]]
		);
		
		if ($processes[0])
		{
			$t->close();
			return 1;
		}
		
		$i++;
	}
	
	$t->close();
	return undef;
}

=head2 check()

Check if cache service is available

=cut

sub check
{
	return undef unless $cache;
	return undef unless $cache->set(
		'namespace'=>"test_namespace",
		'key'=>"test_key",
		'value'=>"test_value"
	);
}

=head2 connect()

Creates connection to memcached daemon/s when defined in configuration

 $TOM::CACHE_memcached
 $TOM::CACHE_memcached_servers

=cut

sub connect
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::connect()");
	
	if (check())
	{
		main::_log("service is already running and connected");
		$t->close();
		return 1;
	}
	
	if (!$TOM::CACHE_memcached)
	{
		main::_log('memcached is disabled by $TOM::CACHE_memcached',1);
		$t->close();
		return undef;
	}
	
	$cache = Cache::Memcached::Managed->new($TOM::CACHE_memcached_servers);
	
	if ($cache)
	{
		main::_log("cache connected");
	}
	else
	{
		main::_log("cache not connected, disabling",1);
		$TOM::CACHE_memcached=0;
		$t->close();
		return undef;
	}
	
	if (check())
	{
		main::_log("memcached responding");
	}
	else
	{
		main::_log("memcached is not responding (try memcached_start() when service is off)",1);
		$t->close();
		return undef;
	}
	
	$t->close();
	return 1;
}

# connect automatically
if ($TOM::CACHE_memcached)
{
	&memcached_start();
	&connect();
}

1;

=head1 AUTHOR

Roman Fordinal (roman.fordinal@comsultia.com)

=cut
