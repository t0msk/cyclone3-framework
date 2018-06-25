package TOM::Debug::pub;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


sub output_save
{
	my $t=track TOM::Debug(__PACKAGE__."::output_save()");
		my $filename="../_logs/_debug/page_".$main::request_code.".".(time()).".output";
		main::_log("saving into file '$filename'");
		open (HND_SAVE,">".$filename);
		print HND_SAVE $main::H->{OUT}{HEADER}."\n".$main::H->{OUT}{BODY}."\n".$main::H->{OUT}{FOOTER};
		close (HND_SAVE);
	$t->close();
}


sub request
{
	my %env=@_;
	
	my $reqtype="B";
	$reqtype="R" if ($TOM::Net::HTTP::UserAgent::table[$main::UserAgent]{agent_type} eq "robot");
	
	my %form_;
	if (!$TOM::event_severity_disable{'debug'})
	{
		%form_=%main::FORM;
		foreach (keys %form_)
		{
			delete $form_{$_} if ref($form_{$_});
			if (length($form_{$_}) > 64)
			{
				$form_{$_} = substr($form_{$_},1,64) . '...';
			}
		}
	}
	
	my $obj={
		'times' => {
			'duration' => $env{'duration'},
			'wait' => $env{'duration'}-$env{'user'}-$env{'sys'},
			'user' => $env{'user'},
			'sys' => $env{'sys'},
		},
		'pub' => {
			'REMOTE_ADDR' => $main::ENV{'REMOTE_ADDR'},
			'REFERER' => $main::ENV{'HTTP_REFERER'},
			'HOST' => $main::ENV{'HTTP_HOST'},
			'REQUEST_URI' => $main::ENV{'REQUEST_URI'},
			'QUERY_STRING' => $main::ENV{'QUERY_STRING'},
#			'query' => {%form_},
			'USER_AGENT' => $main::ENV{'HTTP_USER_AGENT'},
			'UserAgent' => $main::UserAgent_name,
			'UserAgent_type' => $TOM::Net::HTTP::UserAgent::table[$main::UserAgent]{'agent_type'},
			'UserAgent_type_group' => $reqtype,
			'response_status' => $env{'code'},
			'redirect' => $env{'location'}
		}
	};
	
	# remove verbosity
	if ($TOM::event_severity_disable{'debug'})
	{
		delete $obj->{'times'};
		delete $obj->{'pub'}->{'query'};
		delete $obj->{'pub'}->{'USER_AGENT'};
		delete $obj->{'pub'}->{'redirect'};
		delete $obj->{'pub'}->{'REFERER'};
	}
	
#	main::_log("testy");
	my $severity=3;
		$severity=4 if $env{'code'}=~/^[45]..$/;
	main::_log($main::ENV{'REQUEST_METHOD'}." '".$main::ENV{'REQUEST_URI'}."' ".$main::ENV{'QUERY_STRING_FULL'}.' '.$main::ENV{'REMOTE_ADDR'}.' '.$env{'code'}.' '.$env{'location'},{
		'facility' => 'pub.track',
		'severity' => $severity,
		'data' => {
			
			'query_data_t' => substr(join(' ',values %main::FORM),0,1024),
			
			'response_status_i' => $env{'code'},
			'user_s' => $main::USRM{'ID_user'},
			'user_session_s' => $main::USRM{'ID_session'},

			'bid_s' => $main::COOKIES_all{'c3bid'}, # browser id
			'sid_s' => $main::COOKIES_all{'c3sid'}, # session id
			
			'user_logged_s' => $main::USRM{'logged'},
			
			'servicetype_s' => $main::FORM{'type'},
			'servicetype_t' => $main::FORM{'TID'},
			
			'REMOTE_ADDR_t' => $main::ENV{'REMOTE_ADDR'},
			'REQUEST_URI_s' => $main::ENV{'REQUEST_URI'},
			'REFERER_t' => $main::ENV{'HTTP_REFERER'},
			'METHOD_t' => $main::ENV{'REQUEST_METHOD'},
			'USER_AGENT_t' => $main::ENV{'HTTP_USER_AGENT'},
			'HTTPS_s' => $main::ENV{'HTTPS'},
#			'UserAgent_t' => $main::UserAgent_name,
			'UserAgent_s' => $main::UserAgent_name,
			'UserAgent_type_s' => $TOM::Net::HTTP::UserAgent::table[$main::UserAgent]{'agent_type'},
			'UserAgent_type_group_s' => $reqtype,
			
			'CacheControl_s' => $main::ENV{'Cache-Control'},
			
			'duration_f' => $env{'duration'},
			'duration_user_f' => $env{'user'},
			
			'_ga_s' => $main::COOKIES_all{'_ga'}
		}
	});
	main::_event('info','pub.request',$obj);
	
	return undef if $App::110::IP_exclude{$main::ENV{'REMOTE_ADDR'}};
	return undef if $main::FORM{'_rc'}; # if this page is only request to recache content
	return undef unless $TOM::STAT;
	
	my $null;$null="C" if $TOM::DB_name_TOM eq $TOM::DB_name_STAT;
	
	my $var="$tom::Fyear-$tom::Fmom-$tom::Fmday $tom::Fhour:$tom::Fmin:$tom::Fsec";
	
	my $host=$tom::Hm;
		$host=$tom::H_cookie unless $host;
		$host=$tom::H unless $host;
	
	my $filedir=$TOM::P."/_logs/weblog/".$tom::Fyear."-".$tom::Fmom."-".$tom::Fmday.".".$tom::Fhour;
	if (!-e $filedir)
	{
		use File::Path;
		File::Path::mkpath $filedir;
		chmod (0777,$filedir);
	}
	
	my $filename=$filedir."/";
	if ($TOM::serverfarm)
	{
		$filename.="[".$TOM::hostname."]";
	}
	else
	{
		$filename.="default";
	}
	$filename.=".log";

my $URL=$tom::H_www;$URL=~s/\/$//;
$URL=~s|$tom::rewrite_RewriteBase$||;
$URL.='/' unless $main::ENV{'REQUEST_URI'}=~/^\//; # adding '/' if link si like 'http://example.tld'
$URL.=$main::ENV{'REQUEST_URI'};

	if ($App::110::sql_direct)
	{
		
		my $DELAYED;
		$DELAYED='DELAYED' if $TOM::DB{'stats'}{'delayed'};
		
		my $sql="
			INSERT $DELAYED INTO TOM.a110_weblog_rqs
			(
				page_code,
				page_code_referer,
				HTTP_unique_id,
				reqtime,
				reqdatetime,
				host,
				domain,
				domain_sub,
				IP,
				IDhash,
				IDsession,
				logged,
				USRM_flag,
				query_string,
				query_TID,
				query_URL,
				referer,
				referer_SE,
				user_agent,
				load_proc,
				load_req,
				result,
				lng
			)
			VALUES
			(
				'".$main::request_code."',
				'".$main::COOKIES_save{'lh'}."',
				'".$main::ENV{'UNIQUE_ID'}."',
				'".$main::time_current."',
				'".$var."',
				'".$TOM::hostname."',
				'".$host."',
				'".$tom::H."',
				'".$main::ENV{'REMOTE_ADDR'}."',
				'".($main::USRM{'ID_user'} || $main::USRM{'IDhash'})."',
				'".($main::USRM{'ID_session'} || $main::USRM{'IDsession'})."',
				'".$main::USRM{'logged'}."',
				'".$main::USRM_flag."',
				'".TOM::Security::form::sql_escape($main::ENV{'QUERY_STRING_FULL'})."',
				'".$main::FORM{'TID'}."',
				'".TOM::Security::form::sql_escape($URL)."',
				'".TOM::Security::form::sql_escape($main::ENV{'HTTP_REFERER'})."',
				'".TOM::Security::form::sql_escape($main::ENV{'REF_TYPE'})."',
				'".TOM::Security::form::sql_escape($main::ENV{'HTTP_USER_AGENT'})."',
				'".$env{'user'}."',
				'".$env{'duration'}."',
				'".$main::result."',
				'".$tom::lng."'
			)
		";
		TOM::Database::SQL::execute($sql,'quiet'=>1,'db_h'=>'stats');
		
		return 1;
	}

open HND_weblog, ">>".$filename;
chmod (0666,$filename);

print HND_weblog <<"HEAD";
<request>
 <page_code>$main::request_code</page_code>
 <page_code_referer>$main::COOKIES_save{'lh'}</page_code_referer>
 <reqtime>$main::time_current</reqtime>
 <reqdatetime>$var</reqdatetime>
 <reqtype>$reqtype</reqtype>
 <host>$TOM::hostname</host>
 <domain>$host</domain>
 <domain_sub>$tom::H</domain_sub>
 <IP>$main::ENV{'REMOTE_ADDR'}</IP>
HEAD

print HND_weblog "
 <IDhash>".($main::USRM{'ID_user'} || $main::USRM{'IDhash'})."</IDhash>
 <IDsession>".($main::USRM{'ID_session'} || $main::USRM{'IDsession'})."</IDsession>
";

print HND_weblog <<"HEAD";
 <logged>$main::USRM{'logged'}</logged>
 <USRM_flag>$main::USRM_flag</USRM_flag>
 <query_string>$main::ENV{'QUERY_STRING_FULL'}</query_string>
 <query_TID>$main::FORM{'TID'}</query_TID>
 <query_URL>$URL</query_URL>
 <referer>$main::ENV{'HTTP_REFERER'}</referer>
 <ref_type>$main::ENV{'REF_TYPE'}</ref_type>
 <user_agent>$main::ENV{'HTTP_USER_AGENT'}</user_agent>
 <unique_id>$main::ENV{'UNIQUE_ID'}</unique_id>
 <load_proc>$env{'user'}</load_proc>
 <load_req>$env{'duration'}</load_req>
 <lng>$tom::lng</lng>
 <result>$main::result</result>
 <lastmod>$main::env{'lastmod'}</lastmod>
 <changefreq>$main::env{'changefreq'}</changefreq>
 <weight>$main::env{'weight'}</weight>
HEAD
	
	if ($main::sitemap)
	{
		print HND_weblog <<"HEAD";
 <sitemap>1</sitemap>
HEAD
	}
	
print HND_weblog <<"HEAD";
</request>
HEAD
close (HND_weblog);

return 1}


1;
