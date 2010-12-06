package TOM::Domain;

=head1 NAME

TOM::Domain

=head1 DESCRIPTION

Initialize domain service if available

require TOM::Domain only if you want to initialize domain session for engine.
local.conf and dependencies are automatically in initialization loaded.
If $tom::addons_init is true, all configured addons defined in %tom::addons are initalized.
$tom::addons_init is enabled by default only in 'pub' engine.

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
	
	main::_log("tom::P=$tom::P");
	
	if ($tom::P)
	{
		mkdir $tom::P.'/_logs' if (! -e $tom::P.'/_logs');
		chmod 0777,$tom::P.'/_logs';
		
		# load configured addons
		if ($tom::P ne $TOM::P)
		{
			main::_log_stdout("require $tom::P/local.conf");
			require $tom::P."/local.conf";
			
			if ($tom::Pm)
			{
				shift @INC;
				shift @INC;
				unshift @INC,$tom::Pm."/.libs";
				unshift @INC,$tom::Pm."/_addons";
				unshift @INC,$tom::P."/.libs";
				unshift @INC,$tom::P."/_addons";
			}
			
			if ($tom::addons_init) # load all addons only if required by engine
			{
				foreach my $addon(keys %tom::addons)
				{
					delete $tom::addons{$addon} unless $tom::addons{$addon};
				}
				main::_log("load configured addons ".join(";",keys %tom::addons));
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
				}
			}
		}
		
	}
	
}

1;