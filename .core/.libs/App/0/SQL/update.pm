#!/bin/perl
package App::0::SQL::update;
use App::0::SQL;
use strict;

our @ISA=("App::0::SQL"); # dedim z SQL (_execute, etc...)

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

sub allocate
{
 my $class=shift;
 my %env=@_;
 my $self={};
  
 die "can't allocate() - need DBH" unless $env{DBH};
 die "can't allocate() - need db" unless $env{db};
  
 %{$self->{env}}=%env;
 $self->{DBH}=$env{DBH};
 $self->{db}=$env{db};

 $self->{limit}=1 unless $self->{limit}=($env{select_limit}=~/^(\d+|\d+,\d+)$/)[0]; # urcim limit
 $self->{s_limit}="LIMIT ".$self->{limit};# urcim vyzor limitu do QUERY
 $self->{limit}=~/^(\d+)$/ || $self->{limit}=~/^(\d+),(\d+)$/; # urcim si rozsahy
 $self->{limit_from}=$1 if $2; # from
 $self->{limit_max}=$2 || $1; # maximalny pocet na vyselectovanie
 
 return bless $self,$class;
}


sub execute
{
 my $self=shift;  
 my $pointer="db0";  
 my $time_duration=(Time::HiRes::gettimeofday)[0]+((Time::HiRes::gettimeofday)[1]/1000000);
 

  
 $self->{Query_duration}=(Time::HiRes::gettimeofday)[0]+((Time::HiRes::gettimeofday)[1]/1000000)-$time_duration; 
 return 1;
}


1;
