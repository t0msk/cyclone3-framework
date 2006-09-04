package Net::HTTP::cookies;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use strict;
use Utils::datetime;

sub GetCookies
{
	my $t=track TOM::Debug(__PACKAGE__."::GetCookies()");
	my %cookie;
	foreach (split(/; /, $ENV{'HTTP_COOKIE'}))
	{
		s/\+/ /g;
		my ($chip, $val) = split(/=/,$_,2);
		$chip =~ s/%([A-Fa-f0-9]{2})/pack("c",hex($1))/ge;#url kodovanie do normal. kodovanie
		$val =~ s/%([A-Fa-f0-9]{2})/pack("c",hex($1))/ge;
		main::_log("'$chip'='$val'");
		if ($val=~s/^$tom::cookie_name://)
		{
			$cookie{$chip} = $val;
			next;
		}
	}
	$t->close();
	return %cookie;
}


sub SetCookies
{
	my $t=track TOM::Debug(__PACKAGE__."::SetCookies()");
	my %env = @_;
	if (!$env{cookies})
	{
		$t->close();
		return undef
	}
	
	$env{'time'}=($main::time_current+(86400*31*6)) unless $env{'time'}; # na 6 mesiacov dopredu
	
	my %date=Utils::datetime::ctodatetime($env{'time'},'format'=>1);
	
	#my ($second,$minute,$hour,$day,$month,$year,$wday)=localtime($env{time});
	#$year += 1900;
	#$second = sprintf("%02d",$second);
	#$minute = sprintf("%02d",$minute);
	#$hour =  sprintf("%02d",$hour);
	
	my $expires = "expires\=$Utils::datetime::DAYS{en}[$date{wday}], $date{mday}-$Utils::datetime::MONTHS{en}[$date{mon}-1]-$date{year} 00:00:00 GMT";
	
	foreach (keys %{$env{cookies}})
	{
		my $var="Set-Cookie: $_\=$tom::cookie_name:$env{cookies}{$_}; $expires; path\=$tom::P_cookie; domain\=$main::tom::H_cookie;\n";
		main::_log("$var");
		print $var;
	}
	$t->close();
	return 1;
}


sub DeleteCookie
{
	my $t=track TOM::Debug(__PACKAGE__."::DeleteCookie()");
	foreach (@_)
	{
		my $var="Set-Cookie:  $_=deleted; expires=Thu, 01-Jan-1970 00:00:00 GMT; path\=$tom::P_cookie; domain\=$main::tom::H_cookie;\n";
		main::_log("$var");
		print $var;
	}
	$t->close();
	return 1;
}



















1;
