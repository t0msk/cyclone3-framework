package TOM::Engine::cron;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
	
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}
	
	
	use Mysql;
	use Digest::MD5  qw(md5 md5_hex md5_base64);
	use Text::Iconv;
	use Compress::Zlib;
	use Time::Local; # pre opacnu konverziu casu
	use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );
	use MIME::Base64;
	
	
	# CORE PORTAL MODULES
	use TOM::rev;
	use TOM::Debug; # vyziada si logovanie
	use TOM::Error;
	use TOM::Database::connect;
	
	# TOM libraries
	use TOM::Net::email;
	#use TOM::Net::HTTP::UserAgent; # detekcia a praca s UserAgentami
	#use TOM::Net::URI::URL; # praca s URLckami
	#use TOM::Net::URI::rewrite; # praca s rewrite URI
	#use TOM::Net::HTTP::DOS; #  DOS withstand
	use TOM::Debug::breakpoints; # merania
	#use TOM::Debug::trackpoints; # merania
	use TOM::Math;
	use TOM::Int::lng;
	
	
	if (!$ARGV[0])
	{
		main::_log("Type of cron system is not defined",1);
		
		my @ERR=("Type of cron system is not defined");
		push @ERR,$@;
		TOM::Error::engine(@ERR);
		exit(0);
	}
	
	$cron::type=$tom::type=$ARGV[0];
	
	
	
	#TOM::Error::engine("nefunguje to");
	
	
	
1;
