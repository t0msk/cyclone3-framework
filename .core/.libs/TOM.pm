package TOM;

$INC{'TOM.pm'} = [caller]->[1];

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
	$TOM::P=$ENV{'CYCLONE3PATH'} || "/srv/Cyclone3"; # always
	$TOM::P_uuid=(stat($TOM::P.'/.core'))[0].'.'.(stat($TOM::P.'/.core'))[1];
	
	# actual path and domain service path
	chomp($tom::p=`pwd`) unless $tom::p;
	$tom::P=$tom::p;
	
	# try to find domain service local.conf
	my $tomP=$tom::P;$tomP=~s|^$TOM::P/||;
	my $max_skip=()=$tomP=~/\//g;
	for (0..$max_skip)
	{
		if (-e $TOM::P.'/'.$tomP.'/local.conf'){$tom::P=$TOM::P.'/'.$tomP;last;}
		$tomP=~s|^(.*)\/.*$|$1|;
	}
	
	# undef $tom::P if here is not domain service
	$tom::P=$TOM::P unless -e $tom::P.'/local.conf';
	$tom::P_media=$tom::P."/!media" unless $tom::P_media;
	
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
	# localized boolean of cache
	$main::cache = $TOM::CACHE;
}


use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
use POSIX; # 800KB in RAM
use Inline (Config => DIRECTORY => $TOM::InlineDIR);

use JSON;
use Tie::IxHash;
use IO::Socket::INET;
# HiRes load
use Time::HiRes qw( gettimeofday );
use Term::ANSIColor;

use TOM::Lite;
use TOM::Digest;
use TOM::Overlays;
#use TOM::Domain;


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


package TOM;
main::_log("<={LIB} TOM loaded");

1;
