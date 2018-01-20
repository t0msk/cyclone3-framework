#!/bin/perl
package Ext::Redis;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
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
			$INC{'Ext/CacheMemcache/_init.pm'} = [caller]->[1];
		}
	}
	
	$service_->del('c3process|'.$TOM::hostname.':'.$$);
	
	return $service_;
}

_connect(); # default connection
# call $Redis_{custom_name}=Ext::Redis::_connect('{custom_name}') to create parallel connection
# for example: $Redis_para2=Ext::Redis::_connect('para2');

use Compress::Zlib;
use JSON;
our $json = JSON->new->utf8->convert_blessed->allow_nonref;
our $json_canon = JSON->new->utf8->convert_blessed->allow_nonref->canonical;

our $compression=$Ext::Redis::compression || 0;
our $compression_level=$Ext::Redis::compression_level || 4;

sub _compress
{
	my $data=shift;
	my $env=shift;
	my $json_=$env->{'canonical'} ? $json_canon : $json;
	if (ref($data) eq "SCALAR")
	{
		$$data||="";
		return $$data unless $compression;
		if (length($$data)>512)
		{
			$$data='gz|'.compress(Encode::encode_utf8($$data),$compression_level);
		}
	}
	elsif (ref($data) eq "HASH")
	{
		if (!$compression)
		{
			return $json_->encode($data);
		}
		return 'gz|'.compress(Encode::encode_utf8($json_->encode($data)),$compression_level);
	}
	return $$data;
}

sub _uncompress
{
	my $data=shift;
	$$data=Encode::decode_utf8(uncompress($$data))
		if $$data=~s/^gz\|//;
}

sub _store
{
	my $key=shift;
	my $data=ref($key) eq "REF" ? _compress($$key,{'canonical'=>1}) : _compress($key,{'canonical'=>1});
	my $id=TOM::Digest::hash($data);
	
	$service->set('C3|store|'.$id,$data)
		unless $service->exists('C3|store|'.$id);
	
	$service->expire('C3|store|'.$id,86400*7,sub{});
	
	$$key=$id if ref($key) eq "REF";
	return $id;
}

sub _restore
{
	my $data=shift;
	return $$data=$json->decode(
		_uncompress(
			\$service->get('C3|store|'.$$data)
		) || 'null'
	) if ref($data) eq "SCALAR";
}


package XML::XPath;sub TO_JSON{return undef}

package Ext::CacheMemcache::Redis;
use Storable;
use JSON::XS; # this is faster than Storable

our $format = 'j';# s=storable, j=json (json is ~30% faster)
our $json = JSON::XS->new->ascii->convert_blessed();

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
	
	if ($format eq "j")
	{
		$env{'value'}=$json->encode($env{'value'})
			if ref $env{'value'};
	}
	else
	{
		if (ref $env{'value'})
		{
			$env{'value'}=Storable::nfreeze($env{'value'});
		}
		else
		{
			$env{'value'}=Storable::nfreeze(\$env{'value'});
		}
	}
	
	my $key='C3|M'.$format.'|'.$env{'namespace'}.'|'.$env{'key'};
	
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
	elsif ($env{'expiration'}=~/^(\d+)M$/)
	{
		$expire=$1*60;
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
	my $value=$Ext::Redis::service->get(
		'C3|M'.$format.'|'.$env{'namespace'}.'|'.$env{'key'}
	);
	#print "get $env{'key'}\n" if $tom::test;
	#main::_log("RedisDB=".ref($value)."=".$value,3,"debug");
	if (ref($value) eq "RedisDB::Error::DISCONNECTED")
	{
#		main::_log("RedisDB disconnected",1);
		return undef;
	}
	
	if ($format eq "j")
	{
		return $json->decode($value) if $value=~/^{/;
		return {} if ($value eq "null");
		return $value;
	}
	else
	{
		$value=Storable::thaw($value);
		if (ref $value eq "SCALAR")
		{
			return $$value;
		}
		return $value;
	}
}

sub AUTOLOAD
{
	
}

# for exporting symbols
package Ext::Redis::_init;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
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
use String::CRC32;

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
			'utf8' => 1,
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
						
						main::_log("can't connect any active Redis node, disabling Redis service",1);
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
					'raise_error' => 0, # not works
					'utf8' => 1
				)
			}
			else
			{
				$self->{'service'} = RedisDB->new(
					'host' => (split(':',$Ext::Redis::host))[0],
					'port' => (split(':',$Ext::Redis::host))[1] || 6379,
					'raise_error' => 0, # not works
					'utf8' => 1
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
			main::_log("can't connect Redis $@",1);
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
		
		eval # because of raise error
		{
			if ($host=~/^\//)
			{
				$service = RedisDB->new(
					'path' => $host,
					'raise_error' => 0 # from 2.33 works
				)
			}
			else
			{
				$service = RedisDB->new(
					'host' => (split(':',$host))[0],
					'port' => (split(':',$host))[1] || 6379,
					'raise_error' => 0, # from 2.33 works
					'utf8' => 1
				)
			}
		};
		if ($service)
		{
			my $ping=$service->ping;
			if (!ref($ping) && $ping eq "PONG")
			{
				my %info=%{$service->info()};
				main::_log("Redis \@$host v".$info{'redis_version'}." connected and respondig");
			}
			else
			{
				main::_log("can't connect Redis \@$host",1);
				return undef;
			}
		}
		else
		{
			main::_log("can't connect Redis \@$host",1);
			return undef;
		}
		
	return $service;
}


sub DESTROY { }

my %basic_methods=map {$_ => 1} qw{del dump exists expire expireat object persist pexpire pexpireat pttl rename renamenx sort ttl type get decr incr incrby set hdel hexists hget hgetall hstrlen hincrby hkeys len hmget hmset hset hvals blpop brpop lindex linsert llen lpop lpush lpushx lrange lrem lset ltrim rpop rpush rpushx sadd scard sismember smembers spop srandmember srem zadd zcard zcount zincrby zrange zrangebyscore zrank zrem zremrangebyrank zremrangebyscore zrevrange zrevrangebyscore zrevrank zscore};

sub AUTOLOAD
{
	my $self=shift;
	
	(my $method = $AUTOLOAD ) =~ s{.*::}{};
	
	if ($self->{'lib'} eq "AnyEvent")
	{
=head1
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
=cut
	}
	elsif ($self->{'lib'} eq "RedisDB" && $self->{'services'} && @{$self->{'services'}})
	{
#		pop @_ if ref($_[-1]) eq "CODE";
		
		my $service=$self->{'service'};
		my $service_number=0;
		if ($basic_methods{$method})
		{
			my $services=scalar @{$self->{'services'}};
			my $key=$_[0];
			my $crc=crc32($key);
			$service_number=$crc % $services;
			$service=$self->{'services'}[$service_number];
		}
		my $value;
		if ($service->reply_ready){
			main::_log("[RedisDB] not readed replies",1);
			$service->get_all_replies();
		};
		
		if ($method eq "expire" && $Ext::Redis::expire_modifier && $_[1]=~/^\d+$/) # modify expiration time
		{
			my $durr=int($_[1]*$Ext::Redis::expire_modifier);
#			main::_log("[$service_number] expire $durr");
			$value=eval{$service->$method($_[0],$durr,sub{})};
		}
		else
		{
			$value=eval{$service->$method(@_)};
		}
		
		if ($@)
		{
			my $err=$@;
			main::_log("[RedisDB] error '$err' on host $service_number",1);
			if ($err=~/replies to fetch/)
			{
				$service->get_all_replies();
				eval{$value=$service->$method(@_)};
			}
			return [] if $method eq "hgetall";
			return undef;
		}
		if (!$value)
		{
#			main::_log("RedisDB key not found");
		}
		if (ref($value) eq "RedisDB::Error::DISCONNECTED")
		{
			main::_log("RedisDB disconnected ($method call)",1);
			return [] if $method eq "hgetall";
			return undef;
		}
		return $value;
	}
	
	# others
	return $self->{'service'}->$method(@_);
}

1;
