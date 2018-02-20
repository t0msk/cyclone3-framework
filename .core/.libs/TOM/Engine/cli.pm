package TOM::Engine::cli;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


	use TOM;
	
	BEGIN
	{
		$TOM::Engine='cli';
		$tom::addons_init=1;
		$tom::templates_init=1;
	}
	
	use Mysql; # 3.5MB
	use Text::Iconv;
	use Compress::Zlib;
	use MIME::Base64;
	use File::Type;
	#use Image::Magick; # 2.8MB
	
	
	# CORE Engine kniznice
	use TOM::Domain; # all addons will be initialized because $tom::addons_init is in true state
	
	if ($TOM::user_ ne $TOM::user && $TOM::user_ ne $TOM::user_www)
	{
		main::_log_stdout("WARNING: you are starting Cyclone3 framework under user $TOM::user_");
	}
	
	# new Cyclone libs
	use Cyclone;
	
	
package main;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
	
	
	use CML;
	use Int::charsets;
	use Int::charsets::encode;
	
	
1;
