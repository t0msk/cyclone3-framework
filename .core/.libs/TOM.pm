package main;

=head1 NAME

TOM

=head1 DESCRIPTION

Universal Cyclone3 (TOM namespace) initialization

This is the primary requested library to all Cyclone3 perl stuff

=cut


=head1 INITIALIZATION

Fill variables:

=over

=item *

$main::request_code="00000000"

=item *

$TOM::hostname

=item *

$TOM::engine default 'tom'

=item *

$tom::p=`pwd`

=item *

$tom::P to domain pwd (if exists)

=item *

$TOM::P='/www/TOM' (installation directory)

=item *

$TOM::hostname

=item *

$TOM::hostname

=back

Request basic libs

=over

=item *

Inline (Config => DIRECTORY => $TOM::InlineDIR)

=item *

L<TOM::Lite|source-doc/".core/.libs/TOM/Lite.pm">

=item *

L<TOM::Overlays|source-doc/".core/.libs/TOM/Overlays.pm">

=item *

L<TOM::Domain|source-doc/".core/.libs/TOM/Domain.pm">

=item *

L<TOM::Engine|source-doc/".core/.libs/TOM/Engine.pm">

=back

Request configuration files

=over

=item *

L<.core/_config/TOM.conf|source-doc/".core/_config/TOM.conf">

=item *

L<_config/TOM.conf|source-doc/"_config/TOM.conf.tmpl">

=item *

_config/${hostname}.conf

=back

=cut

BEGIN
{
	
	$main::request_code="00000000";
	# debug
	$main::stdout=1 if ($ENV{'TERM'} && not defined $main::stdout);
	# hostname
	chomp ($TOM::hostname=`hostname`);
	# Engine
	$TOM::engine='tom' unless $TOM::engine;
	
	$tom::SCRIPT_NAME=$0;
	# i'm fastcgi?
	$tom::fastcgi=1 if $tom::SCRIPT_NAME=~/(tom|fcgi|fpl)$/;
	# TOM installation directory
	$TOM::P="/www/TOM"; # always
	
	# actual path and domain service path
	chomp($tom::p=`pwd`);
	$tom::P=$tom::p;
	$tom::P=~s|^(.*)/!www$|\1|;
	# undef $tom::P if here is not domain service
	$tom::P=$TOM::P unless -e $tom::P.'/local.conf';
	
	# paths libs
	unshift @INC,$TOM::P."/.core/.libs"; # to beginning
	unshift @INC,$TOM::P."/_addons"; # to beginning
	
	# pre-define _log and _applog
	sub _log{return};sub _applog{return};
	
	# TODO:[fordinal] redirect STDERR over function
	#open(STDERR,">>$TOM::P/_logs/[".$TOM::hostname."]STDERR.log");
	
	# C a C++ libraries
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
use POSIX; # 800KB in RAM
use Inline (Config => DIRECTORY => $TOM::InlineDIR);



use TOM::Lite;
use TOM::Overlays;
use TOM::Domain;



BEGIN
{
	#my $t=track TOM::Debug("INC");
	#foreach (@INC){main::_log("$_");}
	#$t->close();
}



eval
{
	require TOM::Engine;
};
if ($@)
{
	my $error_msg=$@;
	TOM::Error::engine($error_msg);
	die "$error_msg";
}

main::_log("<={LIB} TOM loaded");

1;