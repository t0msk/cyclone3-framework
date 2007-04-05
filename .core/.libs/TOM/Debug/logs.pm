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



sub _log
{
	return undef if $TOM::DEBUG_log_file==-1;
	return _log_lite(@_) unless $TOM::engine_ready;
	# spetna kompatibilita, toto sa neskor vyhodi!
	if ($_[0]=~/^\d+$/ && $_[1])
	{
		shift @_;
		my ($package, $filename, $line) = caller;
		return _deprecated("calling _log(number,text) in deprecated format with message '".$_[0]."' from $filename:$line");
	}
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
	#$get[1]=~s|([\n\r\t]| |g;
	$get[1]=~s|\n|\\n|g;
	$get[1]=~s|\r|\\r|g;
	$get[1]=~s|\t|\\t|g;
	
	my @ref=("+","-","+","+","-");
	
	my %date=Utils::datetime::ctodatetime(time,format=>1);
	
	
	my $file;
	if ($TOM::path_log)
	{
		$file=$TOM::path_log;
		if ($get[4]==1) {} # global
		elsif ($tom::Pm && $get[4]==2) {$file.='/'.$tom::Hm} # master
		elsif ($tom::H) {$file.='/'.$tom::H} # local
		$file.='/'; # global
		if (! -e $file){mkdir $file;chmod (0777,$file)}
	}
	else
	{
		$file=$TOM::P."/_logs/";
		$file=$tom::P."/_logs/" if $tom::P;
		$file=$tom::Pm."/_logs/" if ($tom::Pm && $get[4]==2);
		$file=$TOM::P."/_logs/" if $get[4]==1;
	}
	
	$file.="[".$TOM::hostname."]"."$date{year}-$date{mom}-$date{mday}";
	$file.="-$date{hour}" if $TOM::DEBUG_log_file_frag; # rozlisenie na hodiny
	
	my $msg=
		"[".sprintf ('%06d', $$).";$main::request_code]".
		"[$date{hour}:$date{min}:$date{sec}.".sprintf("%07d",((Time::HiRes::gettimeofday)[1]))."]".
		"[".sprintf("%02d",$get[0])."]".
		" ".(" " x $get[0]).$ref[$get[2]].$get[1];
	if (length($msg)>2048)
	{
		$msg=substr($msg,1,2048);
		$msg.="...";
	}
	
	
	if (
			($TOM::DEBUG_log_file>=$get[0])||
			($get[2])||
			($main::ITst)||
			($main::IAdm)||
			($main::debug)
		) # logujem v pripade ze som v ramci levelu alebo ide o ERROR
	{
		$get[0]=0 unless $get[0];
		open (HND_LOG,">>".$file.".".$get[3].".log");
#			|| die "System can't write into logfile ".$file.".".$get[3].".log"."\n";
		chmod (0666,$file.".".$get[3].".log");
		print HND_LOG $msg."\n";
		close HND_LOG; # TODO: [Aben] uzavretie HND mozno zrusit
	}
	
	if (
			$main::stdout && $main::debug ||
			($main::stdout && $get[3] eq "stdout")
		)
	{
		$msg=" ".(" " x $get[0]).$ref[$get[2]].' '.$get[1] unless $main::debug;
		print color 'green';
		print color 'bold' if $get[1]=~/^</;
		print color 'red' if $ref[$get[2]] eq '-';
		print $msg."\n";
		print color 'reset';
	}
	
	if (($main::IAdm)&&($main::FORM{__IAdm_log})&&($pub::output_log))
	{
		my $message=$get[1];
		
		my $var="#D0D0D0";
		$var="#F0F0F0" if $package eq "Tomahawk::module";
		my $div="<div style=\"font-family:monospace;background:$var;color:black;\" align=left>";
		
		$get[0]=0 unless $get[0];
		#if ($get[0]<4){$var="#C0C0C0"};
		$main::IAdm_log.=$div;
		$main::IAdm_log.="[$date{hour}:$date{min}:$date{sec}.";
		$main::IAdm_log.=sprintf("%07d",((Time::HiRes::gettimeofday)[1]))."] ";
		$main::IAdm_log.="[".sprintf("%02d",$get[0])."] ";
		$main::IAdm_log.=("&nbsp;" x $get[0]);
		$main::IAdm_log.=$ref[$get[2]];
		
		my $max=115-$get[0];
		my $i;
		1 while ($message=~s|  | |g);
		while ($message=~s/^(.{1,$max})//)
		{
			my $message_out=$1;
			$message_out=~s|<|&lt;|g;$message_out=~s|>|&gt;|g;
			$message_out=~s| |&nbsp;|g;
			if ($i>=10)
			{
				$main::IAdm_log.=$div.("&nbsp;" x ($get[0]+24))."<span style='color:yellow;'>&nbsp;</span>"."..."."</div>\n";
				last;
			}
			elsif ($i)
			{
				$main::IAdm_log.=$div.("&nbsp;" x ($get[0]+24))."<span style='color:yellow;'>&nbsp;</span>";
			}
			
			if ($message)
			{
				$message_out.="<span style='color:yellow;'>&nbsp;</span>";
			}
			
			$main::IAdm_log.=$message_out."</div>\n";
			
			$i++;
		}
		
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
