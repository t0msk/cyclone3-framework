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
		
		# data adresar
		mkdir $tom::P."/_data" if (! -e $tom::P."/_data");
		
		# udrziavaci USRM adresar
		mkdir $tom::P."/_data/USRM" if (! -e $tom::P."/_data/USRM");
		
		# debug adresare
		mkdir $tom::P."/_logs/_debug" if (! -e $tom::P."/_logs/_debug");
	}
	
	use Mysql;
	use Digest::MD5  qw(md5 md5_hex md5_base64);
	use Text::Iconv;
	use Compress::Zlib;
	use Time::Local; # pre opacnu konverziu casu
	use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );
	use MIME::Base64;
	
	
	# CORE Engine kniznice
	use TOM::Debug::pub;
	use TOM::Warning;
	use TOM::Database::connect;
	use TOM::TypeID;
	
	
	# TOM libraries
	use TOM::Net::email;
	use TOM::Net::HTTP::UserAgent; # detekcia a praca s UserAgentami
	use TOM::Net::HTTP::Media; # detekcia media
	use TOM::Net::URI::URL; # praca s URLckami
	use TOM::Net::URI::rewrite; # praca s rewrite URI
	use TOM::Net::URI::301; # praca s automatickým redirektovaním 301
	use TOM::Net::HTTP::DOS; #  DOS withstand
	use TOM::Net::HTTP::hacked;
	use TOM::Net::HTTP::CGI;
	use TOM::Debug::breakpoints; # merania
	use TOM::Math;
	use TOM::Int::lng;
	
	
	# default aplikácie
	use App::1B0;
	
	
	# nove Cyclone kniznice
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
