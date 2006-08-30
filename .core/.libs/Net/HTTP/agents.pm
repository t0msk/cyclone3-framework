#!/usr/bin/perl
package Net::HTTP::agents;
# PRESUNIEM NESKOR DO Net::HTTP::UserAgent::browsers;???

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use strict;
use warnings;


our @list=
(
#	 name			,regexp
	['notregexp'		,'notregexp'],
	['MSIE 3.X'			,'MSIE 3'],
	['MSIE 4.X'			,'MSIE 4'],
	['MSIE 5.X'			,'MSIE 5'],
	['MSIE 6.X'			,'MSIE 6'],
	['MSIE X'			,'(iexplore.exe|IEXPLORE.EXE)'],	

	['Netscape 6.X'			,'Netscape6'],
	['Netscape 7.X'			,'Netscape.7'],

	['Mozilla Firebird 0.6'		,'Firebird.0\.6'],
	['Mozilla Firebird 0.7'		,'Firebird.0\.7'],
	['Mozilla Firebird 0.8'		,'Firebird.0\.7'],
	['Mozilla Firefox 0.8'		,'Firefox.0\.8'],
	['Mozilla 5.X'			,'Mozilla.5.*(Linux|BSD|SunOS)'],
	
	['Safari 85'				,'Safari.85'],
	['Safari 100'			,'Safari.100'],
	['Safari 125'			,'Safari.125'],

	['Doris'			,'Doris'],

	['Scooter'			,'Scooter'],
	
	['Mitsu'			,'Mitsu'],	

	# DOWNLOADERS
	['GetRight'				,'GetRight'],
	['FlashGet'				,'FlashGet'],
	['AvantGo'				,'Avant'],
	['WebCopier'			,'WebCopier'],
	['WebStripper'			,'WebStripper'],
	['WebWasher'			,'WebWasher'],
	['Wget'				,'(Wget|wget)'],
	['Web Downloader 6.X'	,'Web Downloader.6'],
	['curl'				,'curl'],
	['W3C Validator'			,'W3C_Validator'],
	['libwww'				,'libwww'],

	# MOBILE
	['UP Browser'				,'UP.Browser'],
	['MobileExplorer'				,'MobileExplorer'],
	['Klondike'					,'Klondike'],
#	['MIDP '			,'Klondike'],
	['Nokia MobileBrowser'		,'Nokia(3|5|6|7|8)'],
	['Nokia (unknown)'			,'Nokia'],
	['SonyEricsson MobileBrowser'	,'SonyEricsson(P800|T100|T300|T610|Z600|T20)'],
	['SonyEricsson (unknown)'		,'SonyEricsson'],

	# MEDIA PLAYERS
	['MPlayer (linux)'			,'MPlayer'],
	['NSPlayer'					,'NSPlayer'],
	['Windows Media Player'		,'Windows.Media.Player'],
	['VLC Media Player'			,'VLC.Media.Player'],
	['RealMedia Player'			,'RealMedia'],
	['WinampMPEG'				,'WinampMPEG'],
	['XINE Media Player (linux)'		,'xine'],
	['DivX Media Player 2.X'		,'DivX Player 2'],
	['XMMS Audio Player 1.X (linux)'	,'xmms.1'],	

	# LINUX BROWSERS
	['Konqueror 3.X'		,'Konqueror/3'],
	['Galeon 1.X'		,'Galeon.1'],
	['Elinks'			,'Elinks'],
	['Lynx'			,'Lynx'],
	['Links'			,'Links'],
	['Dillo'			,'Dillo'],


	['Epiphany 1.X'			,'Epiphany.1'],
	
	['AWeb 3.X (Amiga)'		,'AWeb.3'],	

	['Opera 5.X'			,'Opera.5'],
	['Opera 6.X'			,'Opera.6'],		
	['Opera 7.X'			,'Opera.7'],

	['Mozilla 1.X (unknown compatible)'	,'Mozilla.1'],
	['Mozilla 2.X (unknown compatible)'	,'Mozilla.2'],
	['Mozilla 3.X (unknown compatible)'	,'Mozilla.3'],
	['Mozilla 4.X (unknown compatible)'	,'Mozilla.4'],
	['Mozilla 5.X (unknown compatible)'	,'Mozilla.5'],

#	['unknown'		,'bot'			,0	,0	,1],
);


#our
sub analyze
{
 return undef unless $_[0];
 my $var=0;
 foreach (@Net::HTTP::agents::list){return $var if $_[0]=~/$Net::HTTP::agents::list[$var][1]/i;$var++;}
 return undef;
 #my @ref=@_;
};



# END
1;# DO NOT CHANGE !
