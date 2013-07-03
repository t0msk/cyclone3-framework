#!/bin/perl
package Ext::RabbitMQ;
#use open ':utf8', ':std';
#use encoding 'utf8';
#use utf8;
use strict;

BEGIN
{
	main::_log("<={LIB} ".__PACKAGE__);
}

BEGIN
{
	require Net::RabbitFoot;
	$Ext::RabbitMQ=1;
}

BEGIN {shift @INC;}

#our $cache_available;
our $debug=0;
our $service;

sub service
{
	return undef unless $Ext::RabbitMQ::host;
	if (!$service)
	{
		my $conn = Net::RabbitFoot->new()->load_xml_spec()->connect(
			'host' => $Ext::RabbitMQ::host,
			'port' => $Ext::RabbitMQ::port || 5672,
			'user' => $Ext::RabbitMQ::user || 'guest',
			'pass' => $Ext::RabbitMQ::pass || 'guest',
			'vhost' => $Ext::RabbitMQ::vhost || 'cyclone3',
		);
		
		$service = $conn->open_channel();
		
		$service->declare_queue(
			'queue' => 'log',
		#	durable => 1,
		);
		
	}
	return $service;
}

1;