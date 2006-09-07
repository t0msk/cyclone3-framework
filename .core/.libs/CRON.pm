#!/usr/bin/perl


# DEFINUJEM PREMENNE V OBLASTI MODULOV
package CRON::module;
use vars qw/$ERR/;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

# DEFINUJEM NULOVY DEBUG
package CRON::debug;
sub log{return}

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use conv;

# CRON BEGINN
package CRON;

use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use Utils::vars;
use Utils::datetime;
use System::meter;
use CRON::error;

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
#	waitloop:
	
	#open (HND,"</proc/loadavg");
	#my ($avg,undef)=split(' ',<HND>);
	#close HND;
	
	my $avg=(System::meter::getLoad)[0];
	
=head1
	CRON::debug::log(20,"{$loops} load is $avg, maximum $_[0]");
	
	if (($avg>$_[0]) && ($loops<100))
	{
#		$loops++;
		my $var=rand(10);
		CRON::debug::log(21,"load $avg has reached the maximum $_[0], waiting $var seconds",1);
		Time::HiRes::sleep($var);
		goto waitloop;
	}
=cut
	
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
 	SELECT value,cache
	FROM $tom::DB_name._config
	WHERE type='var' AND variable='$_[0]' LIMIT 1");
 if (my @db0_line=$db0->FetchRow())
 {
  return $db0_line[0];
 }
 return undef}


sub Getmdlvar
{
 return undef unless $_[0];
 return undef unless $_[1];
 my $key=$_[0]."-".$_[1];
 my %env=@_;
 $env{db}=$tom::DB_name unless $env{db};

 main::_log("Get mdlvar ".$key." from ".$env{db});

 my $db0 = $DBH->Query("
 	SELECT value,cache
	FROM $env{db}._config
	WHERE type='mdl' AND variable='$key' LIMIT 1");
 if (my @db0_line=$db0->FetchRow())
 {
  return $db0_line[0];
 }
 return undef}



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
 foreach (keys %mdl_env)
 {
	my $var=$mdl_env{$_};$var=~s|[\n\r]||g;
	if (length($var)>50){$var=substr($var,0,50)."..."}
	main::_log("input (".$_.")=".$var);
	/^-/ && do {$mdl_C{$_}=$mdl_env{$_};delete $mdl_env{$_};}
 }
 $mdl_C{-category}="0" unless $mdl_C{-category};
 $mdl_C{-version}="0" unless $mdl_C{-version}; # NEBUDEM SE S NIKYM SRAAAT BEZ DUUVODU!...

 my $file_data;

 # NECACHUJEM, LEBO VYPRSALA CACHE

 main::_log("executing");

 # KDE JE MODUL?
 if ($mdl_C{-global})
 {$mdl_C{P_MODULE}=
  $CRON::P."/_mdl/".$mdl_C{-category}."/".$mdl_C{-category}."-".$mdl_C{-name}.".".$mdl_C{-version}.".cron";}
 else
 {$mdl_C{P_MODULE}=
  $cron::P."/_mdl/".$mdl_C{-category}."-".$mdl_C{-name}.".".$mdl_C{-version}.".cron";}

 # AK MODUL NEEXISTUJE
 if (not -e $mdl_C{P_MODULE})
 {
 	main::_log("not exist",1);#return undef;
 	CRON::error::module(
   	-MODULE	=>	$mdl_C{-category}."-".$mdl_C{-name},
	-ERROR	=>	"module not exist $mdl_C{P_MODULE}"
   );
 }

 main::_log("secure eval, alarm $CRON::ALRM_mdl");

 # V EVALKU OSETRIM CHYBU RYCHLOSTI A SPATNEHO MODULU
 eval
 {
  local $SIG{ALRM} = sub {die "Timed out $CRON::ALRM_mdl sec.\n"};
  alarm $CRON::ALRM_mdl;

  if (not do $mdl_C{P_MODULE}){die "pre-compilation error - $! $@\n";}

  if (CRON::module::execute(%mdl_env))
  {
   main::_log("end eval");
  }
  else # chyba o ktorej upozorni samotny program vratenim undef :)
  {
   CRON::error::module(
   	-MODULE	=>	$mdl_C{-category}."-".$mdl_C{-name},
	-ERROR	=>	$cron::ERR
   );
   #CRON::debug::log(3,"ERR::$mdl_C{-name} ".$cron::ERR,1);
  };
  alarm 0;
 };
 if ($@)
 {
  CRON::error::module(
   	-MODULE	=>	$mdl_C{-category}."-".$mdl_C{-name},
	-ERROR	=>	$@
   );
  #CRON::debug::log(3,"ERR::$mdl_C{-name} ".$@,1);
 };
 alarm 0;
 $t->close();
}


1;
