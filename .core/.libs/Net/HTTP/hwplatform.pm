#!/usr/bin/perl


package Net::HTTP::hwplatform;
use strict;
use warnings;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our @list=
(
#	 name			,regexp
	['notregexp'			,'notregexp'],

	['PC Intel 386'			,'i386'],
	['PC Intel 486'			,'i486'],
	['PC Intel 586'			,'i586'],
	['PC Intel 686'			,'i686'],
	['PC'				,'(Windows.(NT|95|98|ME|2000)|Win9|WinNT|Win.9)'],


	['Mobile Sony CMD-J7/J70'	,'Sony CMD.J7.J70'],

	['Mobile Nokia 3100'			,'Nokia3100'],
	['Mobile Nokia 3330'			,'Nokia3330'],
	['Mobile Nokia 3410'			,'Nokia3410'],
	['Mobile Nokia 3510'			,'Nokia3510'],
	['Mobile Nokia 3510i'			,'Nokia3510i'],
	['Mobile Nokia 3650'			,'Nokia3650'],
	['Mobile Nokia 5210'			,'Nokia5210'],
	['Mobile Nokia 6100'			,'Nokia6100'],
	['Mobile Nokia 6210'			,'Nokia6210'],
	['Mobile Nokia 6310i'			,'Nokia6310i'],
	['Mobile Nokia 6510'			,'Nokia6510'],
	['Mobile Nokia 6600'			,'Nokia6600'],
	['Mobile Nokia 6610'			,'Nokia6610'],
	['Mobile Nokia 7210'			,'Nokia7210'],
	['Mobile Nokia 7250I'			,'Nokia7250I'],
	['Mobile Nokia 7650'			,'Nokia7650'],
	['Mobile Nokia 8310'			,'Nokia8310'],
	['Mobile Nokia N-Gage'			,'NokiaN.Gage'],
#	['Mobile Nokia'			,'Nokia'],

	['Mobile SonyEricsson P800'		,'SonyEricssonP800'],
	['Mobile SonyEricsson T100'		,'SonyEricssonT100'],
	['Mobile SonyEricsson T300'		,'SonyEricssonT300'],
	['Mobile SonyEricsson T310'		,'SonyEricssonT310'],
	['Mobile SonyEricsson T610'		,'SonyEricssonT610'],
	['Mobile SonyEricsson T630'		,'SonyEricssonT630'],
	['Mobile SonyEricsson Z600'		,'SonyEricssonZ600'],
	['Mobile SonyEricsson P900'		,'SonyEricssonP900'],

	['Mobile Siemens SIE-C45'	,'SIE.C45'],
	['Mobile Siemens SIE-A55'	,'SIE.A55'],
	['Mobile Siemens SIE-S55'	,'SIE.S55'],
	['Mobile Siemens SIE-M55'	,'SIE.M55'],
	['Mobile Siemens SIE-C60'	,'SIE.C60'],

	['Mobile Alcatel-BH4'		,'Alcatel.BH4'],

	['Mobile SAGEM-myX'		,'SAGEM-myX'],
	
	['Mobile SAMSUNG-SGH-E700','SAMSUNG.SGH.E700'],
	
	['Mobile Panasonic-GAD67','Panasonic.GAD67'],

	['Mobile SHARP TQ GX10'		,'SHARP.TQ.GX10'],

#	['Mobile'			,'MobileExplorer'],

	['Apple'			,'(PowerPC|Macintosh)'],

	['PocketPC'			,'(Windows CE|AvantGo)'],

	['Sun'				,'SunOS'],
	
	['IRIX'				,'IRIX'],
	
	['ATARI 800 XE'			,'ATARI 800 XE'],

#	['unknown'		,'bot'			,0	,0	,1],
);

#our
sub analyze
{
 return undef unless $_[0];
 my $var=0;
 foreach (@Net::HTTP::hwplatform::list){return $var if $_[0]=~/$Net::HTTP::hwplatform::list[$var][1]/;$var++;}
 return undef;
 #my @ref=@_;
};



# END
1;# DO NOT CHANGE !
