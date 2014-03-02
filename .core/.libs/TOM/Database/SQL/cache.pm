package TOM::Database::SQL::cache;

=head1 NAME

TOM::Database::SQL::cache

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


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
	
#	print "!$env{'id'}!\n";
	$env{'id'}=TOM::Digest::hash($env{'id'}) if $env{'id'};
	$env{'expire'}=$expiration if $env{'expire'} == 1; # don't cache to 1second
	
	if ($env{'sth'} && $env{'id'})
	{
		main::_log("SQL::cache: created cache object to save data '$env{'id'}' expiration=$env{'expire'}") if $debug;
		$self->{'value'}->{'expire'}=$env{'expire'};
		$self->{'value'}->{'db_h'}=$env{'db_h'} if $env{'db_h'};
		$self->{'value'}->{'sql'}=$env{'sql'} if $env{'sql'};
		$self->{'value'}->{'type'}=$env{'type'} if $env{'type'};
		$self->{'value'}->{'err'}=$env{'err'} if $env{'err'};
		$self->{'value'}->{'info'}=$env{'info'} if $env{'info'};
		$self->{'value'}->{'rows'}=$env{'rows'};# if $env{'rows'};
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
				# finish it after fetch all
				# http://board.issociate.de/thread/160584/Attempt-to-initiate-a-new-SQL-Server-operation-with-results-pending.html
				$env{'sth'}->finish();
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
	}
	else
	{
		main::_log("SQL::cache: created cache object '$env{'id'}' to read data") if $debug;
		$self->{'value'}=$Ext::CacheMemcache::cache->get(
			'namespace' => "db_cache_SQL",
			'key' => $env{'id'}
		);
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

sub finish
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
