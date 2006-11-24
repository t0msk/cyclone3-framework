#!/bin/perl
package App::0::SQL;
use App::0::SQL::functions;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our @ISA=("App::0::SQL::functions"); # pytam si abstrakciu


use TOM::Database::SQL;


sub _new
{
 my $class=shift;
 my %env=@_;
 my $self={};
  
=head1
 foreach (keys %env)
 {
 	main::_log("_new key $_ $env{$_}");
 }
=cut
  
 die "can't allocate() - need DBH" unless $env{DBH};
 die "can't allocate() - need db" unless $env{db};
  
 %{$self->{ENV}}=%env;
 $self->{DBH}=$env{DBH};
 $self->{db}=$env{db};
 
 main::_log("continue");

# $self->{limit}=1 unless $self->{limit}=($env{select_limit}=~/^(\d+|\d+,\d+)$/)[0]; # urcim limit
# $self->{s_limit}="LIMIT ".$self->{limit};# urcim vyzor limitu do QUERY
# $self->{limit}=~/^(\d+)$/ || $self->{limit}=~/^(\d+),(\d+)$/; # urcim si rozsahy
# $self->{limit_from}=$1 if $2; # from
# $self->{limit_max}=$2 || $1; # maximalny pocet na vyselectovanie
 
 return bless $self,$class;
 return 1;
}

sub _prepare
{
	my $self=shift;
	
	# vyprazdnenie
	if ((!$self->{ENV}{select_limit}) && (exists $self->{ENV}{select_limit}))
	{
		delete $self->{limit};
		delete $self->{s_limit};
#		main::_log("rusim limit");
	}
	else
	{
#		main::_log("nechavam limit ");
#		main::_log("exists") if exists $self->{limit};
#		main::_log("null") unless $self->{limit};
		$self->{limit}=1 unless $self->{limit}=($self->{ENV}{select_limit}=~/^(\d+|\d+,\d+)$/)[0]; # urcim limit
		$self->{s_limit}="LIMIT ".$self->{limit};# urcim vyzor limitu do QUERY
		$self->{limit}=~/^(\d+)$/ || $self->{limit}=~/^(\d+),(\d+)$/; # urcim si rozsahy
		$self->{limit_from}=$1 if $2; # from
		$self->{limit_max}=$2 || $1; # maximalny pocet na vyselectovanie
	}
	
	
	return 1;
}


sub SetENV
{
 my $self=shift;
 die "object not defined" unless $self;
 my %env=@_; 
 foreach my $key(keys %env){$self->{ENV}{$key}=$env{$key};} 
 return 1;
}

sub SetENV_end
{
 my $self=shift;
 die "object not defined" unless $self;
 my %env=@_; 
 foreach my $key(keys %env){$self->{ENV}{$key}.=$env{$key};} 
 return 1;
}

sub GetENV
{
 my $self=shift;
 die "object not defined" unless $self;
 return $self->{ENV}{$_[0]};
}

sub GetENV_all
{
 my $self=shift;
 die "object not defined" unless $self;
 return %{$self->{ENV}};
}



# STRINGY

sub errstr
{
 my $self=shift; 
 return $self->{errstr};
}

sub rows
{
 my $self=shift; 
 return $self->{rows};
}





# MUSI BYT SUCASTOU OBJECTU KUA!!!!! (nedavaj to von!)
# kvoli errstr
sub _execute
{
	my $self=shift;
	my $pointer;
	return undef unless my $query=shift;
	
	#main::_log("QUERY:$query");
	
	eval
	{
		local *STDERR;open(STDERR,">>/dev/null") || die "Cant redirect STDERR: $!\n";
		
		my %sth=TOM::Database::SQL::execute($query,'db_h'=>"main",'quiet'=>0,'log'=>0);
		if ($sth{'sth'})
		{
			$pointer=$sth{'sth'};
		}
		else
		{
			die "SQL ERROR: ".$sth{'err'};
		}
		
	};
	
	if ($@)
	{
		die "$@";
	}
	
	return undef if $self->{errstr}=$@;
	
	return $pointer;
}

1;
