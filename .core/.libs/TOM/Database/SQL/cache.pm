package TOM::Database::SQL::cache;

=head1 NAME

TOM::Database::SQL::cache

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


use Digest::MD5  qw(md5 md5_hex md5_base64);


our $debug=0;
our $quiet;$quiet=1 unless $debug;

our $expiration=60;

=head1 FUNCTIONS

=head2 new()

Cache constructor

Nothing special, look into TOM::Database::SQL::execute() function

=cut

sub new
{
	my $class=shift;
	my $self={};
	
	my %env=@_;
	
	$env{'id'}=md5_hex(Encode::encode_utf8($env{'id'})) if $env{'id'};
	$env{'expire'}=$expiration if $env{'expire'} == 1; # don't cache to 1second
	
	if ($env{'sth'} && $env{'id'})
	{
		main::_log("SQL::cache: created cache object to save data '$env{'id'}' expiration=$env{'expire'}") if $debug;
		$self->{'value'}->{'expire'}=$env{'expire'};
		if ($env{'schedule'})
		{
			$env{'expire_original'}=$env{'expire'};
			$env{'expire'}*=10;
			main::_log("SQL::cache: schedule expiration=$env{'expire'}") if $debug;
			$self->{'value'}->{'schedule'}=$env{'schedule'};
			$self->{'value'}->{'schedule_group'}=$env{'schedule_group'};
			my $sql=qq{
				REPLACE INTO TOM.a150_sql(ID,group_ID,cache_duration,datetime_executed)
				VALUES ('$env{'id'}','$env{'schedule_group'}',SEC_TO_TIME($env{'expire_original'}),NOW())
			};
			TOM::Database::SQL::execute($sql,'db_h'=>'sys','quiet'=>1);
		}
		$self->{'value'}->{'db_h'}=$env{'db_h'} if $env{'db_h'};
		$self->{'value'}->{'sql'}=$env{'sql'} if $env{'sql'};
		$self->{'value'}->{'type'}=$env{'type'} if $env{'type'};
		$self->{'value'}->{'err'}=$env{'err'} if $env{'err'};
		$self->{'value'}->{'info'}=$env{'info'} if $env{'info'};
		$self->{'value'}->{'rows'}=$env{'rows'} if $env{'rows'};
		$self->{'value'}->{'time'}=$env{'time'} || time();
		if (!$env{'err'})
		{
			#main::_log("so fetch all data");
			if ($env{'type'} eq "DBI")
			{
				my $line;
				while (my $db0_line=$env{'sth'}->fetchrow_hashref())
				{
					$line++;
					push @{$self->{'value'}->{'fetch'}}, {%{$db0_line}};
				}
			}
			else
			{
				my $line;
				while (my %db0_line=$env{'sth'}->fetchhash)
				{
					$line++;
					push @{$self->{'value'}->{'fetch'}}, {%db0_line};
				}
			}
		}
		# save data
		my $cache=$Ext::CacheMemcache::cache->set(
			'namespace' => "db_cache_SQL",
			'key' => $env{'id'},
			'value' => $self->{'value'},
			'expiration' => $env{'expire'}.'S'
		);
		if ($cache)
		{
			main::_log("SQL::cache: saved to cache") if $debug;
			if ($env{'schedule'} && !$env{'recache'})
			{# don't save last use when only recaching or not scheduling
				$Ext::CacheMemcache::cache->set(
					'namespace' => "db_cache_SQL:use",
					'key' => $env{'id'},
					'value' => time(),
					'expiration' => ($self->{'value'}->{'expire'}*10).'S',
				);
			}
		}
	}
	else
	{
		main::_log("SQL::cache: created cache object '$env{'id'}' to read data") if $debug;
		$self->{'value'}=$Ext::CacheMemcache::cache->get(
			'namespace' => "db_cache_SQL",
			'key' => $env{'id'}
		);
		#main::_log("SQL::cache: readed from cache $self->{'value'}->{'rows'}") if $debug;
		if ($self->{'value'})
		{
			main::_log("SQL::cache: readed from cache") if $debug;
			if ($env{'schedule'} && !$env{'recache'})
			{ # don't save last use when only recaching or not scheduling
				$Ext::CacheMemcache::cache->set(
					'namespace' => "db_cache_SQL:use",
					'key' => $env{'id'},
					'value' => time(),
					'expiration' => ($self->{'value'}->{'expire'}*10).'S',
				);
			}
		}
		else
		{
			return undef;
		}
	}
	
	return bless $self, $class;
}


sub fetchhash()
{
	my $self=shift;
	my $data=shift @{$self->{'value'}->{'fetch'}};
	return %{$data} if $data;
	return
}

sub fetchrow_hashref()
{
	my $self=shift;
	my $data=shift @{$self->{'value'}->{'fetch'}};
	return $data if $data;
	return
}

sub fetch()
{
	my $self=shift;
	my $data=shift @{$self->{'value'}->{'fetch'}};
	my @arr;
	foreach (keys %{$data})
	{
		push @arr,$data->{$_};
	}
	return \@arr if @arr;
	return
}

sub close
{
	my $self=shift;
	
	return undef;
}



sub DESTROY
{
	my $self=shift;
	
	$self={};
	
	return undef;
}

1;
