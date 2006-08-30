package Tomahawk::stat;
use open ':utf8', ':std';
use encoding 'utf8';
use Fcntl ':flock';
use utf8;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

sub rqs
{
 #return 1;
 return undef if $main::IAdm;
 return undef if $App::110::IP_exclude{$main::ENV{'REMOTE_ADDR'}};
 
 my %env=@_;
 my $null;$null="C" if $TOM::DB_name_TOM eq $TOM::DB_name_STAT;

 my $var="$tom::Fyear-$tom::Fmom-$tom::Fmday $tom::Fhour:$tom::Fmin:$tom::Fsec";
 my $reqtype="B";

 $reqtype="R" if ($TOM::Net::HTTP::UserAgent::table[$main::UserAgent]{agent_type} eq "robot");

 # zistim pod ktory host vlastne patrim...
 my $host=$tom::Hm; # moj host je moj master
    $host=$tom::H_cookie unless $host; # ak nemam mastera, moj host je moj cookiehost
    $host=$tom::H unless $host; # ak nemam cookiehost tak moj host je default host v local configu

#open HND_weblog, ">>$TOM::P/_logs/weblog/[$TOM::hostname]$tom::Fyear-$tom::Fmom-$tom::Fmday.$tom::Fhour.$tom::Fmin-".$$.".log";

my $filename="$TOM::P/_logs/weblog/weblog.$tom::Fyear-$tom::Fmom-$tom::Fmday.$tom::Fhour.$tom::Fmin.".$$.".log";

#main::_log("saving request stats into file '$filename'");

open HND_weblog, ">>".$filename;

flock(HND_weblog,LOCK_EX);

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
 <IP>$main::ENV{REMOTE_ADDR}</IP>
 <IDhash>$main::USRM{IDhash}</IDhash>
 <IDsession>$main::USRM{IDsession}</IDsession>
 <logged>$main::USRM{logged}</logged>
 <USRM_flag>$main::USRM_flag</USRM_flag>
 <query_string>$main::ENV{QUERY_STRING_FULL}</query_string>
 <query_TID>$main::FORM{TID}</query_TID>
 <query_URL>http://$main::ENV{HTTP_HOST}$main::ENV{REQUEST_URI}</query_URL>
 <referer>$main::ENV{HTTP_REFERER}</referer>
 <user_agent>$main::ENV{HTTP_USER_AGENT}</user_agent>
 <unique_id>$main::ENV{UNIQUE_ID}</unique_id>
 <load_proc>$env{proc}</load_proc>
 <load_req>$env{req}</load_req>
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
flock(HND_weblog,LOCK_UN);
close (HND_weblog);

return 1}
















1;
