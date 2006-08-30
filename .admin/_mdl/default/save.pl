#!/usr/bin/perl
=head1 NAME

Cyclone core - 
developed on Unix and Linux based systems and Perl 5.6.0 script language

=head1 COPYRIGHT

(c) 2002 WebCom s.r.o.
All right reserved!
Unauthorized access and modification prohibited!

=head1 CHANGES

Cyclone core 1.0519
	*) start

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 WARNINGS & BUGS
	*) tak dufam ze ziadne :)

=cut

chdir "../_core";
# PERL MODULES
#use FCGI;
use Mysql;
use Time::Local; # pre opacnu konverziu casu
# CORE PORTAL MODULES
require "_cookie.m";
require "_html.m";
require "core.conf"; # portal configuration
# CORE ADMIN MODULES
chdir "../admin";
require "_box.m";
require "core.def"; # define core fcions
require "core.dsgn"; # define portal design

##########################################################################################
##########################################################################################
##########################################################################################
##########################################################################################
$dbh = Mysql->Connect($db_host,$db_name,$db_user,$db_pass);

$time_start=(times)[0]; # START COUNTING TIME

%conf_cron=&GetConf("CRON");
%conf_prtl=&GetConf("PRTL");
%conf_admn=&GetConf("ADMN");

 # TIME
 ############################
 local $current_time=time;
 local ($Tsec, $Tmin, $Thour, $Tmday, $Tmom, $Tyear, $Twday, $Tyday, $Tisdst)=localtime($current_time);
 local $Wsec=$Tsec;
 local $Wmin=$Tmin;
 local $Whour=$Thour;
 local $Wmday=$Tmday;
 local $Wmom=$Tmom+1;
 local $Wyear=$Tyear+1900;
 if ($Wsec<10){$Wsec="0$Wsec"}
 if ($Wmin<10){$Wmin="0$Wmin"}
 if ($Whour<10){$Whour="0$Whour"}
 if ($Wmday<10){$Wmday="0$Wmday"}
 if ($Wmom<10){$Wmom="0$Wmom"}


 %form=&GetQuery;
 &GetCookie;
 
 if ($form{type} eq "reset")
 {
  $dbh->Query("DELETE FROM _admin_save WHERE admin='$ENV{REMOTE_USER}'");
 }
 else
 {
  $ENV{QUERY_STRING}=~s/%([0-9A-Fa-f]{2})/pack("C",hex($1))/eg; # URL decode
# open (HND, ">box.html") || die "$!";
# print HND $ENV{QUERY_STRING};
# print HND "ahooj\n";
# close HND;
 
  $db_micro = $dbh->Query("SELECT ID,admin,type,variable,value,about,version FROM _admin_save WHERE admin='$ENV{REMOTE_USER}' AND type='$form{type}' AND variable='$form{id}' LIMIT 1");
  if (@db_micro_line=$db_micro->FetchRow())
  {
   $dbh->Query("UPDATE _admin_save SET value='$ENV{QUERY_STRING}',version='$form{version}' WHERE ID='$db_micro_line[0]' LIMIT 1");
  }
  else
  {
   $dbh->Query("INSERT INTO _admin_save(admin,type,variable,value,about,version) VALUES ('$ENV{REMOTE_USER}','$form{type}','$form{id}','$ENV{QUERY_STRING}','','$form{version}')");
  }
 }
 $H=HP->new(%HTML_HEADER);

 # SEND COOKIE
 ############################
# $cookie{name}=$cookie_name;
# &SetCookie(undef,"$host","/","0");

 # COUNT END, LOG END
 ############################
 my $time_end=int(((times)[0]-$time_start)*100)/100; # END COUNTING TIME
 if (!$time_end){$time_end="0.00"}

 
 $html_temp=$H->HTML_;
 while (my $k=$html_temp=~s/<a href="index.pl\?(.*?)".*?>/!COREGEN!/oi)
 {
  my $v=$1;
  $html_temp=~s/!COREGEN!/<a href="javascript:\/\/" onclick="load('core.pl?$v')">/oi;
 }
 
 print "Content-Type: text/html\n";
 

  print "\n";
  print $html_temp;

 
 $H->DESTROY();
 undef $H;
