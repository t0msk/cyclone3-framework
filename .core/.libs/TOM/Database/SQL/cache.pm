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
		$self->{'value'}->{'err'}=$env{'err'} if $env{'err'};
		$self->{'value'}->{'info'}=$env{'info'} if $env{'info'};
		$self->{'value'}->{'rows'}=$env{'rows'} if $env{'rows'};
		$self->{'value'}->{'time'}=$env{'time'} || time();
		if (!$env{'err'})
		{
			#main::_log("so fetch all data");
			my $line;
			while (my %db0_line=$env{'sth'}->fetchhash())
			{
				$line++;
				#main::_log("fetched line [$line]");
				push @{$self->{'value'}->{'fetch'}}, {%db0_line};
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
