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
			$Ext::CacheMemcache::cache = new Ext::CacheMemcache::Redis;
			main::_log("overriding \$Ext::CacheMemcache::cache object");
		}
	}
	
	return $service_;
}

_connect(); # default connection
# call $Redis_{custom_name}=Ext::Redis::_connect('{custom_name}') to create parallel connection
# for example: $Redis_para2=Ext::Redis::_connect('para2');

package Ext::CacheMemcache::Redis;
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
# implemented dancing between redis nodes
package Ext::Redis::service;
use vars qw{$AUTOLOAD};

sub new
{
	my $class=shift;
	my $self={};
	
	$self->{'lib'}="RedisDB";
	
	my %env=@_;
	
	return undef unless $Ext::Redis::host;
	
	my $t=track TOM::Debug("connect",'attrs_'=>$Ext::Redis::host);
	
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
	elsif ($self->{'lib'} eq "RedisDB" && @Ext::Redis::hosts)
	{
		main::_log("using RedisDB (in sharding cluster mode)");
		my $i=0;
		foreach (@Ext::Redis::hosts)
		{
			if ($self->{'services'}[$i] = _redisdb_connect($_->{'host'}))
			{
			}
			else
			{
				if ($_->{'replica_host'})
				{
					if ($self->{'services'}[$i] = _redisdb_connect($_->{'replica_host'}))
					{
						
					}
					else
					{
						
						main::_log("can't connect Redis",1);
						$t->close();
						undef @Ext::Redis::hosts;
						undef $Ext::Redis::host;
						return undef;
						
					}
				}
				else
				{
					# tento host je neaktivny, sic, koncim
					main::_log("can't connect Redis",1);
					$t->close();
					undef @Ext::Redis::hosts;
					undef $Ext::Redis::host;
					return undef;
				}
			};
			$i++;
		}
		
		$self->{'service'} = $self->{'services'}[0] || do
		{
			main::_log("can't connect Redis",1);
			$t->close();
			undef $Ext::Redis::hosts[0];
			return undef;
		};
		
		main::_log(scalar @{$self->{'services'}}." active nodes");
		
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


sub _redisdb_connect
{
#	my $self=shift;
	my $host=shift;
	my $service=shift;
		
		eval
		{
			if ($host=~/^\//)
			{
				$service = RedisDB->new(
					'path' => $host,
					'raise_error' => 0 # not works
				)
			}
			else
			{
				$service = RedisDB->new(
					'host' => (split(':',$host))[0],
					'port' => (split(':',$host))[1] || 6379,
					'raise_error' => 0 # not works
				)
			}
		};
		if ($service && $service->ping)
		{
			my %info=%{$service->info()};
			main::_log("Redis \@$host v".$info{'redis_version'}." connected and respondig");
		}
		else
		{
			main::_log("can't connect Redis \@$host",1);
			return undef;
		}
		
	return $service;
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
	elsif ($self->{'lib'} eq "RedisDB" && $self->{'services'} && @{$self->{'services'}})
	{
		my $service=$self->{'service'};
		
		if ($method=~/^(del|dump|exists|expire|expireat|object|persist|pexpire|pexpireat|pttl|rename|renamenx|sort|ttl|type|get|decr|incr|incrby|set|hdel|hexists|hget|hgetall|hincrby|hkeys|len|hmget|hmset|hset|hvals|blpop|brpop|lindex|linsert|llen|lpop|lpush|lpushx|lrange|lrem|lset|ltrim|rpop|rpush|rpushx|sadd|scard|sismember|smembers|spop|srandmember|srem|zadd|zcard|zcount|zincrby|zrange|zrangebyscore|zrank|zrem|zremrangebyrank|zremrangebyscore|zrevrange|zrevrangebyscore|zrevrank|zscore)$/)
		{
			my $service_number=0;
			my $services=scalar @{$self->{'services'}};
			my $key=$_[0];
			
			use String::CRC32;
			my $crc=crc32($key);
			
			$service_number=$crc % $services;
			
			$service=$self->{'services'}[$service_number];
		}
		
		return $service->$method(@_);
	}
	
#	scalar @{$self->{'services'}}
	
	# others
	return $self->{'service'}->$method(@_);
}

1;
