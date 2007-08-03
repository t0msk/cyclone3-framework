#!/usr/bin/perl
package TOM::Net::HTTP::UserAgent;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

=head1 NAME

TOM::Net::HTTP::UserAgent

=cut

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DESCRIPTION

List of known UserAgents.

List is stored in @table

=cut

=head1 SYNOPSIS

 @table=(
  {
   'name'="Bot",
   'regexp'=>['bot','Bot'],
   'agent_type' => "browser",
   'agent_group' => "Microsoft",
   'utf8_disable' => 1,
   'recache_disable' => 1,
   'cookies_disable' => 1,
   'USRM_disable' => 1,
   'engine_disable => 1,
   'home_url' => "http://google.com/bot.html",
   'messages' => ["dont' use this agent"],
   'notfinished' => 1,
   'old' => undef, # undef,0,1,2,3,4,5
  },
 )

List of old browser types:

=over

=item *

0 - A newer version of your browser/user_agent is available.

=item *

1 - Your browser/user_agent ist out-of-date.

=item *

2 - Your browser/user_agent ist very out-of-date. Nothig for safe and bugless internet browsing.

=item *

3 - You are using an old version of your browser/user_agent. It is not safe enough to continue using it.

=item *

4 - You are using an very old version of your browser/user_agent. Using it might be a risk.

=item *

5 - You are using an unsupported very old version of your browser/user_agent. Using it might be a big risk. This page can't be display as the creator intended, because your browser/user_agent does not support up-to-time safety and technology standards.

=back

=cut


our %messages=
(
	old=>
	[
	# 0
	# Existuje novsia verzia, ale toto je stale secure a stable verzia
	"A newer version of your browser/user_agent is available. If it is possible, please, upgrade or inform your software distributor.",#0
	# 1
	# Existuje nova verzia, bolo by dobre upgradovat
	"Your browser/user_agent ist out-of-date. It is recommended, that you upgrade your browser/user_agent, or start using another browser/user_agent. Inform your software distributor.",#1
	# 2
	# Toto je unsecure stara verzia, je treba upgradovat.
	"Your browser/user_agent ist very out-of-date. Nothig for safe and bugless internet browsing. It is recommended, that you upgrade your browser/user_agent, or start using another browser/user_agent. Inform your software distributor.",#2
	# 3
	# Toto je velmi stara verzia, bez podpory, unsecure...
	"You are using an old version of your browser/user_agent. It is not safe enough to continue using it. It is recommended, that you upgrade your browser/user_agent and inform your software distributor, or start using another browser/user_agent.",#3
	# 4
	# Toto je uz zastarala verzia, bez podporu, unsecure, pouzivanie je risc.
	"You are using an very old version of your browser/user_agent. Using it might be a risk. This page might not display as the creator intended, because your browser/user_agent does not support up-to-time safety and technology standards. It is highly recommended, that you upgrade your browser/user_agent and inform your software distributor, or start using another browser/user_agent.",#4
	# 5
	# Tvoj browser je prilis stary a nepodporujeme ho.
	"You are using an unsupported very old version of your browser/user_agent. Using it might be a big risk. This page can't be display as the creator intended, because your browser/user_agent does not support up-to-time safety and technology standards. It is highly recommended, that you upgrade your browser/user_agent and inform your software distributor, or start using another browser/user_agent!",#5
	]
);
#=cut






our %type=
(
	'browser'           => 'B',
	'mobile browser'    => 'm',
	'wap browser'       => 'w',
	'RSS browser'       => 'r',
	'media player'      => 'p',
	'checker'           => 'c',
	'library'           => 'l',
	'system'            => 's',
	'shell'             => 'S',
	'downloader'        => 'd',
	'robot'             => 'R',
	'vandaliser'        => 'W',
	'unknown'           => 'X',
	'anonymizer'        => 'A',
);


#our $anonymizer_



our @table=
(
	

	# DEFAULT UNKNOWN AGENT
	# tento agent nezistujem regexpom
	# ked nezistim o akeho agenta ide, pouzijem tohto :)
	#
	{name=>'unknown',
#		regexp=>[''],
#		agent_type	=>	"browser",
#		agent_group	=>	"",
		utf8_disable	=>	1,
		cookies_disable	=>	1,
		notfinished		=> 1,
#		USRM_disable	=>	1,
	},
	{name=>'empty',
		regexp=>['^[\- ]$','^unknown',],
#		agent_type	=>	"browser",
#		agent_group	=>	"",
#		engine_disable	=>	1,
		utf8_disable	=>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
		messages		=>	["Your browser does not identify itself with any user agent information. Please use at least \"Mozilla/3.0 (compatible;)\".","For more information, please refer to RFC2616 chapter 3.8.,14.43 and turn on your browser identification."],
	},
	{name=>'ignorant',
		regexp=>	[
				'FuckYou',
				'^0101',
				'^\(\\\\x',
				'pitche',
#				'',
				],
		agent_type	=>	"anonymizer",
#		agent_group	=>	"",
		engine_disable	=>	1,
		utf8_disable	=>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
		messages		=>	["Your browser does not identify itself with any user agent information. Please use at least \"Mozilla/3.0 (compatible;)\".","For more information, please refer to RFC2616 chapter 3.8.,14.43 and turn on your browser identification."],
	},
	{name=>'anonymizer',
		regexp=>	[
				'anonym',
				'hysteria\.sk',
				],
		agent_type	=>	"anonymizer",
#		agent_group	=>	"",
		engine_disable => 1,
		utf8_disable => 1,
		cookies_disable => 1,
		USRM_disable => 1,
		messages => ["Accessing this service using anonymizer is not allowed","Your browser does not identify itself with any user agent information. Please use at least \"Mozilla/3.0 (compatible;)\".","For more information, please refer to RFC2616 chapter 3.8.,14.43 and turn on your browser identification."],
	},





	# OPERA - operu este pred MSIE, kvoli tomuto:
	# Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; en) Opera 8.54
	# je tam id Opera a i MSIE
	{name=>'Opera 9.X',
		regexp		=>	['Opera.9'],
		agent_type	=>	"browser",
		agent_group	=>	"Opera",
	},
	{name=>'Opera 8.X',
		regexp		=>	['Opera.8','^IE/6\.'],
		agent_type	=>	"browser",
		agent_group	=>	"Opera",
	},
	{name=>'Opera 7.X',
		regexp		=>	['Opera.7'],
		agent_type	=>	"browser",
		agent_group	=>	"Opera",
		old			=>	1,
	},
	{name=>'Opera 6.X',
		regexp		=>	['Opera.6'],
		agent_type	=>	"browser",
		agent_group	=>	"Opera",
		old			=>	2,
	},
	{name=>'Opera 5.X',
		regexp		=>	['Opera.5'],
		agent_type	=>	"browser",
		agent_group	=>	"Opera",
		old			=>	3,
	},

	# CO NAJRYCHLEJSIE NAJCASTEJSIE SA VYSKYTUJUCE BROWSERY...
	# aby dlho netrvali regexpy
	{name=>'MSIE 8.X',
		regexp		=>	['MSIE 8'],
		agent_type	=>	"browser",
		agent_group	=>	"Microsoft",
	},
	{name=>'MSIE 7.X',
		regexp		=>	['MSIE 7'],
		agent_type	=>	"browser",
		agent_group	=>	"Microsoft",
	},
	{name=>'MSIE 6.X',
		regexp		=>	['MSIE 6'],
		agent_type	=>	"browser",
		agent_group	=>	"Microsoft",
		old			=>	0,
	},
	{name=>'MSIE 5.5',
		regexp		=>	['MSIE 5\.5'],
		agent_type	=>	"browser",
		agent_group	=>	"Microsoft",
		old			=>	3,
	},
	{name=>'MSIE 5.0',
		regexp		=>	['MSIE 5'],
		agent_type	=>	"browser",
		agent_group	=>	"Microsoft",
		old			=>	4,
	},
	{name=>'MSIE 4.X',
		regexp		=>	['MSIE 4'],
		agent_type	=>	"browser",
		agent_group	=>	"Microsoft",
		old			=>	5,
	},
	{name=>'MSIE 3.X',
		regexp		=>	['MSIE 3'],
		agent_type	=>	"browser",
		agent_group	=>	"Microsoft",
		utf8_disable	=>	1,
		cookies_disable	=>	1,
		old			=>	5,
	},
	{name=>'MSIE 2.X',
		regexp		=>	['MSIE 2'],
		agent_type	=>	"browser",
		agent_group	=>	"Microsoft",
		utf8_disable	=>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
		old			=>	5,
	},
	{name=>'MSIE 1.X',
		regexp		=>	['MSIE 1'],
		agent_type	=>	"browser",
		agent_group	=>	"Microsoft",
		engine_disable	=>	1,
		utf8_disable	=>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
		old			=>	5,
		#messages		=>	["You browser is too old!"]
	},
	#"OmniExplorer_Bot/1.09 (+http://www.omni-explorer.com) Internet Categorizer"
	{name=>'MSIE unknown',
		regexp		=>	[
						'MSIE',
						'Microsoft Internet Explorer',
						],
		agent_type	=>	"browser",
		agent_group	=>	"Microsoft",
		utf8_disable	=>	1,
		#cookies_disable	=>	1,
		#USRM_disable	=>	1,
		notfinished		=> 1,
	},
	
	
	
	
	
	
	
	
	# NASLEDUJU BROWSERY MENEJ CASTE
	
	# XULADMIN
	{name=>'Comsultia C3 XUL 1.1',
		regexp		=>	['Cyclone3CMS-XUL/1\.1'],
		agent_type	=>	"browser",
		agent_group	=>	"Comsultia",
	},
	{name=>'Comsultia C3 XUL 1.0',
		regexp		=>	['Cyclone3CMS-XUL/1\.0'],
		agent_type	=>	"browser",
		agent_group	=>	"Comsultia",
	},
	
	# NETSCAPE
	{name=>'Netscape 8.X',
		regexp		=>	['Netscape.8'],
		agent_type	=>	"browser",
		agent_group	=>	"Netscape",
	},
	{name=>'Netscape 7.X',
		regexp		=>	['Netscape.7'],
		agent_type	=>	"browser",
		agent_group	=>	"Netscape",
		old			=>	2,
	},
	{name=>'Netscape 6.X',
		regexp		=>	['Netscape6'],
		agent_type	=>	"browser",
		agent_group	=>	"Netscape",
		old			=>	3,
	},
	
	# --------------------------------------------------------------------
	
	# MOZILLA
	{name=>'Mozilla Firefox 3.0',
		regexp		=>	['Firefox/3.0','Minefield/3','GranParadiso/3'],
		agent_type	=>	"browser",
		agent_group	=>	"Mozilla.org",
#		log	=>	1,
	},
	{name=>'Mozilla Firefox 2.0',
		regexp		=>	['Firefox/2.0','BonEcho/2.0'],
		agent_type	=>	"browser",
		agent_group	=>	"Mozilla.org",
#		log	=>	1,
	},
	{name=>'Mozilla Firefox 1.5',
		regexp		=>	['Firefox/1.5'],
		agent_type	=>	"browser",
		agent_group	=>	"Mozilla.org",
		old			=>	0,
#		log	=>	1,
	},
#	{name=>'Mozilla Firefox 1.4',
#		regexp		=>	['Firefox/1.4'],
#		agent_type	=>	"browser",
#		agent_group	=>	"Mozilla.org",
#		log	=>	1,
#	},
#	{name=>'Mozilla Firefox 1.3',
#		regexp		=>	['Firefox/1.3'],
#		agent_type	=>	"browser",
#		agent_group	=>	"Mozilla.org",
#		log	=>	1,
#	},
#	{name=>'Mozilla Firefox 1.2',
#		regexp		=>	['Firefox/1.2'],
#		agent_type	=>	"browser",
#		agent_group	=>	"Mozilla.org",
#		log	=>	1,
#	},
	{name=>'Mozilla Firefox 1.1',
		regexp		=>	['Firefox/1.1'],
		agent_type	=>	"browser",
		agent_group	=>	"Mozilla.org",
		old			=>	1,
#		log	=>	1,
	},
	{name=>'Mozilla Firefox 1.0',
		regexp		=>	['Firefox/1'],
		agent_type	=>	"browser",
		agent_group	=>	"Mozilla.org",
#		log	=>	1,
		old			=>	2,
	},
	{name=>'Mozilla Firefox 0.10',
		regexp		=>	['Firefox/0\.10'],
		agent_type	=>	"browser",
		agent_group	=>	"Mozilla.org",
#		log	=>	1,
		old			=>	3,
	},
	{name=>'Mozilla Firefox 0.9',
		regexp		=>	['Firefox/0\.9'],
		agent_type	=>	"browser",
		agent_group	=>	"Mozilla.org",
#		log	=>	1,
		old			=>	4,
	},
	{name=>'Mozilla Firefox 0.8',
		regexp		=>	['Firefox/0\.8'],
		agent_type	=>	"browser",
		agent_group	=>	"Mozilla.org",
		old			=>	4,
	},
	{name=>'Mozilla Firefox 0.7',
		regexp		=>	['Firefox/0\.7'],
		agent_type	=>	"browser",
		agent_group	=>	"Mozilla.org",
		old			=>	5,
	},
	
	
	# --------------------------------------------------------------------
	
	{name=>'Mozilla Thunderbird 2.x',
		regexp		=>	['Thunderbird/2\.'],
		agent_type	=>	"browser",
		agent_group	=>	"Mozilla.org",
#		old			=>	1,
	},
	{name=>'Mozilla Thunderbird 1.5',
		regexp		=>	['Thunderbird/1\.5'],
		agent_type	=>	"browser",
		agent_group	=>	"Mozilla.org",
#		old			=>	1,
	},
	{name=>'Mozilla Thunderbird 1.4',
		regexp		=>	['Thunderbird/1\.4'],
		agent_type	=>	"browser",
		agent_group	=>	"Mozilla.org",
#		old			=>	1,
	},
	
	# --------------------------------------------------------------------
	
	{name=>'Mozilla Firebird 0.8',
		regexp		=>	['Firebird/0\.8'],
		agent_type	=>	"browser",
		agent_group	=>	"Mozilla.org",
		old			=>	1,
	},
	{name=>'Mozilla Firebird 0.7',
		regexp		=>	['Firebird/0\.7'],
		agent_type	=>	"browser",
		agent_group	=>	"Mozilla.org",
		old			=>	2,
	},
	{name=>'Mozilla Firebird 0.6',
		regexp		=>	['Firebird/0\.6'],
		agent_type	=>	"browser",
		agent_group	=>	"Mozilla.org",
		old			=>	3,
	},
	
	# --------------------------------------------------------------------
	
	# SAFARI
	{name=>'Safari 410',
		regexp		=>	['Safari.41'],
		agent_type	=>	"browser",
		agent_group	=>	"Apple",
	},
	{name=>'Safari 310',
		regexp		=>	['Safari.31'],
		agent_type	=>	"browser",
		agent_group	=>	"Apple",
		old			=>	1,
	},
	{name=>'Safari 120',
		regexp		=>	['Safari.12'],
		agent_type	=>	"browser",
		agent_group	=>	"Apple",
		old			=>	1,
	},
	{name=>'Safari 100',
		regexp		=>	['Safari.10'],
		agent_type	=>	"browser",
		agent_group	=>	"Apple",
		old			=>	2,
	},
	{name=>'Safari 90',
		regexp		=>	['Safari.9'],
		agent_type	=>	"browser",
		agent_group	=>	"Apple",
		old			=>	2,
	},
	{name=>'Safari 80',
		regexp		=>	['Safari.8'],
		agent_type	=>	"browser",
		agent_group	=>	"Apple",
		old			=>	3,
	},
	
	# --------------------------------------------------------------------

	# MINORITY BROWSERS

	{name=>'iSiloX 3.X',
		regexp		=>	['^iSiloX/3'],
		agent_type	=>	"browser",
#		agent_group	=>	"OpenSource",
	},
	{name=>'Scooter',
		regexp		=>	['^Scooter'],
		agent_type	=>	"browser",
#		agent_group	=>	"OpenSource",
	},
	{name=>'Dillo',
		regexp		=>	['Dillo'],
		agent_type	=>	"browser",
#		agent_group	=>	"OpenSource",
	},
	{name=>'JoeDog',
		regexp		=>	['JoeDog'],
		agent_type	=>	"browser",
#		agent_group	=>	"OpenSource",
	},
	{name=>'Epiphany 1.X',
		regexp		=>	['Epiphany.1'],
		agent_type	=>	"browser",
#		agent_group	=>	"OpenSource",
	},
	{name=>'AWeb 3.X (Amiga)',
		regexp		=>	['AWeb.3'],
		agent_type	=>	"browser",
#		agent_group	=>	"OpenSource",
	},
	{name=>'hijacker',
		regexp		=>	['^waol.exe'],
		agent_type	=>	"browser",
		utf8_disable	=>	1,
		USRM_disable	=>	1,
#		agent_group	=>	"OpenSource",
	},
	{name=>'Avant Browser',
		regexp		=>	['^Avant Browser'],
		home_url		=>	"http://www.avantbrowser.com",
		agent_type	=>	"browser",
#		utf8_disable	=>	1,
#		USRM_disable	=>	1,
#		agent_group	=>	"OpenSource",
	},
	{name=>'xChaos Arachne 4.X',
		regexp		=>	['^xChaos_Arachne/4'],
		home_url		=>	"http://www.arachne.cz",
		agent_type	=>	"browser",
#		utf8_disable	=>	1,
#		USRM_disable	=>	1,
#		agent_group	=>	"OpenSource",
	},
	{name=>'SlimBrowser',
		regexp		=>	['^SlimBrowser'],
		agent_type	=>	"browser",
#		utf8_disable	=>	1,
#		USRM_disable	=>	1,
#		agent_group	=>	"OpenSource",
	},








	# LINUX BROWSERS
	
	{name=>'Konqueror 3.X',
		regexp		=>	['Konqueror.3'],
		agent_type	=>	"browser",
		agent_group	=>	"OpenSource",
	},
	{name=>'Konqueror 2.X',
		regexp		=>	['Konqueror.2'],
		agent_type	=>	"browser",
		agent_group	=>	"OpenSource",
		old			=>	3,
	},
	{name=>'Konqueror 1.X',
		regexp		=>	['Konqueror.1'],
		agent_type	=>	"browser",
		agent_group	=>	"OpenSource",
		old			=>	5,
	},
	{name=>'Galeon 1.X',
		regexp		=>	['Galeon.1'],
		agent_type	=>	"browser",
		agent_group	=>	"OpenSource",
	},
	{name=>'ELinks',
		regexp		=>	['ELinks'],
		agent_type	=>	"browser",
		agent_group	=>	"OpenSource",
	},
	{name=>'Lynx',
		regexp		=>	['Lynx'],
		agent_type	=>	"browser",
		agent_group	=>	"OpenSource",
	},
	{name=>'Links',
		regexp		=>	['Links'],
		agent_type	=>	"browser",
		agent_group	=>	"OpenSource",
		messages		=>	["Links, hmm... good choice! :)"],
	},
	{name=>'puf',
		regexp		=>	['^puf/'],
		utf8_disable	=>	1,
		agent_type	=>	"browser",
		agent_group	=>	"OpenSource",
	},









	# MOBILE BROWSERS
	
	# http://developer.openwave.com/dvl/resources/supported_phones/index.htm
	{name=>'Openwave mobile browser',
		regexp		=>	[
							'MOT-A-1C/01.06',
							'MOT-8700',
							'MOT-V880 /1.01',
							'MOT-A890/1.01 ',
							'MOT-V810/6.2.2',
							'MOT-E310/6.2.2',
							'MOT-V510',
							'lge-lg6070',
							'LGE-cx4600',
							'LGE-CX5450',
							'LGE-T5100',
							'LGE-L1150',
							'LGE-VX6100',
							'LGE-VX7000',
							'SIE-CX65',
							'LG-G4015',
							'LG-C1300',
							'Sanyo-SCP588CN/1.0 ',
							'SAGEM-myX5-2/1.0',
							'SEC-scha670/622 ',
							'SHARP-TQ-GX30/1.0',
							'my V-75 LAR',
							'Amoi CA6 ',
							'VM4050/132.037',
							'SCH-A650',
							'Alcatel-BH4',
							'Amoisonic-F9/1.0',
							'CDM-8900TM/6.2 ',
							'Compal-XG966/1',
							'Compal-XG966',
						],
		agent_type	=>	"mobile browser",
#		utf8_disable	=>	1, tento vraj uz podporuje UTF-8
#		cookies_disable	=>	1,
#		USRM_disable	=>	1,
		notfinished=>1,
#		agent_group	=>	"OpenSource",
	},
	
	{name=>'Web Viewer (java)',
		regexp		=>	['MOT-V500'],
		agent_type	=>	"mobile browser",
#		utf8_disable	=>	1,
		notfinished	=>	1,
#		agent_group	=>	"OpenSource",
		comment	=> "Available on these phones: Nokia 7200, Nokia 6230, Nokia 6225, Nokia 6585, Nokia 7600, Sagem My-V65, Samsung Z100, Sharp GX30, SonyEricsson T630, Motorola V400, Nokia 3595, SonyEricsson P900, Nokia 3660, Motorola V600, Motorola V525, Motorola V500, Motorola V300, Siemens C60, Nokia 6600, Siemens MC60, Siemens M55, Nokia 3200, Nokia 6820, Nokia 6810, SonyEricsson T616, SonyEricsson Z600, Sharp GX20, Nokia 3586i, Nokia N-Gage, Nokia 3560, Nokia 6108, Nokia 3100, Nokia 6220, Nokia 3300, Nokia 6800, Nokia 6200, Nokia 5100, Siemens SL42, Motorola T720i, Nokia 7250i, Nokia 8910i, Nokia 3590, Nokia 3585, SonyEricsson T610, SonyEricsson P800, Sharp GX10i, Sharp GX10, Motorola T720, Siemens SL55, Siemens S55, Siemens SL45i, Siemens C55, Siemens M50, Nokia 3650, Nokia 7650, Nokia 7250, Nokia 6100, Nokia 7210, Nokia 6610, Nokia 3410, Nokia 3510i, Nokia 7610, Nokia 3220, Nokia 5140, SonyEricsson P910i, Nokia 6620, Nokia 6630, Nokia 6260, Nokia 6650"
	},
	
	
	{name=>'SEMC Browser (Sony Ericsson)',
		regexp		=>	['SEMC-Browser'],
		agent_type	=>	"mobile browser",
#		utf8_disable	=>	1, tento vraj uz podporuje UTF-8
		cookies_disable	=>	1,
		USRM_disable	=>	1,
#		agent_group	=>	"OpenSource",
	},
	{name=>'UP Browser 7.X',
		regexp		=>	['UP.Browser/7','UP/7'],
		agent_type	=>	"mobile browser",
#		utf8_disable	=>	1, tento vraj uz podporuje UTF-8
#		cookies_disable	=>	1,
#		USRM_disable	=>	1,
#		agent_group	=>	"OpenSource",
	},
	{name=>'UP Browser 6.X',
		regexp		=>	['UP.Browser/6','UP/6'],
		agent_type	=>	"mobile browser",
		utf8_disable	=>	1,
#		cookies_disable	=>	1,
#		USRM_disable	=>	1,
#		agent_group	=>	"OpenSource",
	},
	{name=>'UP Browser 5.X',
		regexp		=>	['UP.Browser/5','UP/5'],
		agent_type	=>	"mobile browser",
		utf8_disable	=>	1,
#		agent_group	=>	"OpenSource",
	},
	{name=>'UP Browser 4.X',
		regexp		=>	['UP.Browser/4','UP/4'],
		agent_type	=>	"mobile browser",
		utf8_disable	=>	1,
#		agent_group	=>	"OpenSource",
	},
	{name=>'UP Link 7.X',
		regexp		=>	['UP.Link/7'],
		agent_type	=>	"mobile browser",
#		utf8_disable	=>	1,
#		agent_group	=>	"OpenSource",
	},
	{name=>'UP Link 6.X',
		regexp		=>	['UP.Link/6'],
		agent_type	=>	"mobile browser",
#		utf8_disable	=>	1,
#		agent_group	=>	"OpenSource",
	},
	{name=>'UP Link 5.X',
		regexp		=>	['UP.Link/5'],
		agent_type	=>	"mobile browser",
#		utf8_disable	=>	1,
#		agent_group	=>	"OpenSource",
	},
	{name=>'UP Link 1.X',
		regexp		=>	['UP.Link/1'],
		agent_type	=>	"mobile browser",
		utf8_disable	=>	1,
#		agent_group	=>	"OpenSource",
	},
	{name=>'Blazer 1.X', #Handspring Treo 300
		regexp		=>	['Blazer.1'],
		agent_type	=>	"mobile browser",
#		utf8_disable	=>	1,
#		agent_group	=>	"OpenSource",
	},
	{name=>'MobileExplorer',
		regexp		=>	['MobileExplorer'],
		agent_type	=>	"mobile browser",
		utf8_disable	=>	1,
#		agent_group	=>	"OpenSource",
	},
	{name=>'Klondike',
		regexp		=>	['Klondike'],
		agent_type	=>	"mobile browser",
		utf8_disable	=>	1,
#		agent_group	=>	"OpenSource",
	},
	
	
	{name=>'Nokia MobileBrowser',
		regexp		=>	['Nokia(3|5|6|7|8)'],
		agent_type	=>	"mobile browser",
		utf8_disable	=>	1,
#		USRM_disable	=>	1, # niesom si isty ci mu funguje USRM a cookies
		notfinished		=>	1,
	},
	{name=>'Nokia (unknown)',
		regexp		=>	['Nokia'],
		agent_type	=>	"mobile browser",
		utf8_disable	=>	1,
		notfinished		=>	1,
	},
	{name=>'SonyEricsson MobileBrowser',
		regexp		=>	['SonyEricsson(P800|T100|T300|T610|Z600|T20)'],
		agent_type	=>	"mobile browser",
		utf8_disable	=>	1,
	},
	{name=>'SonyEricsson (unknown)',
		regexp		=>	['SonyEricsson'],
		agent_type	=>	"mobile browser",
		utf8_disable	=>	1,
		notfinished		=>	1,
	},
	{name=>'MIDP 2.X (compatible)',
		regexp		=>	['MIDP-2'],
		agent_type	=>	"mobile browser",
		utf8_disable	=>	1,
		notfinished		=>	1,
	},
	
	
	
	
	# WAP BROWSERS
	{name=>'Mitsu 1.X',
		regexp		=>	['^Mitsu/1'],
		agent_type	=>	"wap browser",
#		agent_group	=>	"OpenSource",
	},
	{name=>'jBrowser',
		regexp		=>	['^jBrowser'],
#		home_url		=>	"http://www.wapsilon.com",
		agent_type	=>	"wap browser",
		utf8_disable	=>	1,
#		agent_group	=>	"OpenSource",
	},
	{name=>'Wapsilon 2.X',
		regexp		=>	['Wapsilon.2'],
		home_url		=>	"http://www.wapsilon.com",
		agent_type	=>	"wap browser",
		utf8_disable	=>	1,
#		agent_group	=>	"OpenSource",
	},
	{name=>'WAP 1.2.X',
		regexp		=>	['WAP1\.2\.'],
#		home_url		=>	"http://www.wapsilon.com",
		agent_type	=>	"wap browser",
		utf8_disable	=>	1,
#		agent_group	=>	"OpenSource",
	},
	{name=>'Wapalizer 1.X',
		regexp		=>	['Wapalizer.1'],
#		home_url		=>	"Wapsilon/2.4 (www.wapsilon.com)",
		agent_type	=>	"wap browser",
		utf8_disable	=>	1,
#		agent_group	=>	"OpenSource",
	},
	{name=>'WinWAP 3.X',
		regexp		=>	['WinWAP.*3\.'],
#		home_url		=>	"Wapsilon/2.4 (www.wapsilon.com)",
		agent_type	=>	"wap browser",
		utf8_disable	=>	1,
#		agent_group	=>	"OpenSource",
	},
	{name=>'TagTag 1.X',
		regexp		=>	['TagTag emulator v1'],
#		home_url		=>	"Wapsilon/2.4 (www.wapsilon.com)",
		agent_type	=>	"wap browser",
		utf8_disable	=>	1,
#		agent_group	=>	"OpenSource",
	},
	
	
	
	



	# MEDIA PLAYERS


	{name=>'MPlayer (linux)',
		regexp		=>	['MPlayer'],
		agent_type	=>	"media player",
#		utf8_disable	=>	1,
	},
	{name=>'NSPlayer',
		regexp		=>	['NSPlayer'],
		agent_type	=>	"media player",
#		utf8_disable	=>	1,
	},
	{name=>'Windows Media Player',
		regexp		=>	['Windows.Media.Player'],
		agent_type	=>	"media player",
#		utf8_disable	=>	1,
	},
	{name=>'VLC Media Player',
		regexp		=>	['VLC.Media.Player'],
		agent_type	=>	"media player",
#		utf8_disable	=>	1,
	},
	{name=>'RealMedia Player',
		regexp		=>	['RealMedia'],
		agent_type	=>	"media player",
#		utf8_disable	=>	1,
	},
	{name=>'WinampMPEG',
		regexp		=>	['WinampMPEG'],
		agent_type	=>	"media player",
#		utf8_disable	=>	1,
	},
	{name=>'XINE Media Player (linux)',
		regexp		=>	['xine'],
		agent_type	=>	"media player",
#		utf8_disable	=>	1,
	},
	{name=>'DivX Media Player 2.X',
		regexp		=>	['DivX Player 2'],
		agent_type	=>	"media player",
#		utf8_disable	=>	1,
	},
	{name=>'XMMS Audio Player 1.X (linux)',
		regexp		=>	['xmms.1'],
		agent_type	=>	"media player",
#		utf8_disable	=>	1,
	},
	{name=>'Shockwave Flash',
		regexp		=>	['Shockwave Flash'],
		agent_type	=>	"media player",
#		utf8_disable	=>	1,
	},
	





	{name=>'intraVnews 1.X', # RSS reader ktory aj browsuje po webe
		regexp		=>	['intraVnews/1'],
		agent_type	=>	"RSS browser",
		utf8_disable	=>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
#		notfinished		=>	1,
	},
	{name=>'Akregator 1.X',
		regexp		=>	['Akregator/1'],
		agent_type	=>	"RSS browser",
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'Lotus-Notes 5.X', # Lotus
		regexp		=>	['Lotus-Notes/5'],
	},
	{name=>'Lotus-Notes 4.X', # Lotus
		regexp		=>	['Lotus-Notes/4'],
		old			=>	1,
	},
	{name=>'Offline Explorer 2.X',
		regexp		=>	['Offline Explorer/2'],
	},
	{name=>'Offline Explorer 1.X',
		regexp		=>	['Offline Explorer/1'],
	},
	
	{name=>'MSFrontPage 5.X',
		regexp		=>	['MSFrontPage/5'],
		agent_group	=>	"Microsoft",
	},
	{name=>'MSFrontPage 4.X',
		regexp		=>	['MSFrontPage/4'],
		agent_group	=>	"Microsoft",
	},


	# CHECKERS


	{name=>'check_http',
		regexp		=>	['check_http'],
		agent_type	=>	"checker",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'Alchemy Eye',
		regexp		=>	['Alchemy Eye Agent'],
		home_url		=> 'http://www.agentland.com/Download/Intelligent_Agent/433.html',
		agent_type	=>	"checker",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'LinkWalker™',
		regexp		=>	['LinkWalker'],
		home_url		=> 'http://www.seventwentyfour.com/tech.html',
		agent_type	=>	"checker",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'InternetSeer',
		regexp		=>	['InternetSeer'],
		home_url		=> 'http://internetseer.com',
		agent_type	=>	"checker",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'W3C Validator',
		regexp		=>	['W3C_Validator'],
		agent_type	=>	"checker",
#		utf8_disable	=> 1,
		recache_disable=> 1,
		cookies_disable=> 1,
		USRM_disable	=> 1,
#		engine_disable	=> 1,
	},
	
	





	# DOWNLOADERS


	{name=>'GetRight',
		regexp		=>	['GetRight'],
		agent_type	=>	"downloader",
#		utf8_disable	=> 1,
		recache_disable=> 1,
		cookies_disable=> 1,
		USRM_disable	=> 1,
#		engine_disable	=> 1,
	},
	{name=>'FlashGet',
		regexp		=>	['FlashGet'],
		agent_type	=>	"downloader",
#		utf8_disable	=> 1,
		recache_disable=> 1,
		cookies_disable=> 1,
		USRM_disable	=> 1,
#		engine_disable	=> 1,
	},
	{name=>'AvantGo 5.X',
		regexp		=>	['AvantGo.5'],
#		agent_type	=>	"downloader",
		agent_type	=>	"browser", # preco som ho zmenil na browser?
#		utf8_disable	=> 1,
#		recache_disable=> 1,
#		cookies_disable=> 1,
#		USRM_disable	=> 1,
#		engine_disable	=> 1,
	},
	{name=>'WebCopier',
		regexp		=>	['WebCopier'],
		agent_type	=>	"downloader",
#		utf8_disable	=> 1,
		recache_disable=> 1,
		cookies_disable=> 1,
		USRM_disable	=> 1,
#		engine_disable	=> 1,
	},
	{name=>'WebStripper',
		regexp		=>	['WebStripper'],
		agent_type	=>	"downloader",
#		utf8_disable	=> 1,
		recache_disable=> 1,
		cookies_disable=> 1,
		USRM_disable	=> 1,
#		engine_disable	=> 1,
	},
	{name=>'WebWasher',
		regexp		=>	['WebWasher'],
		agent_type	=>	"downloader",
#		utf8_disable	=> 1,
		recache_disable=> 1,
		cookies_disable=> 1,
		USRM_disable	=> 1,
#		engine_disable	=> 1,
	},
	{name=>'Wget',
		regexp		=>	['wget'],
		agent_type	=>	"downloader",
#		utf8_disable	=> 1,
		recache_disable=> 1,
		cookies_disable=> 1,
		USRM_disable	=> 1,
#		engine_disable	=> 1,
	},
	{name=>'Web Downloader 6.X',
		regexp		=>	['^Web Downloader/6'],
		agent_type	=>	"downloader",
#		utf8_disable	=> 1,
		recache_disable=> 1,
		cookies_disable=> 1,
		USRM_disable	=> 1,
#		engine_disable	=> 1,
	},
	{name=>'Web Downloader 5.X',
		regexp		=>	['^Web Downloader/5'],
		agent_type	=>	"downloader",
#		utf8_disable	=> 1,
		recache_disable=> 1,
		cookies_disable=> 1,
		USRM_disable	=> 1,
#		engine_disable	=> 1,
	},
	{name=>'curl',
		regexp		=>	['curl'],
		agent_type	=>	"downloader",
#		utf8_disable	=> 1,
		recache_disable=> 1,
		cookies_disable=> 1,
		USRM_disable	=> 1,
#		engine_disable	=> 1,
	},












	# LIBRARIES
	{name=>'Tomahawk LiteAgent', # musim mu zapnut plnu podporu
		regexp		=>	['LiteAgent'],
		agent_type	=>	"library",
#		utf8_disable	=> 1,
#		recache_disable=> 1,
#		cookies_disable=> 1,
#		USRM_disable	=> 1,
#		engine_disable	=> 1,
	},
	{name=>'Perl libwww',
		regexp		=>	['libwww'],
		agent_type	=>	"library",
#		utf8_disable	=> 1,
		recache_disable=> 1,
		cookies_disable=> 1,
		USRM_disable	=> 1,
#		engine_disable	=> 1,
	},
	{name=>'LWP',
		regexp		=>	['lwp-trivial','LWP::'],
		agent_type	=>	"library",
#		utf8_disable	=> 1,
		recache_disable=> 1,
		cookies_disable=> 1,
		USRM_disable	=> 1,
#		engine_disable	=> 1,
	},
	{name=>'PHP http',
		regexp		=>	['PHP/class http'],
		agent_type	=>	"library",
#		utf8_disable	=> 1,
		recache_disable=> 1,
		cookies_disable=> 1,
		USRM_disable	=> 1,
#		engine_disable	=> 1,
	},
	{name=>'PHP 4.X',
		regexp		=>	['PHP.4'],
		agent_type	=>	"library",
#		utf8_disable	=> 1,
		recache_disable=> 1,
		cookies_disable=> 1,
		USRM_disable	=> 1,
#		engine_disable	=> 1,
	},
	{name=>'Snoopy',
		regexp		=>	['Snoopy'],
		agent_type	=>	"library",
		home_url		=>	"http://sourceforge.net/projects/snoopy/",
#		utf8_disable	=> 1,
		recache_disable=> 1,
		cookies_disable=> 1,
		USRM_disable	=> 1,
#		engine_disable	=> 1,
	},
	{name=>'Java',
		regexp		=>	['^Java'],
		agent_type	=>	"library",
#		utf8_disable	=> 1,
		recache_disable=> 1,
		cookies_disable=> 1,
		USRM_disable	=> 1,
#		engine_disable	=> 1,
	},







	# SYSTEMS (&proxy)
	
	
	{name=>'WebDav',
		regexp		=>	['Microsoft Data Access','WebDAV'],
		agent_type	=>	"system",
		utf8_disable	=> 1,
		recache_disable=> 1,
		cookies_disable=> 1,
		USRM_disable	=> 1,
		notfinished		=> 1,
#		engine_disable	=> 1,
	},
	{name=>'Microsoft URL Control',
		regexp		=>	['Microsoft URL Control'],
		agent_type	=>	"system",
		utf8_disable	=> 1,
		recache_disable=> 1,
		cookies_disable=> 1,
		USRM_disable	=> 1,
#		engine_disable	=> 1,
	},
	{name=>'MSProxy 1.X',
		regexp		=>	['MSProxy.1'],
		agent_type	=>	"system",
#		utf8_disable	=> 1,
#		recache_disable=> 1,
		cookies_disable=> 1,
		USRM_disable	=> 1,
#		engine_disable	=> 1,
	},
	{name=>'MSProxy 2.X',
		regexp		=>	['MSProxy.2'],
		agent_type	=>	"system",
#		utf8_disable	=> 1,
#		recache_disable=> 1,
		cookies_disable=> 1,
		USRM_disable	=> 1,
#		engine_disable	=> 1,
	},
	{name=>'IWeb2Wap',
		regexp		=>	['^i-Web2WAP'],
		agent_type	=>	"system",
		utf8_disable	=> 1,
#		recache_disable=> 1,
		cookies_disable=> 1,
		USRM_disable	=> 1,
#		engine_disable	=> 1,
	},


	
	


	# A HNED POTOM ROBOTY
	{name=>'MJ12bot',
		regexp		=>	[
						'MJ12bot'
						],
		agent_type	=>	"robot",
		engine_disable	=>	1,
		recache_disable	=>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
		messages		=>	["Your UserAgent requests bad URLs"],
	},
	{name=>'bad_robot',
		regexp		=>	[
						'^DA ',
						'^Obscurix'
						],
		agent_type	=>	"robot",
		engine_disable	=>	1,
		recache_disable	=>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
		messages		=>	["Your UserAgent is too agressive"],
	},
	
	{name=>'OmniExplorer',
		regexp		=>	['OmniExplorer'],
		agent_type	=>	"robot",
		home_url		=>	"http://www.omni-explorer.com",
#		engine_disable	=>	1,
		recache_disable	=>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
#		messages		=>	["Your UserAgent is too agressive"],
	},
	{name=>'HTTrack 3.X',
		regexp		=>	['HTTrack 3'],
		agent_type	=>	"robot",
#		engine_disable	=>	1,
		recache_disable	=>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
#		messages		=>	["Your UserAgent is too agressive"],
	},
	{name=>'VB OpenUrl',
		regexp		=>	['^VB OpenUrl'],
		agent_type	=>	"robot",
#		engine_disable	=>	1,
		recache_disable	=>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
#		messages		=>	["Your UserAgent is too agressive"],
	},
	{name=>'Zao crawler',
		regexp		=>	['^Zao/'],
		agent_type	=>	"robot",
		home_url		=>	"http://www.kototoi.org/zao/",
#		engine_disable	=>	1,
		recache_disable	=>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
#		messages		=>	["Your UserAgent is too agressive"],
	},
	{name=>'ASPseek',
		regexp		=>	['^ASPSeek'],
		agent_type	=>	"robot",
		home_url		=>	"http://www.aspseek.org",
#		engine_disable	=>	1,
		recache_disable	=>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
#		messages		=>	["Your UserAgent is too agressive"],
	},
	{name=>'WebPix 1.X',
		regexp		=>	['^WebPix 1'],
		agent_type	=>	"robot",
		home_url		=>	"http://www.netwu.com",
#		engine_disable	=>	1,
		recache_disable	=>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
#		messages		=>	["Your UserAgent is too agressive"],
	},
	{name=>'AOLserver-Tcl 3.X',
		regexp		=>	['^AOLserver-Tcl/3'],
		home_url		=>	"http://www.aolserver.com",
		agent_type	=>	"robot",
#		engine_disable	=>	1,
		recache_disable	=>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
#		messages		=>	["Your UserAgent is too agressive"],
	},
	{name=>'Green Research, Inc', # email spider from Nigeria, Panama, Mozambique and Israel
		regexp		=>	['^Green Research, Inc'],
		home_url		=>	"http://www.webmasterworld.com/forum11/2400.htm",
		agent_type	=>	"robot",
		engine_disable	=>	1,
		recache_disable	=>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
		messages		=>	["Your UserAgent is too agressive"],
	},
	{name=>'QuepasaCreep',
		regexp		=>	['^QuepasaCreep'],
		home_url		=>	"http://www.quepasa.com/",
		agent_type	=>	"robot",
		recache_disable	=>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'Larbin 2.X',
		regexp		=>	['larbin2'],
		home_url		=>	"http://larbin.sourceforge.net",
		agent_type	=>	"robot",
		recache_disable	=>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'GoForIt', # vyhladavaci bot filmov
		regexp		=>	['^GoForIt.com'],
		home_url		=>	"http://goforit.com",
		agent_type	=>	"robot",
		recache_disable	=>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'BlackMask.Net', # vyhladavaci bot filmov
		regexp		=>	['^BlackMask.Net Search Engine'],
		home_url		=>	"http://search.blackmask.net/",
		agent_type	=>	"robot",
		recache_disable	=>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'Cerberian Drtrs',
		regexp		=>	['Cerberian Drtrs'],
		agent_type	=>	"robot",
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'SURF', # email harvester
		regexp		=>	['^SURF'],
		agent_type	=>	"robot",
		engine_disable	=>	1,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
		messages		=>	["Sorry, but you is client side email harvester"],
	},
	{name=>'Echoping',
		regexp		=>	['^Echoping'],
		agent_type	=>	"robot",
		#engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'ia_archiver',
		regexp		=>	['ia_archiver'],
		home_url		=>	"http://pages.alexa.com/help/webmasters/",
		agent_type	=>	"robot",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'Slurp',
		regexp		=>	['Slurp'],
		home_url		=>	"http://help.yahoo.com/help/us/ysearch/slurp",
		agent_type	=>	"robot",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},

	# BIG TRAFFIC
	{name=>'Jyxo.cz',
		regexp		=>	['^Jyxobot'],
		agent_type	=>	"robot",
		#engine_disable	=>	1,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
		#messages		=>	["Your robot or agent is too agressive in requests, sorry"],
	},
	{name=>'UbiCrawler',
		regexp		=>	['^UbiCrawler'],
		home_url	=>	"http://ubi0.iit.cnr.it/projects/ubicrawler/",
		agent_type	=>	"robot",
		engine_disable	=>	1,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
		messages		=>	["Your robot or agent is too agressive in requests, sorry"],
	},
	{name=>'almaden.ibm.com/cs/crawler',
		regexp		=>	['ibm.com.*crawler'],
		agent_type	=>	"robot",
		engine_disable	=>	1,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
		messages		=>	["Your robot or agent is too agressive in requests, sorry"],
	},
	{name=>'httperf',
		regexp		=>	['httperf'],
		agent_type	=>	"robot",
		engine_disable	=>	1,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
		messages		=>	["Your robot or agent is too agressive in requests, sorry"],
		DOS=>1,
	},
	
	
	{name=>'Google.com',
		regexp		=>	['Googlebot'],
		agent_type	=>	"robot",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'AskJeeves.com',
		regexp		=>	['Ask Jeeves/Teoma'],
		home_url	=>	"http://sp.ask.com/docs/about/tech_crawling.html",
		agent_type	=>	"robot",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'fast.no',
		regexp		=>	['^FAST'],
		home_url	=>	"http://fastsearch.com",
		agent_type	=>	"robot",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'search.msn.com',
		regexp		=>	['^msnbot'],
		agent_type	=>	"robot",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
		log=>1,
	},
	{name=>'woko.cz',
		regexp		=>	['^Woko robot'],
		agent_type	=>	"robot",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'Nutch.org',
		regexp		=>	['^NutchOrg'],
		agent_type	=>	"robot",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'szukacz.pl',
		regexp		=>	['^Szukacz'],
		agent_type	=>	"robot",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'GigaBot 2.X',
		regexp		=>	['^Gigabot.2'],
		home_url		=>	"http://www.gigablast.com/",
		agent_type	=>	"robot",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		utf8_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'GigaBot 1.X',
		regexp		=>	['^GigaBot.1'],
		home_url		=>	"http://www.gigablast.com/",
		agent_type	=>	"robot",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		utf8_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'SuperBot',
		regexp		=>	['^SuperBot'],
		agent_type	=>	"robot",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'NaverRobot',
		regexp		=>	['NaverRobot'],
		agent_type	=>	"robot",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'icsbot',
		regexp		=>	['^icsbot'],
		agent_type	=>	"robot",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'kuloko-bot',
		regexp		=>	['^kuloko-bot'],
		agent_type	=>	"robot",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'exo.sk',
		regexp		=>	['^EXO'],
		agent_type	=>	"robot",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'ucw.cz/holmes',
		regexp		=>	['^holmes'],
		agent_type	=>	"robot",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'WISEnutbot.com',
		regexp		=>	['^ZyBorg'],
		agent_type	=>	"robot",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'turnitin.com',
		regexp		=>	['^TurnitinBot'],
		agent_type	=>	"robot",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'baidu.com',
		regexp		=>	['^Baiduspider'],
		agent_type	=>	"robot",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'Teleport',
		regexp		=>	['^Teleport'],
		agent_type	=>	"robot",
		engine_disable	=>	1,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
		messages		=>	[],
	},
	{name=>'grub.org',
		regexp		=>	['^grub-client'],
		agent_type	=>	"robot",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'dir.com',
		regexp		=>	['Pompos'],
		agent_type	=>	"robot",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'walhello.com',
		regexp		=>	['appie'],
		agent_type	=>	"robot",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'Tkensaku.com',
		regexp		=>	['Tkensaku'],
		agent_type	=>	"robot",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'LinkWalker',
		regexp		=>	['^msnbot'],
		agent_type	=>	"robot",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'Xenu Link Sleuth 1.X',
		regexp		=>	['Xenu Link Sleuth'],
		agent_type	=>	"robot",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'Voyager',
		regexp		=>	['voyager'],
		home_url		=> "http://www.kosmix.com/crawler.html",
		agent_type	=>	"robot",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'Interseek',
		regexp		=>	['Interseek'],
		agent_type	=>	"robot",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'Charlotte',
		regexp		=>	['Charlotte'],
		home_url		=> "http://www.searchme.com/support/",
		agent_type	=>	"robot",
		engine_disable	=>	0,
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},






	# NAKONIEC UNKNOWN BOT	
	
	{name=>'unknown robot',
		regexp		=>	['bot','crawler','spider'],
		agent_type	=>	"robot",
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
		utf8_disable	=>	1,
		agent_group	=>	0,
		notfinished		=>	1,
	},







	# NEJEDNOZNACNOSTI


	{name=>'Mozilla 1.8',
		regexp		=>	['^Mozilla.*rv:1.8.*Gecko'],
		agent_type	=>	"browser",
		agent_group	=>	"Mozilla.org",
		notfinished		=>	1,
	},
	{name=>'Mozilla 1.7',
		regexp		=>	['^Mozilla.*rv:1.7.*Gecko'],
		agent_type	=>	"browser",
		agent_group	=>	"Mozilla.org",
#		notfinished		=>	1,
		old			=>	0,
	},
	{name=>'Mozilla 1.6',
		regexp		=>	['^Mozilla.*rv:1.6.*Gecko'],
		agent_type	=>	"browser",
		agent_group	=>	"Mozilla.org",
#		notfinished		=>	1,
		old			=>	1,
	},
	{name=>'Mozilla 1.5',
		regexp		=>	['^Mozilla.*rv:1.5.*Gecko'],
		agent_type	=>	"browser",
		agent_group	=>	"Mozilla.org",
#		notfinished		=>	1,
		old			=>	2,
	},
	{name=>'Mozilla 1.4',
		regexp		=>	['^Mozilla.*rv:1.4.*Gecko'],
		agent_type	=>	"browser",
		agent_group	=>	"Mozilla.org",
#		notfinished		=>	1,
		old			=>	2,
	},
	{name=>'Mozilla 1.3',
		regexp		=>	['^Mozilla.*rv:1.3.*Gecko'],
		agent_type	=>	"browser",
		agent_group	=>	"Mozilla.org",
#		notfinished		=>	1,
		old			=>	3,
	},
	{name=>'Mozilla 1.2',
		regexp		=>	['^Mozilla.*rv:1.2.*Gecko'],
		agent_type	=>	"browser",
		agent_group	=>	"Mozilla.org",
#		notfinished		=>	1,
		old			=>	3,
	},
	{name=>'Mozilla 1.1',
		regexp		=>	['^Mozilla.*rv:1.1.*Gecko'],
		agent_type	=>	"browser",
		agent_group	=>	"Mozilla.org",
#		notfinished		=>	1,
		old			=>	4,
	},
	{name=>'Mozilla 0.9',
		regexp		=>	['^Mozilla.*rv:0.9.*Gecko'],
		agent_type	=>	"browser",
		agent_group	=>	"Mozilla.org",
#		notfinished		=>	1,
		old			=>	5,
	},



#	{name=>'Mozilla 5.X',
#		regexp		=>	[
#						'^Mozilla.5.*(Linux|BSD|SunOS)',
#						'^Mozilla.5.*MultiZilla',
#						],
#		agent_type	=>	"browser",
#		agent_group	=>	"Mozilla.org",
#		notfinished		=>	1,
#	},
	{name=>'Scarab (?)',
		regexp		=>	[
						'^PRHH_SCARAB',
						],
#		agent_type	=>	"browser",
#		agent_group	=>	"Mozilla.org",
		notfinished		=>	1,
	},






	# A NAKONIEC COMPATIBLE LIST


	{name=>'Mozilla 1.X (unknown compatible)',
		regexp		=>	['^Mozilla/1'],
		agent_type	=>	"browser",
		agent_group	=>	"Mozilla (compatible)",
		notfinished		=>	1,
#		engine_disable	=>	0,
#		recache_disable =>	1,
#		cookies_disable	=>	1,
#		USRM_disable	=>	1,
#		message		=>	[""],
	},
	{name=>'Mozilla 2.X (unknown compatible)',
		regexp		=>	['^Mozilla/2'],
		agent_type	=>	"browser",
		agent_group	=>	"Mozilla (compatible)",
		notfinished		=>	1,
#		engine_disable	=>	0,
#		recache_disable =>	1,
#		cookies_disable	=>	1,
#		USRM_disable	=>	1,
#		message		=>	[""],
	},
	{name=>'Mozilla 3.X (unknown compatible)',
		regexp		=>	['^Mozilla/3'],
		agent_type	=>	"browser",
		agent_group	=>	"Mozilla (compatible)",
		notfinished		=>	1,
#		engine_disable	=>	0,
#		recache_disable =>	1,
#		cookies_disable	=>	1,
#		USRM_disable	=>	1,
#		message		=>	[""],
	},
	{name=>'Mozilla 4.X (unknown compatible)',
		regexp		=>	['^Mozilla/4'],
		agent_type	=>	"browser",
		agent_group	=>	"Mozilla (compatible)",
		notfinished		=>	1,
#		engine_disable	=>	0,
#		recache_disable =>	1,
#		cookies_disable	=>	1,
#		USRM_disable	=>	1,
#		message		=>	[""],
	},
	{name=>'Mozilla 5.X (unknown compatible)',
		regexp		=>	['^Mozilla/5'],
		agent_type	=>	"browser",
		agent_group	=>	"Mozilla (compatible)",
		notfinished		=>	1,
#		engine_disable	=>	0,
#		recache_disable =>	1,
#		cookies_disable	=>	1,
#		USRM_disable	=>	1,
#		message		=>	[""],
	},
#	{name=>'Mozilla (unknown compatible)',
#		regexp		=>	['Mozilla'],
#		agent_type	=>	"browser",
#		agent_group	=>	"Mozilla (compatible)",
#		notfinished		=>	1,
#		cookies_disable	=>	1,
#		USRM_disable	=>	1,
#	},

	# SHELLS
	{name=>'/bin/sh',
		regexp		=>	['^/bin/sh'],
#		agent_type	=>	"browser",
		agent_type	=>	"shell",
		utf8_disable	=>	1,
#		engine_disable	=>	1,
#		recache_disable =>	1,
#		cookies_disable	=>	1,
#		USRM_disable	=>	1,
		old			=>	5,
		messages		=>	["In shell, is this only preview!!!"],
	},


# IPs, false useragents
	
	{name=>'Internet For Learning',
		agent_type	=>	"vandaliser",
		home_url=>"http://www.biocrawler.com/encyclopedia/Biocrawler:Vandalism_in_progress",
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'161.53.50.60',
		agent_type	=>	"robot",
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'194.106.164.177',
		agent_type	=>	"vandaliser",
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'70.68.139.169', # Shaw Communications Inc. (Canada)
		agent_type	=>	"vandaliser",
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'USAMITC',
		agent_type	=>	"vandaliser",
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'PUBNETPLUS',
		agent_type	=>	"vandaliser",
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'ARBINET-SYNETRIX',
		agent_type	=>	"vandaliser",
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'WSZ_PLOCK',
		agent_type	=>	"vandaliser",
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'JPNIC-NET-JP', # Japan Network Information Center
		agent_type	=>	"vandaliser",
		recache_disable =>	1,
		cookies_disable	=>	1,
		USRM_disable	=>	1,
	},
	{name=>'hacked',
		agent_type	=>	"vandaliser",
		recache_disable =>	1,
		cookies_disable	=>	0,
		USRM_disable	=>	0,
	},
);


#MJ12bot

our %table_IP=
(
	'62\.171\.194\.' => 'Internet For Learning', # 2006-01-27
	'161\.53\.50\.60' => '161.53.50.60',         # 2006-01-27
	'194\.106\.164\.177' => '194.106.164.177',   # 2006-02-06 Beotel Beograd
	# 2006-02-21 - Shaw Communications Inc. (Canada)
	# velmi kvalitny vandalizer, podporuje cookies, chova sa ako MSIE 6.0, avsak neposiela ziadne
	# referery a probi privela requestov na obycajneho usera :)
	# 9900 requestov za jednu session
	'70\.68\.139\.169' => '70.68.139.169',
	# 2006-03-21
	# nekorektny bot spravodajskej sluzby USA ARMY
	'192\.138\.77\.36' => 'USAMITC',
	# 2006-03-21
	# korejsky bot - neznamy ucel
	'125\.248\.131\.130' => 'PUBNETPLUS',
	# 2006-03-27
	# niekto neprijemny z velkej britanie
	'213\.232\.79\.' => 'ARBINET-SYNETRIX',
	# 2006-04-03
	# podozrivy bot z polskej vojenskej nemocnice
	'217\.28\.152\.148' => 'WSZ_PLOCK',
	# 2006-04-03 - Japan Network Information Center
	'219\.117\.215\.202' => 'JPNIC-NET-JP',
	
	
	# list of anonymizers
	#'91\.127\.103\.156' => 'anonymizer',
	
);

=head1 FUNCTIONS

=head2 analyze()

=cut

sub analyze
{
	my $user_agent=shift @_;
	return undef unless $user_agent;
	my %env=@_;
	
	# hladanie vandalizatora
	if ($env{IP})
	{
		foreach my $k(sort keys %table_IP)
		{
			return (&getIDbyName($table_IP{$k}),$table[&getIDbyName($table_IP{$k})]{name}) if $env{IP}=~/^$k/;
		}
	}
	
	# my $var=0;
	foreach my $i(1..@table-1)
	{
		foreach my $regexp (@{$table[$i]{regexp}})
		{
			return ($i,$table[$i]{name}) if $user_agent=~/$regexp/i;
		}
	}
	return undef;
};



=head2 getIDbyName()

=cut

sub getIDbyName
{
	my $name=shift @_;
	foreach my $i(0..@table-1)
	{
		return $i if $table[$i]{name} eq $name;
	}
	return undef;
}


=head2 initialize_hacked()

=cut

sub initialize_hacked
{
	# naliatie hacked IP's do listu vandalizerov
	return undef;
	
	my %hacked;
	main::_log("hacked IP's");
	open(HCK,$TOM::P.'/_temp/hacked_IP.list') || return undef;
	while (my $line=<HCK>)
	{
		chomp($line);
		my @arr=split(':',$line);
		$hacked{$arr[1]}++;
	}
	
	foreach (keys %hacked)
	{
		main::_log("add to list IP '$_'");
		$table_IP{$_}='hacked';
	}
	
}

&initialize_hacked();

# END
1;# DO NOT CHANGE !
