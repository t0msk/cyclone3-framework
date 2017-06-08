#!/bin/perl
package App::301::session;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

use POSIX;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our $debug=0;
our $serialize=1;
our $IDsession;
our $IDuser;
our $session_save;
our $performance=1;

sub TIEHASH
{
	my $class = shift;
	my ($package, $filename, $line) = caller;
	main::_log("TIE-TIEHASH a301::session from $filename:$line") if $debug;
	$IDsession=$main::USRM{'ID_session'};
	$IDuser=$main::USRM{'ID_user'};
	$session_save=$main::USRM{'session_save'};
	return bless {}, $class;
}

sub DESTROY
{
	my $self = shift;
	my ($package, $filename, $line) = caller;
	
	main::_log("TIE-DESTROY a301::session from $filename:$line",3,"a301") if $debug;
	
	# pokial nemam jednoznacny identifikator danej session je
	# zbytocne nieco serializovat a ukladat to, ked sa to vlastne
	# nikam neulozi
	return undef unless $IDsession;
	if (!$App::301::session::serialize)
	{
		# nebudem serializovat do databazy ak to nemam dovolene
		# toto moze nastat len v pripade ked je object poskodeny
		# a serializovat by sa nemal, takze to dost agresivne zalogujem
#		main::_log("TIE-DESTROY trying to serialize unavailable object from $filename:$line",4,"pub.err");
		main::_log("TIE-DESTROY trying to serialize unavailable object from $filename:$line",1);
		return undef;
	}
	
		main::_log("TIE-DESTROY a301::session='$IDsession'",3,"a301") if $debug;
		my $cvml=CVML::structure::serialize(%{$self});
		
		return undef if (($cvml eq $session_save) && $performance);
		
		main::_log("TIE-string:='$cvml'",3,"a301") if $debug;
		
		my %sth0=TOM::Database::SQL::execute(qq{
			UPDATE
				TOM.a301_user_online
			SET
				session=?
			WHERE
				ID_session=?
				AND ID_user=?
			LIMIT 1
		},'quiet'=>1,'bind'=>[$cvml,$IDsession,$IDuser]);
		main::_log("TIE-serialized in $sth0{'rows'} a301_user_online rows",3,"a301") if ($debug && $sth0{'rows'});
		
		# changes user session
		$main::COOKIES{'usrmevent'}=$tom::Tyear."-".$tom::Fmom."-".$tom::Fmday." ".$tom::Fhour.":".$tom::Fmin.":".$tom::Fsec;
		
	return undef;
}

sub FETCH
{
	my ($self,$key) = @_;
	return $self->{$key};
}

sub DELETE
{
	my ($self,$key) = @_;
	delete $self->{$key};
	return 1;
}

sub STORE
{
	my ($self,$key,$value)=@_;
	my ($package, $filename, $line) = caller;
	main::_log("TIE-STORE a301::session change key '$key' to value '$value' from $filename:$line") if $debug;
	$self->{$key}=$value;
}

sub CLEAR
{
	my $self=shift;
	%$self=();
}

sub FIRSTKEY
{
	my $self=shift;
	scalar keys %$self;
	return scalar each %$self;
}

sub NEXTKEY
{
	my $self=shift;
	return scalar each %$self;
}


# proces request in pub
sub process
{
	return 1 if $main::USRM{'logged'};
	
	if ($main::COOKIES{'_ID_user'} && (not $main::COOKIES{'_ID_user'}=~/^[a-zA-Z0-9]{8}$/))
	{
		# check for invalid ID_user
		return 1;
	}
	
	my $t=track TOM::Debug(__PACKAGE__."::process()",'timer'=>1);
	
#	my $debug=0;
#	return 1;
	
	my $memcached=0;
	
=head1
	G - generated new user
	R - registered new user
	L - logged old user
	I - incoming old user
=cut
	
	main::_log("ID_user=$main::COOKIES{'_ID_user'} ID_session='$main::COOKIES{'_ID_session'}'");
#	undef $main::COOKIES{'_lh'};
	
	my %env=@_;
	
	my $max_cnt=10;
	
	if ($TOM::Net::HTTP::UserAgent::table[$main::UserAgent]{'USRM_disable'})
	{
		main::_log("this is robot, deleting USRM from COOKIES, deleting USRM");
		%main::USRM=();
		undef $main::COOKIES{'_ID_user'} if $main::COOKIES{'_ID_user'};
		undef $main::COOKIES{'_ID_session'} if $main::COOKIES{'_ID_session'};
		$t->close();
		return 1;
	}
	
	main::_log("USRM configured for hostname='$tom::H_cookie' in domain='$tom::H'");
 
	# toto je priznak toho ze pouzivam USRM, pokial je niekde v logu
	# prazdne miesto, znamena to ze nebezi USRM
	$main::USRM{'logged'}="N";
	
	my $loc;
 
	# DAVAT SI POZOR NA TO ZE DATA
	# $main::USRM{reqtime}
	# $main::USRM{host_sub}
	# $main::USRM{rqs}
	# sa netykaju sucasneho requestu ale toho posledneho
	
	#foreach (sort keys %main::COOKIES){main::_log("C:$_=".$main::COOKIES{$_});}
	#foreach (sort keys %main::USRM){if ($_ ne "xdata"){main::_log("U:$_=".$main::USRM{$_})}}
	
	#if ((keys %main::COOKIES) != 0)
	#if (((keys %main::COOKIES) != 0) && ($main::FORM{cookies} ne "GET"))
	if ($main::COOKIES{'_lt'})
	{
		main::_log("here is standard cookies supported");
		if ($main::COOKIES{'_ID_user'}) # MAM HASH? (ak ano, tak som zjavne zucastneny v USRM)
		{
			
			# check if user is in memcached
			
			if ($TOM::CACHE_memcached && $memcached)
			{
				my $cache=$Ext::CacheMemcache::cache->get(
					'namespace' => "a301_online",
					'key' => $tom::H_cookie.':'.$main::COOKIES{_ID_user}
				);
				%main::USRM=%{$cache} if $cache;
			}
			# or check if the user is in online table
			if (!$main::USRM{'ID_user'})
			{
				my $sql=qq{
					SELECT
						user_online.ID_user,
						user_online.ID_session,
						user_online.logged,
						user_online.datetime_login,
						user_online.datetime_request,
						user_online.requests,
						user_online.IP,
						user_online.domain,
						user_online.user_agent,
						user_online.cookies,
						user_online.session
					FROM
						`TOM`.`a301_user_online` AS user_online
					WHERE
						user_online.ID_user=?
					LIMIT 1
				};
				my %sth0=TOM::Database::SQL::execute($sql,'bind'=>[$main::COOKIES{'_ID_user'}],'quiet'=>1,'-slave'=>0);
				%main::USRM=$sth0{'sth'}->fetchhash();
				
				my %sth0=TOM::Database::SQL::execute(qq{
					SELECT
						user.secure_hash,
						user.login,
						user.autolog,
						user.hostname,
						user.datetime_register,
						user.datetime_last_login,
						user.requests_all,
						user.email,
						user.email_verified
					FROM
						`TOM`.`a301_user` AS user
					WHERE
						user.ID_user=?
					LIMIT 1
				},'bind'=>[$main::COOKIES{'_ID_user'}],'quiet'=>1,'-slave'=>0);
				my %db0_line=$sth0{'sth'}->fetchhash();
				foreach(keys %db0_line)
				{
					$main::USRM{$_}=$db0_line{$_};
				}
				
			}
			if ($main::USRM{'ID_user'}) # yes, user is online
			{
				main::_log("user '$main::COOKIES{_ID_user}' is online");
				$main::USRM{'ID_user'}=$main::COOKIES{'_ID_user'} unless $main::USRM{'ID_user'};
				
				# set last changed state of user into cookies
				$main::COOKIES{'usrmevent'}=$main::USRM{'datetime_login'}
					if $main::COOKIES{'usrmevent'} lt $main::USRM{'datetime_login'};
				
				# fix unicode in session
				utf8::decode($main::USRM{'session'}) unless utf8::is_utf8($main::USRM{'session'});
				
				# overenie pravosti prihlasenia
				my @ref=($main::USRM{'IP'},$main::ENV{'REMOTE_ADDR'});
				$ref[0]=~s|^(.*)\.(\d+)$|$1|;
				$ref[1]=~s|^(.*)\.(\d+)$|$1|;
				if (
					($main::USRM{'ID_session'} eq $main::COOKIES{'_ID_session'})
#					&&($ref[0] eq $ref[1])
#					&&($main::USRM{HTTP_USER_AGENT} eq $main::ENV{HTTP_USER_AGENT})
				)
				{
					
					main::_log("verified '$main::USRM{'ID_session'}' '$main::USRM{'IP'}'='$ref[0].*'");
					
					# naplnim obsah USRM{cookies}
					my %hash;foreach (sort keys %main::COOKIES){$_=~/^_/ && do {$hash{$_}=$main::COOKIES{$_};next}};
					$main::USRM{'cookies'}=CVML::structure::serialize(%hash);
					
					if ($main::USRM{'logged'} eq "Y")
					{
						my %sth0=TOM::Database::SQL::execute(qq{
							SELECT
								*
							FROM
								$App::301::db_name.a301_user_profile
							WHERE
								ID_entity=?
							LIMIT 1
						},
							'log'=>0,
							'quiet'=>1,
							'bind'=>[$main::USRM{'ID_user'}],
							'-cache' => 3600,
							'-cache_changetime' => App::020::SQL::functions::_get_changetime({
								'db_name' => $App::301::db_name,
								'tb_name' => 'a301_user_profile',
								'ID_entity' => $main::USRM{'ID_user'}
							})
						);
						my %profile=$sth0{'sth'}->fetchhash();
						%{$main::USRM{'profile'}}=%profile;
					}
					
					if ($TOM::CACHE_memcached)
					{
						$Ext::CacheMemcache::cache->set(
							'namespace' => "a301_online",
							'key' => $tom::H_cookie.':'.$main::COOKIES{_ID_user},
							'value' => {
								%main::USRM,
								'domain' => $tom::H,
								'datetime_request' => $main::time_current,
								'cookies' => $main::USRM{'cookies'},
								'user_agent' => $main::ENV{'HTTP_USER_AGENT'},
								'requests' => $main::USRM{'requests'}+1,
								'status' => 'Y'
							},
							'expiration' => '1H'
						);
					}
					
					if (!$TOM::CACHE_memcached || !$memcached)
					{
						my $plus=0;
							$plus=1 if $pub::DOC=~/HTML/;
						
						# UPDATE online
						TOM::Database::SQL::execute(qq{
							UPDATE
								TOM.a301_user_online
							SET
								domain=?,
								datetime_request=FROM_UNIXTIME($main::time_current),
								cookies=?,
								user_agent=?,
								_ga=?,
								requests=requests+$plus,
								status='Y'
							WHERE
								ID_user=?
							LIMIT 1
						},'quiet'=>1,
						'bind'=>[$tom::H,$main::USRM{'cookies'},$main::ENV{'HTTP_USER_AGENT'},$main::COOKIES_all{'_ga'},$main::COOKIES{'_ID_user'}]);
					}
				}
				else # divna ID_session ktora nesuhlasi
				{
					my $var;
					my $bad;
					if ($main::USRM{'ID_session'} ne $main::COOKIES{'_ID_session'}){$var.=" ID_session:( "};
					if ($main::USRM{'user_agent'} ne $main::ENV{'HTTP_USER_AGENT'}){$var.=" AGENT:( ";$bad=1;}
					if ($ref[0] ne $ref[1]){$var.=" IP:( ";$bad=1;}
					
					if (($main::USRM{'logged'} eq "Y")||($bad))
					{
						main::_log("not verified ID_user='$main::COOKIES{_ID_user}' '$var'");
						# ZNICIM JEHO COOKIES!!!
						# (mozno slo len o dvojity request/2requesty v tom istom case)
						$main::USRM_flag="O";
						if (($main::USRM{reqtime}+5) < $tom::time_current)
						{
							main::_log("destroy cookies");
							# staci vyprazdnit, tomahawk sa uz o DELETE postara sam
							foreach (keys %main::COOKIES){$main::COOKIES{$_}=""}; 
						}
						%main::USRM=(); # vyprazdnenie
					}
					else
					{
						
					}
				}
			}
			
			# user prisiel na stranku po nejakom case, toto je teda jeho request
			# bez platnej session, uz nieje v online tabulke
			else
			{
				main::_log("I'm not online, finding in user table");
				
				# activize user when deactivated
				App::301::functions::user_get($main::COOKIES{'_ID_user'});
				
				my $sql=qq{
					SELECT
						*
					FROM
						TOM.a301_user
					WHERE
						ID_user=? AND
						hostname=?
					LIMIT 1
				};
				my %sth_u=TOM::Database::SQL::execute($sql,'bind'=>[$main::COOKIES{'_ID_user'},$tom::H_cookie],'quiet'=>1,'-slave'=>1);
				%main::USRM=$sth_u{'sth'}->fetchhash();
				
				if ($main::USRM{'ID_user'})
				{
					main::_log("I'm in users");
					
					use DateTime;
					my $dt_now=DateTime->now;
					my $dt_old=$dt_now;
					if ($main::USRM{'datetime_last_login'}=~/^(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)$/)
					{
						$dt_old=DateTime->new(
							year   => $1,
							month  => $2,
							day    => $3,
							hour   => $4,
							minute => $5
						);
					}
					else
					{
						main::_log("invalid 'datetime_last_login' = '$main::USRM{'datetime_last_login'}'",3,"pub.err");
					}
					
					#main::_log("go online user '$main::USRM{'ID_user'}' from '$main::USRM{'datetime_last_login'}' (".($dt_diff->year)."-".($dt_diff->month).") with '$main::USRM{'requests_all'}' requests",3,"a301",2);
					main::_log("[$tom::H] returned user '$main::USRM{'ID_user'}' last logged '$main::USRM{'datetime_last_login'}' with '$main::USRM{'requests_all'}' requests",3,"a301",2);
					##############################################################
					if ($main::USRM{'autolog'} eq "Y") # lognutie iba ak ide o autolog
					{
						$main::USRM{'logged'}="Y";
						$main::USRM_flag="L";
						main::_log("autolog=Y");
						$main::USRM{'autologged'}="Y";
					}
					else
					{
						$main::USRM{'logged'}="N";
						$main::USRM_flag="I";
					}
					
					##############################################################
					$main::USRM{'ID_session'}=TOM::Utils::vars::genhash(32);# vygenerujem hash session
					$main::COOKIES{'_ID_session'}=$main::USRM{'ID_session'}; # a priradim ho
					
					# PRIPRAVA DAT PRE $main::USRM
					$main::USRM{'cookies'}="";
					
					# vypraznim page_code posledneho requestu
					# pretoze toto je nova session
#					undef $main::COOKIES_save{'lh'};
					
#					foreach (sort keys %main::COOKIES)
#					{$_=~/^_/ && do {$main::USRM{'cookies'}.="<VAR id=\"".$_."\">".$main::COOKIES{$_}."</VAR>\n";next}}
					
					# INSERT DO ONLINE
					main::_log("insert into user_online");
					
					TOM::Database::SQL::execute(qq{
						UPDATE
							TOM.a301_user
						SET
							datetime_last_login = FROM_UNIXTIME($main::time_current)
						WHERE
							ID_user=?
							AND hostname=?
						LIMIT 1
					},'bind'=>[$main::COOKIES{'_ID_user'},$tom::H_cookie],'quiet'=>1,'-slave'=>1);
					
					if (!$main::USRM{'login'} or $main::USRM{'autolog'} eq "Y") # user v tabulke a301_user nieje regularny user s kontom
					{
						main::_log("move saved cookies and session");
						
						$main::USRM{'cookies'}=$main::USRM{'saved_cookies'};
						$main::USRM{'session'}=$main::USRM{'saved_session'};
						
						TOM::Database::SQL::execute(qq{
							REPLACE INTO TOM.a301_user_online
							(
								ID_user,
								ID_session,
								domain,
								logged,
								datetime_login,
								datetime_request,
								requests,
								IP,
								user_agent,
								cookies,
								session
							)
							VALUES
							(
								?,
								?,
								?,
								?,
								FROM_UNIXTIME($main::time_current),
								FROM_UNIXTIME($main::time_current),
								'1',
								?,
								?,
								?,
								?
							)
						},'bind'=>[
							$main::COOKIES{'_ID_user'},
							$main::COOKIES{'_ID_session'},
							$tom::H,
							$main::USRM{'logged'},
							$main::ENV{'REMOTE_ADDR'},
							$main::ENV{'HTTP_USER_AGENT'},
							$main::USRM{'saved_cookies'},
							$main::USRM{'saved_session'}
						]);
					}
					else # user v tabulke a301_user je regularny user s kontom
					{
						TOM::Database::SQL::execute(qq{
							REPLACE INTO TOM.a301_user_online
							(
								ID_user,
								ID_session,
								domain,
								logged,
								datetime_login,
								datetime_request,
								requests,
								IP,
								user_agent
							)
							VALUES
							(
								?,
								?,
								?,
								?,
								FROM_UNIXTIME($main::time_current),
								FROM_UNIXTIME($main::time_current),
								'1',
								?,
								?
							)
						},'bind'=>[
							$main::COOKIES{'_ID_user'},
							$main::COOKIES{'_ID_session'},
							$tom::H,
							$main::USRM{'logged'},
							$main::ENV{'REMOTE_ADDR'},
							$main::ENV{'HTTP_USER_AGENT'}
						]);
					}
					
				}
				else # NENASIEL SOM SA ANI V OLD
				{
					main::_log("this user not exists");
					main::_log("user '$main::COOKIES{_ID_user}' not exists, cleaning cookies",4,"a301",2);
					
					$main::USRM_flag="O";
					# ok, falosny users zaznam, nasleduje destrukcia cookies
					# staci vyprazdnit, tomahawk sa uz o DELETE postara sam
					foreach (keys %main::COOKIES){$main::COOKIES{$_}=""};
					%main::USRM=();
					# IDEM VYTVARAT NOVEHO USERA, ALEBO TO TERAZ NECHAM TAK?
					# ZATIAL NECHAVAM TAK. POKIAL NEJDE O ZASKODNIKA TAK PRI DALSOM REQUESTE SA VYTVORI NOVY USER UPLNE V PORIADKU
					# TATO SITUACIA BY PRAKTICKY NEMALA NIKDY NASTAT
				}
				
			}
		}
		else # mam cookies, ale nemam ID_user, idem sa registrovat
		{
			main::_log("missing ID_user");
			
			# NAJPRV SA POZRIEM CI TENTO USER SA NEPOKUSA OPAKOVANE
			# ZISKAVAT ID_user. AK ANO, ZAMEDZIME TOMU
			
=head1
			my $db0=$main::DB{'main'}->Query("
				SELECT COUNT(*) AS cnt
				FROM TOM.a300_online
				WHERE
					host='$tom::H_cookie'
					AND rqs=1
					AND IP='$ENV{REMOTE_ADDR}'
					AND HTTP_USER_AGENT='$ENV{HTTP_USER_AGENT}'
					AND logtime>".($main::time_current-600)."
			");
			if (my %db0_line=$db0->fetchhash())
			{
				if ($db0_line{cnt}>=$max_cnt)
				{
					my $msg="Too many ($db0_line{cnt}>=$max_cnt) identical registered users from IP='$ENV{REMOTE_ADDR}' HTTP_USER_AGENT='$ENV{HTTP_USER_AGENT}' in last 10 minutes. Potentially robot grabber";
					# pub.log ako error
					main::_log("$msg",1);
					# pub.warn.log local
					main::_log("$msg",4,"pub.warn");
					# pub.warn.log master
					main::_log("[$tom::H]$msg",4,"pub.warn",2) if ($tom::H ne $tom::Hm);
					# pub.warn.log global
					main::_log("[$tom::H]$msg",4,"pub.warn",1);
					$t->close();
					return 1;
				}
			}
=cut
			
			# GENERUJEM NOVY HASH A OVERUJEM CI UZ NEEXISTUJE
			my $var=App::301::functions::user_newhash();
			$main::COOKIES{'_ID_user'}=$var;
			
			# OK, VYTVORIL SOM NOVY HASH, ZAPISUJEM
			# TOTO JE TEDA AUTOREGISTRACIA NOVEHO USERA
			main::_log("generujem ID_user=".$var." a zapisujem do users");
			
			TOM::Database::SQL::execute(qq{
				INSERT INTO TOM.a301_user
				(
					ID_user,
					posix_owner,
					hostname,
					datetime_register,
					datetime_last_login,
					status
				)
				VALUES
				(
					?,
					?,
					?,
					FROM_UNIXTIME($main::time_current),
					FROM_UNIXTIME($main::time_current),
					'Y'
				)
			},'bind'=>[$var,$var,$tom::H_cookie],'quiet'=>1);
			
			$main::COOKIES{'_ID_session'}=TOM::Utils::vars::genhash(32); # vygenerujem hash session
			main::_log("insert into online ID_session:$main::COOKIES{'_ID_session'}");
			
			main::_log("new user '$var' with session '$main::COOKIES{'_ID_session'}' (IP='$main::ENV{'REMOTE_ADDR'}' UserAgent='$main::UserAgent_name' referer='$main::ENV{'HTTP_REFERER'}' ref_type='$main::ENV{'REF_TYPE'}' query_string='$main::ENV{'QUERY_STRING_FULL'}')",3,"a301",2);
			
			$main::USRM{'cookies'}=CVML::structure::serialize(%main::COOKIES);
			
			# save info about new user registration (from where is comming?)
			$main::ENV{'REF_TYPE'}='direct' if $main::ENV{'REF_TYPE'} eq "onsite"; # ugly hotfix
			$main::USRM{'session'}=CVML::structure::serialize(
				'USRM_G' =>
				{
					'ref_type' => $main::ENV{'REF_TYPE'},
					'referer' => $main::ENV{'HTTP_REFERER'},
					'time' => $main::time_current,
					# utm sources
					'utm_medium' => $main::ENV{'REF_TYPE'},
					'utm_source' => $main::FORM{'utm_source'},
					'utm_campaign' => $main::FORM{'utm_campaign'},
					'utm_content' => $main::FORM{'utm_content'},
					'utm_term' => $main::FORM{'utm_term'},
				},
				'USRM_S' =>
				{
					'ref_type' => $main::ENV{'REF_TYPE'},
					'referer' => $main::ENV{'HTTP_REFERER'},
					'time' => $main::time_current,
					# utm sources
					'utm_medium' => $main::ENV{'REF_TYPE'},
					'utm_source' => $main::FORM{'utm_source'},
					'utm_campaign' => $main::FORM{'utm_campaign'},
					'utm_content' => $main::FORM{'utm_content'},
					'utm_term' => $main::FORM{'utm_term'},
				}
			);
			
			TOM::Database::SQL::execute(qq{
				INSERT INTO TOM.a301_user_online
				(
					ID_user,
					ID_session,
					domain,
					logged,
					datetime_login,
					datetime_request,
					requests,
					IP,
					user_agent,
					cookies,
					session
				)
				VALUES
				(
					?,
					?,
					?,
					?,
					FROM_UNIXTIME($main::time_current),
					FROM_UNIXTIME($main::time_current),
					'1',
					?,
					?,
					?,
					?
				)
			},'bind'=>[
				$main::COOKIES{'_ID_user'},
				$main::COOKIES{'_ID_session'},
				$tom::H,
				$main::USRM{'logged'},
				$main::ENV{'REMOTE_ADDR'},
				$main::ENV{'HTTP_USER_AGENT'},
				$main::USRM{'cookies'},
				$main::USRM{'session'}
			],'quiet'=>1);
			
			
			TOM::Database::SQL::execute(qq{
				UPDATE TOM.a301_user
				SET
					saved_session=?
				WHERE
					ID_user=?
				LIMIT 1
			},'bind'=>[$main::USRM{'session'},$main::COOKIES{'_ID_user'}],'quiet'=>1);
			
			# PRIDAT EXPORT DO $main::USRM
			# je to tu vobec potreba?
			# v tomto pripade urcite nebude user logged, budem potom
			# teda priamo v tomto requeste potrebovat data $main::USRM???
			##############################################################
			$main::USRM{'ID_user'}=$main::COOKIES{'_ID_user'}; # ID_user usera
			$main::USRM{'ID_session'}=$main::COOKIES{'_ID_session'}; # Idhash pre session usera
			$main::USRM_flag="G";
			##############################################################
		}
	}
	else
	{
		main::_log("none cookies IP:$main::ENV{REMOTE_ADDR} agent=$main::ENV{HTTP_USER_AGENT} cookies=$main::ENV{HTTP_COOKIE}");
	}
	
	
	
	# get session datas from online table in CVML
	# save it into cvml object
	my $cvml=new CVML('data'=>$main::USRM{'session'});
	main::_log("loading session='$main::USRM{'session'}'") if $debug;
	# save backup copy of session, to compare it at end of request
	$main::USRM{'session_save'}=$main::USRM{'session'};
	# remove all session data
	undef $main::USRM{'session'};
	# control CVML session datas as object
	$App::301::session::serialize=0; # don't serialize into database now!
	# fill session hash with datas from CVML
	tie %{$main::USRM{'session'}}, 'App::301::session'; # create empty tie hash
	%{$main::USRM{'session'}}=%{$cvml->{'hash'}}; # fill tie hash
	# setup AB testing if not set already
	if (!$main::USRM{'session'}{'AB'})
	{
		my @ab=('A','B');
		$main::USRM{'session'}{'AB'}=$ab[int(rand(2))];
	}
	
	if ($main::USRM{'autologged'}) # user logged automatically
	{
		autolog();
		undef $main::USRM{'autologged'};
	}
	# create new session referer info
	if ($main::USRM_flag eq "G")
	{
#		%{$main::USRM{'session'}{'USRM_S'}}=%{$main::USRM{'session'}{'USRM_G'}};
	}
	elsif ($main::USRM_flag eq "L" || $main::USRM_flag eq "I")
	{
		$main::USRM{'session'}{'USRM_S'}={};
		$main::USRM{'session'}{'USRM_S'}{'ref_type'} = $main::ENV{'REF_TYPE'};
		$main::USRM{'session'}{'USRM_S'}{'referer'} = $main::ENV{'HTTP_REFERER'};
		$main::USRM{'session'}{'USRM_S'}{'time'} = $main::time_current;
	}
	# override session referer info
	if ($main::FORM{'utm_medium'} || $main::FORM{'ref'})
	{
		# setup override incoming info for this session (for example clicked to banner in already existing session)
		$main::USRM{'session'}{'USRM_S'}{'ref_type'} = $main::ENV{'REF_TYPE'};
		$main::USRM{'session'}{'USRM_S'}{'referer'} = $main::ENV{'HTTP_REFERER'};
		$main::USRM{'session'}{'USRM_S'}{'time'} = $main::time_current;
		$main::USRM{'session'}{'USRM_S'}{'utm_medium'} = $main::FORM{'utm_medium'} || $main::FORM{'ref'};
		$main::USRM{'session'}{'USRM_S'}{'utm_source'} = $main::FORM{'utm_source'};
		$main::USRM{'session'}{'USRM_S'}{'utm_campaign'} = $main::FORM{'utm_campaign'};
		$main::USRM{'session'}{'USRM_S'}{'utm_content'} = $main::FORM{'utm_content'};
		$main::USRM{'session'}{'USRM_S'}{'utm_term'} = $main::FORM{'utm_term'};
	}
	$App::301::session::serialize=1;
	
	foreach (keys %main::USRM)
	{
		main::_log("USRM $_='$main::USRM{$_}'") if $debug;
	};
	
	foreach (keys %main::COOKIES)
	{
		main::_log("COOKIES $_='$main::COOKIES{$_}'") if $debug;
	}
	
	foreach (keys %{$main::USRM{'session'}})
	{
		main::_log("USRM-SESSION $_='".$main::USRM{'session'}{$_}."'") if $debug;
	}
	
	main::_log("main::USRM_flag='$main::USRM_flag'");
	$t->close();
	return 1;
}



sub archive
{
	my $ID_user=shift;
	my %env=@_;
	return undef unless $ID_user;
	
	my $msec=ceil((Time::HiRes::gettimeofday)[1]/100);
	
	# INSERT IGNORE?
	TOM::Database::SQL::execute(qq{
		INSERT IGNORE INTO TOM.a301_user_session
		(
			ID_user,
			ID_session,
			IP,
			datetime_session_begin,
			datetime_session_begin_msec,
			datetime_session_end,
			requests_all,
			saved_cookies,
			saved_session
		)
		SELECT
			ID_user,
			ID_session,
			IP,
			datetime_login,
			$msec,
			datetime_request,
			requests,
			cookies,
			session
		FROM
			TOM.a301_user_online
		WHERE
			ID_user='$ID_user'
		LIMIT 1
	},'quiet'=>1);
	
	if ($env{'reset'})
	{
		TOM::Database::SQL::execute(qq{
			UPDATE
				TOM.a301_user_online
			SET
				datetime_login=datetime_request,
				requests=0
			WHERE
				ID_user='$ID_user'
			LIMIT 1
		},'quiet'=>1);
	}
	
	return 1;
}


sub online_clone
{
	my $ID_user=shift;
	my $ID_user2=shift;
	my %env=@_;
	return undef unless $ID_user;
	return undef unless $ID_user2;
	
	TOM::Database::SQL::execute(qq{
		INSERT IGNORE INTO TOM.a301_user_online
		(
			ID_user,
			ID_session,
			domain,
			logged,
			datetime_login,
			datetime_request,
			requests,
			IP,
			user_agent,
			cookies,
			session,
			status
		)
		SELECT
			'$ID_user2',
			ID_session,
			domain,
			logged,
			datetime_login,
			datetime_request,
			requests,
			IP,
			user_agent,
			cookies,
			session,
			status
		FROM
			TOM.a301_user_online
		WHERE
			ID_user='$ID_user'
		LIMIT 1
	},'quiet'=>1);
	
	return 1;
}


sub autolog
{
}

1;
