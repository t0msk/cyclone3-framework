#!/usr/bin/perl


package Net::HTTP::systems;
use strict;
use warnings;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our @list=
(
#	 name			,regexp
	['notregexp'		,'notregexp'],
	['Windows 95'		,'(Win95|Windows 95)'],
	['Windows 98'		,'(Win98|Windows 98)'],
	['Windows 9X'		,'Win 9x'],

	['Windows CE'		,'Windows CE'],
	['Windows ME'		,'Windows ME'],
	['Windows XP'		,'Windows XP'],
	['Windows 2000'		,'Windows 2000'],
	['Windows NT 4.X'	,'(Windows NT 4|WinNT4)'],
	['Windows NT 5.X'	,'(Windows NT 5|WinNT5)'],
	['Windows NT X'		,'(Windows.NT|WinNT)'],
	['Windows X'		,'(Windows|Win32)'],

	['Linux'			,'([Ll]inux|Wget|Lynx)'],
	['Linux (emulator)'	,'CYGWIN'],

	['FreeBSD'		,'FreeBSD'],

	['HP-UX'		,'HP.UX'],	
	['Unix'		,'Unix'],	
	
	['IRIX IP32'	,'IRIX IP32'],
	
	['ATARI'		,'ATARI'],
	
	['SunOS'		,'SunOS'],

	['Mac OS X'		,'Mac OS X'],
	['Mac_PowerPC'		,'(Mac_PowerPC|Macintosh)'],

	['SymbianOS 7.X'	,'SymbianOS/7'],
	['SymbianOS X'		,'Symbian'],
	
	['EPOC32'			,'EPOC32'],
	
	['PalmOS'			,'PalmOS'],

	['Sony'			,'Sony'],
	['SonyEricsson'		,'SonyEricsson'],
	['Nokia'		,'Nokia'],
	['Alcatel'		,'Alcatel'],
	['SAGEM'		,'SAGEM'],


#	['unknown'		,'bot'			,0	,0	,1],
);

#our
sub analyze
{
 return undef unless $_[0];
 my $var=0;
 foreach (@Net::HTTP::systems::list){return $var if $_[0]=~/$Net::HTTP::systems::list[$var][1]/;$var++;}
 return undef;
 #my @ref=@_;
};



# END
1;# DO NOT CHANGE !
