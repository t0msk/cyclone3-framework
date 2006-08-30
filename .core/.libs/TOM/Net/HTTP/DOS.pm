#!/usr/bin/perl
# DOS withstand
package TOM::Net::HTTP::DOS;
use System::meter; # TODO: [Aben] Pridat do System::meter fciu na zistenie poctu procesorov
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our %restricted_IP;
our @requests;
our %analyzed_IP;

our $last_time_load;
our $last_time_analyze;
our $load;

sub processENV(\%)
{
	my $hash=shift;
	
	$hash->{'REMOTE_ADDR'}="localhost" unless $hash->{'REMOTE_ADDR'};
	
#	main::_log("analyze request from IP:".($hash->{REMOTE_ADDR})."",0,"DOS",1);
	
	# skontrolujem ci je tato IP medzi DOS
	# TODO: spravit restrict na subory a nie na array
	if ($restricted_IP{$hash->{'REMOTE_ADDR'}})
	{
		$restricted_IP{$hash->{'REMOTE_ADDR'}}++;
		#main::_log("REJECT ".$hash->{REMOTE_ADDR},1,"DOS",1);
		main::_log("[".$tom::H."] DOS: REJECT IP: ".$hash->{'REMOTE_ADDR'},1,"DOS",1);
		return 1;
	}
	
	
	# dotaz na vysku loadu robim len kazdych 10 sekund
	# to v podstate znamena rychlost reakcie jedneho processu na DOS utok
	if ($last_time_load<time-10)
	{
		$load=(System::meter::getLoad)[0];
#		main::_log("1m load is $load",0,"DOS",1);
		$last_time_load=time;
	}
	
	
	# je podozrivo vysoke vytazenie?
	return undef if $load<5.0;
	
	
	main::_log("[".$tom::H."] possible DOS: 1m load is too high: $load",1,"DOS_warn",1);
	
	
	# idem teda analyzovat vsetky requesty
	push @requests,
	{
		IP=>$hash->{'REMOTE_ADDR'},
		request_time=>time
	};
#	main::_log("in memory requests:".(@requests),0,"DOS",1);
	
	
	return undef if ($last_time_analyze>time-10); # analyza kazdych 10 sekund
	$last_time_analyze=time;
	
	
	main::_log("[".$tom::H."] analyze possible DOS",1,"DOS_warn",1);
	
	# cleaning
	while ($requests[0]{request_time}<time-60) # data starsie ako minuta ma nezaujimaju
	{
#		main::_log("deleting old request",0,"DOS",1);
		shift @requests;
	};
	
	
	my %hash0;
	for my $i (0..@requests-1)
	{
#		main::_log("IP:".$requests[$i]{IP},0,"DOS",1);
		$hash0{$requests[$i]{IP}}++;
	}
	
	foreach (sort {$hash0{$b} <=> $hash0{$a}} keys %hash0)
	{
		main::_log("[".$tom::H."] max requests from IP:$_ = ".$hash0{$_}."/min",1,"DOS_warn",1);
		
		if ($hash0{$_}>30)
		{
			main::_log("[".$tom::H."] add to REJECT ".$hash->{'REMOTE_ADDR'},1,"DOS_warn",1);
			main::_log("[".$tom::H."] add to REJECT ".$hash->{'REMOTE_ADDR'},1,"DOS",1);
			$restricted_IP{$_}++;
		}
		# TODO: [Aben] na rejectnutu IP by bolo dobre dat "dig"
		last;
		#if ($hash0{$_})>
	}
	
	
	return undef;
}


















# END
1;# DO NOT CHANGE !
