package main;

=head1 NAME

TOM

=head1 DESCRIPTION

Univerzálny zavádzač frameworku

Framework v software, je definovany ako struktura v ktorej sa da vyvinut,
organizovat a udrzovat iny software projekt. Framework includuje podporu
pre programy, kniznice a iny software ktory pomaha v spajani roznych
komponentov do projektu.

=cut

BEGIN
{
	
	$main::request_code="00000000";
	# debug
	$main::debug=1 if ($ENV{'TERM'} && not defined $main::debug);
	# hostname
	chomp ($TOM::hostname=`hostname`);
	# Engine
	$TOM::engine='tom' unless $TOM::engine;
	
	# cesta k aktualnemu adresaru a domene
	chomp($tom::p=`pwd`);
	$tom::P=$tom::p;
	$tom::P=~s|^(.*)/!www$|\1|;
	undef $tom::P unless -e $tom::P.'/local.conf'; # zrusit $tom::P ak tu nieje local.conf
	
	$tom::SCRIPT_NAME=$0;
	$tom::fastcgi=1 if $tom::SCRIPT_NAME=~/(tom|fcgi|fpl)$/; # zistujem ci som fastcgi script
	# cesta core
	$TOM::P="/www/TOM"; # vzdy, bez diskusii
	#$tom::P=~s|^.*?/!|$TOM::P/!|; # zrusenie aliasovanej linky, nahradenej za /www/TOM
	# cesta libs
	unshift @INC,$TOM::P."/.core/.libs"; # na zaciatok
	unshift @INC,$TOM::P."/_addons"; # na zaciatok
	unshift @INC,$tom::P."/.libs"; # na zaciatok
	unshift @INC,$tom::P."/_addons"; # na zaciatok
	
	# default log aby som nepadol na volani niecoho neexistujuceho
	sub _log{return};sub _applog{return};
	
	# TODO:[fordinal] presmerovavat STDERR cez funkciu
	#open(STDERR,">>$TOM::P/_logs/[".$TOM::hostname."]STDERR.log");
	
	# C a C++ kniznice
	$TOM::InlineDIR="$TOM::P/_temp/_Inline.[".$TOM::hostname."]";
	mkdir $TOM::InlineDIR if (! -e $TOM::InlineDIR);
	
	$main::time_current=time();
	
	# CONFIG
	# configuration defined by software
	require $TOM::P.'/.core/_config/TOM.conf';
	# configuration defined by this installation ( server farm )
	require $TOM::P.'/_config/TOM.conf';
	# configuration defined by this hostname ( one node in server farm )
	require $TOM::P.'/_config/'.$TOM::hostname.'.conf' if -e $TOM::P.'/_config/'.$TOM::hostname.'.conf';
}


use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
use POSIX; # 800KB
use Inline (Config => DIRECTORY => $TOM::InlineDIR);

=head1 DEPENDS

knižnice:

 Inline;
 TOM::Lite - základné knižnice v obmedzenej forme
 TOM::Engine - základné knižnice každého engine

CONFIG files:

 .core/_config/TOM.conf
 _config/TOM.conf
 _config/${hostname}.conf

=cut

use TOM::Lite;

eval
{
	require TOM::Engine;
};
if ($@)
{
	TOM::Error::engine($@);
	die "$@";
}

1;