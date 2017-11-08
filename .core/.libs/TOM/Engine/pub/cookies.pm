package TOM::Engine::pub::cookies;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use Net::HTTP::cookies;

our $debug=0;

sub send
{
	# UPRAVIM COOKIES, ALE LEN VTEDY AK TO NIESU GETCOOKIES
	my $t_cookies=track TOM::Debug("Set Cookies") if $debug;
	
	if (!$main::FORM{'cookies'})
	{
#		$main::COOKIES{'lh'}=$main::request_code;
		
		if (($main::COOKIES{'_lt'}+86400)<$tom::time_current){$main::COOKIES{'_lt'}=$tom::time_current}
		# cistim a upravujem cookies len ak ide o normalne cookies
		foreach (keys %main::COOKIES)
		{
			if (!$main::COOKIES{$_}) # cookie je prazdna (pripravena na zmazanie :))
			{
				main::_log("empty cookie '".$_."'") if $debug;
				Net::HTTP::cookies::DeleteCookie($_);
				delete $main::COOKIES{$_};
				next;
			}
			if (($main::COOKIES{'_lt'} ne $tom::time_current)&&($main::COOKIES{$_} eq $main::COOKIES_save{$_}))
				{delete $main::COOKIES{$_};next;} # zmazem rovnake
			# ostanu mi nerovnake cookies, a len tie budem zapisovat
			# neskor opravit tak aby sa zapisalo aspon raz za mesiac vsetko!!!
		}
	}
	
	#
	# FIXME: [Aben] neustale posielam cookie {key} z IAdm modu, bolo by ho treba zrusit, neviem preco tu stale ostava :(
	#
	
	foreach (keys %main::COOKIES)
	{
		main::_log("cookie '$_'='$main::COOKIES{$_}'") if $debug;
	}
	
	
	# aj ked nemam povolene cookies, posielam ich pre istotu,
	# co ked si ich nahle niekto zapne? :))
	# (nebudem vyuzivat GET cookies predsa stale)
	Net::HTTP::cookies::SetCookies
	(
		'time' => $tom::time_current + (86400*31*6)+86400+3600,
		'cookies' => {%main::COOKIES}
	) unless $TOM::Net::HTTP::UserAgent::table[$main::UserAgent]{'cookies_disable'};
	
	# if requested to remove one of original cookie
	foreach (keys %main::COOKIES_all_save)
	{
		if (!$main::COOKIES_all{$_})
		{
			my $var="Set-Cookie: $_=deleted; expires=Thu, 01-Jan-1970 00:00:00 GMT; path\=$tom::P_cookie; domain\=.$tom::D_cookie;\n";
			main::_log("$var");
			print $var;
		}
	}
	
	if (!$TOM::Net::HTTP::UserAgent::table[$main::UserAgent]{'cookies_disable'})
	{
		# change original cookies
		my $time_=($main::time_current+(86400*31*6)); # na 6 mesiacov dopredu
		my %date=Utils::datetime::ctodatetime($time_,'format'=>1);
		my $expires = "expires\=$Utils::datetime::DAYS{en}[$date{wday}], $date{mday}-$Utils::datetime::MONTHS{en}[$date{mon}-1]-$date{year} 00:00:00 GMT";
		
		foreach (keys %main::COOKIES_all)
		{
			if ($main::COOKIES_all{$_} && ($main::COOKIES_all_save{$_} ne $main::COOKIES_all{$_}))
			{
				my $var="Set-Cookie: $_\=$main::COOKIES_all{$_}; $expires; path\=$tom::P_cookie; domain\=$tom::D_cookie;\n";
				main::_log("$var");
				print $var;
			}
		}
		
		# autoset browser id
		if (!$main::COOKIES_all{'c3bid'} && $main::USRM{'ID_user'})
		{
			my $var="Set-Cookie: c3bid\=$main::USRM{'ID_user'}; $expires; path\=$tom::P_cookie; domain\=$tom::D_cookie;\n";
			main::_log("$var");
			print $var;
		}
		
		# autoset browser session id
		if (!$main::COOKIES_all{'c3sid'} && $main::USRM{'ID_session'})
		{
			my $var="Set-Cookie: c3sid\=$main::USRM{'ID_session'}; path\=$tom::P_cookie; domain\=$tom::D_cookie;\n";
			main::_log("$var");
			print $var;
		}
		
	}
	
	$t_cookies->close() if $debug;
	
}

1;
