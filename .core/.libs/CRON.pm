#!/usr/bin/perl


# DEFINUJEM PREMENNE V OBLASTI MODULOV
package CRON::module;
use vars qw/$ERR/;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

# DEFINUJEM NULOVY DEBUG
package CRON::debug;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

# CRON BEGINN
package CRON;

use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use Utils::vars;
use Utils::datetime;
use System::meter;

#use warnings;
use vars qw/
	@ISA
	@EXPORT
	$DBH
	%mdl_C
	%mdl_env
	/;
use Exporter;
@ISA=qw/Exporter/;
@EXPORT=qw/
	module
	$DBH
	/;




sub waitload
{
	return undef unless $_[0];
	my $loops;
	my $avg=(System::meter::getLoad)[0];
	
	while (($avg>$_[0])&&($loops<100))
	{
		$avg=(System::meter::getLoad)[0];
		my $var=int(rand(10));
		$loops++;
		main::_log("{$loops} load ".((System::meter::getLoad)[0])." has reached the maximum $_[0], waiting $var seconds",1);
		Time::HiRes::sleep($var);
	}
	return 1;
}


sub Getvar
{
	return undef unless $_[0];
	main::_log("Get var ".$_[0]." from ".$tom::DB_name);
	my $db0 = $DBH->Query("
		SELECT
			value,
			cache
		FROM
			$tom::DB_name._config
		WHERE
			type='var' AND
			variable='$_[0]'
		LIMIT 1");
	if (my @db0_line=$db0->FetchRow())
	{
		return $db0_line[0];
	}
	return undef
}


sub Getmdlvar
{
	return undef unless $_[0];
	return undef unless $_[1];
	my $key=$_[0]."-".$_[1];
	my %env=@_;
	$env{db}=$tom::DB_name unless $env{db};
	
	main::_log("Get mdlvar ".$key." from ".$env{db});
	
	my $db0 = $DBH->Query("
		SELECT
			value,
			cache
		FROM
			$env{db}._config
		WHERE
			type='mdl' AND
			variable='$key'
		LIMIT 1");
	if (my @db0_line=$db0->FetchRow())
	{
		return $db0_line[0];
	}
	return undef
}


# ADD MODULE
###############
sub module
{
	local %mdl_env=@_;
	local %mdl_C;
	local $cron::ERR;
	
	my $t=track TOM::Debug("module");
	
	main::_log("adding module ($tom::H) ".$mdl_env{-category}."-".$mdl_env{-name}."/".$mdl_env{-version}."/".$mdl_env{-global});
	
	# SPRACOVANIE PREMMENNYCH
	foreach (sort keys %mdl_env)
	{
		my $var=$mdl_env{$_};$var=~s|[\n\r]||g;
		if (length($var)>50){$var=substr($var,0,50)."..."}
		main::_log("input (".$_.")=".$var);
		/^-/ && do {$mdl_C{$_}=$mdl_env{$_};delete $mdl_env{$_};}
	}
	$mdl_C{-category}="0" unless $mdl_C{-category};
	$mdl_C{-version}="0" unless $mdl_C{-version}; # NEBUDEM SE S NIKYM SRAAAT BEZ DUUVODU!...
	
	my $file_data;
	
	# where is module?
	if ($mdl_C{-global})
	{
		my $addon_path=
			$CRON::P."/_addons/App/".$mdl_C{-category}."/_mdl/".
			$mdl_C{-category}."-".$mdl_C{-name}.".".$mdl_C{-version}.".cron";
			
		
		# find in overlays
		foreach my $item(@TOM::Overlays::item)
		{
			my $file=
				$TOM::P.'/_overlays/'.$item
				.'/_addons/App/'.$mdl_C{'-category'}.'/_mdl/'
				.$mdl_C{'-category'}."-".$mdl_C{'-name'}.".".$mdl_C{'-version'}.".cron";
			if (-e $file){$addon_path=$file;last;}
		}
		
		if (-e $addon_path)
		{
			$mdl_C{P_MODULE}=$addon_path;
		}
		else
		{
			$mdl_C{P_MODULE}=
				$CRON::P."/_mdl/".
				$mdl_C{-category}."/".$mdl_C{-category}."-".$mdl_C{-name}.".".$mdl_C{-version}.".cron";
		}
	}
	else
	{
		my $addon_path=
			$cron::P."/_addons/App/".$mdl_C{-category}."/_mdl/".
			$mdl_C{-category}."-".$mdl_C{-name}.".".$mdl_C{-version}.".cron";
		if (-e $addon_path)
		{
			$mdl_C{P_MODULE}=$addon_path;
		}
		else
		{
			$mdl_C{P_MODULE}=
				$cron::P."/_mdl/".
				$mdl_C{-category}."-".$mdl_C{-name}.".".$mdl_C{-version}.".cron";
		}
	}
	
	# AK MODUL NEEXISTUJE
	if (not -e $mdl_C{P_MODULE})
	{
		TOM::Error::module
		(
			-MODULE	=>	$mdl_C{-category}."-".$mdl_C{-name},
			-ERROR	=>	"module file not found $mdl_C{P_MODULE}"
		);
		$t->close();
		return undef;
	}
	
	# V EVALKU OSETRIM CHYBU RYCHLOSTI A SPATNEHO MODULU
	my $t_eval=track TOM::Debug("exec");
	main::_log("set ALARM timetout to $CRON::ALRM_mdl");
	eval
	{
		local $SIG{ALRM} = sub {die "Timed out $CRON::ALRM_mdl sec.\n"};
		alarm $CRON::ALRM_mdl;
		
		if (not do $mdl_C{'P_MODULE'}){die "pre-compilation error - $! $@\n";}
		
		if (CRON::module::execute(%mdl_env))
		{
			#main::_log("end eval");
		}
		else # chyba o ktorej upozorni samotny program vratenim undef :)
		{
			TOM::Error::module
			(
				-MODULE	=> $mdl_C{-category}."-".$mdl_C{-name},
				-ERROR	=>	$cron::ERR
			);
		};
		alarm 0;
	};
	$t_eval->close();
	
	if ($@)
	{
		TOM::Error::module
		(
			-MODULE	=>	$mdl_C{-category}."-".$mdl_C{-name},
			-ERROR	=>	$@
		);
	};
	alarm 0;
	$t->close();
}


1;
