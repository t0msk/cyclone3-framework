=head1 NAME

Tomahawk definitions - 3.0218
developed on Unix and Linux based systems and Perl 5.8.0 script language

=head1 COPYRIGHT

(c) 2003 WebCom s.r.o.
All right reserved!
Unauthorized access and modification prohibited!

=head1 CHANGES

Tomahawk 3.0218
	*)

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 WARNINGS & BUGS
	*) tak dufam ze ziadne :)

=cut

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
  #Tomahawk::debug::log(8,$_);
  #Tomahawk::debug::log(0,"C:".$_,0,"a300");
  s/\+/ /g;
  my ($chip, $val) = split(/=/,$_,2);
  $chip =~ s/%([A-Fa-f0-9]{2})/pack("c",hex($1))/ge;#url kodovanie do normal. kodovanie
  $val =~ s/%([A-Fa-f0-9]{2})/pack("c",hex($1))/ge;
  main::_log("'$chip'='$val'");
  if ($val=~s/^$tom::cookie_name://)
  {
   $cookie{$chip} = $val;
   #Tomahawk::debug::log(9,"ok :)");
   #Tomahawk::debug::log(1,"ok :)",0,"a300");
   next;
  }
 }
	$t->close();
 return %cookie;
}



sub SetCookies{
	my $t=track TOM::Debug(__PACKAGE__."::SetCookies()");
	my %env = @_;
	if (!$env{cookies})
	{
		$t->close();
		return undef
	}

 $env{time}=($tom::time_current+(60*60*24*31*4)) unless $env{time}; # na 4 mesiace dopredu

 my ($second,$minute,$hour,$day,$month,$year,$wday)=localtime($env{time});
 $year += 1900;
 $second = sprintf("%02d",$second);
 $minute = sprintf("%02d",$minute);
 $hour =  sprintf("%02d",$hour);

 my $expires = "expires\=$Utils::datetime::DAYS{en}[$wday], $day-$Utils::datetime::MONTHS{en}[$month]-$year $hour:$minute:$second GMT";

 foreach (keys %{$env{cookies}})
 {
  my $var="Set-Cookie: $_\=$tom::cookie_name:$env{cookies}{$_}; $expires; path\=$tom::P_cookie; domain\=$main::tom::H_cookie;\n";
  main::_log("$var");
  print $var;
  #Tomahawk::debug::log(8,$var);
  #Tomahawk::debug::log(0,$var,0,"a300");
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
  #Tomahawk::debug::log(8,$var);
  #Tomahawk::debug::log(0,$var,0,"a300");
 #print  "Set-Cookie:  $_=deleted; expires=Thu, 01-Jan-1970 00:00:00 GMT;\n";
}
	$t->close();
	return 1;
}



















1;
