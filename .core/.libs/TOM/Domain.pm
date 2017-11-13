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
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
use JSON;

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
		
		# load configation
		if ($tom::P ne $TOM::P)
		{
			$tom::P_media=$tom::P."/!media"; # redefine P_media
			main::_log_stdout("require $tom::P/local.conf");
			require $tom::P."/local.conf";
			main::_log("tom::Pm=$tom::Pm");
			
			push @main::mfiles, $tom::P.'/local.conf';
			push @main::mfiles, $tom::P.'/master.conf'
				if -e $tom::P.'/master.conf';
			if ($tom::Pm && $tom::P ne $tom::Pm)
			{
				push @main::mfiles, $tom::Pm.'/local.conf'
					if -e $tom::Pm.'/local.conf';
				push @main::mfiles, $tom::Pm.'/master.conf'
					if -e $tom::Pm.'/master.conf';
			}
			
			# save original tom::H
			$tom::H_orig=$tom::H;
			
			main::_log("domain hostname '$tom::H'");
			$0.=" [".$tom::H."]";
			
			#
			$tom::D_cookie=$tom::H_cookie unless $tom::D_cookie;
			$tom::H_cookie=$tom::H_cookie.$tom::P_cookie;
				$tom::H_cookie=~s|/$||;
			main::_log("cookie domain='$tom::D_cookie' USRM unique hostname='$tom::H_cookie'");
			
			if ($tom::Pm)
			{
				shift @INC;
				shift @INC;
				unshift @INC,$tom::Pm."/.libs";
				unshift @INC,$tom::Pm."/_addons";
				unshift @INC,$tom::P."/.libs";
				unshift @INC,$tom::P."/_addons";
			}
			
			TOM::Database::connect::multi(@TOM::DB_pub_connect);
#				|| die "Error during connection request to database server\n";
			
			if ($tom::addons_init) # load all addons only if required by engine
			{
				foreach my $addon(keys %tom::addons)
				{
					delete $tom::addons{$addon} unless $tom::addons{$addon};
				}
				main::_log("loading configured addons ".join(";",keys %tom::addons));
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
				require App::020::mimetypes; # default parser
			}
			
			require TOM::Template;
			if ($tom::templates_init) # load all templates only if required by engine
			{
				foreach my $template(keys %tom::templates)
				{
					delete $tom::templates{$template} unless $tom::templates{$template};
				}
				main::_log("load configured templates ".join(";",keys %tom::templates));
				foreach my $template(sort keys %tom::templates)
				{
					my %tpl_set;
					if (ref($tom::templates{$template}) eq "HASH")
					{
						%tpl_set=%{$tom::templates{$template}};
					}
					main::_log("<={TPL} '$template'");
					new TOM::Template(
						'name' => $template,
						'content-type' => "xhtml",
						%tpl_set
					);
				}
			}
			
			# when locally defined
			require Ext::Solr::_init if $Ext::Solr::url;
			require Ext::RabbitMQ::_init if $Ext::RabbitMQ::host;
			require Ext::Redis::_init if $Ext::Redis::host;
			require Ext::CacheMemcache::_init if $TOM::CACHE_memcached && !$Ext::CacheMemcache::cache;
			
			if ($Ext::Redis::service){eval{
				main::_log("updating register of domains (RedisDB)");
				no strict;
				my %addons=%tom::addons;
				foreach (keys %addons)
				{
					my $db_var=$_.'::db_name';
						$db_var=~s|^a|App::| || $db_var=~s|^e|Ext::|;
					my $db_name=$$db_var || $TOM::DB{'main'}{'name'};
					$addons{$_}=$db_name;
				}
				my $path=$tom::P;
					$path=~s|^.*?!|!|;
				$Ext::Redis::service->hset('C3|domains',$tom::H_orig,to_json({
					'updated' => time(),
					'env' => {
						'cmd' => $0,
						'engine' => $TOM::engine,
						'hostname' => $TOM::hostname,
						'PID' => $$
					},
					'db_name' => $TOM::DB{'main'}{'name'},
					'tom::P' => $tom::P,
					'tom::P_rel' => $path,
					'tom::Pm' => $tom::Pm,
#					'ENV' => %m
					'addons' => \%addons
				}),sub{});
			};}
			
			# Git when available
			if (-d $tom::P.'/.git' || -d $tom::Pm.'/.git'){eval{require Git};if (!$@)
			{
				eval {
				my $repo = Git->repository('Directory' => $tom::P);
				$tom::devel_branch=$repo->command('rev-parse','--abbrev-ref'=>'HEAD');
					chomp($tom::devel_branch);
				main::_log("identified git branch '$tom::devel_branch'");
				};
			}}
		}
		
	}
	
}

1;
