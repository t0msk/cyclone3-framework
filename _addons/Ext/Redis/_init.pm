#!/bin/perl
package Ext::Redis;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

=head1 NAME

Extension Redis

=head1 DESCRIPTION

Library that uses memory daemon to store data between processes

=cut

#use Redis;

our $service;
our %services;
our $lib;

BEGIN
{
	main::_log("<={LIB} ".__PACKAGE__);
	
#	eval {require AnyEvent::Redis}; RedisDB is faster (30%)
	eval {require RedisDB};
	if ($@)
	{
		main::_log("<={LIB} RedisDB",1);
		undef $Ext::Redis::host;
	}
	else
	{
		main::_log("<={LIB} RedisDB");
		$lib='RedisDB';
	}
	
};

sub _connect
{
	my $name=shift;
	my $service_;
	
	if ($service_=Ext::Redis::service->new())
	{
		if ($name)
		{
			$services{$name}=$service_;
		}
		else
		{
			$service=$service_;
			# override memcached
			$TOM::CACHE_memcached=1;
			$Ext::CacheMemcache::cache = new Ext::CacheMemcache::Redir;
			main::_log("overriding \$Ext::CacheMemcache::cache object");
		}
	}
	
	return $service_;
}

_connect(); # default connection
# call $Redis_{custom_name}=Ext::Redis::_connect('{custom_name}') to create parallel connection
# for example: $Redis_para2=Ext::Redis::_connect('para2');

package Ext::CacheMemcache::Redir;
use Storable;

sub new
{
	my $class=shift;
	my $self={};
	
	return bless $self, $class;
}

sub set
{
	my $self=shift;
	my %env=@_;
	
	if (ref $env{'value'})
	{
		$env{'value'}=Storable::nfreeze($env{'value'});
	}
	else
	{
		$env{'value'}=Storable::nfreeze(\$env{'value'});
	}
	
	my $key='memcache|'.$env{'namespace'}.'|'.$env{'key'};
	
	my $expire;
	if ($env{'expiration'}=~/^(\d+)S?$/)
	{
		$expire=$1;
	}
	elsif ($env{'expiration'}=~/^(\d+)D$/)
	{
		$expire=$1*86400;
	}
	elsif ($env{'expiration'}=~/^(\d+)H$/)
	{
		$expire=$1*3600;
	}
	
	$Ext::Redis::service->set(
		$key,
		$env{'value'},
		sub {} # in pipeline
	);
	$Ext::Redis::service->expire(
		$key,
		$expire || 600,
		sub {} # in pipeline
	);
	
	return 1;
}

sub get
{
	my $self=shift;
	my %env=@_;
	my $value=Storable::thaw(
		$Ext::Redis::service->get(
			'memcache|'.$env{'namespace'}.'|'.$env{'key'}
		)
	);
	if (ref $value eq "SCALAR")
	{
		return $$value;
	}
	return $value;
}

sub AUTOLOAD
{
	
}

# for exporting symbols
package Ext::Redis::_init;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
use base 'Exporter';
our @EXPORT = qw($Redis);

our $Redis=$Ext::Redis::service;


# override default handling of get commands in AnyEvent - to be blocking
# only set commands we want to have non-blocking
package Ext::Redis::service;
use vars qw{$AUTOLOAD};

sub new
{
	my $class=shift;
	my $self={};
	
	$self->{'lib'}="RedisDB";
	
	my %env=@_;
	
	return undef unless $Ext::Redis::host;
	
	my $t=track TOM::Debug("connect",'attrs'=>$Ext::Redis::host);
	
	if ($self->{'lib'} eq "AnyEvent")
	{
		main::_log("using AnyEvent");
		$Ext::Redis::host='localhost:6379' if $Ext::Redis::host=~/\//;
		$self->{'service'}=AnyEvent::Redis->new(
			'host' => (split(':',$Ext::Redis::host))[0],
			'port' => (split(':',$Ext::Redis::host))[1] || 6379,
		);
		
		if ($self->{'service'} && $self->{'service'}->ping->recv())
		{
			my %info=%{$self->{'service'}->info()->recv()};
			main::_log("Redis v".$info{'redis_version'}." connected and respondig");
		}
		else
		{
			main::_log("can't connect Redis",1);
			$t->close();
			undef $Ext::Redis::host;
			return undef;
		}
	}
	elsif ($self->{'lib'} eq "RedisDB")
	{
		main::_log("using RedisDB");
		eval
		{
			if ($Ext::Redis::host=~/^\//)
			{
				$self->{'service'} = RedisDB->new(
					'path' => $Ext::Redis::host,
					'raise_error' => 0 # not works
				)
			}
			else
			{
				$self->{'service'} = RedisDB->new(
					'host' => (split(':',$Ext::Redis::host))[0],
					'port' => (split(':',$Ext::Redis::host))[1] || 6379,
					'raise_error' => 0 # not works
				)
			}
		};
		if ($self->{'service'} && $self->{'service'}->ping)
		{
			my %info=%{$self->{'service'}->info()};
			main::_log("Redis v".$info{'redis_version'}." connected and respondig");
		}
		else
		{
			main::_log("can't connect Redis",1);
			$t->close();
			undef $Ext::Redis::host;
			return undef;
		}
	}
	
	$t->close();
	return bless $self, $class;
}

sub DESTROY { }

sub AUTOLOAD
{
	my $self=shift;
	
	(my $method = $AUTOLOAD ) =~ s{.*::}{};
	
	if ($self->{'lib'} eq "AnyEvent")
	{
		if (ref($_[-1]) eq "CODE") # last parameter is sub{}
		{
			# async
			return $self->{'service'}->$method(@_);
		}
		else
		{
			# sync
			return $self->{'service'}->$method(@_)->recv();
		}
	}
	# others
	return $self->{'service'}->$method(@_);
}

1;