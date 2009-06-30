package TOM::Engine::download;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


	use TOM;
	
	BEGIN
	{
		$TOM::Engine='download';
	}
	
	use Mysql; # 3.5MB
	use Compress::Zlib;
	use MIME::Base64;
	use File::Type;
	#use Image::Magick; # 2.8MB
	
	
	# CORE Engine kniznice
	use TOM::Domain; # all addons will be initialized because $tom::addons_init is in true state
	use TOM::Engine::pub::SIG;
#	use TOM::Debug::pub;
#	use TOM::Warning;
	use TOM::Database::connect;
	use TOM::Database::SQL;
#	use TOM::TypeID;
#	use TOM::Security::form;
	
	
	# TOM libraries
	use TOM::Net::email;
	use TOM::Net::HTTP::UserAgent; # detekcia a praca s UserAgentami
#	use TOM::Net::HTTP::Media; # detekcia media
	use TOM::Net::URI::URL; # praca s URLckami
	use TOM::Net::URI::rewrite; # praca s rewrite URI
#	use TOM::Net::URI::301; # praca s automatickým redirektovaním 301
#	use TOM::Net::HTTP::DOS; #  DOS withstand
#	use TOM::Net::HTTP::hacked;
	use TOM::Net::HTTP::CGI;
#	use TOM::Debug::breakpoints; # merania
#	use TOM::Math;
#	use TOM::Int::lng;
#	use TOM::Utils::datetime;
	
	# default addons
	use App::020::_init; # standard 0
	use App::1B0::_init; # Banning system
	require Ext::CacheMemcache::_init if $TOM::CACHE_memcached; # memcache support
	
	# new Cyclone libs
	use Cyclone;
	
	
package main;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
	
	use CML;
	use Int::charsets;
	use Int::charsets::encode;
	
	
1;
