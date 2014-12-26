package CRON::debug;

use strict;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use TOM::Debug;
use TOM::Debug::logs;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

sub log
{
	main::_obsolete_func();
	my @env=@_;
	if ($env[0]=~/^\d+/)
	{
		shift @env;
	}
	main::_log(@env);
}


1;
