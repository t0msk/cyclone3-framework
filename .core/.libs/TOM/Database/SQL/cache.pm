package TOM::Database::SQL::cache;

=head1 NAME

TOM::Database::SQL::cache

=cut

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use Encode;
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}
use Ext::Redis::_init;
use Compress::Zlib;
use JSON;
our $json = JSON::XS->new->utf8;

our $debug=0;
our $quiet;$quiet=1 unless $debug;

our $expiration=60;
our $compress=$TOM::Database::SQL::cache::compress || 0;

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
	$env{'id'}=TOM::Digest::hash(Encode::encode('UTF-8',$env{'id'})) if $env{'id'};
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
					# autofix unicode
					foreach (grep {!utf8::is_utf8($db0_line->{$_})} keys %{$db0_line})
						{utf8::decode($db0_line->{$_})};
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
		
		if ($compress)
		{
			$Redis->set('C3|sql|'.$env{'id'},
				'gz|'.Compress::Zlib::memGzip(
					Encode::encode_utf8($json->encode($self->{'value'}))
				),sub {} # in pipeline
			);
		}
		else
		{
			$Redis->set('C3|sql|'.$env{'id'},
				$json->encode($self->{'value'})
				,sub {} # in pipeline
			);
		}
		$Redis->expire('C3|sql|'.$env{'id'},$env{'expire'},sub {}); # set expiration time in pipeline
	}
	else
	{
		main::_log("SQL::cache: created cache object '$env{'id'}' to read data") if $debug;
		
		$self->{'value'} = $Redis->get('C3|sql|'.$env{'id'});
		if ($self->{'value'}=~s/^gz\|//)
		{
			$self->{'value'}=Encode::decode_utf8(Compress::Zlib::memGunzip($self->{'value'}));
		}
		
		$self->{'value'}=$json->decode($self->{'value'})
			if $self->{'value'};
		
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
