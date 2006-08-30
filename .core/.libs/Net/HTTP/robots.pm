#!/usr/bin/perl


package Net::HTTP::robots;
use strict;
#use warnings;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our @list=
(
#	 name			,regexp			,Dpage	,Dcook	,cache
	['testbot'					,'pleasenotregexp!'],
	['Jyxo.cz'					,'^Jyxobot'			,1	,1	,1], # velmi agresivny!
	['Google.com'				,'^Googlebot'		,0	,1	,1],
	['fast.no'					,'^FAST-WebCrawler'	,0	,1	,1],
	['search.msn.com'			,'^msnbot'			,0	,1	,1],
	['www.nameprotect.com'		,'^NPBot'			,0	,1	,1],
	['woko.cz'					,'^Woko robot'		,0	,1	,1],
	['Nutch.org'				,'^NutchOrg'		,0	,1	,1],
	['szukacz.pl'				,'^Szukacz'		,0	,1	,1],
	['SuperBot'				,'^SuperBot'		,0	,1	,1],
	['NaverRobot'				,'NaverRobot'		,0	,1	,1],
	['icsbot'					,'^icsbot'			,0	,1	,1],
	['kuloko-bot'				,'^kuloko-bot'		,0	,1	,1],
	['exo.sk'					,'^EXO'			,0	,1	,1],
	['ucw.cz/holmes'				,'^holmes'			,1	,1	,1],	# nevie robit s %7C
	['WISEnutbot.com'			,'ZyBorg'			,0	,1	,1],
	['turnitin.com'				,'TurnitinBot'		,0	,1	,1],
	['baidu.com'				,'Baiduspider'		,1	,1	,1],	#agressive
	['Teleport'					,'^Teleport'		,1	,1	,1],	#agressive
	['Inktomi.com (Slurp bot)'		,'Slurp'			,0	,1	,1],	#agressive????
	['grub.org'					,'grub-client'		,0	,1	,1],
	['dir.com'					,'Pompos'			,0	,1	,1],
	['check_http'				,'check_http'		,0	,1	,1],
	['walhello.com'				,'appie'			,0	,1	,1],
	['almaden.ibm.com/cs/crawler'	,'ibm.com.*crawler'	,0	,1	,1],
	['Tkensaku.com'				,'Tkensaku',		,0	,1	,1],
	['LinkWalker'				,'LinkWalker',		,0	,1	,1],
	['Xenu Link Sleuth 1.X	'		,'Xenu Link Sleuth'	,0	,1	,1],	# check broken links

	['unknown'				,'^$'				,1	,1	,1], # neznamy
	['unknown_bot'			,'bot'				,0	,1	,1], # neznamy robot
	['unknown_crawler'		,'crawler'			,0	,1	,1], # neznamy crawler
	['unknown_spider'		,'spider'			,0	,1	,1], # neznamy spider
#	['unknown'		,'bot'			,0	,0	,1],
);

#our
sub analyze
{
 return undef unless $_[0];my $var=0;
 foreach (@Net::HTTP::robots::list){return $var if $_[0]=~/$Net::HTTP::robots::list[$var][1]/i;$var++;}
 #foreach (@Net::HTTP::robots::list){return $var if $_[0]=~/$Net::HTTP::robots::list[$var][1]/;$var++;}
 return undef;
 #my @ref=@_;
};



# END
1;# DO NOT CHANGE !
