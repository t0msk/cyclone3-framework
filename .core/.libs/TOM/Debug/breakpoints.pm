#!/usr/bin/perl
package TOM::Debug::breakpoints;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

sub new
{
	my $class=shift;
	my $self={};
	my %env=@_;
	#%{$self->{ENV}}=%{%env};
	return bless $self, $class;
}


sub start
{
	my $self=shift;
	$self->{time}{req}{start}=(Time::HiRes::gettimeofday)[0]+((Time::HiRes::gettimeofday)[1]/1000000);
	$self->{time}{sys}{start}=(times)[1];
	$self->{time}{proc}{start}=(times)[0];
}


sub end
{
	my $self=shift;
	$self->{time}{req}{end}=(Time::HiRes::gettimeofday)[0]+((Time::HiRes::gettimeofday)[1]/1000000);
	$self->{time}{sys}{end}=(times)[1];
	$self->{time}{proc}{end}=(times)[0];
}

sub duration
{
	my $self=shift;
	$self->{time}{req}{duration}=$self->{time}{req}{end}-$self->{time}{req}{start};
	$self->{time}{sys}{duration}=$self->{time}{sys}{end}-$self->{time}{sys}{start};
	$self->{time}{proc}{duration}=$self->{time}{proc}{end}-$self->{time}{proc}{start};
	
	$self->{time}{req}{duration}=int($self->{time}{req}{duration}*1000)/1000;
	$self->{time}{sys}{duration}=int($self->{time}{sys}{duration}*1000)/1000;
	$self->{time}{proc}{duration}=int($self->{time}{proc}{duration}*1000)/1000;
}

sub duration_plus
{
	my $self=shift;
	$self->{time}{req}{duration}+=$self->{time}{req}{end}-$self->{time}{req}{start};
	$self->{time}{proc}{duration}+=$self->{time}{proc}{end}-$self->{time}{proc}{start};
}


sub getvalues
{
	my $self=shift;
}




# END
1;# DO NOT CHANGE !
