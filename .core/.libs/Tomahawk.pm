#!/usr/bin/perl
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use Tomahawk::debug;

#use encoding 'utf8';
# áéíóú - USE UTF-8!!!
=head1 NAME

Tomahawk core library - 3.030807
developed on Unix and Linux based systems and Perl 5.8.0 script language
=cut
=head1 COPYRIGHT

(c) 2003 WebCom s.r.o.
All right reserved!
Unauthorized access and modification prohibited!
=cut
=head1 CHANGES

Tomahawk 3.030807
	*) hlbsie previazanie verzii
	*) zmena adresarov modulov, designov, languages
=cut
=head1 SYNOPSIS
=cut
=head1 DESCRIPTION
=cut
=head1 WARNINGS & BUGS
	*) tak dufam ze ziadne :)

=cut

# DEFINUJEM PREMENNE V OBLASTI MODULOV
package Tomahawk::module;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use vars qw/%XSGN %XLNG $ERR/;



# DEFINUJEM NULOVY DEBUG
use Tomahawk::debug;
#use open ':utf8', ':std';
#use encoding 'utf8';
#use utf8;

#BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

#sub log{return}
#sub mdllog{return}
#sub errlog{return}
#sub cache_conf_opt{return}
#sub cache_conf_opt_plus{return}
#sub module_load{return}
#sub type{return}



# DEFINUJEM NULOVE STATISTIKY
package Tomahawk::stat;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

sub rqs{return 1}



# DEFINUJEM NULOVY CACHE
package Tomahawk::cache;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

sub destroy{return undef}

#package conv;
#require Exporter;
#require DynaLoader;
#@ISA = qw(Exporter DynaLoader);
#bootstrap conv;
#@EXPORT = qw( );

# TOMAHAWK BEGINN
package Tomahawk;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
use Utils::vars;
use Utils::datetime;
use conv;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );
use Digest::MD5  qw(md5 md5_hex md5_base64);


#use warnings;
use vars qw/
	@ISA
	@EXPORT
	%mdl_C
	%mdl_env
	%smdl_env
	%CACHE
	%VAR
	$app
	%var
	%mdlvar
	/;
use Exporter;
@ISA=qw/Exporter/;
@EXPORT=qw/
	HtmlError
	module
	supermodule
	designmodule
	/;
	
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}




sub Getvar
{
 return undef unless $_[0];
 if (($TOM::var_cache)&&($var{$_[0]}{time}+$var{$_[0]}{cachetime}>$tom::time_current)){return $var{$_[0]}{value}}
 
 #main::_log("Quering");
 
 main::_log("Getvar($_[0]) from database $TOM::DB{main}{name}");
 
 #main::_log("Get var SQL ".$_[0]." from ".$TOM::DB_name." ".($tom::time_current-$var{$_[0]}{time})."-".$var{$_[0]}{cachetime});
 
 my $db0 = $main::DB{main}->Query("
 	SELECT value,cache
	FROM $TOM::DB_name._config
	WHERE type='var' AND variable='$_[0]' LIMIT 1");
 if (my @db0_line=$db0->FetchRow())
 {
  $main::DB{main}->Query("
	UPDATE $TOM::DB_name._config
	SET reqtime='$tom::time_current'
	WHERE type='var' AND variable='$_[0]' LIMIT 1") if $TOM::DEBUG_var_cache;
  if ($TOM::var_cache)
  {
   $db0_line[1]=$TOM::var_loadtime unless $db0_line[1];
   $var{$_[0]}{time}=$tom::time_current;$var{$_[0]}{value}=$db0_line[0];
   $var{$_[0]}{cachetime}=$db0_line[1];
  }
  return $db0_line[0];
 }
 else
 {
  main::_log("writing");
  my $db0 = $main::DB{main}->Query("
	SELECT *
	FROM $TOM::DB_name_TOM._config
	WHERE type='var' AND variable='$_[0]' LIMIT 1");
  if (my %env0=$db0->fetchhash())
  {
   $main::DB{main}->Query("
   	INSERT INTO $TOM::DB_name._config(variable,value,type,cache,about)
	VALUES('$_[0]','$env0{value}','var','$env0{cache}','RQS - $env0{about}')
	");
  }
  else
  {
   $main::DB{main}->Query("INSERT INTO $TOM::DB_name._config(variable,type,about) VALUES('$_[0]','var','RQS! - ')");
  }
 }
 return undef}



sub Getmdlvar
{
 return undef unless $_[0];
 return undef unless $_[1];
 my $key=$_[0]."-".$_[1];
 
 my %env=@_;
 
 $env{db}=$TOM::DB_name unless $env{db};
 
 #main::_log("Get mdlvar ".$key." from ".$env{db});
 
 return $mdlvar{$key}{value} if (($TOM::var_cache)&&($mdlvar{$key}{time}+$mdlvar{$key}{cachetime}>$tom::time_current));
 
 main::_log("Get mdlvar SQL ".$key." from ".$env{db});
 #main::_log("Quering");
 
 #my $key=shift."-".shift;
 #if (($TOM::var_cache)&&($mdlvar{$key}{time}+$mdlvar{$key}{cachetime}>$tom::time_current)){return $mdlvar{$key}{value}}
 my $db0 = $main::DB{main}->Query("
 	SELECT value,cache
	FROM $env{db}._config
	WHERE type='mdl' AND variable='$key' LIMIT 1");
 if (my @db0_line=$db0->FetchRow())
 {
  $main::DB{main}->Query("
	UPDATE $env{db}._config
	SET reqtime='$main::time_current'
	WHERE type='mdl' AND variable='$key' LIMIT 1") if $TOM::DEBUG_var_cache;
  if ($TOM::var_cache)
  {
   $db0_line[1]=$TOM::var_loadtime unless $db0_line[1];
   $mdlvar{$key}{time}=$tom::time_current;$mdlvar{$key}{value}=$db0_line[0];
   $mdlvar{$key}{cachetime}=$db0_line[1];
  }
  return $db0_line[0];
 }
 else
 {
  my $db0 = $main::DB{main}->Query("
	SELECT *
	FROM $TOM::DB_name_TOM._config
	WHERE type='mdl' AND variable='$key' LIMIT 1");
  if (my %env0=$db0->fetchhash())
  {
   $main::DB{main}->Query("
   	INSERT INTO $env{db}._config(variable,value,type,cache,about)
	VALUES('$key','$env0{value}','mdl','$env0{cache}','RQS - $env0{about}')
	");
  }
  else
  {
   $main::DB{main}->Query("INSERT INTO $env{db}._config(variable,type,about) VALUES('$key','mdl','RQS! - ')");
  }
  #$DBH->Query("INSERT INTO $env{db}._config(variable,type,about) VALUES('$key','mdl','ERR - requested!')");
 }
 return undef}




sub GetCACHE_CONF
{
	my $t=track TOM::Debug(__PACKAGE__."::GetCACHE_CONF()");
	my $count=0;
	my $db0 = $main::DB{sys}->Query("
		SELECT *
		FROM TOM.a150_config
		WHERE	(domain='$tom::Hm' OR domain='')
				AND (domain_sub='$tom::H' OR domain_sub='')
				AND engine='pub'
		ORDER BY domain,domain_sub
		");
	while (my %db0_line=$db0->fetchhash())
	{
		$count++;
		my $var=$db0_line{Capp}."-".$db0_line{Cmodule}."-".$db0_line{Cid};
		$CACHE{$var}{'-cache_time'}=$db0_line{time_duration};
		$CACHE{$var}{'-opt_time'}=$db0_line{time_optimalization};
		$CACHE{$var}{'-domain'}=$db0_line{domain};
		$CACHE{$var}{'-domain_sub'}=$db0_line{domain_sub};
		$CACHE{$var}{'-ID_config'}=$db0_line{ID};
	}
	main::_log("loaded ".$count." cache configs from TOM.a150_config");
	$t->close();
	return 1;
}








# ADD MODULE
###############
sub module
{
	my $t=track TOM::Debug(__PACKAGE__."::module()");
	
	local %mdl_env=@_;
	local %mdl_C;
	local $tom::ERR;
	local $tom::ERR_plus;
	local $app=$mdl_env{-category};
	my $cache_domain;
	my $return_code;

=head1 RETURN
0 - error

1 - OK

10 - TMP_check -> TMP not found
120 - not runned -> IAdm || ITst
121 - not runned -> IAdm
122 - not runned -> ITst

130 - readed from cache <- zatial nepouzivam a tusim ani nechcem pouzit

2XX - user

=cut

	# najpv si ocheckujem ci nechcem zistovat pritomnost TMP
	# zaroven pritomnost TMP zistim
	if ($mdl_env{-TMP_check})
	{
		main::_log("-TMP_check enabled");
		if (not $main::H->{OUT}{BODY}=~/<!TMP-$mdl_env{-TMP}!>/)
		{
			main::_log("return 10, TMP '$mdl_env{-TMP}' not exists in BODY");
			$t->close();
			return 10;
		}
	}
	
	# rusim modul pokial je setovany ako IAdm
	# neviem preco to tu robim, ak to mam uz nastavene vonku :-o priamo v core?
	if (($main::IAdm && $mdl_env{-IAdm}==-1)
	||(!$main::IAdm && $mdl_env{-IAdm}==1))
	{
		main::_log("return 120, -IAdm");
		return 120;
	}
	
	#my $time_module=TOM::Debug::breakpoints->new();$time_module->start();
	
	main::_log("adding module ".$mdl_env{-category}."-".$mdl_env{-name}."/".$mdl_env{-version}."/".$mdl_env{-global});
	
	# rusim CACHOVANIE pokial som IAdm
	delete $mdl_env{-cache_id}
		if (($main::IAdm && $main::FORM{__IAdm_uncache})
		||($main::ITst && $main::FORM{__ITst_uncache}));
	
	
	
	# SPRACOVANIE PREMENNYCH
	foreach (sort keys %mdl_env)
	{
=head1
		if ($main::IAdm)
		{
			my $var=$mdl_env{$_};$var=~s|[\n\r]| |g;
			#if (length($var)>50){$var=substr($var,0,50)."..."}
			$var=substr($var,0,50)."..." if length($var)>50;
			#main::_log(1,"input (".$_.")=".$var);
			main::_log("input '$_'='$var'");
		}
=cut
		main::_log("input '$_'='$mdl_env{$_}'");
		/^-/ && do {$mdl_C{$_}=$mdl_env{$_};delete $mdl_env{$_};}
	}
	
	$mdl_C{-category}="0" unless $mdl_C{-category};
	$mdl_C{-version}="0" unless $mdl_C{-version}; # NEBUDEM SE S NIKYM SRAAAT BEZ DUUVODU!...
	$mdl_C{-xsgn}=$tom::dsgn unless $mdl_C{-xsgn}; # SAJRAJT
	$mdl_C{-xsgn_global}=0 unless $mdl_C{-xsgn_global};
	$mdl_C{-xlng}=$tom::lng unless $mdl_C{-xlng};
	$mdl_C{-xlng_global}=0 unless $mdl_C{-xlng_global};
	# nastavit default alarmu ak nevyzadujem zmenu alebo nieje povolena zmena
	$mdl_C{-ALRM}=$TOM::ALRM_mdl if ((not exists $mdl_C{-ALRM})||(!$TOM::ALRM_change));
	if ((exists $mdl_C{-cache_id})&&(!$mdl_C{-cache_id})){$mdl_C{-cache_id}="0"}
		
	
	my $file_data;
	
	# definujem rec pre modul aby ju mohol prijat ako $env{lng}
	# AK NIEJE ZADANA NATVRDO CEZ module (-xlng), tak vezmem language
	# tejto session. predam do $env{lng}
	$mdl_env{lng}=$mdl_C{-xlng};
	
	# definujem design pre modul aby ju mohol prijat ako $env{dsgn}
	# AK NIEJE ZADANA NATVRDO CEZ module (-xsgn), tak vezmem design
	# tejto session. predam do $env{lng}
	$mdl_env{dsgn}=$mdl_C{-xsgn};
	
	# AK JE DEFINOVANA POZIADAVKA NA CACHOVANIE A JE DEFINOVANA
	# POZIADAVKA NA VOBEC CACHOVANIE, TAK SA TOMU VENUJEM
	if ((exists $mdl_C{-cache_id})&&($TOM::CACHE))
	{
		$mdl_C{-cache_id_sub}="0" unless $mdl_C{-cache_id_sub};
		$mdl_C{-cahe_id}="0" unless $mdl_C{-cache_id}; # ak je vstup s cache_id ale nieje 0
		$cache_domain=$tom::H unless $mdl_C{-cache_master};
	
		# Tomahawk::debug::log(3,"cache defined");
		my $null;
		foreach (sort keys %mdl_env){$_=~/^[^_]/ && do{$null.=$_."=\"".$mdl_env{$_}."\"\n";}}
		foreach (sort keys %mdl_C){$null.=$_."=\"".$mdl_C{$_}."\"\n";}
		
		$mdl_C{-md5}=md5_hex(Int::charsets::encode::UTF8_ASCII($null));
		main::_log("cache md5='".$mdl_C{-md5}."'");
		
		
		# NAZOV PRE TYP CACHE V KONFIGURAKU
		$mdl_C{T_CACHE}=$mdl_C{-category}."-".$mdl_C{-name}."-".$mdl_C{-cache_id};
		
		my $cache;
		my $memcached;
		if ($TOM::CACHE_memcached)
		{
			$memcached=Ext::Cache_memcache::check();
			main::_log("memcached: reading");
			if ($memcached)
			{
				$cache=$Ext::Cache_memcache::cache->get(
					'namespace' => "mcache",
					'key' => $tom::Hm.":".$cache_domain.":pub:".$mdl_C{'-md5'}
				);
			}
			else
			{
				main::_log("memcached: daemon is not running");
			}
		}
		
		if ($cache)
		{
			main::_log("memcached: readed");
		}
		else
		{
			main::_log("sqlcache: reading");
			my $db0=$main::DB{sys}->Query("
				SELECT *
				FROM TOM.a150_cache
				WHERE
						domain='$tom::Hm'
						AND domain_sub='$cache_domain'
						AND engine='pub'
						AND Cid_md5='$mdl_C{-md5}'
				ORDER BY ID DESC
				LIMIT 1
			");
			my %db0_line=$db0->fetchhash();
			if (%db0_line)
			{
				$cache = \%db0_line;
				
				if ($TOM::CACHE_memcached)
				{
					if ($Ext::Cache_memcache::cache->set(
							'namespace' => "mcache",
							'key' => $tom::Hm.":".$cache_domain.":pub:".$mdl_C{-md5},
							'value' => $cache
						))
					{
						main::_log("memcached: saved record from db");
					}
					else
					{
						main::_log("memcached: can't save record from db");
					}
				}
			}
		}
		# AND time_to>=$main::time_current
		#
		# mal som tu este tuto podmienku, ale v podstate sposobila to,
		# ze bola vyselektovana len aktualna cache, co mi nevyhovuje,
		# pretoze chcem robotom dodavat neaktualnu cache aby som setril
		# vykonom. pri browsery je taka cache vyhodnotena ako neplatna, pri
		# robotovi je akakolvek vyselektovana platna
		#
		# vykonovy rozdiel sa da zmerat takto
		# SELECT reqtype, AVG(load_proc), AVG(load_req) FROM `a110_weblog_rqs` GROUP BY reqtype
		#
		if ($cache)
		{
			$mdl_C{N_IDcache}=$cache->{ID};
			$mdl_C{-cache_from}=$cache->{time_from};
			$mdl_C{-cache_duration}=$cache->{time_duration};
			$file_data=$cache->{body};

			$return_code=$cache->{return_code};
			$return_code=1 if $return_code<1; # osetrenie pre stare caches
		}
		else
		{
			# TUTO BOL INSERT, ale vazne neviem naco :-O
		}
		
		if (($main::IAdm)&&($main::FORM{'_rc'}))
		{
			#delete $main::FORM{'_rc'};
		}
		
		# VYPOCITAM STARIE CACHE
		$mdl_C{-cache_old}=$tom::time_current-$mdl_C{-cache_from};
		
		# nevlozil uz nahodou data o tejto cache druhy proces?
		if (not exists $CACHE{$mdl_C{T_CACHE}}){GetCACHE_CONF();}
		
		
		
		
		# nie nevlozil, ide sa na tooooo! :))
		if (not exists $CACHE{$mdl_C{T_CACHE}})
		{
			$mdl_C{-cache_time}=$TOM::CACHE_time unless $mdl_C{-cache_time};
			$CACHE{$mdl_C{T_CACHE}}{-cache_time}=$mdl_C{-cache_time};
			
			# TERAZ SPRAVIM INSERT DO DATABAZY   
			main::_log("sqlcache: insert config $mdl_C{T_CACHE} s -cache_time $mdl_C{-cache_time}",0,"pub.cache");
			
			$main::DB{sys}->Query("
				INSERT INTO TOM.a150_config
				(	domain,
					domain_sub,
					engine,
					Capp,
					Cmodule,
					Cid,
					time_insert,
					time_use,
					time_duration,
					about
				)
				VALUES
				(
					'$tom::Hm',
					'$cache_domain',
					'pub',
					'$mdl_C{-category}',
					'$mdl_C{-name}',
					'$mdl_C{-cache_id}',
					'$main::time_current',
					'$main::time_use',
					'$mdl_C{-cache_time}',
					'RQS! - from TID:$main::FORM{TID} on $tom::time_current'
				)
			");
		}
		
		
		# AK SOM STLACIL RECACHE TAK SKRATIM DURATION
		if ($main::FORM{'_rc'})
		{
			main::_log("skracujem duration cache (request na recache)");
			$mdl_C{'-cache_duration'}=$mdl_C{'-cache_old'};
		}
		
		
		
		main::_log("cache info md5:$mdl_C{-md5} old:$mdl_C{-cache_old} duration:$mdl_C{-cache_duration} from:$mdl_C{-cache_from} to:$mdl_C{-cache_to}");
		
		if(
			(
				# AK JE STARIE CACHE MENSIE AKO VYZADOVANE STARIE
				#($mdl_C{-cache_old}<$CACHE{$mdl_C{T_CACHE}}{-cache_time})
				($mdl_C{-cache_old} < $mdl_C{-cache_duration})
				# ALEBO
				||
				(
					# tento browser ma zakazane recachovanie
					# pokial cache existuje v databaze
					# TO V PREKLADE DO SLOVENCINY ZNAMENA ZE ROBOT
					# AK NAJDE NAJAKY STARY CACHE, NEZAUJIMA HO CI JE AKTUALNY,
					# STACI MU ZE CACHE PROSTE MA A TAK HO POUZIJE
					($TOM::Net::HTTP::UserAgent::table[$main::UserAgent]{recache_disable})
					&&($mdl_C{-cache_from})
				)
			)
			# A
			&&
			(
				# NIESOM V IADM MODE A MAM SPUSTENE VYPNUTIE CACHE
			not(
					($main::IAdm)
					&& ($main::FORM{_rc})
				)
			)
		)
		# TAK TUTO CACHE POUZIJEM
		{
			main::_log("using cache domain:$cache_domain from:$mdl_C{-cache_from} old:$mdl_C{-cache_old} ".
				"max:$CACHE{$mdl_C{T_CACHE}}{-cache_time} ".
				"remain:".($CACHE{$mdl_C{T_CACHE}}{-cache_time}-$mdl_C{-cache_old}));
				
			# NATIAHNEM HTML KOD :))
			
			# TU NEPOTREBUJEM NACITAVANIE Z OSTATNYCH ZDROJOV, LEBO SOM TO UZ NACITAL
			
			# zvysujem counter vyuzitia tejto cache
			Tomahawk::debug::cache_conf_opt_plus();
			
=head1
			if (not utf8::is_utf8($file_data))
			{
				$main::page_save=1; # tuto stranku si radsej ulozim
				main::_log("cache_data '$mdl_C{T_CACHE}' nieje v UTF-8!",1);
				#utf8::decode($file_data);
			}
=cut
			
			$main::H->r_("<!TMP-".$mdl_C{-TMP}."!>",$file_data);
			
			
			
			#my $time_load_req=(((Time::HiRes::gettimeofday)[0]+((Time::HiRes::gettimeofday)[1]/1000000))-$time_start_req);
			#my $time_load_proc=((times)[0]-$time_start_proc);
			#main::_log("end of cached module req:".$time_load_req." proc:".$time_load_proc." ret:".$return_code);
			
			#$time_module->end();$time_module->duration();
			#main::_log("end of cached module req:".($time_module->{time}{req}{duration})." proc:".($time_module->{time}{proc}{duration})." ret:".$return_code);
			$t->close();
			return $return_code;
		}
		else # CACHE JE STARY, SPRACUJEM DATA O CACHE
		{
			if ($mdl_C{-cache_old} eq $tom::time_current)
			{
				# tato cache prebehla cez destroy()
				#main::_log("cache $mdl_C{N_CACHE} neexistuje, preslo destroy()",1,"pub.cache");
			}
			else
			{
				# cache je stary, spracujem debug data o cache
				# kedze je cache system len v databaze, tak toto robit nemusim
				# fcia je prazdna
				Tomahawk::debug::cache_conf_opt();
			}
		}
	} #KONIEC OBLUSHY CACHE
	
	#NECACHUJEM, LEBO VYPRSALA CACHE
	
	
	
	#ide o dget? :)
#	if ($mdl_C{-type} eq "dget")
#	{
#		main::_log("downloading");
#		return 1;
#	}
	
	
	

	
	# KDE JE MODUL?
	if (($mdl_C{-global}==2)&&($tom::Pm))
	{
		$mdl_C{P_MODULE}=$tom::Pm."/_mdl/".$mdl_C{-category}."-".$mdl_C{-name}.".".$mdl_C{-version}.".mdl";
	}
	elsif ($mdl_C{-global})
	{
		$mdl_C{-global}=1;
		$mdl_C{P_MODULE}=$TOM::P."/_mdl/".$mdl_C{-category}."/".$mdl_C{-category}."-".$mdl_C{-name}.".".$mdl_C{-version}.".mdl";
	}
	else
	{
		$mdl_C{P_MODULE}=$tom::P."/_mdl/".$mdl_C{-category}."-".$mdl_C{-name}.".".$mdl_C{-version}.".mdl";
	}
	
	
	
	
	# AK MODUL NEEXISTUJE
	if (not -e $mdl_C{P_MODULE})
	{
		main::_log("not exist",1);
		TOM::Error::module(
			-TMP	=>	$mdl_C{-TMP},
			-MODULE	=>	"[MDL::".$mdl_C{-category}."-".$mdl_C{-name}."]",
			-ERROR	=>	"module does not exist!"#.$!
		);
		return undef;
	}
	
	
	
	main::_log("executing module ".$mdl_C{-name}."/".$mdl_C{-version}."/".$mdl_C{-global});
	main::_log("secure eval");
	
	# zapinam defaultne debug, ktory mozem v module vypnut
	$Tomahawk::module::debug_disable=0;
	$Tomahawk::module::authors=""; # vyprazdnim zoznam authorov
	
	# V EVALKU OSETRIM CHYBU RYCHLOSTI A SPATNEHO MODULU
	eval
	{
		# registering alarm
		my $action_die = POSIX::SigAction->new(
			sub {die "Timed out $mdl_C{-ALRM} sec.\n"},
			$TOM::Engine::pub::SIG::sigset,
			&POSIX::SA_NODEFER);
		POSIX::sigaction(&POSIX::SIGALRM, $action_die);
		Time::HiRes::alarm($mdl_C{-ALRM});
		
		if (not do $mdl_C{P_MODULE}){$tom::ERR="$@ $!";die "pre-compilation error: $@ $!\n";}#- $! $@\n";
		
		local %Tomahawk::module::XSGN;
		local %Tomahawk::module::XLNG;
		
		my $t_execute=track TOM::Debug("Tomahawk::module::execute()");
		$return_code=Tomahawk::module::execute(%mdl_env);
		$t_execute->close();
		
		if ($return_code)
		{
			$Tomahawk::module::XSGN{TMP}=~s|<#.*?#>||g;
			$Tomahawk::module::XSGN{TMP}=~s|<%.*?%>||g;
			
			# preco som toto robil?
			# rusim pretoze chcem ten isty vystup ako mam vstup
			#1 while ($Tomahawk::module::XSGN{TMP}=~s|\n\n|\n|g);
			if ($Tomahawk::module::XSGN{TMP})
			{
				if (not utf8::is_utf8($Tomahawk::module::XSGN{TMP}))
				{
					$main::page_save=1; # tuto stranku si radsej ulozim
					main::_log("XSGN{TMP} nieje v UTF-8!",1);
					main::_log("[MDL::".$mdl_C{-category}."-".$mdl_C{-name}."/".$mdl_C{-version}."/".$mdl_C{-global}." XSGN{TMP} nieje v UTF-8",1,"pub.err");
					utf8::decode($Tomahawk::module::XSGN{TMP});
				}
			}
			
			#main::_log("length of XSGN{TMP} is ".length($Tomahawk::module::XSGN{TMP}));
			
			if (($Tomahawk::module::XSGN{TMP})
				&&(not $main::H->r_("<!TMP-".$mdl_C{-TMP}."!>",$Tomahawk::module::XSGN{TMP})))
			{
				#TOM::Debug::pub::output_save();
				Time::HiRes::alarm(0);
				#$main::time_modules->end();
				#$main::time_modules->duration_plus();
				
				TOM::Error::module
				(
					-TMP	=>	$mdl_C{-TMP},
					-MODULE	=>	"[MDL::".$mdl_C{-category}."-".$mdl_C{-name}."]",
					-ERROR	=>	"Unknown TMP-".$mdl_C{-TMP},
				);return undef;
				
			};
		
			# IDEME NACACHOVAT - VERY VERY VERY SPEEEEEDY! BUAAAh!:))
			# BUD DO FILESU ALEBO DO DB :))
			# if ((defined $mdl_C{-cache_id})&&($TOM::CACHE))
			if ((exists $mdl_C{-cache_id})&&($TOM::CACHE))
			{
				my $ID_config=$CACHE{$mdl_C{T_CACHE}}{'-ID_config'};
				my $memcached;
				
				if ($TOM::CACHE_memcached)
				{
					# trying to save new cache to memcached
					my $cache={
						'ID_config' => $ID_config,
						'domain' => $tom::Hm,
						'domain_sub' => $cache_domain,
						'engine' => "pub",
						'Capp' => $mdl_C{'-category'},
						'Cmodule' => $mdl_C{'-name'},
						'Cid' => $mdl_C{'-cache_id'},
						'Cid_md5' => $mdl_C{'-md5'},
						'C_id_sub' => $mdl_C{'-cache_id_sub'},
						'C_xsgn' => $mdl_env{'dsgn'},
						'C_xlng' => $mdl_env{'lng'},
						'body' => $Tomahawk::module::XSGN{'TMP'},
						'time_from' => $main::time_current,
						'time_duration' => $CACHE{$mdl_C{'T_CACHE'}}{'-cache_time'},
						'time_to' => ($main::time_current+$CACHE{$mdl_C{'T_CACHE'}}{'-cache_time'}),
						'return_code' => $return_code
					};
					
					if ($Ext::Cache_memcache::cache->set(
							'namespace' => "mcache",
							'key' => $tom::Hm.":".$cache_domain.":pub:".$mdl_C{-md5},
							'value' => $cache
						)
					)
					{
						main::_log("memcached: saved record");
						$memcached=1;
					}
					else {main::_log("memcached: can't save record");}
				}
				
				if (!$memcached)
				{
					main::_log("sqlcache: saving '$tom::Hm', '$cache_domain', 'pub', '$mdl_C{-category}', '$mdl_C{-name}', '$mdl_C{-cache_id}', '$mdl_C{-md5}', '$mdl_C{-cache_id_sub}', '$mdl_env{dsgn}', '$mdl_env{lng}', '$main::time_current', '".$CACHE{$mdl_C{T_CACHE}}{-cache_time}."'");  #
					
					$Tomahawk::module::XSGN{TMP}=~s|'|\\'|g;
					
					my $sql="
					REPLACE INTO $TOM::DB_name_TOM.a150_cache
					(
						ID_config,
						domain,
						domain_sub,
						engine,
						Capp,
						Cmodule,
						Cid,
						Cid_md5,
						C_id_sub,
						C_xsgn,
						C_xlng,
						body,
						time_from,
						time_duration,
						time_to,
						return_code
						)
					VALUES
					(
						'$ID_config',
						'$tom::Hm',
						'$cache_domain',
						'pub',
						'$mdl_C{-category}',
						'$mdl_C{-name}',
						'$mdl_C{-cache_id}',
						'$mdl_C{-md5}',
						'$mdl_C{-cache_id_sub}',
						'$mdl_env{dsgn}',
						'$mdl_env{lng}',
						'".$Tomahawk::module::XSGN{TMP}."',
						'$main::time_current',
						'$CACHE{$mdl_C{T_CACHE}}{-cache_time}',
						'".($main::time_current+$CACHE{$mdl_C{T_CACHE}}{-cache_time})."',
						'$return_code'
						)
					";
					#main::_log("s: $sql");
					if (my $null=$main::DB{sys}->Query($sql))
					{
						main::_log("ok");
					}
					else
					{
						main::_log("bad");
					}
					
					$main::DB{sys}->Query("
						UPDATE TOM.a150_config
						SET		time_use='$main::time_current'
						WHERE	domain='$CACHE{$mdl_C{T_CACHE}}{-domain}'
								AND domain_sub='$CACHE{$mdl_C{T_CACHE}}{-domain_sub}'
								AND engine='pub'
								AND Capp='$mdl_C{-category}'
								AND Cmodule='$mdl_C{-name}'
								AND Cid='$mdl_C{-cache_id}'
						LIMIT 1
					");
				}
			}
			
			undef &Tomahawk::module::execute;
			
		}
		else # chyba o ktorej upozorni samotny program vratenim undef :)
		{
			TOM::Error::module(
				-TMP	=>	$mdl_C{-TMP},
				-MODULE	=>	"[MDL::".$mdl_C{-category}."-".$mdl_C{-name}."]",
				-ERROR	=>	$tom::ERR,
				-PLUS	=>	$tom::ERR_plus,
			)
		};
		Time::HiRes::alarm(0);
	};
	#$main::time_modules->end();
	#$main::time_modules->duration_plus();
	Time::HiRes::alarm(0);
	
	main::_log("end of secure eval");
	
	if ($@)
	{
		TOM::Error::module
		(
			-TMP	=>	$mdl_C{-TMP},
			-MODULE	=>	"[MDL::".$mdl_C{-category}."-".$mdl_C{-name}."]",
			-ERROR	=>	$@,
		);# unless $mdl_C{-noerror_run};
	};
	
	
	$t->close();
	#main::_log("end of module req:".($t->{'time'}{req}{duration})." proc:".($t->{'time'}{proc}{duration})." ret:".$return_code);
	
	# spravim debug tohto modulu ak bol fyzicky vykonany
	# a v module som nenastavil ze nan nemam robit debug
	main::_log("debug_disable is $Tomahawk::module::debug_disable");
	Tomahawk::debug::module_load(
		-type => $mdl_C{-type},
		-category => $mdl_C{-category},
		-name => $mdl_C{-name},
 		-load_req => $t->{'time'}{req}{duration},
		-load_proc => $t->{'time'}{proc}{duration}
	) unless $Tomahawk::module::debug_disable==0;
	
	#$t->close();
	return $return_code;
}














# ADD MODULE
###############
sub supermodule
{
 local %smdl_env=@_;
 local $app=$smdl_env{-category};
 $Tomahawk::module::authors=""; # vyprazdnim zoznam authorov

 #my $time_start=(times)[0];
 #my $time_start=(Time::HiRes::gettimeofday)[0]+((Time::HiRes::gettimeofday)[1]/1000000);
 # SPRACOVANIE PREMMENNYCH
 $smdl_env{-category}=0 unless $smdl_env{-category};
 $smdl_env{-version}="0" unless $smdl_env{-version}; # NEBUDEM SE S NIKYM SRAAAT BEZ DUUVODU!...
 $smdl_env{-xsgn}=$tom::dsgn unless $smdl_env{-xsgn}; # SAJRAJT
 $smdl_env{-xlng}=$tom::lng unless $smdl_env{-xlng};

 main::_log("adding supermodule ".$smdl_env{-category}."-".$smdl_env{-name}."/".$smdl_env{-version}."/".$smdl_env{-global});
 foreach (sort keys %smdl_env)
 {
  my $var=$smdl_env{$_};$var=~s|[\n\r]||g;
  if (length($var)>50){$var=substr($var,0,50)."..."}
  main::_log("input (".$_.")=".$var);
 }

 my $file_data;

 # definujem rec pre modul aby ju mohol prijat ako $env{lng}
 # AK NIEJE ZADANA NATVRDO CEZ module (-xlng), tak vezmem language
 # tejto session. predam do $env{lng}
 #if (!$smdl_env{lng}){$smdl_env{lng}=$tom::lng;$smdl_env{lng}=$smdl_env{-xlng} if $smdl_env{-xlng};}
 $smdl_env{lng}=$smdl_env{-xlng};

 # definujem design pre modul aby ju mohol prijat ako $env{dsgn}
 # AK NIEJE ZADANA NATVRDO CEZ module (-xsgn), tak vezmem design
 # tejto session. predam do $env{lng}
 #if (!$smdl_env{dsgn}){$smdl_env{dsgn}=$tom::dsgn;$smdl_env{dsgn}=$smdl_env{-xsgn} if $smdl_env{-xsgn};}
 $smdl_env{dsgn}=$smdl_env{-xsgn};

 # AK JE DEFINOVANA POZIADAVKA NA CACHOVANIE A JE DEFINOVANA
 # POZIADAVKA NA NA VOBEC CACHOVANIE, TAK SA TOMU VENUJEM

 main::_log("executing");

 # KDE JE MODUL?
# $smdl_env{P_MODULE}="/_mdl/".$smdl_env{-category}."-".$smdl_env{-name}.".".$smdl_env{-version}.".smdl";
# if ($smdl_env{-global}){$smdl_env{P_MODULE}=$TOM::P.$smdl_env{P_MODULE}}
# else{$smdl_env{P_MODULE}=$tom::P.$smdl_env{P_MODULE}}

 if (($smdl_env{-global}==2)&&($tom::Pm))
 {
  $smdl_env{P_MODULE}=
  $tom::Pm."/_mdl/".$smdl_env{-category}."-".$smdl_env{-name}.".".$smdl_env{-version}.".smdl";
 }
 elsif ($smdl_env{-global})
 {
  $smdl_env{-global}=1;
  $smdl_env{P_MODULE}=
  $TOM::P."/_mdl/".$smdl_env{-category}."/".$smdl_env{-category}."-".$smdl_env{-name}.".".$smdl_env{-version}.".smdl";
 }
 else
 {
  $smdl_env{P_MODULE}=
  $tom::P."/_mdl/".$smdl_env{-category}."-".$smdl_env{-name}.".".$smdl_env{-version}.".smdl";
 }

 # AK MODUL NEEXISTUJE
 if (not -e $smdl_env{P_MODULE})
 {TOM::Error::module(
	-MODULE	=>	"[SMDL::".$smdl_env{-category}."-".$smdl_env{-name}."]",
	-ERROR	=>	$!);return undef;}


 # V EVALKU OSETRIM CHYBU RYCHLOSTI A SPATNEHO MODULU
 eval
 {
	local $SIG{ALRM} = sub {die "Timeout ".$TOM::ALRM_smdl." sec.\n"};
	alarm $TOM::ALRM_smdl;
	do $smdl_env{P_MODULE};
	if (Tomahawk::module::execute(%smdl_env))
	{
	}
	else
	{
		TOM::Error::module(
		-MODULE	=>	"[SMDL::".$smdl_env{-category}."-".$smdl_env{-name}."]",
		-ERROR	=>	$tom::ERR);
		alarm 0;
		return undef;
	}
	alarm 0;
 };
 #alarm 0;
 
 
#=head1
 if ($@){TOM::Error::module( # toto je syntakticka chyba zistitelna az pri behu
  	-TMP	=>	$mdl_C{-TMP},
	-MODULE	=>	"[SMDL::".$smdl_env{-category}."-".$smdl_env{-name}."]",
	-ERROR	=>	$@,
	-PLUS	=>	$@." ".$!." ".$tom::ERR
  	)};
#=cut
=head1
 if ($@){Tomahawk::error::module(
	-MODULE	=>	$smdl_env{-category}."-".$smdl_env{-name},
	-ERROR	=>	$@);return undef;}
=cut

# my $time_end=(((Time::HiRes::gettimeofday)[0]+((Time::HiRes::gettimeofday)[1]/1000000))-$time_start);
# Tomahawk::debug::module_load(
#	-type		=>	$mdl_C{-type},
#	-category		=>	$mdl_C{-category},
#	-name		=>	$mdl_C{-name},
#	-load_req		=>	$time_load_req,
#	-load_proc		=>	$time_load_proc
# ) if ($TOM::DEBUG_cache && exists $Tomahawk::CACHE{$Tomahawk::mdl_C{T_CACHE}});


 #my $time_end=(((Time::HiRes::gettimeofday)[0]+((Time::HiRes::gettimeofday)[1]/1000000))-$time_start);
 #Tomahawk::debug::module_load(
#	-type		=>	$smdl_env{-type},
#	-category	=>	$smdl_env{-category},
#	-name		=>	$smdl_env{-name},
#	-load		=>	$time_end
# );
}








# ADD MODULE
###############
sub designmodule
{
	my $t=track TOM::Debug(__PACKAGE__."::designmodule()");
	
	local %mdl_env=@_;
	$Tomahawk::module::authors=""; # vyprazdnim zoznam authorov
	# SPRACOVANIE PREMMENNYCH
	$mdl_env{-category}=0 unless $mdl_env{-category};
	$mdl_env{-xsgn}=$tom::dsgn unless $mdl_env{-xsgn}; # SAJRAJT
	$mdl_env{-xlng}=$tom::lng unless $mdl_env{-xlng};
	
	#main::_log("adding designmodule ".$mdl_env{-category}."-".$mdl_env{-name}."/".$mdl_env{-global});
	
	my $file_data;
	
	# definujem rec pre modul aby ju mohol prijat ako $env{lng}
	# AK NIEJE ZADANA NATVRDO CEZ module (-xlng), tak vezmem language
	# tejto session. predam do $env{lng}
	#if (!$mdl_env{lng}){$mdl_env{lng}=$tom::lng;$mdl_env{lng}=$mdl_env{-xlng} if $mdl_env{-xlng};}
	
	# definujem design pre modul aby ju mohol prijat ako $env{dsgn}
	# AK NIEJE ZADANA NATVRDO CEZ module (-xsgn), tak vezmem design
	# tejto session. predam do $env{lng}
	#if (!$mdl_env{dsgn}){$mdl_env{dsgn}=$tom::dsgn;$mdl_env{dsgn}=$mdl_env{-xsgn} if $mdl_env{-xsgn};}
	
	# AK JE DEFINOVANA POZIADAVKA NA CACHOVANIE A JE DEFINOVANA
	# POZIADAVKA NA NA VOBEC CACHOVANIE, TAK SA TOMU VENUJEM
	
	# KDE JE MODUL?
	# $mdl_env{P_MODULE}="/_mdl/".$mdl_env{-category}."-".$mdl_env{-name}.".".$mdl_env{-xsgn}.".".$mdl_env{-xlng}.".dmdl";
	# if ($mdl_env{-global}){$mdl_env{P_MODULE}=$TOM::P.$mdl_env{P_MODULE}}
	# else{$mdl_env{P_MODULE}=$tom::P.$mdl_env{P_MODULE}}
	
	$mdl_env{'MODULE'}=$mdl_env{-category}."-".$mdl_env{-name}.".".$mdl_env{-xsgn}.".".$mdl_env{-xlng};
	
	if (($mdl_env{-global}==2)&&($tom::Pm))
	{
		$mdl_env{P_MODULE}=
			$tom::Pm."/_mdl/".
			$mdl_env{-category}."-".$mdl_env{-name}.".".$mdl_env{-xsgn}.".".$mdl_env{-xlng}.".dmdl";
	}
	elsif ($mdl_env{-global})
	{
		$mdl_env{-global}=1;
		$mdl_env{P_MODULE}=
			$TOM::P."/_mdl/".$mdl_env{-category}."/".
			$mdl_env{-category}."-".$mdl_env{-name}.".".$mdl_env{-xsgn}.".".$mdl_env{-xlng}.".dmdl";
	}
	else
	{
		$mdl_env{P_MODULE}=
			$tom::P."/_mdl/".
			$mdl_env{-category}."-".$mdl_env{-name}.".".$mdl_env{-xsgn}.".".$mdl_env{-xlng}.".dmdl";
	}
	
	main::_log("file '$mdl_env{P_MODULE}'");
	
	# AK MODUL NEEXISTUJE
	if (not -e $mdl_env{P_MODULE})
	{
		TOM::Error::module(
		-TMP	=>	$mdl_env{-TMP},
		-MODULE	=>	"[DMDL::".$mdl_env{'MODULE'}."]",
		-ERROR	=>	$!
				);
		$t->close();
		return undef;
	}
	
	open (HND,"<".$mdl_env{P_MODULE}) || do
	{
		$tom::ERR="Can't open design file ".$mdl_env{P_MODULE};
		TOM::Error::module(
			-TMP	=>	$mdl_env{-TMP},
			-MODULE	=>	"[DMDL::".$mdl_env{'MODULE'}."]",
			-ERROR	=>	"Cannot open design module ".$!
		);
		$t->close();
		return undef;
	};
	
	my $file_data;my $file_line;
	while ($file_line=<HND>){$file_data.=$file_line;}
	
	main::_log("readed '".(length($file_data))."' bytes");
	
	if ($mdl_env{-convertvars})
	{
		main::_log("'-convertvars' enabled, converting <\$vars>");
		TOM::Utils::vars::replace($file_data);
	}
	
	if (not $main::H->r_("<!TMP-".$mdl_env{-TMP}."!>",$file_data))
	{
		TOM::Error::module(
			-TMP	=>	$mdl_env{-TMP},
			-MODULE	=>	"[DMDL::".$mdl_env{'MODULE'}."]",
			-ERROR	=>	"Unknown TMP ".$mdl_env{-TMP}
		);
		$t->close();
		return undef;
	};
	
	$t->close();
}














sub GetXSGN
{
 my %env=@_;
	# HLADAME DESIGN
	main::_log("loading XSGN -category='$mdl_C{-category}' -name='$mdl_C{-name}' -version='$mdl_C{-version}' -xsgn='$mdl_C{-xsgn}'");
	$mdl_C{P_XSGN}=$mdl_C{-category}."-".$mdl_C{-name}.".".$mdl_C{-version}.".".$mdl_C{-xsgn}.".xsgn";
	main::_log("P_XSGN='$mdl_C{P_XSGN}'");
 
	if (!$mdl_C{-name})
	{
		main::_log("sorry, I am not in module, can't import design",1);
		$tom::ERR="Can't import design, I am not in module";
		return undef;
	}
	

=head1
 moznosti
 MDL MSTR XSGN =
 G   0    0    0
 -G   0    1    1+
 G   0    2    0
 G   1    0    0
 -G   1    1    1+
 G   1    2    2+
 ---
 M   0    0    0
 M   0    1    1
 M   0    2    0
 M   1    0    0
 M   1    1    1
 M   1    2    0
 ---
 L   0    0    0
 L   0    1    0
 L   0    2    0
 L   1    0    0
 L   1    1    0
 L   1    2    0
=cut

 if (!$mdl_C{-global}) # ak je modul lokalny, tak moze byt design len lokalny
 {
  $mdl_C{-xsgn_global}=0;
  $mdl_C{P_XSGN}=$tom::P."/_mdl/".$mdl_C{P_XSGN};
  #Tomahawk::debug::log(9,"1 - ak je modul lokalny, tak moze byt design len lokalny");
 }
 # ak je modul global, a chcem design global, tak ho dostanem :))
 elsif ($mdl_C{-xsgn_global}==1)
 {
  $mdl_C{-xsgn_global}=1;
  $mdl_C{P_XSGN}=$TOM::P."/_mdl/".$mdl_C{-category}."/".$mdl_C{P_XSGN};
  #Tomahawk::debug::log(9,"2 - ak je modul global, a chcem design global, tak ho dostanem :))");
 }
 # chcem mastera, mam mastera a modul je global, alebo master
 elsif (($tom::Pm)&&($mdl_C{-xsgn_global}==2))
 {
  $mdl_C{-xsgn_global}=2;
  $mdl_C{P_XSGN}=$tom::Pm."/_mdl/".$mdl_C{P_XSGN};
  #Tomahawk::debug::log(4,"executing");
  #Tomahawk::debug::log(9,"3 - chcem mastera, mam mastera a modul je global, alebo master");
 }
 else
 {
  $mdl_C{-xsgn_global}=0;
  $mdl_C{P_XSGN}=$tom::P."/_mdl/".$mdl_C{P_XSGN};
  #Tomahawk::debug::log(9,"4 - posledna podmienka, nastavujem local");
 }

	main::_log("P_XSGN='$mdl_C{P_XSGN}'");
	
=head1
 if (!$mdl_C{-global}) # ak je modul lokalny, tak samozrejme ze je aj design lokalny
 {		       # nemoze byt ani master, ani global
  $mdl_C{P_XSGN}=$tom::P."/_mdl/".$mdl_C{P_XSGN};
 }
 elsif (($mdl_C{-xsgn_global}==2)&&($tom::Pm)&&($mdl_C{-global})) # ak mam cestu k masterovi a chcem mastera
 {
  $mdl_C{P_XSGN}=$tom::Pm."/_mdl/".$mdl_C{P_XSGN};
 }
 elsif ($mdl_C{-xsgn_global}) # design je globalny, modul je globalny
 {
  $mdl_C{P_XSGN}=$TOM::P."/_mdl/".$mdl_C{-category}."/".$mdl_C{P_XSGN};
 }
 else # design je lokalny, modul je globalny
 {
  $mdl_C{P_XSGN}=$tom::P."/_mdl/".$mdl_C{P_XSGN};
 }
=cut

 # OTVORIM DESIGN
 open (HND,"<".$mdl_C{P_XSGN}) || do
 {
 	main::_log("can't open file '$mdl_C{P_XSGN}' '$!'",1);
  $tom::ERR="Cannot import design \"".$mdl_C{-xsgn}."\" (".$mdl_C{-xsgn_global}."/".$mdl_C{-global}."/".$mdl_C{-category}."-".$mdl_C{-name}.".".$mdl_C{-version}.".".$mdl_C{-xsgn}.".xsgn".") ($mdl_C{P_XSGN}) - ".$!;
  return undef;
 };
 
 
 my $file_data;my $file_line;
 while ($file_line=<HND>){$file_data.=$file_line;}
 ($file_data)=$file_data=~/<XML_DESIGN_DEFINITION.*?>(.*)<\/XML_DESIGN_DEFINITION>/s;

 # KONVERZIA PREMMENNYCH
# if ($env{-convertvars})
# {while ($file_data=~s/<\$(.*?)>/<!TMP!>/s) # ZRUSIT S?
# {my $var=$1;my $value;eval "\$value=\$$var;"; # TAK TOTO NEVIEM CI JE BEZPECNE
#  $file_data=~s|<!TMP!>|$value|;
# }}
 TOM::Utils::vars::replace($file_data) if $env{-convertvars};

 #while ($file_data=~s|<DEFINITION id="(.*?)">[\n\r ]*(.*?)[\n\r ]*</DEFINITION>||s)
 while ($file_data=~s|<DEFINITION id="(.*?)">[\n\r]?(.*?)[\n\r]?</DEFINITION>||s)
 #while ($file_data=~s|<DEFINITION id="(.*?)">(.*?)</DEFINITION>||s)
 {
  my $var=$1;
  $Tomahawk::module::XSGN{$var}=$2;
#  $Tomahawk::module::XSGN{$var}=~s|^\W||g; # zmaze vsetky neviditelne znaky na zaciatku
  #$Tomahawk::module::XSGN{$var}=~s|[\n\r]\W$||g; # zmaze vsetky neviditelne znaky na konci
 }
 return 1;
}




sub GetXLNG
{
	my %env=@_;
 # HLADAME LANGUAGE
 $mdl_C{P_XLNG}=$mdl_C{-category}."-".$mdl_C{-name}.".".$mdl_C{-version};
 $mdl_C{P_XLNG}.=".".$mdl_C{-xsgn} if $mdl_C{-xlng_xsgn};
 $mdl_C{P_XLNG}.=".xlng";


 if (!$mdl_C{-global}) # ak je modul lokalny, tak moze byt design len lokalny
 {
  $mdl_C{-xlng_global}=0;
  $mdl_C{P_XLNG}=$tom::P."/_mdl/".$mdl_C{P_XLNG};
 }
 # ak je modul global, a chcem design global, tak ho dostanem :))
 elsif ($mdl_C{-xlng_global}==1)
 {
  $mdl_C{P_XLNG}=$TOM::P."/_mdl/".$mdl_C{-category}."/".$mdl_C{P_XLNG};
 }
 # chcem mastera, mam mastera a modul je global, alebo master
 elsif (($tom::Pm)&&($mdl_C{-xlng_global}==2))
 {
  $mdl_C{P_XLNG}=$tom::Pm."/_mdl/".$mdl_C{P_XLNG};
 }
 else
 {
  $mdl_C{-xlng_global}=0;
  $mdl_C{P_XLNG}=$tom::P."/_mdl/".$mdl_C{P_XLNG};
 }


=head1
 if (!$mdl_C{-global}) # ak je modul lokalny, tak samozrejme ze je aj jazyk lokalny
 {		       # nemoze byt ani master, ani global
  $mdl_C{P_XLNG}=$tom::P."/_mdl/".$mdl_C{P_XLNG};
 }
 elsif (($mdl_C{-xlng_global}==2)&&($tom::Pm)&&($mdl_C{-global})) # ak mam cestu k masterovi a chcem mastera
 {
  $mdl_C{P_XLNG}=$tom::Pm."/_mdl/".$mdl_C{P_XLNG};
 }
 elsif ($mdl_C{-xlng_global})
 {
  $mdl_C{P_XLNG}=$TOM::P."/_mdl/".$mdl_C{-category}."/".$mdl_C{P_XLNG};
 }# design je globalny, modul je globalny
 else
 {
  $mdl_C{P_XLNG}=$tom::P."/_mdl/".$mdl_C{P_XLNG};
 }# design je lokalny, modul je globalny
=cut

 # OTVORIM DESIGN
 open (HND,"<".$mdl_C{P_XLNG}) || do
 {$tom::ERR="Cannot open language file ".$mdl_C{-xlng}."/".$mdl_C{-xlng_global}."-".$mdl_C{P_XLNG};return undef;};
 my $file_data;my $file_line;
 while ($file_line=<HND>){$file_data.=$file_line;}
 ($file_line,$file_data)=$file_data=~/<XML_LANGUAGE_DEFINITION lngs="(.*?)">(.*)<\/XML_LANGUAGE_DEFINITION>/s;
 $file_line=",".$file_line.",";

# return undef;

 # hladam rec :)
 if (not $file_line=~/,$mdl_env{lng},/)
 {
  if ($TOM::LNG_search)
  {
   if ($file_line=~/,$tom::lng,/){$mdl_env{lng}=$tom::lng;}#print "ok:".$mdl_env{lng}."\n";}
   elsif ($file_line=~/,$tom::LNG,/){$mdl_env{lng}=$tom::LNG;}#print "ok:".$mdl_env{lng}."\n";}
   elsif ($file_line=~/,$TOM::LNG,/){$mdl_env{lng}=$TOM::LNG;}#print "ok:".$mdl_env{lng}."\n";}
   else{$tom::ERR="Cannot import language code ".$mdl_env{lng}.",".$tom::lng.",".$tom::LNG.",".$TOM::LNG;return undef}
  }
  else {$tom::ERR="Cannot import language code ".$mdl_env{lng};return undef}
 }
	
	
	TOM::Utils::vars::replace($file_data) if $env{'-convertvars'};
	
	while ($file_data=~s|<VALUE lng="$mdl_env{lng}" id="(.*?)">(.*?)</VALUE>||s){$Tomahawk::module::XLNG{$1}=$2;}
	
 return $mdl_env{lng};
}




sub XLNGtoXSGN
{
 foreach my $ref0(keys %Tomahawk::module::XLNG)
 {foreach my $ref1(keys %Tomahawk::module::XSGN)
  {$Tomahawk::module::XSGN{$ref1}=~s|<%XLNG-$ref0%>|$Tomahawk::module::XLNG{$ref0}|g;}}
 return 1;
}



sub XLNGtoVARS
{
 my @ref=@_;
 for(0..@ref){foreach my $ref0(%Tomahawk::module::XLNG){$ref[$_]=~s|<%XLNG-$ref0%>|$Tomahawk::module::XLNG{$ref0}|g;}}
 return @ref;
}




# EXIT(us) :)
#############
sub shutdown
{
 my $req = FCGI::Request();
 $req->Finish();
 exit(0);
}



1;
