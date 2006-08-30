package main;
use Fcntl;
#
# HLAVNY ZAVADZAC VSETKYCH ENGINES
#
# Framework v software, je definovany ako struktura v ktorej sa da vyvinut,
# organizovat a udrzovat iny software projekt. Framework includuje podporu
# pre programy, kniznice a iny software ktory pomaha v spajani roznych
# komponentov do projektu.
#

BEGIN
{
	
	$main::request_code="00000000";
	# debug
	$main::debug=1 if $ENV{'TERM'};
	# hostname
	$TOM::hostname=`hostname`;chomp($TOM::hostname);
	#
	$TOM::engine='tom' unless $TOM::engine;
	# cesta domain
	$tom::P=`pwd` unless $ENV{SCRIPT_FILENAME} && do
	{$tom::P=$ENV{SCRIPT_FILENAME};$tom::P=~s|(.*)/.*?/||;$tom::P=$1;};
	$tom::P=~s|(.*)/.*?\n$|\1|;
	$tom::SCRIPT_NAME=$0;
	$tom::fastcgi=1 if $tom::SCRIPT_NAME=~/(tom|fcgi|fpl)$/; # zistujem ci som fastcgi script
	# cesta core
	$TOM::P="/www/TOM"; # vzdy, bez diskusii
	# cesta libs
	unshift @INC,$TOM::P."/.core/.libs"; # na zaciatok
	unshift @INC,$tom::P."/.libs"; # na zaciatok
	
	# default log aby som nepadol na volani niecoho neexistujuceho
	sub _log{return};sub _applog{return};
	
	# TODO:[fordinal] presmerovavat STDERR cez funkciu
	#open(STDERR,">>$TOM::P/_logs/[".$TOM::hostname."]STDERR.log");
	
	# C a C++ kniznice
	$TOM::InlineDIR="$TOM::P/_temp/_Inline.[".$TOM::hostname."]";
	mkdir $TOM::InlineDIR if (! -e $TOM::InlineDIR);
	
	# data adresar
	mkdir $tom::P."/_data" if (! -e $tom::P."/_data");
	
	# udrziavaci USRM adresar
	mkdir $tom::P."/_data/USRM" if (! -e $tom::P."/_data/USRM");
	
	# debug adresare
	mkdir $tom::P."/_logs/_debug" if (! -e $tom::P."/_logs/_debug");
	
	# odosielanie emailov "natvrdo"
	#mkdir $TOM::P."/_temp/_email" if (! -e $TOM::P."/_temp/_email");
	
}


use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
use Inline (Config => DIRECTORY => $TOM::InlineDIR);

# hlavna konfiguracia
require $TOM::P."/.core/_config.sg/TOM.conf";
require $TOM::P."/.core/_config/TOM.conf";


# len zakladna funkcia, bude prevalena TOM::Debug::logs
sub _log_lite
{
	if ($_[0]=~/^\d+$/)
	{
		shift @_;
		my ($package, $filename, $line) = caller;
		return _deprecated("calling _log(number,text) in deprecated format with message '".$_[0]."' from $filename:$line");
	}
	unshift @_, $TOM::Debug::track_level;
	
	my @get=@_;
	return undef unless $get[1];
	
	$get[3]=$TOM::engine unless $get[3];
	$get[1]=~s|[\n\r]||g;
	
	$get[0]=0 if $get[2]==3;
	$get[0]=0 if $get[2]==4;
	my @ref=("+","-","+","+","-");
	
	my %date;#=Utils::datetime::ctodatetime(time,format=>1);
	
	(
		$date{sec},
		$date{min},
		$date{hour},
		$date{mday},
		$date{mom},
		$date{year},
		undef,
		undef,
		undef
	) = localtime(time);
		
	# formatujem cas
	($date{sec},$date{min},$date{hour},$date{mday},$date{mom},$date{year}) = 
		(sprintf ('%02d', $date{sec}),sprintf ('%02d', $date{min}),sprintf ('%02d', $date{hour}),sprintf ('%02d', $date{mday}),sprintf ('%02d', $date{mom}+1),$date{year}+1900);
	
	
	my $filename=$tom::P."/_logs/";
	$filename=$tom::Pm."/_logs/" if ($tom::Pm && $get[4]==2);
	$filename=$TOM::P."/_logs/" if $get[4]==1;
	$filename.="[".$TOM::hostname."]"."$date{year}-$date{mom}-$date{mday}";
	$filename.=".".$get[3].".log";
	
	$get[0]=0 unless $get[0];
	
	my $msg=
		"[".sprintf ('%06d', $$).";$main::request_code]".
		"[$date{hour}:$date{min}:$date{sec}.???????]".
		"[".sprintf("%02d",$get[0])."]".
		" ".(" " x $get[0]).$ref[$get[2]].$get[1];
	
	
	#sysopen(HND_LOG, $filename, O_WRONLY|O_APPEND|O_CREAT, 0660) || return undef;
	open (HND_LOG,">>".$filename) || return undef;
	chmod (0660,$filename);
	print HND_LOG $msg."\n";
	close HND_LOG;
	
	print $msg."\n" if $main::debug;
	
	return 1;
};

sub _log {_log_lite(@_);}
sub _applog {_log_lite(@_);}
sub _deprecated
{
	#return 1;
	my ($package, $filename, $line) = caller;
	_log_lite($_[0]." from $filename:$line",0,"deprecated",1);
}











package TOM;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__." (null) + _log + conf");};}





package TOM::Net::email;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__." (Lite)");};}

sub send
{
	my $ID=time()."-".$$."-".sprintf("%07d",int(rand(10)));
	my %env=@_;
	
	main::_log("saving email into file $ID");
	
	open(HND_mail,">".$TOM::P."/_temp/_email-".$ID) || die "can't send email over file!\n";
	print HND_mail "$env{from}\n";
	print HND_mail "$env{to}\n";
	print HND_mail $env{body}."\n";
	close (HND_mail);
	chmod 0666, $TOM::P."/_temp/_email-".$ID;
	
	return 1;
}





package TOM::Error;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__." (Lite)");};}

my $date=`date "+%a,%e %b %Y %H:%M:%S %z (%Z)"`;$date=~s|[\n\r]||g;

our $engine_email_lite=<<"HEADER";
Return-Path: <TOM\@webcom.sk>
From: "$TOM::hostname" <TOM\@$TOM::hostname>
To: "TOM" <TOM\@webcom.sk>
Subject: [ERR][ENGINE]
Date: $date
List-Id: TOM3
MIME-Version: 1.0
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: 7bit

<%ERROR%>
HEADER

sub engine_lite
{
	#
	#
	# Tato chyba moze nastat pri inicializovani core
	# teda pytani kniznic pomocou request "TOM::Engine::'engine'"
	#
	#
	
	my $var=join(". ",@_);$var=~s|\n| |g;
	
	# zalogujeme chybu
	main::_log("[ENGINE][".($tom::H?$tom::H:$tom::type?$tom::type:"?")." on $TOM::hostname] $var",1);
	main::_log("[ENGINE][".($tom::H?$tom::H:$tom::type?$tom::type:"?")." on $TOM::hostname] $var",1,$TOM::engine.".err",1);
	
	# co vyplujem von?
	
	# ZAPISANIE ERROR EMAILU DO textoveho suboru
	my $email=$engine_email_lite;
	$email=~s|<%ERROR%>|$var|;
	
	TOM::Net::email::send(
		'from'=>"TOM\@$TOM::hostname",
		'to'=>"TOM\@webcom.sk",
		'body'=>$email,
	);
	
}

sub engine
{
	engine_lite(@_);
}







package TOM::Debug;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__." (trackpoints)");};}

our $track_level=0;
our @tracks;
our @tracks_obj;
our %namespace;

sub track
{
	my $class=shift;
	my $self={};
	
	$self->{'name'}=shift;
	my %env=@_;
	
	main::_log("<$self->{name}>");
	
	$track_level++;
	$self->{'level'}=$track_level;
	
	$tracks[$track_level]=$self->{'name'};
	
	($self->{'package'}, $self->{'filename'}, $self->{'line'}) = caller;
	
	#eval "$self->{'package'}"."::"."debug";
	
	$self->{'namespace'}=$env{'namespace'};
	
	$self->{'time'}{req}{start}=(Time::HiRes::gettimeofday)[0]+((Time::HiRes::gettimeofday)[1]/1000000);
	$self->{'time'}{proc}{start}=(times)[0];
	
	$tracks_obj[$track_level]=bless $self, $class;
	return $tracks_obj[$track_level];
}



sub close
{
	my $self=shift;
	
	if ($self->{DESTROY})
	{
		my ($package, $filename, $line) = caller;
		main::_log("Ooops! from '$filename:$line' This track named '$self->{name}' has been destroyed by calling from '$self->{'DESTROY_filename'}:$self->{'DESTROY_line'}'. Track is generated on '$self->{'filename'}:$self->{'line'}'");
		return undef;
	}
	
	if ($self->{level}<$track_level)
	{
		my ($package, $filename, $line) = caller;
		main::_log("Ooops! from '$filename:$line' Can't close this track! You must close first track named '$tracks[$track_level]'. Trying to close");
		$tracks_obj[$track_level]->close();
		$self->close();
		return undef;
	}
	
	$track_level--;
	
	$self->{'time'}{req}{end}=(Time::HiRes::gettimeofday)[0]+((Time::HiRes::gettimeofday)[1]/1000000);
	$self->{'time'}{proc}{end}=(times)[0];
	$self->{'time'}{req}{duration}=$self->{'time'}{req}{end}-$self->{'time'}{req}{start};
	$self->{'time'}{proc}{duration}=$self->{'time'}{proc}{end}-$self->{'time'}{proc}{start};
	$self->{'time'}{req}{duration}=int($self->{'time'}{req}{duration}*10000)/10000;
	$self->{'time'}{proc}{duration}=int($self->{'time'}{proc}{duration}*10000)/10000;
	
	
	if ($self->{'namespace'})
	{
		if ($tracks_obj[$track_level]->{'namespace'} ne $self->{'namespace'})
		{
			#main::_log("collect namespace '".$self->{'namespace'}."'");
			$namespace{$self->{'namespace'}}{'time'}{'req'}{'duration'}+=$self->{'time'}{'req'}{'duration'};
			$namespace{$self->{'namespace'}}{'time'}{'proc'}{'duration'}+=$self->{'time'}{'proc'}{'duration'};
		}
	}
	
	
	$self->{'DESTROY'}=1;
	($self->{'DESTROY_package'}, $self->{'DESTROY_filename'}, $self->{'DESTROY_line'}) = caller;
	
	main::_log("</$self->{name}> (req:".($self->{'time'}{req}{duration})." proc:".($self->{'time'}{proc}{duration}).")");
	
}


sub clear_namespaces
{
	%namespace=();
}












1;