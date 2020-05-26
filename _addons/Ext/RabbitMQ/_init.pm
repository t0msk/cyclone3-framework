#!/bin/perl
package Ext::RabbitMQ;
use open ':utf8', ':std';
#use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN
{
	main::_log("<={LIB} ".__PACKAGE__);
}

BEGIN
{
	eval {
		require Net::RabbitFoot if $Ext::RabbitMQ::host;
		$Ext::RabbitMQ::lib=1;
	};
}

#BEGIN {shift @INC;}

our $debug=0;
our $service;
our @services;
our $last_message;

sub service
{
	my %env=@_;
#	no encoding;
	return undef unless $Ext::RabbitMQ::host;
	return undef unless $Ext::RabbitMQ::lib;
	if (!$Ext::RabbitMQ::service || $env{'reconnect'})
	{
#		my $t=track TOM::Debug("connect");
		utf8::encode($Ext::RabbitMQ::user); # octets -> bytes
		utf8::encode($Ext::RabbitMQ::pass);
		utf8::encode($Ext::RabbitMQ::vhost);
		$Ext::RabbitMQ::heartbeat||=60;
		main::_log("connecting RabbitMQ $Ext::RabbitMQ::user\@$Ext::RabbitMQ::host vhost=".$Ext::RabbitMQ::vhost." heartbeat=".$Ext::RabbitMQ::heartbeat);
		eval {$Ext::RabbitMQ::service = Ext::RabbitMQ::RabbitFoot->new()->load_xml_spec()->connect(
			'host' => $Ext::RabbitMQ::host || 'localhost',
			'port' => $Ext::RabbitMQ::port || 5672,
			'user' => $Ext::RabbitMQ::user || 'guest',
			'pass' => $Ext::RabbitMQ::pass || 'guest',
			'vhost' => $Ext::RabbitMQ::vhost || '/',
			'timeout' => (3600*24),
			'heartbeat' => $Ext::RabbitMQ::heartbeat,
		)};
		if ($@)
		{
			main::_log("can't connect RabbitMQ \@$Ext::RabbitMQ::host",1);
			return undef;
		}
		
#		use Data::Dumper;
#		print Dumper($Ext::RabbitMQ::service);
		
		my $channel=$Ext::RabbitMQ::service->{'_exclusive_channel'}=$Ext::RabbitMQ::service->open_channel();
		$channel->{'arc'}->confirm();
#		$channel->confirm();
#		print Dumper($channel);
		
		main::_log("open_channel \@$Ext::RabbitMQ::host ".$Ext::RabbitMQ::service->{'_ar'}->{'_server_properties'}->{'product'}.' v'.$Ext::RabbitMQ::service->{'_ar'}->{'_server_properties'}->{'version'});
		
#		$Ext::RabbitMQ::service->confirm();
		
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
		push @services,$Ext::RabbitMQ::service;
	}
#	main::_log("return service");
#	use Data::Dumper;print Dumper($service);
	return $Ext::RabbitMQ::service;
}

service();

# find and close all active channels
END
{
#	main::_log("[RabbitMQ] END");
	sleep 1 if (($Ext::RabbitMQ::last_message>(time()-15)) && $Ext::RabbitMQ::last_message);
	Coro::cede;
	sleep 1 if (($Ext::RabbitMQ::last_message>(time()-15)) && $Ext::RabbitMQ::last_message);
	foreach my $service (@services)
	{
#		main::_log("[RabbitMQ]  close service in pool");
		foreach my $channel (keys %{$service->_channels()})
		{
#			main::_log("[RabbitMQ]   close channel ".$channel);
			$service->_channels->{$channel}->close();
		}
	}
	Coro::cede;
	sleep 1 if (($Ext::RabbitMQ::last_message>(time()-15)) && $Ext::RabbitMQ::last_message);
}

# for exporting symbols
package Ext::RabbitMQ::_init;
use strict;
use base 'Exporter';
our @EXPORT = qw($RabbitMQ);

our $RabbitMQ = $Ext::RabbitMQ::service;


package Ext::RabbitMQ::RabbitFoot;
use parent 'Net::RabbitFoot';
use Ext::Redis::_init;
use JSON;
our $json = JSON->new->ascii();
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;

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
	$Ext::RabbitMQ::last_message=time();
	
	use Encode;
	
	$env{'header'}{'headers'}{'original_timestamp'}=$env{'header'}{'headers'}{'publish_timestamp'}=time();
	$env{'header'}{'headers'}{'c3_hostname'}=$TOM::hostname if $TOM::hostname;
	$env{'header'}{'headers'}{'c3_domain'}=$tom::H if $tom::H;
	$env{'header'}{'headers'}{'c3_pid'}=$$;
	$env{'header'}{'headers'}{'c3_request_code'}=$main::request_code if $main::request_code;
	$env{'header'}{'headers'}{'message_id'}=TOM::Utils::vars::genhash(8)
		unless $env{'header'}{'headers'}{'message_id'};
	
	main::_log("[RabbitMQ] publish message_id='$env{'header'}{'headers'}{'message_id'}' exchange='".$env{'exchange'}."' routing_key='".$env{'routing_key'}."' size=".length($env{'body'}))
		if $debug;
	
	if ($Redis && ($env{'exchange'} eq "cyclone3.job")) # backup job messages
	{
#		$Redis->set('RabbitMQ|'.$env{'header'}{'headers'}{'message_id'},$json->encode(\%env));
#		$Redis->sadd('RabbitMQ|msgs','RabbitMQ|'.$env{'header'}{'headers'}{'message_id'});
#		$Redis->expire('RabbitMQ|'.$env{'header'}{'headers'}{'message_id'},(86400*7));
	}
	
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
#			'on_inactive' => sub(){
#				main::_log("on_inactive");
#			}
		);
		main::_log("[RabbitMQ] WARN: wbuf size=".(length($out->{'arc'}->{'connection'}->{'_handle'}->{'wbuf'})),3)
			if $out->{'arc'}->{'connection'}->{'_handle'}->{'wbuf'};
		die "wbuf detected, message to RabbitMQ not published" if $out->{'arc'}->{'connection'}->{'_handle'}->{'wbuf'};
		use Data::Dumper;
		main::_log("[RabbitMQ] published (".$env{'header'}{'headers'}{'message_id'}.")",{
			'data' => {
				'rabbit' => {
					'state' => $out->{'arc'}->{'connection'}->{'_state'},
					'active' => $out->{'arc'}->{'connection'}->{'_channels'}->{1}->{'_is_active'},
					'confirm' => $out->{'arc'}->{'connection'}->{'_channels'}->{1}->{'_is_confirm'},
				}
			}
		}) if $debug;
	};
	if ($@)
	{
		if ($TOM::experimental)
		{
			main::_log("[RabbitMQ] reconnecting (experimental)");
			if (($Ext::RabbitMQ::_init::RabbitMQ=Ext::RabbitMQ::service('reconnect'=>1)) && !$env{'retry'})
			{
				main::_log("[RabbitMQ] recall publish");
				return $Ext::RabbitMQ::service->publish(%env,'retry'=>1);
			}
		}
		main::_log("[RabbitMQ] error '$@'",1);
		$tom::HUP=2; # exit this process as soon as possible
		
		if ($Redis) # will be executed directly, removing from backup queue
		{
			$Redis->del('RabbitMQ|'.$env{'header'}{'headers'}{'message_id'});
			$Redis->srem('RabbitMQ|msgs','RabbitMQ|'.$env{'header'}{'headers'}{'message_id'});
		}
		
		return undef;
	}
	return 1;
}

sub DESTROY
{
	my $self=shift;
#	main::_log("[RabbitMQ] DESTROY");
	$self->SUPER::DESTROY();
}

1;
