#!/usr/bin/perl
package main;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

use TOM;
use Utils::datetime;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );
use Term::ANSIColor;

our %HND;

sub _log
{
	return undef if $TOM::DEBUG_log_file==-1;
	return _log_lite(@_) unless $TOM::engine_ready;
	unshift @_, $TOM::Debug::track_level;
	
	my ($package, $filename, $line) = caller;
	
	my @get=@_;
	#$get[0] = level
	#$get[1] = message
	#$get[2] = rezim 
	#	0=norm	level	not
	#	1=error!	level	mustlog
	#	2=norm	level	mustlog
	#	3=norm	not	mustlog
	#	4=error	not	mustlog
	#$get[3] = engine, or logname
	#$get[4] = 0-local 1-global 2-master
	
	return undef unless $get[1];
	$get[0]=0 if $get[2]==3;
	$get[0]=0 if $get[2]==4;
	return undef if
	(
		($TOM::DEBUG_log_file<$get[0]) &&
		(!$get[2]) &&
		(!$main::IAdm) &&
		(!$main::ITst) &&
		(!$main::debug) &&
		(!$main::stdout)
	);
	
	$get[3]=$TOM::engine unless $get[3];
	$get[1]=~s|[\n\r\t]| |g;
	
	my @ref=("+","-","+","+","-");
	
	my %date=Utils::datetime::ctodatetime(time,format=>1);
	
	my $msec=(Time::HiRes::gettimeofday)[1];
#		$msec='0'.$msec if $msec < 1000;
#		$msec='0.'.$msec;
		$msec=int($msec/100);# useconds to mseconds
	
	my $msg;
		$msg.="[";
		$msg.=sprintf ('%06d', $$);# unless $main::stdout;
		$msg.=";$main::request_code" if ($TOM::Engine eq "pub" && !$main::stdout);
		$msg.="]";
		$msg.="[$date{hour}:$date{min}:$date{sec}.".sprintf("%04d",$msec)."]";
#		"[".sprintf("%02d",$get[0])."]".
		$msg.=" ".(" " x $get[0]).$ref[$get[2]].$get[1];
	if (length($msg)>8048)
	{
		$msg=substr($msg,1,8048);
		$msg.="...";
	}
	
	if (
			($main::stdout && $main::debug && $get[3] eq $TOM::engine) ||
			($main::stdout && $get[3] eq "stdout")
		)
	{
		$msg=" ".(" " x $get[0]).$ref[$get[2]].' '.$get[1] unless $main::debug;
		print color 'green';
		print color 'bold' if $get[1]=~/^</;
		print color 'red' if $ref[$get[2]] eq '-';
		print $msg."\n";
		print color 'reset';
		return 1 if $get[3] eq "stdout";
	}
	elsif ($main::stdout && $ref[$get[2]] eq '-' && $get[3] eq $TOM::engine)
	{
		print STDERR color 'red';
		print STDERR "CYCLONE3STDERR: ".$get[1]." at ".$filename." line ". $line ."\n";
		print STDERR color 'reset';
	}
	
	if (
			($TOM::DEBUG_log_file>=$get[0])||
			($get[2])||
			($main::debug)
		) # logujem v pripade ze som v ramci levelu alebo ide o ERROR
	{
		
		my $file;
		if ($TOM::path_log)
		{
			$file=$TOM::path_log;
			if ($get[4]==1) {} # global
			elsif ($tom::Pm && $get[4]==2) {$file.='/'.($tom::H_orig || $tom::Hm)} # master
			elsif ($tom::H) {$file.='/'.($tom::H_orig || $tom::H)} # local
			$file.='/'; # global
	#		print "file = $file\n";
			if (! -e $file){mkdir $file;chmod (0777,$file)}
		}
		else
		{
			$file=$TOM::P."/_logs/";
			$file=$tom::P."/_logs/" if $tom::P;
			$file=$tom::Pm."/_logs/" if ($tom::Pm && $get[4]==2);
			$file=$TOM::P."/_logs/" if $get[4]==1;
		}
		
		$file.="[".$TOM::hostname."]" if $TOM::serverfarm;
		$file.="$date{year}-$date{mom}-$date{mday}";
		$file.="-$date{hour}" if $TOM::DEBUG_log_file_frag; # rozlisenie na hodiny
		
		$get[0]=0 unless $get[0];
		
		my $filename_full=$file.".".$get[3].".log";
		if (!$HND{$filename_full})
		{
			use Fcntl;
			my $logfile_new;
			$logfile_new=1 unless -e $filename_full;
			# open this handler at first
			open ($HND{$filename_full},">>".$filename_full)
				|| print STDERR "Cyclone3 system can't write into logfile $filename_full $!\n";
			chmod (0666 , $filename_full) if $logfile_new;
		}
		syswrite($HND{$filename_full}, $msg."\n", length($msg."\n"));
	}
	
	return 1;
};



=head2 _log_stdout()

Log message to STDOUT when $main::stdout is enabled. Used to log in console utils

=cut

sub _log_stdout
{
	return undef unless $main::stdout;
	$_[2]="stdout";
	_log(@_);
}


# main::_applog($urovne,"$text",$critique,$global);
# main::_applog(0,"spustam prikaz");
# main::_applog(1,"spustam dalsi","300");
sub _applog
{
	if ($_[0]=~/^\d+$/)
	{
		shift @_;
		#return _log(@_);
	}
	return _log(@_);
}


# tu pridam uz rozoznavanie domen
sub _deprecated
{
	#return 1;
	my ($package, $filename, $line) = caller;
	_log("[".($tom::H || "?domain?")."] ".$_[0]." from $filename:$line",0,"deprecated",1);
}


package TOM::Debug::logs;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

1;# DO NOT CHANGE !
