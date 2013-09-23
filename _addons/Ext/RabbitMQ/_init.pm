#!/bin/perl
package Ext::RabbitMQ;
use open ':utf8', ':std';
#use encoding 'utf8';
use utf8;
use strict;

BEGIN
{
	main::_log("<={LIB} ".__PACKAGE__);
}

BEGIN
{
	require Net::RabbitFoot;
	$Ext::RabbitMQ::lib=1;
}

BEGIN {shift @INC;}

our $debug=0;
our $service;

sub service
{
#	no encoding;
	return undef unless $Ext::RabbitMQ::host;
	return undef unless $Ext::RabbitMQ::lib;
	if (!$Ext::RabbitMQ::service)
	{
		my $t=track TOM::Debug("connect");
		utf8::decode($Ext::RabbitMQ::user);
		utf8::decode($Ext::RabbitMQ::pass);
		$Ext::RabbitMQ::service = Ext::RabbitMQ::RabbitFoot->new()->load_xml_spec()->connect(
			'host' => $Ext::RabbitMQ::host || 'localhost',
			'port' => $Ext::RabbitMQ::port || 5672,
			'user' => $Ext::RabbitMQ::user || 'guest',
			'pass' => $Ext::RabbitMQ::pass || 'guest',
			'vhost' => $Ext::RabbitMQ::vhost || 'Cyclone3',
			'timeout' => 1
		);
		
#		use Data::Dumper;
#		print Dumper($Ext::RabbitMQ::service);
		
		my $channel=$Ext::RabbitMQ::service->{'_exclusive_channel'}=$Ext::RabbitMQ::service->open_channel();
#		print Dumper($channel);
		
		main::_log("open_channel \@$Ext::RabbitMQ::host ".$Ext::RabbitMQ::service->{'_ar'}->{'_server_properties'}->{'product'}.' v'.$Ext::RabbitMQ::service->{'_ar'}->{'_server_properties'}->{'version'});
		
#		$channel->{'arc'}->confirm();
		
		my $queue=$Ext::RabbitMQ::service->{'_exclusive_queue'}=$channel->declare_queue('exclusive' => 1,'queue' => '['.$TOM::hostname.':'.$$.'] callback '.$TOM::engine.' '.$tom::H);
		use Data::Dumper;
#		print Dumper(
#			$Ext::RabbitMQ::service->{'queue'}=$channel->declare_queue(exclusive => 1)
#		);
		
#=head1
		$channel->declare_exchange(
			'exchange' => 'log',
			'type' => 'fanout',
		);
		
		$channel->declare_exchange(
			'exchange' => 'entity.change',
			'type' => 'fanout',
		);
		
		# topics
		$channel->declare_exchange(
			'exchange' => 'topic',
			'type' => 'topic',
			'durable' => 1,
		);
		
		# rpc
		$channel->declare_exchange(
			'exchange' => 'rpc',
			'type' => 'direct',
			'durable' => 0,
		);
		$channel->declare_exchange(
			'exchange' => 'rpc.async',
			'type' => 'direct',
			'durable' => 1,
		);
		
		$channel->declare_queue(
			'queue' => 'pub.job.module',
			'exchange' => 'rpc.async',
			'durable' => 1,
		);
#=cut
		
		$t->close();
	}
	main::_log("return service");
#	use Data::Dumper;print Dumper($service);
	return $Ext::RabbitMQ::service;
}

service();

# for exporting symbols
package Ext::RabbitMQ::_init;
use strict;
use base 'Exporter';
our @EXPORT = qw($RabbitMQ);

our $RabbitMQ = $Ext::RabbitMQ::service;


package Ext::RabbitMQ::RabbitFoot;
use parent 'Net::RabbitFoot';

sub _channel
{
	my $self=shift;
	return $self->{'_exclusive_channel'}
}

sub _queue
{
	my $self=shift;
	return $self->{'_exclusive_queue'};
}

sub publish
{
	my $self=shift;
	my %env=@_;utf8::decode($env{$_}) foreach keys %env;
	utf8::decode($env{'header'}{$_}) foreach keys %{$env{'header'}};# if $env{'header'};
	$self->_channel->publish(%env);
}


1;