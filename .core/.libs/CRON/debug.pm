package CRON::debug;

use strict;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use TOM::Debug;

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
