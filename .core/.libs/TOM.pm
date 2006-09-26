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

=head1 DEPENDS

knižnice:

 Inline;
 TOM::Lite - základné knižnice v obmedzenej forme
 TOM::Engine - základné knižnice každého engine

konfigurácie:

 _config.sg/TOM.conf
 _config/TOM.conf

=cut

use TOM::Lite;
use TOM::Engine;

# hlavna konfiguracia
require $TOM::P."/.core/_config.sg/TOM.conf";
require $TOM::P."/.core/_config/TOM.conf";


1;