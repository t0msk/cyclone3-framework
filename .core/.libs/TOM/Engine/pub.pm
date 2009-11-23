package TOM::Engine::pub;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__.'{$Id$}');};}


	use TOM;
	
	BEGIN
	{
		$TOM::Engine='pub';
		$tom::addons_init=1;
		
		# data adresar
		mkdir $tom::P."/_data" if (! -e $tom::P."/_data");
		
		# udrziavaci USRM adresar
		mkdir $tom::P."/_data/USRM" if (! -e $tom::P."/_data/USRM");
		
		# debug adresare
		mkdir $tom::P."/_logs/_debug" if (! -e $tom::P."/_logs/_debug");
		
		# temp grf directory
		if (! -e $tom::P.'/!media/grf/temp')
		{
			mkdir $tom::P.'/!media/grf/temp';
			chmod(0777,$tom::P.'/!media/grf/temp');
		}
	}
	
	use Mysql; # 3.5MB
	use Text::Iconv;
	use Compress::Zlib;
	use MIME::Base64;
	use File::Type;
	#use Image::Magick; # 2.8MB
	
	
	# CORE Engine kniznice
	use TOM::Domain; # all addons will be initialized because $tom::addons_init is in true state
	use TOM::Engine::pub::SIG;
	use TOM::Engine::pub::cookies;
	use TOM::Engine::pub::IAdm;
	use TOM::Debug::pub;
	use TOM::Warning;
	use TOM::Database::connect;
	use TOM::TypeID;
	use TOM::Security::form;
	
	
	# TOM libraries
	use TOM::Net::email;
	use TOM::Net::HTTP;
	use TOM::Net::HTTP::UserAgent; # detekcia a praca s UserAgentami
	use TOM::Net::HTTP::Media; # detekcia media
	use TOM::Net::HTTP::referer; # detekcia a praca s refererom
	use TOM::Net::URI::URL; # praca s URLckami
	use TOM::Net::URI::rewrite; # praca s rewrite URI
	use TOM::Net::URI::301; # praca s automatickým redirektovaním 301
	use TOM::Net::HTTP::DOS; #  DOS withstand
	use TOM::Net::HTTP::hacked;
	use TOM::Net::HTTP::CGI;
	use TOM::Debug::breakpoints; # merania
	use TOM::Math;
	use TOM::Int::lng;
	use TOM::Utils::datetime;
	
	# default addons
	use App::020::_init; # standard 0
	use App::1B0::_init; # Banning system
	use App::210::_init; # Sitemap
	require Ext::CacheMemcache::_init if $TOM::CACHE_memcached; # memcache support
	
	# new Cyclone libs
	use Cyclone;
	
	
package main;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
	
	
	use Tomahawk::error;
	use Tomahawk::debug;
	
	use Tomahawk;
	
	use Net::DOC; # v skutocnosti to je Net::DOC::base
	use Net::HTTP::CGI; # TODO: [Aben] Pomaly sa zbavit vsetkych Net::* kniznic a vytvorit nove pod TOM::Net::*
	use Net::HTTP::cookies;
	use Net::HTTP::robots;
	
	use CML;
	use Int::charsets;
	use Int::charsets::encode;
	
	
1;
