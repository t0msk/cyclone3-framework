#!/usr/bin/perl
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
#use Tomahawk::debug;

=head1 NAME

Tomahawk - core library

=cut

# DEFINUJEM PREMENNE V OBLASTI MODULOV
package Tomahawk::module;
use Encode;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use vars qw/%XSGN %XLNG $ERR $TPL &XSGN_load_hash/;

sub XSGN_load_hash
{
	my $XSGN=shift;
	my $refhash=shift;
	
	foreach my $key(keys %{$refhash})
	{
		$$XSGN=~s|<%$key%>|$refhash->{$key}|g;
	}
	return 1;
}

# DEFINUJEM NULOVY DEBUG
#use Tomahawk::debug;
#use open ':utf8', ':std';
#use if $] < 5.018, 'encoding','utf8';
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
use if $] < 5.018, 'encoding','utf8';
use utf8;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

sub rqs{return 1}



# DEFINUJEM NULOVY CACHE
package Tomahawk::cache;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
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
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
use Utils::vars;
use Utils::datetime;
use conv;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );
use Ext::Redis::_init;
use Ext::RabbitMQ::_init;
use Storable;
use Compress::Zlib;
use JSON;
our $json = JSON::XS->new->ascii->convert_blessed;
our $jsonc = JSON::XS->new->ascii->canonical;

#use warnings;
use vars qw/
	@ISA
	@EXPORT
	%mdl_C
	%mdl_env
	%smdl_env
	%CACHE
	%VAR
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
	tplmodule
	/;
	
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 FUNCTIONS



=cut

=head2 Getvar()



=cut

sub Getvar
{
	return undef unless $_[0];
	if (($TOM::var_cache)&&($var{$_[0]}{'time'}+$var{$_[0]}{'cachetime'}>$main::time_current)){return $var{$_[0]}{'value'}}
	main::_log("Getvar($_[0]) from database $TOM::DB{'main'}{'name'}");
	
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT value,cache
		FROM `$TOM::DB{'main'}{'name'}`._config
		WHERE type='var' AND variable='$_[0]'
		LIMIT 1
	},'quiet'=>1);
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		TOM::Database::SQL::execute(qq{
			UPDATE `$TOM::DB{'main'}{'name'}`._config
			SET reqtime='$main::time_current'
			WHERE type='var' AND variable='$_[0]' LIMIT 1},'quiet'=>1) if $TOM::DEBUG_var_cache;
		if ($TOM::var_cache)
		{
			$db0_line{'cache'}=$TOM::var_loadtime unless $db0_line{'cache'};
			$var{$_[0]}{'time'}=$tom::time_current;$var{$_[0]}{'value'}=$db0_line{'value'};
			$var{$_[0]}{'cachetime'}=$db0_line{'cache'};
		}
		return $db0_line{'value'};
	}
	else
	{
		my %sth0 = TOM::Database::SQL::execute(qq{
			SELECT *
			FROM `TOM`._config
			WHERE type='var' AND variable='$_[0]' LIMIT 1},'quiet'=>1);
		if (my %env0=$sth0{'sth'}->fetchhash())
		{
			TOM::Database::SQL::execute(qq{
				INSERT INTO `$TOM::DB{'main'}{'name'}`._config(variable,value,type,cache,about)
				VALUES('$_[0]','$env0{'value'}','var','$env0{'cache'}','RQS - $env0{'about'}')
			},'quiet'=>1);
		}
		else
		{
			TOM::Database::SQL::execute(qq{INSERT INTO `$TOM::DB{'main'}{'name'}`._config(variable,type,about) VALUES('$_[0]','var','RQS! - ')},'quiet'=>1);
		}
	}
	return undef
}


=head2 Getmdlvar



=cut

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


=head2 GetCACHE_CONF



=cut

sub GetCACHE_CONF
{
	my $t=track TOM::Debug(__PACKAGE__."::GetCACHE_CONF()");
	my $count=0;
	my %sth0 = TOM::Database::SQL::execute(qq{
		SELECT *
		FROM TOM.a150_config
		WHERE	(domain='$tom::Hm' OR domain='')
				AND (domain_sub='$tom::H' OR domain_sub='')
				AND engine='pub'
		ORDER BY domain,domain_sub
		},'quiet'=>1,'db_h'=>'sys');
	while (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		$count++;
		my $var=$db0_line{'Capp'}."-".$db0_line{'Cmodule'}."-".$db0_line{'Cid'};
		$CACHE{$var}{'-cache_time'}=$db0_line{'time_duration'};
		$CACHE{$var}{'-opt_time'}=$db0_line{'time_optimalization'};
		$CACHE{$var}{'-domain'}=$db0_line{'domain'};
		$CACHE{$var}{'-domain_sub'}=$db0_line{'domain_sub'};
		$CACHE{$var}{'-ID_config'}=$db0_line{'ID'};
	}
	main::_log("loaded ".$count." cache configs from TOM.a150_config");
	$t->close();
	return 1;
}






=head2 module



=cut

sub module
{
	local %mdl_env=@_;
	if (exists $mdl_env{'-category'}){$mdl_env{'-addon'}="a".$mdl_env{'-category'}}; # backward compatibility
	$mdl_env{'-addon_type'}='App' if $mdl_env{'-addon'}=~/^a/;
	$mdl_env{'-addon_type'}='Ext' if $mdl_env{'-addon'}=~/^e/;
	$mdl_env{'-addon_name'}=$mdl_env{'-addon'};$mdl_env{'-addon_name'}=~s|^.||;
	my $t=track TOM::Debug("module",'attrs'=>$mdl_env{'-addon'}."-".$mdl_env{'-name'},'timer'=>1,'namespace'=>'MDL');
	
	local %mdl_C;
	local $tom::ERR;
	local $tom::ERR_plus;
	
	local $TOM::DEBUG_log_file = $TOM::DEBUG_log_file;
	
	if ($mdl_env{'-log'})
	{
		$TOM::DEBUG_log_file = $mdl_env{'-log'};
	}
	
#	local $app=$mdl_env{-category};
	my $cache_domain;
	my $return_code;
	my %return_data;
	
	# SPRACOVANIE PREMENNYCH
	my $debug;
		$debug=1 if $mdl_env{'-debug'};
	
	# najpv si ocheckujem ci nechcem zistovat pritomnost TMP
	# zaroven pritomnost TMP zistim
	if ($mdl_env{'-TMP_check'})
	{
		main::_log("-TMP_check enabled") if $debug;
		if (not $main::H->{'OUT'}{'BODY'}=~/<!TMP-$mdl_env{-TMP}!>/)
		{
			main::_log("return 10, TMP '$mdl_env{-TMP}' not exists in BODY");
			$t->close();
			return 10;
		}
	}
	
	foreach (sort keys %mdl_env)
	{
		main::_log("input '$_'='$mdl_env{$_}'") if $debug;
		/^-/ && do {$mdl_C{$_}=$mdl_env{$_};delete $mdl_env{$_};}
	}
	
	$mdl_C{'-addon'}="a010" unless $mdl_C{'-addon'};
	$mdl_C{'-version'}="0" unless $mdl_C{'-version'};
	$mdl_C{'-xsgn'}=$mdl_C{'-tpl'} || $tom::dsgn unless $mdl_C{'-xsgn'};
	$mdl_C{'-tpl'}=$mdl_C{'-xsgn'} unless $mdl_C{'-tpl'};
	$mdl_C{'-xsgn_global'}=0 unless $mdl_C{'-xsgn_global'};
	$mdl_C{'-tpl_global'}=0 unless $mdl_C{'-tpl_global'};
	$mdl_C{'-xlng'}=$tom::lng unless $mdl_C{'-xlng'};
	$mdl_C{'-xlng_global'}=0 unless $mdl_C{'-xlng_global'};
	# nastavit default alarmu ak nevyzadujem zmenu alebo nieje povolena zmena
	$mdl_C{'-ALRM'}=$TOM::ALRM_mdl if ((not exists $mdl_C{'-ALRM'})||(!$TOM::ALRM_change));
	if ($mdl_C{'-cache_id'} && !$mdl_C{'-cache'})
	{
		main::_log("parameter -cache_id is obsolete, use -cache to configure instead ".
			$jsonc->encode(\%mdl_C)
		,1);
	}
	if ((exists $mdl_C{'-cache'})&&(!$mdl_C{'-cache'})){$mdl_C{'-cache'}=$TOM::CACHE_time."s"};
	if ((exists $mdl_C{'-cache_id'})&&(!$mdl_C{'-cache_id'})){$mdl_C{'-cache_id'}="default"};
	
	my $file_data;
	
	# definujem rec pre modul aby ju mohol prijat ako $env{lng}
	# AK NIEJE ZADANA NATVRDO CEZ module (-xlng), tak vezmem language
	# tejto session. predam do $env{lng}
	$mdl_env{'lng'}=$mdl_C{'-xlng'};
	
	# definujem design pre modul aby ju mohol prijat ako $env{dsgn}
	# AK NIEJE ZADANA NATVRDO CEZ module (-xsgn), tak vezmem design
	# tejto session. predam do $env{lng}
	$mdl_env{'dsgn'}=$mdl_C{'-xsgn'};
	
	# AK JE DEFINOVANA POZIADAVKA NA CACHOVANIE A JE DEFINOVANA
	# POZIADAVKA NA VOBEC CACHOVANIE, TAK SA TOMU VENUJEM
	if ((exists $mdl_C{'-cache_id'} || $mdl_C{'-cache'})&&($TOM::CACHE))
	{
		$mdl_C{'-cache'}||=$TOM::CACHE_time."s";
		$mdl_C{'-cache_id'}||="default"; # ak je vstup s cache_id ale nieje 0
		delete $mdl_C{'-cache_backend'} if ($TOM::P ne $TOM::DP && $tom::devel); # ignore background caching in multidevelopment environment
		$cache_domain=$tom::H unless $mdl_C{'-cache_master'};
		
		my $null;
		foreach (sort keys %mdl_env){$_=~/^[^_]/ && do{
			if (ref($mdl_env{$_}) eq "ARRAY" || ref($mdl_env{$_}) eq "HASH"){$null.=$_."=\"".$jsonc->encode($mdl_env{$_})."\"\n";}
			else {$null.=$_."=\"".$mdl_env{$_}."\"\n";}
		}}
		foreach (sort keys %mdl_C){
#			main::_log("c '$_'='".$mdl_C{$_}."'");
			next unless $mdl_C{$_};
			next if $_ eq "-cache_debug";
			next if $_ eq "-ALRM";
			next if $_ eq "-debug";
			next if $_ eq "-stdout";
			next if $_ eq "-stdout_dummy";
			next if $_ eq "-cache_backend";
			next if $_ eq "-cache_warmup";
			next if $_ eq "-cache_id";
			next if $_ eq "-cache_ignore";
			next if $_ eq "-cache"; # duration configuration don't affects cache
#			main::_log("c '$_'='".$mdl_C{$_}."'");
			$null.=$_."=\"".$mdl_C{$_}."\"\n";
		}
		
		$mdl_C{'-digest'}=TOM::Digest::hash($null);
		main::_log("cache digest='".$mdl_C{'-digest'}."' from string ".$null) if $debug;
		
		# NAZOV PRE TYP CACHE V KONFIGURAKU
		$mdl_C{'T_CACHE'}=$mdl_C{'-addon'}."-".$mdl_C{'-name'}."-".$mdl_C{'-cache_id'};#."-".$mdl_C{'-cache'};
		
		my $cache;
		my $cache_parallel;
		my $cache_key = 'C3|mdl|'.$TOM::P_uuid.':'.$tom::Hm.":".$cache_domain.":pub:".$mdl_C{'-digest'};
		
		if ($Redis)
		{
			# get from Redis
			$cache={
				@{$Redis->hgetall($cache_key)}
			};
			Ext::Redis::_uncompress(\$cache->{'return_data'});
			$cache->{'return_data'}=$json->decode($cache->{'return_data'})
				if $cache->{'return_data'};
			$cache->{'return_data'}={} unless $cache->{'return_data'};
			$cache_parallel=$cache->{'bhash'} || $cache->{'etime'};
		}
		else
		{
			main::_log("memcached/redis: not available (lower performance)",1);# if $debug;
		}
		
		if ($cache)
		{
			$mdl_C{'-cache_from'}=$cache->{'time_from'};
			$mdl_C{'-cache_duration'}=$cache->{'time_duration'};
			$file_data=$cache->{'body'};
			Ext::Redis::_uncompress(\$file_data);
			$return_code=$cache->{'return_code'};
			if (ref($cache->{'return_data'}) eq "HASH")
			{
				%return_data=%{$cache->{'return_data'}};
			}
			$return_code=1 if $return_code<1; # osetrenie pre stare caches
		}
		
		# VYPOCITAM STARIE CACHE
		$mdl_C{'-cache_old'}=$tom::time_current-$mdl_C{'-cache_from'};
		
		# a definujem dlzku cache priamo z typecka
		if ($mdl_C{'-cache'}=~/^(\d+)D$/i)
		{
			$mdl_C{'-cache_time'}=86400*$1;
		}
		elsif ($mdl_C{'-cache'}=~/^(\d+)H$/i)
		{
			$mdl_C{'-cache_time'}=3600*$1;
		}
		elsif ($mdl_C{'-cache'}=~/^(\d+)M$/i)
		{
			$mdl_C{'-cache_time'}=60*$1;
		}
		elsif ($mdl_C{'-cache'}=~/^(\d+)S$/i)
		{
			$mdl_C{'-cache_time'}=$1;
		}
		else
		{
			$mdl_C{'-cache_time'}=$mdl_C{'-cache'};
		}
		
		# config object
		$CACHE{$mdl_C{'T_CACHE'}}{'-cache_time'}=$mdl_C{'-cache_time'};
		
		# v tomto requeste je cache ignorovana
		if (!$main::cache)
		{
			main::_log("skracujem duration cache (request na recache)");
			$mdl_C{'-cache_duration'}=$mdl_C{'-cache_old'};
		}
		
		# CHECK CACHED ENTITIES
		my $data_changed;
		my $entity_i;
		if ($return_data{'entity'})# && !$Redis) # when Redis, expiration is active
		{
			main::_log("checking cache of entities") if $debug;
			foreach my $entity (@{$return_data{'entity'}})
			{
				$entity_i++;
				my $changetime=App::020::SQL::functions::_get_changetime($entity);
				main::_log("changetime of entity [$entity_i]".$entity->{'db_h'}."::".$entity->{'db_name'}."::".$entity->{'tb_name'}.do{"::".$entity->{'ID_entity'} if $entity->{'ID_entity'}}." ".$changetime."S") if $debug;
				if ($changetime > $mdl_C{'-cache_from'})
				{
					my $changetime_diff=$main::time_current - $changetime;
					main::_log("entity ".$entity->{'db_h'}."::".$entity->{'db_name'}."::".$entity->{'tb_name'}.do{"::".$entity->{'ID_entity'} if $entity->{'ID_entity'}}." changed in ".($mdl_C{'-cache_from'}-$changetime)."S (relative to module cache start time)");
					$data_changed=1;
					last;
				}
			}
		}
		
		if (!$mdl_C{'-cache_from'})
		{
			main::_log("cache info digest:$mdl_C{-digest} missing parallel=".$cache_parallel) if $debug;
		}
		else
		{
			main::_log("cache info digest:$mdl_C{-digest} old:".int($mdl_C{'-cache_old'})."S duration:$mdl_C{-cache_duration}S from:".int($mdl_C{-cache_from})."S to:".int($mdl_C{-cache_to})."S parallel=".$cache_parallel) if $debug;
		}
		
		if(
			(
				# AK JE STARIE CACHE MENSIE AKO VYZADOVANE STARIE
				#($mdl_C{-cache_old}<$CACHE{$mdl_C{T_CACHE}}{-cache_time})
				($mdl_C{'-cache_old'} < $mdl_C{'-cache_duration'})
				# ALEBO
				||
				(
					# tento browser ma zakazane recachovanie
					# pokial cache existuje v databaze
					# AK ROBOT NEJAKY STARY CACHE, NEZAUJIMA HO CI JE AKTUALNY,
					# STACI MU ZE CACHE PROSTE MA A TAK HO POUZIJE
					($TOM::Net::HTTP::UserAgent::table[$main::UserAgent]{'recache_disable'})
					&&($mdl_C{'-cache_from'})
				)
				||
				(
					# ak iny proces sa snazi prave naplnit tuto cache
					# pouzijem proste tu cache ktoru mam
					$cache_parallel && $mdl_C{'-cache_from'}
					
				)
				||
				(
					# alebo je pouzity parameter pre automaticku obsluhu cache na pozadi
					$mdl_C{'-cache_backend'} && $mdl_C{'-cache_from'} && $TOM::cache_backend
				)
			)
			# A
			&&
			(
				# data sa nezmenili
				!$data_changed
			)
			&&
			(
				!$mdl_C{'-cache_ignore'}
			)
		)
		# TAK TUTO CACHE POUZIJEM
		{
			main::_log("load cache from:$mdl_C{'-cache_from'}s old:".int($mdl_C{'-cache_old'})."s ".
				"durr:".$CACHE{$mdl_C{'T_CACHE'}}{'-cache_time'}."s ".
				"est.:".int($CACHE{$mdl_C{'T_CACHE'}}{'-cache_time'}-$mdl_C{'-cache_old'})."s ".
				"hits:".$cache->{'hits'}." ".
				"parallel?:".$cache_parallel." ".
				"object:".$cache_key
			);
			
			# idem poslat do backendu request
			if (
				$mdl_C{'-cache_old'} >= ($mdl_C{'-cache_duration'}*0.95) # cache je stara
				&& $mdl_C{'-cache_backend'} # chcem aby nacachoval backend
				&& $TOM::cache_backend
				&& !$cache_parallel # a uz sa tak nedeje v inom procese/poziadavke
#				&& $RabbitMQ # je k dispozicii backend services
			)
			{
				use Encode qw(decode encode);
				
				my $key = 'C3|mdl|'.$TOM::P_uuid.':'.$tom::Hm.":".$cache_domain.":pub:".$mdl_C{'-digest'};
				
				my $id=TOM::Utils::vars::genhash(8);
				my $warmup_time=int( time()/$TOM::CACHE_warmup_granularity ) * $TOM::CACHE_warmup_granularity;
				main::_log("[cache warmup/backend] ".$key." to ".$warmup_time." request=".$id,3);
				my $mdl_cache_type='C3|warmup|'.$warmup_time;
					$Redis->sadd($mdl_cache_type, $key, sub{});
					$Redis->expire($mdl_cache_type,(86400 * 30 * 2),sub{});
					
				my %env_origin=@_;
#					delete $env_origin{'-cache_backend'};
#					$env_origin{'-cache_ignore'}=1;
				
				my $queue=$tom::H_orig || '_global';
					$queue.="::pub";
				
				$Redis->hset($key,'etime',time());
				$Redis->hset($key,'warmup',
					Ext::Redis::_compress(\$json->encode({
						'routing_key' => $queue,
						'created' => time(),
						'body' => {
							'requested-id' => $id,
							'pub-mdl' => $mdl_C{'-addon'}.'-'.$mdl_C{'-name'}.'.'.$mdl_C{'-version'},
							'args' => \%env_origin,
							'FORM' => Ext::Redis::_store \%main::FORM,
							'key' => \%main::key,
							'env' => \%main::env,
							'setup' => Ext::Redis::_store \%tom::setup,
							'a210' => Ext::Redis::_store {%main::a210,'node'=>undef},
							'lng' => $tom::lng
						},
					}))
				);
			}
			
			if ($TOM::DEBUG_cache)
			{
				my $hits;
				if ($Redis)
				{
					my $date_str=$tom::Fyear.'-'.$tom::Fmon.'-'.$tom::Fmday.' '.$tom::Fhour.':'.$tom::Fmin;
					$Redis->hincrby('C3|counters|mdl_cache|'.$date_str,'hit',1,sub{});
					$Redis->expire('C3|counters|mdl_cache|'.$date_str,3600,sub{});
					$Redis->hincrby($cache_key,'hits',1,sub{});
				}
#				$hits=1 unless $hits;
#				my $hpm=0;
#					$hpm=int($hits/($mdl_C{'-cache_old'}/60))
#						if ($mdl_C{'-cache_old'}/60);
#				main::_log("[mdl][".$mdl_C{'-md5'}."][HIT] name='".$mdl_C{'T_CACHE'}."' (start:".$mdl_C{'-cache_from'}." old:".$mdl_C{'-cache_old'}." hits:$hits hpm:$hpm)",3,"cache");
#				main::_log("[mdl][$tom::H][".$mdl_C{'-md5'}."][HIT] #$hits",3,"cache",1);
			}
			
			if ($mdl_C{'-stdout'} && $main::stdout)
			{
				print $file_data."\n";
			}
			
			if ($mdl_C{'-cache_debug'})
			{
#				$mdl_C{'-md5'}
				$file_data="<!-- mdl"
					." do='".$cache_domain."'"
					." t='".$mdl_C{'T_CACHE'}."'"
					." e='".$cache->{'engine'}."'"
					." c='".$cache->{'request_code'}."'"
					." u='".$TOM::P_uuid."'"
					." h='".$TOM::hostname."'"
					." d='".int($mdl_C{'-cache_old'})."s'"
					." id='".$mdl_C{'-digest'}."'"
					." -->\n"
					.$file_data
					."<!-- /mdl -->\n";
			}
			
			if (!$mdl_C{'-stdout_dummy'})
			{
				$main::H->r_("<!TMP-".$mdl_C{-TMP}."!>",$file_data);
			}
			
			$t->close();
			module_process_return_data(%return_data);
			return $return_code,%return_data;
		}
		else # CACHE JE STARY, SPRACUJEM DATA O CACHE
		{
			if ($mdl_C{'-cache_old'} eq $tom::time_current)
			{
				# tato cache prebehla cez destroy()
				#main::_log("cache $mdl_C{N_CACHE} neexistuje, preslo destroy()",1,"pub.cache");
			}
			else
			{
				# cache je stary, spracujem debug data o cache
				# kedze je cache system len v databaze, tak toto robit nemusim
				# fcia je prazdna
#				Tomahawk::debug::cache_conf_opt();
			}
		}
	} #KONIEC OBLUSHY CACHE
	
	#NECACHUJEM, LEBO VYPRSALA CACHE
	
	if ($mdl_C{'-tpl_level'})
	{
		if ($mdl_C{'-tpl_level'} eq "global"){$mdl_C{'-tpl_global'} = 1;}
		elsif ($mdl_C{'-tpl_level'} eq "master"){$mdl_C{'-tpl_global'} = 2;}
		elsif ($mdl_C{'-tpl_level'} eq "local"){$mdl_C{'-tpl_global'} = 0;}
	}
	
	if ($mdl_C{'-level'})
	{
		if ($mdl_C{'-level'} eq "global"){$mdl_C{'-global'} = 1;}
		elsif ($mdl_C{'-level'} eq "master"){$mdl_C{'-global'} = 2;}
		elsif ($mdl_C{'-level'} eq "local"){$mdl_C{'-global'} = 0;}
	}
	
	# Where is the modul?
	if (($mdl_C{'-global'}==2)&&($tom::Pm))
	{
		# at first try addons directory
		my $addon_path = $tom::Pm . "/_addons/".$mdl_C{'-addon_type'}."/" . $mdl_C{'-addon_name'} . "/_mdl/" . $mdl_C{'-addon_name'} . "-" . $mdl_C{'-name'} . "." . $mdl_C{'-version'} . ".mdl";
		if (-e $addon_path)
		{
			$mdl_C{'P_MODULE'}=$addon_path;
		}
		else
		{
			$mdl_C{'P_MODULE'}=$tom::Pm."/_mdl/".$mdl_C{'-addon_name'}."-".$mdl_C{'-name'}.".".$mdl_C{'-version'}.".mdl";
		}
	}
	elsif ($mdl_C{'-global'})
	{
		$mdl_C{'-global'}=1;
		my $addon_path = $TOM::P . "/_addons/".$mdl_C{'-addon_type'}."/" . $mdl_C{'-addon_name'} . "/_mdl/" . $mdl_C{'-addon_name'} . "-" . $mdl_C{'-name'} . "." . $mdl_C{'-version'} . ".mdl";
		# find in overlays
		foreach my $item(@TOM::Overlays::item)
		{
			if ($item=~/^\//)
			{
				my $file=
					$item
					.'/_addons/'.$mdl_C{'-addon_type'}.'/'.$mdl_C{'-addon_name'}.'/_mdl/'
					.$mdl_C{'-addon_name'}.'-'.$mdl_C{'-name'}.'.'.$mdl_C{'-version'}.'.mdl';
				if (-e $file){$addon_path=$file;last;}
			}
			else
			{
				my $file=
					$TOM::P.'/_overlays/'.$item
					.'/_addons/'.$mdl_C{'-addon_type'}.'/'.$mdl_C{'-addon_name'}.'/_mdl/'
					.$mdl_C{'-addon_name'}.'-'.$mdl_C{'-name'}.'.'.$mdl_C{'-version'}.'.mdl';
				if (-e $file){$addon_path=$file;last;}
			}
		}
		# at first try addons directory
		if (-e $addon_path)
		{
			$mdl_C{'P_MODULE'}=$addon_path;
		}
		else
		{
			$mdl_C{'P_MODULE'}=$TOM::P."/_mdl/".$mdl_C{'-addon_name'}."/".$mdl_C{'-addon_name'}."-".$mdl_C{'-name'}.".".$mdl_C{'-version'}.".mdl";
		}
	}
	else
	{
		my $addon_path = $tom::P . "/_addons/".$mdl_C{'-addon_type'}."/" . $mdl_C{'-addon_name'} . "/_mdl/" . $mdl_C{'-addon_name'} . "-" . $mdl_C{'-name'} . "." . $mdl_C{'-version'} . ".mdl";
		# at first try addons directory
		if (-e $addon_path)
		{
			$mdl_C{'P_MODULE'}=$addon_path;
		}
		else
		{
			$mdl_C{'P_MODULE'}=$tom::P."/_mdl/".$mdl_C{'-addon_name'}."-".$mdl_C{'-name'}.".".$mdl_C{'-version'}.".mdl";
		}
	}
	
	# AK MODUL NEEXISTUJE
	if (not -e $mdl_C{'P_MODULE'})
	{
#		main::_log("module file '$mdl_C{'P_MODULE'}' can't be found",1);
		TOM::Error::module(
			'-TMP' => $mdl_C{'-TMP'},
			'-MODULE' => "[MDL::".$mdl_C{'-addon'}."-".$mdl_C{'-name'}."]",
			'-ERROR' => "module file '$mdl_C{'P_MODULE'}' can't be found"
		);
		$t->close();
		return undef;
	}
	
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
		Time::HiRes::alarm($mdl_C{'-ALRM'});
		
		if (exists $mdl_C{'-cache'} && $TOM::CACHE)
		{
			if ($Redis)
			{
				my $key = 'C3|mdl|'.$TOM::P_uuid.':'.$tom::Hm.":".$cache_domain.":pub:".$mdl_C{'-digest'};
				$Redis->hset($key,'etime',$main::time_current);
				$Redis->hset($key,'bhash',$main::request_code);
			}
			elsif ($TOM::CACHE_memcached)
			{
				$Ext::CacheMemcache::cache->set(
					'namespace' => "mcache_parallel",
					'key' => $TOM::P_uuid.':'.$tom::Hm.":".$cache_domain.":pub:".$mdl_C{'-digest'},
					'value' => 1,
					'expiration' => '60S' # safe time to not parallel caching
				);
			}
		}
		
		main::_log("source '$mdl_C{'P_MODULE'}'");
		my $mdl_ID=$mdl_C{'P_MODULE'};
			$mdl_ID=~s|\.mdl$||;
			$mdl_ID=~s|^$TOM::P/||;
			$mdl_ID=~s|_mdl/||g;
			$mdl_ID=~s|/|:|g;
			$mdl_ID=~s|[\./\-\! ]|_|g;
			1 while ($mdl_ID=~s|[:_][:_]|:|g);
			1 while ($mdl_ID=~s|__|_|g);
			1 while ($mdl_ID=~s|::|:|g);
			$mdl_ID=~s|^[:_]||g;
			$mdl_ID=~s|:|::|g;
		
		my $mdl_version='MODULE::'.$mdl_ID;
		my $m_time=(stat($mdl_C{'P_MODULE'}))[9];
		
		if (!$mdl_version->VERSION() || ($mdl_version->VERSION() < $m_time))
		{
			my $t_do=track TOM::Debug("loadfile mtime:".$m_time,'timer'=>1);
			use Fcntl;
			sysopen(HND_DO, $mdl_C{'P_MODULE'}, O_RDONLY);
			my $mdl_buffer;
			my $mdl_src;
			while (sysread(HND_DO, $mdl_buffer, 1024)){$mdl_src.=$mdl_buffer;}
			close(HND_DO);
			my $mdl_inject=qq{use Tomahawk::module qw(\$TPL \%XSGN \%XLNG &XSGN_load_hash);our \$authors;our \$VERSION=$m_time;};
			$mdl_src=~s|package Tomahawk::module;|package MODULE::$mdl_ID;$mdl_inject|;
			eval $mdl_src;
			if ($@){$t_do->close();$tom::ERR="$@";die "evalfile error: $@\n";}
			$t_do->close();
		}
		
		# reset variables
		undef %Tomahawk::module::XSGN;
		undef $Tomahawk::module::TPL;
		undef %Tomahawk::module::XLNG;
		
		my $t_execute=track TOM::Debug("exec",'timer'=>1);
		
		no strict;
		my $execute_package='MODULE::'.$mdl_ID.'::execute';
		($return_code,%return_data)=&$execute_package(%mdl_env);
		if ($Tomahawk::module::TPL)
		{
			my $t_tt=track TOM::Debug("tt:process",'timer'=>1);
			# basic environment variables are attached in TOM::Template::process()
			# module variables
			$Tomahawk::module::TPL->{'variables'}->{'module'}={
				'name'=> $mdl_C{'-name'},
				'version'=> $mdl_C{'-version'},
				'addon'=> $mdl_C{'-addon'},
				'filename' => $mdl_C{'P_MODULE'}
			};
			# add all module input variables
			%{$Tomahawk::module::TPL->{'variables'}->{'module'}->{'env'}}=(%mdl_C,%mdl_env);
			# output can be processed too
			$Tomahawk::module::TPL->{'variables'}->{'module'}->{'output'}=\%return_data;
			$Tomahawk::module::TPL->process() || do
			{
				$t_tt->close();
				$t_execute->close();
				$tom::ERR=$Tomahawk::module::TPL->{'error'};
				TOM::Error::module
				(
					'-TMP' => $mdl_C{'-TMP'},
					'-MODULE' => "[MDL::".$mdl_C{'-addon'}."-".$mdl_C{'-name'}."]",
					'-ERROR' => $tom::ERR,
				);
				return undef;
			};
			$Tomahawk::module::XSGN{'TMP'}=$Tomahawk::module::TPL->{'output'};
			$t_tt->close();
		}
		$t_execute->close();
		
		if ($return_code)
		{
			if (!$Tomahawk::module::TPL)
			{
				TOM::Utils::vars::replace_comment($Tomahawk::module::XSGN{'TMP'});
				
				$Tomahawk::module::XSGN{'TMP'}=~s|<#.*?#>||g;
				$Tomahawk::module::XSGN{'TMP'}=~s|<%.*?%>||g;
			}
			
			if ($mdl_C{'-stdout'} && $main::stdout)
			{
				print $Tomahawk::module::XSGN{'TMP'}."\n";
			}
			
			if (
				!$mdl_C{'-stdout_dummy'}
				&& $Tomahawk::module::XSGN{'TMP'}
				&& (not $main::H->r_("<!TMP-".$mdl_C{'-TMP'}."!>",$Tomahawk::module::XSGN{'TMP'}))
				&& !$main::stdout
			)
			{
				Time::HiRes::alarm(0);
				TOM::Error::module
				(
					'-TMP' => $mdl_C{'-TMP'},
					'-MODULE' => "[MDL::".$mdl_C{'-addon'}."-".$mdl_C{'-name'}."]",
					'-ERROR' => "Unknown TMP-".$mdl_C{'-TMP'},
				);
				return undef;
			};
			
			# IDEME NACACHOVAT
			if (exists $mdl_C{'-cache'} && $TOM::CACHE)
			{
				my $ID_config=$CACHE{$mdl_C{'T_CACHE'}}{'-ID_config'};
				
				if ($Redis)
				{
					my $key = 'C3|mdl|'.$TOM::P_uuid.':'.$tom::Hm.":".$cache_domain.":pub:".$mdl_C{'-digest'};
					
					if ($return_data{'entity'})
					{
						foreach my $entity (@{$return_data{'entity'}})
						{
							my $key_entity=$entity->{'db_h'}."::".$entity->{'db_name'}."::".$entity->{'tb_name'};
								$key_entity.="::".$entity->{'ID_entity'} if $entity->{'ID_entity'};
							my $changetime=App::020::SQL::functions::_get_changetime($entity);
#							main::_log(" autoinvalidate if key 'C3|db_entity|$key_entity' changes at mtime=".$changetime);
							$Redis->sadd('C3|invalidate|db_entity|'.$key_entity,$key,sub{});
							$Redis->expire('C3|invalidate|db_entity|'.$key_entity,(86400*30),sub{});
						}
					}
					
					# save to Redis
					$Redis->hmset($key,
						'body' => Ext::Redis::_compress(\$Tomahawk::module::XSGN{'TMP'}),
						'return_data' => Ext::Redis::_compress(\$json->encode(\%return_data)),
						'return_code' => $return_code,
						'time_from' => Time::HiRes::time(),
						'time_duration' => $CACHE{$mdl_C{'T_CACHE'}}{'-cache_time'},
						'execute_time_duration' => $t_execute->{'time'}{'duration'},
						'execute_time_user' => $t_execute->{'time'}{'user'}{'duration'},
						'engine' => $TOM::engine,
						'request_code' => $main::request_code,
						'hits' => 0,
						sub {} # in pipeline
					);
					$Redis->hdel($key,'etime',sub {}); # remove execution time
					$Redis->hdel($key,'bhash',sub {}); # remove bhash time
					my $expiretime=$CACHE{$mdl_C{'T_CACHE'}}{'-cache_time'};
					if ($TOM::CACHE_pub_mdl_grace)
					{
						my $grace=int($CACHE{$mdl_C{'T_CACHE'}}{'-cache_time'} * $TOM::CACHE_pub_mdl_grace);
						$grace=$TOM::CACHE_pub_mdl_grace_min if
							$grace < $TOM::CACHE_pub_mdl_grace_min;
						$grace=$TOM::CACHE_pub_mdl_grace_max if
							$grace > $TOM::CACHE_pub_mdl_grace_max;
						$expiretime+=$grace;
					}
					$Redis->expire($key,
						$expiretime,
						sub {} # in pipeline
					); # set expiration time
					main::_log("save cache object '$key' type '".$mdl_C{'T_CACHE'}."' body_size=".length($Tomahawk::module::XSGN{'TMP'}));
					
					if ($mdl_C{'-cache_warmup'})
					{
						my $warmup_time=int( (time()+$expiretime)/$TOM::CACHE_warmup_granularity ) * $TOM::CACHE_warmup_granularity;
						main::_log("[cache warmup] ".$key." to ".$warmup_time,3);
						my $mdl_cache_type='C3|warmup|'.$warmup_time;
							$Redis->sadd($mdl_cache_type, $key, sub{});
							$Redis->expire($mdl_cache_type,(86400 * 30 * 2),sub{});
							
						my %env_origin=@_;
#							delete $env_origin{'-cache_backend'};
#							$env_origin{'-cache_ignore'}=1;
						
						my $queue=$tom::H_orig || '_global';
							$queue.="::pub";
							
						$Redis->hset($key,'warmup',
							Ext::Redis::_compress(\$json->encode({
								'routing_key' => $queue,
								'body' => {
									'pub-mdl' => $mdl_C{'-addon'}.'-'.$mdl_C{'-name'}.'.'.$mdl_C{'-version'},
									'args' => \%env_origin,
									'FORM' => Ext::Redis::_store \%main::FORM,
									'key' => \%main::key,
									'env' => \%main::env,
									'setup' => Ext::Redis::_store \%tom::setup,
									'a210' => Ext::Redis::_store {%main::a210,'node'=>undef},
									'lng' => $tom::lng
								},
							}))
						);
					}
					
					if ($TOM::DEBUG_cache)
					{
						my $date_str=$tom::Fyear.'-'.$tom::Fmon.'-'.$tom::Fmday.' '.$tom::Fhour.':'.$tom::Fmin;
						$Redis->hincrby('C3|counters|mdl_cache|'.$date_str,'crt',1,sub{});
						$Redis->expire('C3|counters|mdl_cache|'.$date_str,3600,sub{});
						
						my $mdl_cache_type='C3|debug|mdl_cache|'.$tom::H.':'.$mdl_C{'T_CACHE'};
						$Redis->sadd('C3|debug|mdl_caches', $mdl_cache_type,sub{});
						$Redis->sadd('C3|debug|mdl_caches|'.$tom::H, $mdl_cache_type,sub{});
						$Redis->expire('C3|debug|mdl_caches|'.$tom::H, (86400*30),sub{});
						$Redis->sadd($mdl_cache_type,$key,sub{});
						$Redis->expire($mdl_cache_type,(86400*30),sub{});
					}
					
				}
				
			}
			
#			undef &Tomahawk::module::execute;
			
		}
		else # chyba o ktorej upozorni samotny program vratenim undef :)
		{
			if (exists $mdl_C{'-cache'} && $TOM::CACHE)
			{
				if ($Redis)
				{
					my $key = 'C3|mdl|'.$TOM::P_uuid.':'.$tom::Hm.":".$cache_domain.":pub:".$mdl_C{'-digest'};
					$Redis->hdel($key,'etime'); # remove execution time
					$Redis->hdel($key,'bhash'); # remove bhash
				}
			}
			TOM::Error::module(
				'-TMP' => $mdl_C{'-TMP'},
				'-MODULE' => "[MDL::".$mdl_C{'-addon'}."-".$mdl_C{'-name'}."]",
				'-ERROR' => $tom::ERR,
				'-PLUS' => $tom::ERR_plus,
			)
		};
		Time::HiRes::alarm(0);
	};
	Time::HiRes::alarm(0);
	
	if ($@)
	{
		if (exists $mdl_C{'-cache_id'} && $TOM::CACHE)
		{
			if ($Redis)
			{
				my $key = 'C3|mdl|'.$TOM::P_uuid.':'.$tom::Hm.":".$cache_domain.":pub:".$mdl_C{'-digets'};
				$Redis->hdel($key,'etime'); # remove execution time
				$Redis->hdel($key,'bhash'); # remove bhash
			}
			elsif ($TOM::CACHE_memcached)
			{
				# refilling cache stopped
				$Ext::CacheMemcache::cache->set(
					'namespace' => "mcache_parallel",
					'key' => $TOM::P_uuid.':'.$tom::Hm.":".$cache_domain.":pub:".$mdl_C{'-digest'},
					'value' => 0
				);
			}
		}
		TOM::Error::module
		(
			'-TMP' => $mdl_C{'-TMP'},
			'-MODULE' => "[MDL::".$mdl_C{'-addon'}."-".$mdl_C{'-name'}."]",
			'-ERROR' => $@,
		);# unless $mdl_C{-noerror_run};
	};
	
	$t->close();
	
	module_process_return_data(%return_data);
	return $return_code,%return_data;
}



sub module_process_return_data
{
	my %return_data=@_;
	
	if ($return_data{'call'})
	{
		if ($return_data{'call'}{'H'})
		{
			# metadata
			foreach my $env0(@{$return_data{'call'}{'H'}{'add_DOC_meta'}})
			{
				$main::H->add_DOC_meta(%{$env0});
			}
			# title
			foreach my $env0(@{$return_data{'call'}{'H'}{'add_DOC_title'}})
			{
				$main::H->add_DOC_title($env0);
			}
			foreach my $env0(@{$return_data{'call'}{'H'}{'change_DOC_title'}})
			{
				$main::H->change_DOC_title($env0);
			}
			# keywords
			foreach my $env0(@{$return_data{'call'}{'H'}{'add_DOC_keywords'}})
			{
				$main::H->add_DOC_keywords($env0);
			}
			# description
			foreach my $env0(@{$return_data{'call'}{'H'}{'change_DOC_description'}})
			{
				$main::H->change_DOC_description($env0,{'lng'=>$tom::lng});
			}
			# link
			foreach my $env0(@{$return_data{'call'}{'H'}{'add_DOC_link'}})
			{
				$main::H->add_DOC_link(%{$env0});
			}
		}
	}
	
	if ($return_data{'set'})
	{
		foreach (keys %{$return_data{'set'}{'env'}})
		{
			$main::env{$_}=$return_data{'set'}{'env'}{$_};
		}
		foreach (keys %{$return_data{'set'}{'key'}})
		{
			$main::key{$_}=$return_data{'set'}{'key'}{$_};
		}
	}
	
}





=head2 supermodule()



=cut


sub supermodule
{
	local %smdl_env=@_;
#	local $app=$smdl_env{-category};
	$Tomahawk::module::authors="";
	
	if (exists $smdl_env{'-category'}){$smdl_env{'-addon'}="a".$smdl_env{'-category'}}; # backward compatibility
	$smdl_env{'-addon_type'}='App' if $smdl_env{'-addon'}=~/^a/;
	$smdl_env{'-addon_type'}='Ext' if $smdl_env{'-addon'}=~/^e/;
	$smdl_env{'-addon_name'}=$smdl_env{'-addon'};$smdl_env{'-addon_name'}=~s|^.||;
	$smdl_env{'-addon'}="a010" unless $smdl_env{'-addon'};
	
	$smdl_env{'-version'}="0" unless $smdl_env{'-version'}; # NEBUDEM SE S NIKYM SRAAAT BEZ DUUVODU!...
	$smdl_env{'-xsgn'}=$tom::dsgn unless $smdl_env{'-xsgn'}; # SAJRAJT
	$smdl_env{'-xlng'}=$tom::lng unless $smdl_env{'-xlng'};
	
	# main::_log("adding supermodule ".$smdl_env{-category}."-".$smdl_env{-name}."/".$smdl_env{-version}."/".$smdl_env{-global});
	my $t=track TOM::Debug("supermodule",'attrs'=>$smdl_env{-addon}."-".$smdl_env{-name}.'.'.$smdl_env{'-version'},'timer'=>1);
	
	foreach (sort keys %smdl_env)
	{
#		my $var=$smdl_env{$_};$var=~s|[\n\r]||g;
#		if (length($var)>50){$var=substr($var,0,50)."..."}
#		main::_log("input (".$_.")=".$var);
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
	
	# KDE JE MODUL?
	# $smdl_env{P_MODULE}="/_mdl/".$smdl_env{-category}."-".$smdl_env{-name}.".".$smdl_env{-version}.".smdl";
	# if ($smdl_env{-global}){$smdl_env{P_MODULE}=$TOM::P.$smdl_env{P_MODULE}}
	# else{$smdl_env{P_MODULE}=$tom::P.$smdl_env{P_MODULE}}
	
	if ($smdl_env{'-level'})
	{
		if ($smdl_env{'-level'} eq "global"){$smdl_env{'-global'} = 1;}
		elsif ($smdl_env{'-level'} eq "master"){$smdl_env{'-global'} = 2;}
		elsif ($smdl_env{'-level'} eq "local"){$smdl_env{'-global'} = 0;}
	}
	
	if (($smdl_env{-global}==2)&&($tom::Pm))
	{
		my $addon_path=
			$tom::Pm . "/_addons/" . $smdl_env{'-addon_type'} . "/" . $smdl_env{'-addon_name'} . "/_mdl/" . $smdl_env{'-addon_name'} . "-" . $smdl_env{-name} . "." . $smdl_env{-version} . ".smdl";
		if (-e $addon_path)
		{$smdl_env{P_MODULE}=$addon_path}
		else
		{$smdl_env{P_MODULE}=
			$tom::Pm."/_mdl/".$smdl_env{'-addon_name'}."-".$smdl_env{'-name'}.".".$smdl_env{-version}.".smdl";
		}
	}
	elsif ($smdl_env{-global})
	{
		$smdl_env{-global}=1;
		my $addon_path=
			$TOM::P . "/_addons/" . $smdl_env{'-addon_type'} . "/" . $smdl_env{'-addon_name'} . "/_mdl/" . $smdl_env{'-addon_name'} . "-" . $smdl_env{-name} . "." . $smdl_env{-version} . ".smdl";
		# find in overlays
		foreach my $item(@TOM::Overlays::item)
		{
			if ($item=~/^\//)
			{
				my $file=
					$item
					.'/_addons/'.$smdl_env{'-addon_type'} . "/" . $smdl_env{'-addon_name'}.'/_mdl/'
					.$smdl_env{'-addon_name'}.'-'.$smdl_env{'-name'}.'.'. $smdl_env{'-version'}.'.smdl';
				if (-e $file){$addon_path=$file;last;}
			}
			else
			{
				my $file=
					$TOM::P.'/_overlays/'.$item
					.'/_addons/'.$smdl_env{'-addon_type'} . "/" . $smdl_env{'-addon_name'}.'/_mdl/'
					.$smdl_env{'-addon_name'}.'-'.$smdl_env{'-name'}.'.'. $smdl_env{'-version'}.'.smdl';
				if (-e $file){$addon_path=$file;last;}
			}
		}
		if (-e $addon_path)
		{$smdl_env{P_MODULE}=$addon_path}
		else
		{$smdl_env{P_MODULE}=
			$TOM::P."/_mdl/".$smdl_env{'-addon_name'}."-".$smdl_env{'-name'}.".".$smdl_env{-version}.".smdl";
		}
	}
	else
	{
		my $addon_path=
			$tom::P . "/_addons/" . $smdl_env{'-addon_type'} . "/" . $smdl_env{'-addon_name'} . "/_mdl/" . $smdl_env{'-addon_name'}.'-'.$smdl_env{'-name'} . "." . $smdl_env{-version} . ".smdl";
		if (-e $addon_path)
		{$smdl_env{P_MODULE}=$addon_path}
		else
		{$smdl_env{P_MODULE}=
			$tom::P."/_mdl/".$smdl_env{'-addon_name'}."-".$smdl_env{'-name'}.".".$smdl_env{-version}.".smdl";
		}
	}

	# AK MODUL NEEXISTUJE
	if (not -e $smdl_env{P_MODULE})
	{TOM::Error::module(
		-MODULE	=>	"[SMDL::".$smdl_env{-category}."-".$smdl_env{-name}."]",
		-ERROR	=>	$!);$t->close();return undef;}
	
	
	# V EVALKU OSETRIM CHYBU RYCHLOSTI A SPATNEHO MODULU
	eval
	{
		local $SIG{ALRM} = sub {die "Timeout ".$TOM::ALRM_smdl." sec.\n"};
		alarm $TOM::ALRM_smdl;
		
		if (not do $smdl_env{'P_MODULE'}){$tom::ERR="$@ $!";die "pre-compilation error: $@ $!\n";}
		
		if (Tomahawk::module::execute(%smdl_env))
		{
		}
		else
		{
			TOM::Error::module(
			-MODULE	=>	"[SMDL::".$smdl_env{-category}."-".$smdl_env{-name}."]",
			-ERROR	=>	$tom::ERR);
			alarm 0;
			$t->close();
			return undef;
		}
		alarm 0;
	};
	
	if ($@){TOM::Error::module( # toto je syntakticka chyba zistitelna az pri behu
		-TMP	=>	$mdl_C{-TMP},
		-MODULE	=>	"[SMDL::".$smdl_env{-category}."-".$smdl_env{-name}."]",
		-ERROR	=>	$@,
		-PLUS	=>	$@." ".$!." ".$tom::ERR
  	)};
	$t->close();
	return 1;
}








=head2 designmodule()



=cut


sub designmodule
{
	my $t=track TOM::Debug("designmodule",'timer'=>1,'namespace'=>'MDL');
	
	local %mdl_env=@_;
	$Tomahawk::module::authors=""; # vyprazdnim zoznam authorov
	# SPRACOVANIE PREMMENNYCH
	if (exists $mdl_env{'-category'}){$mdl_env{'-addon'}="a".$mdl_env{'-category'}}; # backward compatibility
	$mdl_env{'-addon_type'}='App' if $mdl_env{'-addon'}=~/^a/;
	$mdl_env{'-addon_type'}='Ext' if $mdl_env{'-addon'}=~/^e/;
	$mdl_env{'-addon_name'}=$mdl_env{'-addon'};$mdl_env{'-addon_name'}=~s|^.||;
	$mdl_env{'-addon'}="a010" unless $mdl_env{'-addon'};
	
	$mdl_env{'-xsgn'}=$mdl_env{'-version'} if $mdl_env{'-version'}; # -version is higher priority than -xsgn, -xsgn is deprecated
	$mdl_env{'-xsgn'}=$tom::dsgn unless $mdl_env{'-xsgn'};
	$mdl_env{'-xlng'}=$tom::lng unless $mdl_env{'-xlng'};
	$mdl_env{'-convertvars'}=1 unless exists $mdl_env{'-convertvars'};
	
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
	
	if ($mdl_env{'-level'})
	{
		if ($mdl_env{'-level'} eq "global"){$mdl_env{'-global'} = 1;}
		elsif ($mdl_env{'-level'} eq "master"){$mdl_env{'-global'} = 2;}
		elsif ($mdl_env{'-level'} eq "local"){$mdl_env{'-global'} = 0;}
	}
	
	$mdl_env{'MODULE'}=$mdl_env{'-addon_name'}."-".$mdl_env{'-name'}.".".$mdl_env{-xsgn}.".".$mdl_env{-xlng};
	
	if (($mdl_env{-global}==2)&&($tom::Pm))
	{
		my $addon_path=$tom::Pm."/_addons/".$mdl_env{'-addon_type'}."/" . $mdl_env{'-addon_name'} . "/_mdl/".
			$mdl_env{'-addon_name'} . "-" . $mdl_env{'-name'} . ".".$mdl_env{-xsgn}.".".$mdl_env{-xlng}.".dmdl";
		if (-e $addon_path)
		{$mdl_env{P_MODULE}=$addon_path}
		else
		{$mdl_env{P_MODULE}=
			$tom::Pm."/_mdl/".
			$mdl_env{'-addon_name'} . "-" . $mdl_env{'-name'} . ".".$mdl_env{-xsgn}.".".$mdl_env{-xlng}.".dmdl";
		}
	}
	elsif ($mdl_env{-global})
	{
		$mdl_env{-global}=1;
		my $addon_path=$TOM::P."/_addons/".$mdl_env{'-addon_type'}."/" . $mdl_env{'-addon_name'}."/_mdl/".
			$mdl_env{'-addon_name'} . "-" . $mdl_env{'-name'} . ".".$mdl_env{-xsgn}.".".$mdl_env{-xlng}.".dmdl";
		# find in overlays
		foreach my $item(@TOM::Overlays::item)
		{
			if ($item=~/^\//)
			{
				my $file=
					$item
					.'/_addons/'.$mdl_env{'-addon_type'} . "/" . $mdl_env{'-addon_name'}.'/_mdl/'
					.$mdl_env{'-addon_name'} . "-" . $mdl_env{'-name'}.'.'.$mdl_env{'-xsgn'}.'.'.$mdl_env{'-xlng'}.'.dmdl';
				if (-e $file){$addon_path=$file;last;}
			}
			else
			{
				my $file=
					$TOM::P.'/_overlays/'.$item
					.'/_addons/'.$mdl_env{'-addon_type'} . "/" . $mdl_env{'-addon_name'}.'/_mdl/'
					.$mdl_env{'-addon_name'} . "-" . $mdl_env{'-name'}.'.'.$mdl_env{'-xsgn'}.'.'.$mdl_env{'-xlng'}.'.dmdl';
				if (-e $file){$addon_path=$file;last;}
			}
		}
		if (-e $addon_path)
		{$mdl_env{P_MODULE}=$addon_path}
		else
		{$mdl_env{P_MODULE}=
			$TOM::P."/_mdl/".$mdl_env{'-addon_name'}."/".
			$mdl_env{'-addon_name'} . "-" . $mdl_env{'-name'}.".".$mdl_env{-xsgn}.".".$mdl_env{-xlng}.".dmdl";
		}
	}
	else
	{
		my $addon_path=$tom::P."/_addons/".$mdl_env{'-addon_type'} . "/" . $mdl_env{'-addon_name'}."/_mdl/".
			$mdl_env{'-addon_name'} . "-" . $mdl_env{'-name'}.".".$mdl_env{-xsgn}.".".$mdl_env{-xlng}.".dmdl";
		if (-e $addon_path)
		{$mdl_env{P_MODULE}=$addon_path}
		else
		{$mdl_env{P_MODULE}=
			$tom::P."/_mdl/".
			$mdl_env{'-addon_name'} . "-" . $mdl_env{'-name'}.".".$mdl_env{-xsgn}.".".$mdl_env{-xlng}.".dmdl";
		}
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
		TOM::Utils::vars::replace_comment($file_data);
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




=head2 tplmodule()



=cut

sub tplmodule
{
	local %mdl_env=@_;
#	$mdl_env{'-cache'} if $mdl_env{'-cache_id'};
	if (exists $mdl_env{'-category'}){$mdl_env{'-addon'}="a".$mdl_env{'-category'}}; # backward compatibility
	$mdl_env{'-addon_type'}='App' if $mdl_env{'-addon'}=~/^a/;
	$mdl_env{'-addon_type'}='Ext' if $mdl_env{'-addon'}=~/^e/;
	$mdl_env{'-addon_name'}=$mdl_env{'-addon'};$mdl_env{'-addon_name'}=~s|^.||;
	my $t=track TOM::Debug("tplmodule",'attrs'=>$mdl_env{'-addon'}."-".$mdl_env{'-name'},'timer'=>1,'namespace'=>'MDL');
	
	local %mdl_C;
	local $tom::ERR;
	local $tom::ERR_plus;
#	local $app=$mdl_env{-category};
	my $cache_domain;
	my $return_code;
	my %return_data;
	
	# najpv si ocheckujem ci nechcem zistovat pritomnost TMP
	# zaroven pritomnost TMP zistim
	if ($mdl_env{'-TMP_check'})
	{
		main::_log("-TMP_check enabled");
		if (not $main::H->{'OUT'}{'BODY'}=~/<!TMP-$mdl_env{-TMP}!>/)
		{
			main::_log("return 10, TMP '$mdl_env{-TMP}' not exists in BODY");
			$t->close();
			return 10;
		}
	}
	
	# SPRACOVANIE PREMENNYCH
	my $debug;
	my $debug=1 if $mdl_env{'-debug'};
	
	foreach (sort keys %mdl_env)
	{
		main::_log("input '$_'='$mdl_env{$_}'") if $debug;
		/^-/ && do {$mdl_C{$_}=$mdl_env{$_};delete $mdl_env{$_};}
	}
	
	$mdl_C{'-addon'}="a010" unless $mdl_C{'-addon'};
	$mdl_C{'-version'}="0" unless $mdl_C{'-version'};
	$mdl_C{'-xsgn'}=$mdl_C{'-tpl'} || $tom::dsgn unless $mdl_C{'-xsgn'};
	$mdl_C{'-tpl'}=$mdl_C{'-xsgn'} unless $mdl_C{'-tpl'};
	$mdl_C{'-xsgn_global'}=0 unless $mdl_C{'-xsgn_global'};
	$mdl_C{'-tpl_global'}=0 unless $mdl_C{'-tpl_global'};
	$mdl_C{'-xlng'}=$tom::lng unless $mdl_C{'-xlng'};
	$mdl_C{'-xlng_global'}=0 unless $mdl_C{'-xlng_global'};
	# nastavit default alarmu ak nevyzadujem zmenu alebo nieje povolena zmena
	$mdl_C{'-ALRM'}=$TOM::ALRM_mdl if ((not exists $mdl_C{'-ALRM'})||(!$TOM::ALRM_change));
	if ((exists $mdl_C{'-cache'})&&(!$mdl_C{'-cache'})){$mdl_C{'-cache'}=$TOM::CACHE_time."s"};
	if ((exists $mdl_C{'-cache_id'})&&(!$mdl_C{'-cache_id'})){$mdl_C{'-cache_id'}="default"};
	
	my $file_data;
	
	# definujem rec pre modul aby ju mohol prijat ako $env{lng}
	# AK NIEJE ZADANA NATVRDO CEZ module (-xlng), tak vezmem language
	# tejto session. predam do $env{lng}
	$mdl_env{'lng'}=$mdl_C{'-xlng'};
	
	# definujem design pre modul aby ju mohol prijat ako $env{dsgn}
	# AK NIEJE ZADANA NATVRDO CEZ module (-xsgn), tak vezmem design
	# tejto session. predam do $env{lng}
	$mdl_env{'dsgn'}=$mdl_C{'-xsgn'};
	
	
	# AK JE DEFINOVANA POZIADAVKA NA CACHOVANIE A JE DEFINOVANA
	# POZIADAVKA NA VOBEC CACHOVANIE, TAK SA TOMU VENUJEM
	if ($mdl_C{'-cache'} && $TOM::CACHE)
	{
		$mdl_C{'-cache'}||=$TOM::CACHE_time."s";
		$mdl_C{'-cache_id'}||="default"; # ak je vstup s cache_id ale nieje 0
		$cache_domain=$tom::H unless $mdl_C{'-cache_master'};
		
		my $null;
		foreach (sort keys %mdl_env){$_=~/^[^_]/ && do{
			if (ref($mdl_env{$_}) eq "ARRAY" || ref($mdl_env{$_}) eq "HASH"){$null.=$_."=\"".$jsonc->encode($mdl_env{$_})."\"\n";}
			else {$null.=$_."=\"".$mdl_env{$_}."\"\n";}
		}}
		foreach (sort keys %mdl_C){
			next if $_ eq "-cache_debug";
			next if $_ eq "-cache_id";
			next if $_ eq "-cache"; # duration configuration don't affects cache
			$null.=$_."=\"".$mdl_C{$_}."\"\n";
		}
		
		$mdl_C{'-digest'}=TOM::Digest::hash($null);
		main::_log("cache digest='".$mdl_C{'-digest'}."' from string ".$null) if $debug;
		
		# NAZOV PRE TYP CACHE V KONFIGURAKU
		$mdl_C{'T_CACHE'}=$mdl_C{'-addon'}."-".$mdl_C{'-name'}."-".$mdl_C{'-cache_id'};
		
		my $cache;
		my $cache_parallel;
		my $cache_key = 'C3|tplmdl|'.$TOM::P_uuid.':'.$tom::Hm.":".$cache_domain.":pub:".$mdl_C{'-digest'};
		
		if ($Redis)
		{
			# get from Redis
			$cache={
				@{$Redis->hgetall($cache_key)}
			};
			Ext::Redis::_uncompress(\$cache->{'return_data'});
			$cache->{'return_data'}=$json->decode($cache->{'return_data'})
				if $cache->{'return_data'};
			$cache->{'return_data'}={} unless $cache->{'return_data'};
			$cache_parallel=$cache->{'bhash'} || $cache->{'etime'};
		}
		
		if ($cache)
		{
			$mdl_C{'-cache_from'}=$cache->{'time_from'};
			$mdl_C{'-cache_duration'}=$cache->{'time_duration'};
			$file_data=$cache->{'body'};
			Ext::Redis::_uncompress(\$file_data);
			$return_code=$cache->{'return_code'};
			if (ref($cache->{'return_data'}) eq "HASH")
			{
				%return_data=%{$cache->{'return_data'}};
			}
			
			$return_code=1 if $return_code<1; # osetrenie pre stare caches
		}
		
		# VYPOCITAM STARIE CACHE
		$mdl_C{'-cache_old'}=$tom::time_current-$mdl_C{'-cache_from'};
		
		# definujem dlzku cache priamo z typecka
		if ($mdl_C{'-cache'}=~/^(\d+)D$/i)
		{
			$mdl_C{'-cache_time'}=86400*$1;
		}
		elsif ($mdl_C{'-cache'}=~/^(\d+)H$/i)
		{
			$mdl_C{'-cache_time'}=3600*$1;
		}
		elsif ($mdl_C{'-cache'}=~/^(\d+)M$/i)
		{
			$mdl_C{'-cache_time'}=60*$1;
		}
		elsif ($mdl_C{'-cache'}=~/^(\d+)S$/i)
		{
			$mdl_C{'-cache_time'}=$1;
		}
		else
		{
			$mdl_C{'-cache_time'}=$mdl_C{'-cache'};
		}
		
		# config object
		$CACHE{$mdl_C{'T_CACHE'}}{'-cache_time'}=$mdl_C{'-cache_time'};
		
		# v tomto requeste je cache ignorovana
		if (!$main::cache)
		{
			main::_log("skracujem duration cache (request na recache)");
			$mdl_C{'-cache_duration'}=$mdl_C{'-cache_old'};
		}
		
		if (!$mdl_C{'-cache_from'})
		{
			main::_log("cache info digest:$mdl_C{-digest} missing parallel=".$cache_parallel) if $debug;
		}
		else
		{
			main::_log("cache info digest:$mdl_C{-digest} old:".int($mdl_C{'-cache_old'})."S duration:$mdl_C{-cache_duration}S from:".int($mdl_C{-cache_from})."S to:".int($mdl_C{-cache_to})."S parallel=".$cache_parallel) if $debug;
		}
		
		if(
			# AK JE STARIE CACHE MENSIE AKO VYZADOVANE STARIE
			#($mdl_C{-cache_old}<$CACHE{$mdl_C{T_CACHE}}{-cache_time})
			($mdl_C{'-cache_old'} < $mdl_C{'-cache_duration'})
			# ALEBO
			||
			(
				# tento browser ma zakazane recachovanie
				# pokial cache existuje v databaze
				# TO V PREKLADE DO SLOVENCINY ZNAMENA ZE ROBOT
				# AK NAJDE NAJAKY STARY CACHE, NEZAUJIMA HO CI JE AKTUALNY,
				# STACI MU ZE CACHE PROSTE MA A TAK HO POUZIJE
				($TOM::Net::HTTP::UserAgent::table[$main::UserAgent]{'recache_disable'})
				&&($mdl_C{'-cache_from'})
			)
			||
			(
				# ak iny proces sa snazi prave naplnit tuto cache
				# pouzijem proste tu cache ktoru mam
				$cache_parallel == 1 && $mdl_C{'-cache_from'}
			)
		)
		# TAK TUTO CACHE POUZIJEM
		{
			main::_log("using cache domain:$cache_domain from:$mdl_C{'-cache_from'}s old:".int($mdl_C{'-cache_old'})."s ".
				"max:".$CACHE{$mdl_C{'T_CACHE'}}{'-cache_time'}."s ".
				"est:".int($CACHE{$mdl_C{'T_CACHE'}}{'-cache_time'}-$mdl_C{'-cache_old'})."s ".
				"hits:".$cache->{'hits'}." ".
				"parallel?:".$cache_parallel
				);
			
			if ($TOM::DEBUG_cache)
			{
				my $hits;
				if ($Redis)
				{
#					my $date_str=$tom::Fyear.'-'.$tom::Fmon.'-'.$tom::Fmday.' '.$tom::Fhour.':'.$tom::Fmin;
#					$Redis->hincrby('C3|counters|mdl_cache|'.$date_str,'hit',1,sub{});
#					$Redis->expire('C3|counters|mdl_cache|'.$date_str,3600,sub{});
					$Redis->hincrby($cache_key,'hits',1,sub{});
				}
			}
			
			if (!$mdl_C{'-stdout_dummy'})
			{
				$main::H->r_("<!TMP-".$mdl_C{-TMP}."!>",$file_data);
			}
			
			
			
			$t->close();
			return $return_code;
		}
		else # CACHE JE STARY, SPRACUJEM DATA O CACHE
		{
			if ($mdl_C{'-cache_old'} eq $tom::time_current)
			{
				# tato cache prebehla cez destroy()
				#main::_log("cache $mdl_C{N_CACHE} neexistuje, preslo destroy()",1,"pub.cache");
			}
			else
			{
				# cache je stary, spracujem debug data o cache
				# kedze je cache system len v databaze, tak toto robit nemusim
				# fcia je prazdna
#				Tomahawk::debug::cache_conf_opt();
			}
		}
	} #KONIEC OBLUSHY CACHE
	
	
	if ($mdl_C{'-tpl_level'})
	{
		if ($mdl_C{'-tpl_level'} eq "global"){$mdl_C{'-tpl_global'} = 1;}
		elsif ($mdl_C{'-tpl_level'} eq "master"){$mdl_C{'-tpl_global'} = 2;}
		elsif ($mdl_C{'-tpl_level'} eq "local"){$mdl_C{'-tpl_global'} = 0;}
	}
	
	if ($mdl_C{'-level'})
	{
		if ($mdl_C{'-level'} eq "global"){$mdl_C{'-global'} = 1;}
		elsif ($mdl_C{'-level'} eq "master"){$mdl_C{'-global'} = 2;}
		elsif ($mdl_C{'-level'} eq "local"){$mdl_C{'-global'} = 0;}
		
		# -level has higher priority than -tpl_level and -tpl_global
		$mdl_C{'-tpl_global'} = $mdl_C{'-global'};
	}
	
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
		Time::HiRes::alarm($mdl_C{'-ALRM'});
		
		# reset variables
		undef $Tomahawk::module::TPL;
		
		my $t_execute=track TOM::Debug("exec",'timer'=>1);
		
		# gettpl
		Tomahawk::GetTpl();
		
		if ($Tomahawk::module::TPL)
		{
			my $t_tt=track TOM::Debug("tt:process",'timer'=>1);
			# basic environment variables are attached in TOM::Template::process()
			# module variables
			$Tomahawk::module::TPL->{'variables'}->{'module'}={
				'name'=> $mdl_C{'-name'},
				'version'=> $mdl_C{'-version'},
				'addon'=> $mdl_C{'-addon'},
				'filename' => $mdl_C{'P_MODULE'}
			};
			# add all module input variables
			%{$Tomahawk::module::TPL->{'variables'}->{'module'}->{'env'}}=(%mdl_C,%mdl_env);
			
			$Tomahawk::module::TPL->process() || do
			{
				$t_tt->close();
#				$t_execute->close();
				$tom::ERR=$Tomahawk::module::TPL->{'error'};
				TOM::Error::module
				(
					'-TMP' => $mdl_C{'-TMP'},
					'-MODULE' => "[TPLMDL::".$mdl_C{'-addon'}."-".$mdl_C{'-name'}."]",
					'-ERROR' => $tom::ERR,
				);
				return undef;
			};
			
			$Tomahawk::module::XSGN{'TMP'}=$Tomahawk::module::TPL->{'output'};
			$t_tt->close();
		}
		else
		{
#			$t_execute->close();
			Time::HiRes::alarm(0);
			TOM::Error::module
			(
				'-TMP' => $mdl_C{'-TMP'},
				'-MODULE' => "[TPLMDL::".$mdl_C{'-addon'}."-".$mdl_C{'-name'}."]",
				'-ERROR' => "TPL not defined or not found",
			);
			return undef;
		}
		$t_execute->close();
		
#		if ($return_code)
#		{
			if ($mdl_C{'-stdout'} && $main::stdout)
			{
				print $Tomahawk::module::XSGN{'TMP'}."\n";
			}
			
			if (($Tomahawk::module::XSGN{'TMP'})
				&&(not $main::H->r_("<!TMP-".$mdl_C{'-TMP'}."!>",$Tomahawk::module::XSGN{'TMP'})))
			{
				Time::HiRes::alarm(0);
				TOM::Error::module
				(
					'-TMP' => $mdl_C{'-TMP'},
					'-MODULE' => "[TPLMDL::".$mdl_C{'-addong'}."-".$mdl_C{'-name'}."]",
					'-ERROR' => "Unknown TMP-".$mdl_C{'-TMP'},
				);
				return undef;
			};
			
			
			# IDEME NACACHOVAT
			if ((exists $mdl_C{'-cache'})&&($TOM::CACHE))
			{
				my $cache_key = 'C3|tplmdl|'.$TOM::P_uuid.':'.$tom::Hm.":".$cache_domain.":pub:".$mdl_C{'-digest'};
				my $ID_config=$CACHE{$mdl_C{'T_CACHE'}}{'-ID_config'};
				
				if ($Redis)
				{
					# save to Redis
					$Redis->hmset($cache_key,
						'body' => Ext::Redis::_compress(\$Tomahawk::module::XSGN{'TMP'}),
#						'return_data' => $json->encode(\%return_data),
						'return_code' => $return_code,
						'time_from' => Time::HiRes::time(),
						'time_duration' => $CACHE{$mdl_C{'T_CACHE'}}{'-cache_time'},
						'execute_time_duration' => $t_execute->{'time'}{'duration'},
						'execute_time_user' => $t_execute->{'time'}{'user'}{'duration'},
						'hits' => 0,
						sub {} # in pipeline
					);
					$Redis->hdel($cache_key,'etime',sub {}); # remove execution time
					$Redis->hdel($cache_key,'bhash',sub {}); # remove bhash
					$Redis->expire($cache_key,
						$CACHE{$mdl_C{'T_CACHE'}}{'-cache_time'} + 
						int($CACHE{$mdl_C{'T_CACHE'}}{'-cache_time'}/2),
						sub {} # in pipeline
					); # set expiration time
					main::_log("save cache object '$cache_key'");
					
					if ($TOM::DEBUG_cache)
					{
#						my $date_str=$tom::Fyear.'-'.$tom::Fmon.'-'.$tom::Fmday.' '.$tom::Fhour.':'.$tom::Fmin;
#						$Redis->hincrby('C3|counters|mdl_cache|'.$date_str,'crt',1,sub{});
#						$Redis->expire('C3|counters|mdl_cache|'.$date_str,3600,sub{});
						
						my $mdl_cache_type='C3|debug|tpl_cache|'.$tom::H.':'.$mdl_C{'T_CACHE'};
						$Redis->sadd('C3|debug|mdl_caches', $mdl_cache_type,sub{});
						$Redis->sadd('C3|debug|mdl_caches|'.$tom::H, $mdl_cache_type,sub{});
						$Redis->expire('C3|debug|mdl_caches|'.$tom::H, (86400*30),sub{});
						$Redis->sadd($mdl_cache_type,$cache_key,sub{});
						$Redis->expire($mdl_cache_type,(86400*30),sub{});
					}
				}
				
			}
			
			
			
#		}
#		else # chyba o ktorej upozorni samotny program vratenim undef :)
#		{
#			TOM::Error::module(
#				'-TMP' => $mdl_C{'-TMP'},
#				'-MODULE' => "[TPLMDL::".$mdl_C{'-addon'}."-".$mdl_C{'-name'}."]",
#				'-ERROR' => $tom::ERR,
#				'-PLUS' => $tom::ERR_plus,
#			)
#		};
		Time::HiRes::alarm(0);
	};
	Time::HiRes::alarm(0);
	
	if ($@)
	{
		TOM::Error::module
		(
			'-TMP' => $mdl_C{'-TMP'},
			'-MODULE' => "[TPLMDL::".$mdl_C{'-addon'}."-".$mdl_C{'-name'}."]",
			'-ERROR' => $@,
		);# unless $mdl_C{-noerror_run};
	};
	
	$t->close();
	
	return $return_code,%return_data;
}




=head2 GetXSGN()

Used in modules to load xsgn file

 sub execute
 {
  my %env=@_;
  Tomahawk::GetXSGN('-convertvars'=>1) || return undef;
  return 1;
 }

=cut

sub GetXSGN
{
	my %env=@_;
	
	main::_log("loading XSGN -addon='$mdl_C{-addon}' -name='$mdl_C{-name}' -version='$mdl_C{-version}' -xsgn='$mdl_C{-xsgn}'");
	$mdl_C{'P_XSGN'}=$mdl_C{'-addon_name'}."-".$mdl_C{'-name'}.".".$mdl_C{'-version'}.".".$mdl_C{'-xsgn'}.".xsgn";
#	main::_log("P_XSGN='$mdl_C{P_XSGN}'");
 
	if (!$mdl_C{'-name'})
	{
		main::_log("sorry, I am not in module, can't import design",1);
		$tom::ERR="Can't import design, I am not in module";
		return undef;
	}
	
#  MDL  MSTR XSGN =
#  G    0    0    0
#  -G   0    1    1+
#  G    0    2    0
#  G    1    0    0
#  -G   1    1    1+
#  G    1    2    2+
#  ---
#  M   0    0    0
#  M   0    1    1
#  M   0    2    0
#  M   1    0    0
#  M   1    1    1
#  M   1    2    0
#  ---
#  L   0    0    0
#  L   0    1    0
#  L   0    2    0
#  L   1    0    0
#  L   1    1    0
#  L   1    2    0

	# if module is local, xsgn file can be only local
	if (!$mdl_C{-global})
	{
		$mdl_C{-xsgn_global}=0;
		my $addon_path=$tom::P."/_addons/".$mdl_C{'-addon_type'}."/".$mdl_C{'-addon_name'}."/_mdl/".$mdl_C{P_XSGN};
#		main::_log("addon_path='$addon_path'");
		if (-e $addon_path){$mdl_C{P_XSGN}=$addon_path;}
		else {$mdl_C{P_XSGN}=$tom::P."/_mdl/".$mdl_C{P_XSGN};}
	}
	# if module is global and xsgn file is global
	elsif ($mdl_C{-xsgn_global}==1)
	{
		$mdl_C{-xsgn_global}=1;
		my $addon_path=$TOM::P."/_addons/".$mdl_C{'-addon_type'}."/".$mdl_C{'-addon_name'}."/_mdl/".$mdl_C{P_XSGN};
		# find in overlays
		foreach my $item(@TOM::Overlays::item)
		{
			if ($item=~/^\//)
			{
				my $file=
					$item
					.'/_addons/App/'.$mdl_C{'-category'}.'/_mdl/'
					.$mdl_C{'P_XSGN'};
				if (-e $file){$addon_path=$file;last;}
			}
			else
			{
				my $file=
					$TOM::P.'/_overlays/'.$item
					.'/_addons/App/'.$mdl_C{'-category'}.'/_mdl/'
					.$mdl_C{'P_XSGN'};
				if (-e $file){$addon_path=$file;last;}
			}
		}
#		main::_log("addon_path='$addon_path'");
		if (-e $addon_path){$mdl_C{P_XSGN}=$addon_path;}
		else {$mdl_C{P_XSGN}=$TOM::P."/_mdl/".$mdl_C{'-addon_name'}."/".$mdl_C{P_XSGN}}
	}
	# if module is in master/global and i wish to load xsgn file master
	elsif (($tom::Pm)&&($mdl_C{-xsgn_global}==2))
	{
		$mdl_C{-xsgn_global}=2;
		my $addon_path=$tom::Pm."/_addons/".$mdl_C{'-addon_type'}."/".$mdl_C{'-addon_name'}."/_mdl/".$mdl_C{P_XSGN};
#		main::_log("addon_path='$addon_path'");
		if (-e $addon_path){$mdl_C{P_XSGN}=$addon_path;}
		else {$mdl_C{P_XSGN}=$tom::Pm."/_mdl/".$mdl_C{P_XSGN};}
	}
	else
	{
		$mdl_C{-xsgn_global}=0;
		my $addon_path=$tom::P."/_addons/".$mdl_C{'-addon_type'}."/".$mdl_C{'-addon_name'}."/_mdl/".$mdl_C{P_XSGN};
#		main::_log("addon_path='$addon_path'");
		if (-e $addon_path){$mdl_C{P_XSGN}=$addon_path;}
		else {$mdl_C{P_XSGN}=$tom::P."/_mdl/".$mdl_C{P_XSGN};}
	}
	
#	main::_log("P_XSGN='$mdl_C{P_XSGN}'");
	
	# open file with xsgn
	open (HND,"<".$mdl_C{P_XSGN}) || do
	{
		main::_log("can't open file '$mdl_C{P_XSGN}' '$!'",1);
		$tom::ERR= "Can't import design \"" .
			$mdl_C{-xsgn} . "\" (" . $mdl_C{-xsgn_global} . "/" . $mdl_C{-global} . "/" . $mdl_C{'-addon'} . "-" . $mdl_C{-name} . "." . $mdl_C{-version} . "." . $mdl_C{-xsgn} . ".xsgn".") ($mdl_C{P_XSGN}) - " . $!;
		return undef;
	};
	
	my $file_data;my $file_line;
	while ($file_line=<HND>){$file_data.=$file_line;}
	($file_data)=$file_data=~/<XML_DESIGN_DEFINITION.*?>(.*)<\/XML_DESIGN_DEFINITION>/s;
	
	close(HND);
	
	TOM::Utils::vars::replace($file_data);# if $env{'-convertvars'};
	
	while ($file_data=~s|<DEFINITION id="(.*?)">[\n\r]?(.*?)[\n\r]?</DEFINITION>||s)
	{
		my $var=$1;
		$Tomahawk::module::XSGN{$var}=$2;
	}
	
	return 1;
}



=head2 GetTpl()

Used in modules to load tpl file

 sub execute
 {
    my %env=@_;
    Tomahawk::GetTpl() || return undef;
    return 1;
 }

=cut

sub GetTpl
{
	my %env=@_;
	
	if ($env{'env'})
	{
		%mdl_env=%{$env{'env'}};
	}
	
	$mdl_C{'-tpl'}="default" unless $mdl_C{'-tpl'};
	main::_log("GetTpl -addon='$mdl_C{'-addon'}' -name='$mdl_C{'-name'}' -version='$mdl_C{'-version'}' -tpl='$mdl_C{'-tpl'}'");
	$mdl_C{'P_TPL'}=$mdl_C{'-addon_name'}."-".$mdl_C{'-name'}.".".$mdl_C{'-version'}.".".$mdl_C{'-tpl'}.".tpl";
	
	if (!$mdl_C{'-name'})
	{
		main::_log("sorry, I am not in module, can't import tpl",1);
		$tom::ERR="Can't import tpl, I am not in module";
		return undef;
	}
	
	# if module is local, tpl file can be only local
	if (!$mdl_C{'-global'})
	{
		$mdl_C{'-tpl_global'}=0;
		my $addon_path=$tom::P."/_addons/".$mdl_C{'-addon_type'}."/".$mdl_C{'-addon_name'}."/_mdl/".$mdl_C{'P_TPL'};
		if (-e $addon_path){$mdl_C{'P_TPL'}=$addon_path;}
		else {$mdl_C{'P_TPL'}=$tom::P."/_mdl/".$mdl_C{'P_TPL'};}
	}
	# if module is global and tpl file is global
	elsif ($mdl_C{'-tpl_global'}==1)
	{
		$mdl_C{'-tpl_global'}=1;
		my $addon_path=$TOM::P."/_addons/".$mdl_C{'-addon_type'}."/".$mdl_C{'-addon_name'}."/_mdl/".$mdl_C{'P_TPL'};
		# find in overlays
		foreach my $item(@TOM::Overlays::item)
		{
			if ($item=~/^\//)
			{
				my $file=
					$item
					.'/_addons/'.$mdl_C{'-addon_type'}.'/'.$mdl_C{'-addon_name'}.'/_mdl/'
					.$mdl_C{'P_TPL'};
				if (-e $file){$addon_path=$file;last;}
			}
			else
			{
				my $file=
					$TOM::P.'/_overlays/'.$item
					.'/_addons/'.$mdl_C{'-addon_type'}.'/'.$mdl_C{'-addon_name'}.'/_mdl/'
					.$mdl_C{'P_TPL'};
				if (-e $file){$addon_path=$file;last;}
			}
		}
		if (-e $addon_path){$mdl_C{'P_TPL'}=$addon_path;}
		else {$mdl_C{'P_TPL'}=$TOM::P."/_mdl/".$mdl_C{'-addon_name'}."/".$mdl_C{'P_TPL'}}
	}
	# if module is in master/global and i wish to load tpl file master
	elsif (($tom::Pm)&&($mdl_C{'-tpl_global'}==2))
	{
		$mdl_C{'-tpl_global'}=2;
		my $addon_path=$tom::Pm."/_addons/".$mdl_C{'-addon_type'}."/".$mdl_C{'-addon_name'}."/_mdl/".$mdl_C{'P_TPL'};
		if (-e $addon_path){$mdl_C{'P_TPL'}=$addon_path;}
		else {$mdl_C{'P_TPL'}=$tom::Pm."/_mdl/".$mdl_C{'P_TPL'};}
	}
	else
	{
		$mdl_C{'-tpl_global'}=0;
		my $addon_path=$tom::P."/_addons/".$mdl_C{'-addon_type'}."/".$mdl_C{'-addon_name'}."/_mdl/".$mdl_C{'P_TPL'};
		if (-e $addon_path){$mdl_C{'P_TPL'}=$addon_path;}
		else {$mdl_C{'P_TPL'}=$tom::P."/_mdl/".$mdl_C{'P_TPL'};}
	}
	
	if (! -e $mdl_C{'P_TPL'})
	{
		main::_log("tpl file '$mdl_C{'P_TPL'}' not exists",1);
		return undef;
	}
	
	$Tomahawk::module::TPL=new TOM::Template(
		'level' => "auto",
		'name' => "default",
		'content-type' => $TOM::Document::type,
		'location' => $mdl_C{'P_TPL'},
		'tt' => 1,
		'lng' => $mdl_C{'-xlng'}
	) || return undef;
	
	if (!$Tomahawk::module::TPL->{'entity'}->{'main'})
	{
		main::_log("main entity not defined",3);
	}
	
	return 1;
}



=head2 GetXLNG()

Used in modules to load xlng file

 sub execute
 {
  my %env=@_;
  Tomahawk::GetXLNG() || return undef;
  return 1;
 }

=cut

sub GetXLNG
{
	my %env=@_;
	# HLADAME LANGUAGE
	$mdl_C{P_XLNG}=$mdl_C{'-addon_name'}."-".$mdl_C{-name}.".".$mdl_C{-version};
	$mdl_C{P_XLNG}.=".".$mdl_C{-xsgn} if $mdl_C{-xlng_xsgn};
	$mdl_C{P_XLNG}.=".xlng";
	
	
	if (!$mdl_C{-global}) # ak je modul lokalny, tak moze byt design len lokalny
	{
		$mdl_C{-xlng_global}=0;
		my $addon_path=$tom::P."/_addons/".$mdl_C{'-addon_type'}."/".$mdl_C{'-addon_name'}."/_mdl/".$mdl_C{P_XLNG};
		if (-e $addon_path){$mdl_C{P_XLNG}=$addon_path}
		else {$mdl_C{P_XLNG}=$tom::P."/_mdl/".$mdl_C{P_XLNG};}
	}
	# ak je modul global, a chcem design global, tak ho dostanem :))
	elsif ($mdl_C{-xlng_global}==1)
	{
		my $addon_path=$TOM::P."/_addons/".$mdl_C{'-addon_type'}."/".$mdl_C{'-addon_name'}."/_mdl/".$mdl_C{P_XLNG};
		# find in overlays
		foreach my $item(@TOM::Overlays::item)
		{
			if ($item=~/^\//)
			{
				my $file=
					$TOM::P.'/_overlays/'.$item
					.'/_addons/'.$mdl_C{'-addon_type'}.'/'.$mdl_C{'-addon_name'}.'/_mdl/'
					.$mdl_C{'P_XSGN'};
				if (-e $file){$addon_path=$file;last;}
			}
			else
			{
				my $file=
					$item
					.'/_addons/'.$mdl_C{'-addon_type'}.'/'.$mdl_C{'-addon_name'}.'/_mdl/'
					.$mdl_C{'P_XSGN'};
				if (-e $file){$addon_path=$file;last;}
			}
		}
		if (-e $addon_path){$mdl_C{P_XLNG}=$addon_path}
		else {$mdl_C{P_XLNG}=$TOM::P."/_mdl/".$mdl_C{'-addon_name'}."/".$mdl_C{P_XLNG}};
	}
	# chcem mastera, mam mastera a modul je global, alebo master
	elsif (($tom::Pm)&&($mdl_C{-xlng_global}==2))
	{
		my $addon_path=$tom::Pm."/_addons/".$mdl_C{'addon_type'}."/".$mdl_C{'-addon_name'}."/_mdl/".$mdl_C{P_XLNG};
		if (-e $addon_path){$mdl_C{P_XLNG}=$addon_path}
		else {$mdl_C{P_XLNG}=$tom::Pm."/_mdl/".$mdl_C{P_XLNG}};
	}
	else
	{
		$mdl_C{-xlng_global}=0;
		my $addon_path=$tom::P."/_addons/".$mdl_C{'-addon_type'}."/".$mdl_C{'-addon_name'}."/_mdl/".$mdl_C{P_XLNG};
		if (-e $addon_path){$mdl_C{P_XLNG}=$addon_path}
		else {$mdl_C{P_XLNG}=$tom::P."/_mdl/".$mdl_C{P_XLNG}};
	}
	
	
	# load design file
	open (HND,"<".$mdl_C{P_XLNG}) || do
	{$tom::ERR="Cannot open language file ".$mdl_C{-xlng}."/".$mdl_C{-xlng_global}."-".$mdl_C{P_XLNG};return undef;};
	my $file_data;my $file_line;
	while ($file_line=<HND>){$file_data.=$file_line;}
	($file_line,$file_data)=$file_data=~/<XML_LANGUAGE_DEFINITION lngs="(.*?)">(.*)<\/XML_LANGUAGE_DEFINITION>/s;
	
	# check language
	$file_line=",".$file_line.",";
	if (not $file_line=~/,$mdl_env{lng},/)
	{
		if ($TOM::LNG_search)
		{
			if ($file_line=~/,$tom::lng,/){$mdl_env{lng}=$tom::lng;}
			elsif ($file_line=~/,$tom::LNG,/){$mdl_env{lng}=$tom::LNG;}
			elsif ($file_line=~/,$TOM::LNG,/){$mdl_env{lng}=$TOM::LNG;}
			else{$tom::ERR="Cannot import language code ".$mdl_env{lng}.",".$tom::lng.",".$tom::LNG.",".$TOM::LNG;return undef}
		}
		else {$tom::ERR="Cannot import language code ".$mdl_env{lng};return undef}
	}
	
	TOM::Utils::vars::replace($file_data) if $env{'-convertvars'};
	
	while ($file_data=~s|<VALUE lng="$mdl_env{lng}" id="(.*?)">(.*?)</VALUE>||s){$Tomahawk::module::XLNG{$1}=$2;}
	
	return $mdl_env{lng};
}


=head2 XLNGtoXSGN()



=cut

sub XLNGtoXSGN
{
 foreach my $ref0(keys %Tomahawk::module::XLNG)
 {foreach my $ref1(keys %Tomahawk::module::XSGN)
  {$Tomahawk::module::XSGN{$ref1}=~s|<%XLNG-$ref0%>|$Tomahawk::module::XLNG{$ref0}|g;}}
 return 1;
}

=head2 XLNGtoVARS()



=cut

sub XLNGtoVARS
{
 my @ref=@_;
 for(0..@ref){foreach my $ref0(%Tomahawk::module::XLNG){$ref[$_]=~s|<%XLNG-$ref0%>|$Tomahawk::module::XLNG{$ref0}|g;}}
 return @ref;
}


=head2 shutdown()



=cut

sub shutdown
{
	exit(0);
}



1;
