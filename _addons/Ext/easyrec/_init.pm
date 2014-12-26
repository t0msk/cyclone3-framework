#!/bin/perl
package Ext::easyrec;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN
{
	main::_log("<={LIB} ".__PACKAGE__);
}

our $ua;
BEGIN
{
	require LWP::UserAgent;
	$ua = LWP::UserAgent->new;
	$ua->timeout(1);
	$ua->env_proxy;
	$Ext::easyrec=1 if $Ext::easyrec::location;
}

BEGIN {shift @INC;}

our $debug=0;


sub call
{
	return undef unless $Ext::easyrec;
	my %env=@_;
	
	my $url = URI->new(($Ext::easyrec::location || "http://localhost:8080/easyrec-web")."/api/1.0/".($env{'action'} || 'view'));
	delete $env{'action'};
	
	$env{'tenantid'}=$env{'tenantid'} || $Ext::easyrec::tenantid || 'EASYREC_DEMO';
	$env{'apikey'}=$env{'apikey'} || $Ext::easyrec::apikey;
#	$env{'itemid'}='1';
#	$env{'itemdescription'}='description';
	$env{'itemurl'}=$tom::H_www.$main::ENV{'REQUEST_URI'};
#	$form{'itemimageurl'}='/img/1';
	$env{'userid'}=$env{'userid'} || $main::USRM{'ID_user'} || '0';
	$env{'sessionid'}=$main::USRM{'ID_session'} || '0';
#	$form{'actiontime'}='23_06_2013_00_42_59';
#	$form{'ratingvalue'}='10';
	$env{'itemtype'}=$env{'itemtype'} || 'ITEM';
	
	$url->query_form(%env);
	return $ua->get($url);
}

1;
