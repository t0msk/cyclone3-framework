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
#		my $t=track TOM::Debug("connect");
		utf8::encode($Ext::RabbitMQ::user); # octets -> bytes
		utf8::encode($Ext::RabbitMQ::pass);
		utf8::encode($Ext::RabbitMQ::vhost);
		main::_log("connecting $Ext::RabbitMQ::user \@$Ext::RabbitMQ::host");
		$Ext::RabbitMQ::service = Ext::RabbitMQ::RabbitFoot->new()->load_xml_spec()->connect(
			'host' => $Ext::RabbitMQ::host || 'localhost',
			'port' => $Ext::RabbitMQ::port || 5672,
			'user' => $Ext::RabbitMQ::user || 'guest',
			'pass' => $Ext::RabbitMQ::pass || 'guest',
			'vhost' => $Ext::RabbitMQ::vhost || '/',
			'timeout' => 0
		);
		
#		use Data::Dumper;
#		print Dumper($Ext::RabbitMQ::service);
		
		my $channel=$Ext::RabbitMQ::service->{'_exclusive_channel'}=$Ext::RabbitMQ::service->open_channel();
#		print Dumper($channel);
		
		main::_log("open_channel \@$Ext::RabbitMQ::host ".$Ext::RabbitMQ::service->{'_ar'}->{'_server_properties'}->{'product'}.' v'.$Ext::RabbitMQ::service->{'_ar'}->{'_server_properties'}->{'version'});
		
#		$channel->{'arc'}->confirm();
		
#		my $queue_name='['.$TOM::hostname.':'.$$.'] callback '.$TOM::engine.' '.$tom::H;
		my $queue_name='['.$TOM::hostname.':'.$$.'] exclusive callback';
			utf8::encode($queue_name);
		my $queue=$Ext::RabbitMQ::service->{'_exclusive_queue'}=$channel->declare_queue('exclusive' => 1,'queue' => $queue_name);
#		use Data::Dumper;
#		print Dumper(
#			$Ext::RabbitMQ::service->{'queue'}=$channel->declare_queue(exclusive => 1)
#		);
		
#=head1
#		$channel->declare_exchange(
#			'exchange' => 'log',
#			'type' => 'fanout',
#		);
		
#		$channel->declare_exchange(
#			'exchange' => 'entity.change',
#			'type' => 'fanout',
#		);
		
		# topics
#		$channel->declare_exchange(
#			'exchange' => 'topic',
#			'type' => 'topic',
#			'durable' => 1,
#		);
		
		# rpc
#		$channel->declare_exchange(
#			'exchange' => 'rpc',
#			'type' => 'direct',
#			'durable' => 0,
#		);
#		$channel->declare_exchange(
#			'exchange' => 'rpc.async',
#			'type' => 'direct',
#			'durable' => 1,
#		);
		
#		$channel->declare_queue(
#			'queue' => 'pub.job.module',
#			'exchange' => 'rpc.async',
#			'durable' => 1,
#		);
#=cut
		
#		# cyclone3.notify
#		$channel->declare_exchange('exchange' => 'cyclone3.notify','type' => 'direct','durable' => 1);
		
=head1
		# cyclone3.notify: notify -> cyclone3.notify
		$channel->declare_queue('exchange' => 'cyclone3.notify','queue' => 'cyclone3.notify','durable' => 1);
		$channel->bind_queue('exchange' => 'cyclone3.notify','routing_key' => 'notify','queue' => 'cyclone3.notify');
		
		# cyclone3.job
		$channel->declare_exchange('exchange' => 'cyclone3.job','type' => 'direct','durable' => 1);
=cut

=head1
		# cyclone3.job: job -> cyclone3.job
		$channel->declare_queue('exchange' => 'cyclone3.job','queue' => 'cyclone3.job','durable' => 1);
		$channel->bind_queue('exchange' => 'cyclone3.job','routing_key' => 'job','queue' => 'cyclone3.job');
		
		# cyclone3.job: cyclone3.job.domain.tld -> cyclone3.job.domain.tld
		if ($tom::H_orig)
		{
			my $queue_name='cyclone3.job.'.$tom::H_orig;utf8::encode($queue_name);
			$channel->declare_queue('exchange' => 'cyclone3.job','queue' => $queue_name,'durable' => 1);
			$channel->bind_queue('exchange' => 'cyclone3.job','queue' => $queue_name,'routing_key' => $queue_name);
		}
=cut
		
#		$channel->delete_queue(
#			'queue' => $queue_name,
#			'exchange' => 'cyclone3.async',
#			'durable' => 1,
#		);# if $tom::H;
		
#		$channel->declare_queue(
#			'queue' => utf8::decode('cyclone3.rpc.'.$tom::H),
#			'exchange' => 'cyclone3.async',
#			'durable' => 1,
#		);
		
#		$t->close();
	}
#	main::_log("return service");
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

sub _channels
{
	my $self=shift;
	return $self->_channel->{'arc'}->{'connection'}->{'_channels'}
}

sub _queue
{
	my $self=shift;
	return $self->{'_exclusive_queue'};
}

sub publish
{
	my $self=shift;
	my %env=@_;
	
	use Encode;
	
	$env{'header'}{'headers'}{'message_id'}=TOM::Utils::vars::genhash(16)
		unless $env{'header'}{'headers'}{'message_id'};
	
	main::_log("[RabbitMQ] publish message_id='$env{'header'}{'headers'}{'message_id'}' exchange='".$env{'exchange'}."' routing_key='".$env{'routing_key'}."'")
		if $debug;
	
	utf8::encode($env{$_}) foreach(grep {!ref($env{$_})} keys %env);
	if (ref($env{'header'})){
		utf8::encode($env{'header'}{$_}) foreach grep {!ref($env{'header'}{$_})} keys %{$env{'header'}};
		if (ref($env{'header'}{'headers'}))
		{
			foreach my $key (grep {!ref($env{'header'}{'headers'}{$_})} keys %{$env{'header'}{'headers'}})
			{
				$key=encode('utf8',$key);
				$env{'header'}{'headers'}{$key}=encode('utf8',$env{'header'}{'headers'}{$key});
			}
		}
	};
	
	eval {
		my $out=$self->_channel->publish(%env,
#		'on_inactive' => sub(){}
		);
		main::_log("[RabbitMQ] published (".$env{'header'}{'headers'}{'message_id'}.")")
			if $debug;
	};
	if ($@)
	{
		main::_log("[RabbitMQ] error '$@'",1);
		return undef;
	}
	return 1;
}

sub DESTROY
{
	my $self=shift;
#	main::_log("DESTROY RabbitMQ");
	$self->_channel->close();
}

1;
