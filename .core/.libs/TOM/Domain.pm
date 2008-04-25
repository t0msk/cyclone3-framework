package TOM::Domain;

=head1 NAME

TOM::Domain

=head1 DESCRIPTION

Initialize domain service if available

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {main::_log("<={LIB} ".__PACKAGE__)}

BEGIN
{
	unshift @INC,$tom::P."/.libs" if $tom::P;
	unshift @INC,$tom::P."/_addons" if $tom::P;
	if ($tom::P)
	{
		mkdir $tom::P.'/_logs' if (! -e $tom::P.'/_logs');
		chmod 0777,$tom::P.'/_logs';
		
		# load configured applications
		#main::_log("load addons");
		if ($tom::P ne $TOM::P)
		{
			main::_log("require $tom::P/local.conf");
			require $tom::P."/local.conf";
			
			main::_log("load configured addons");
			foreach my $addon(sort keys %tom::addons)
			{
				my $addon_path;
				if ($addon=~s/^a//)
				{
					$addon_path='App::'.$addon.'::_init';
				}
				elsif ($addon=~s/^e//)
				{
					$addon_path='Ext::'.$addon.'::_init';
				}
				main::_log("<={ADDON} '$addon_path'");
				eval "use $addon_path;";
				if ($@){main::_log("can't load addon '$addon_path' $@ $!",1)}
				#require 
			}
		}
		
	}
}

1;