#!/usr/bin/perl
=head1 NAME

Cyclone desktop based on:
Tomahawk core -
developed on Linux based systems and Perl 5.6.0 scripting language

=head1 COPYRIGHT

(c) 2002 WebCom s.r.o.
All right reserved!
Unauthorized access and modification prohibited!

=head1 CHANGES

Cyclone desktop 1.0519 (eXPerience)
	*) little core :)


=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 WARNINGS & BUGS
	*) tak dufam ze ziadne :)

=cut

# PERL MODULES

BEGIN
{
 push @INC,"/usr/www/TOM/.core/.libs";
}

sub _log
{
	print "$_[0]-$_[1]\n" if $main::debug;
}

use Mysql;
use Utils::datetime;

	######################################################
	# GLOBALIZATION!!!!!!!!!                                                          #
	######################################################

	my $tmp=$ENV{'HTTP_HOST'};
	#$tmp=~/(.*)\.(..)$/;				# only 2nd level domain identificator
	#$tmp=$2;
	$tmp=~/(.*)$/;;				# whole host identificator
	$tmp=$1;

	our $localizationString=$tmp;
	our $localizationString="default" unless $tmp;

	undef $tmp;

 open (OUTFILE, ">>_logs/DESKTOP_log-".$localizationString.".log");

	my %logtime=Utils::datetime::ctodatetime(time,format=>1);

	print OUTFILE "---- log opened at: $logtime{hour}:$logtime{min}.$logtime{sec} - $logtime{mday}. $logtime{mom}, $logtime{year}\n";
	print OUTFILE "---- localization string: $localizationString\n";

# CORE & PORTAL MODULES
#chdir "../";
#require "admin_local.conf"; # get mysql,domain names,cookie host...
#$dbh = Mysql->Connect($TOM::DB_host,$TOM::DB_name,$TOM::DB_user,$TOM::DB_pass);
# ADMIN DESKTOP MODULES
#chdir "!admin";

	######################################################
	# loading configuration file                                                        #
	######################################################

#require "_conf/".$localizationString.".conf"; # get mysql,domain names,cookie host...
if(-e "_conf/".$localizationString.".conf"){ require "_conf/".$localizationString.".conf"; print OUTFILE "  *** !!! using special configuration file\n";}
	else {require "_conf/default.conf"; print OUTFILE "  *** no special configuration file found. using default.\n";}

	######################################################
	# loading boxes library                                                             #
	######################################################

#require "_libs/".$localizationString."/_box.m";
if(-e "_libs/".$localizationString."/_box.m"){ require "_libs/".$localizationString."/_box.m"; print OUTFILE "  *** !!! using special boxes definitions library.\n";}
	else {require "_libs/default/_box.m"; print OUTFILE "  *** no special boxes definitions library. using default designs.\n";}

	######################################################
	# loading html librariy                                                               #
	######################################################

#require "_libs/".$localizationString."/_html.m";
if(-e "_libs/".$localizationString."/_html.m"){ require "_libs/".$localizationString."/_html.m"; print OUTFILE "  *** !!! using special html library\n";}
	else {require "_libs/default/_html.m"; print OUTFILE "  *** no special html library available. using default.\n";}

	######################################################
	# loading desktop functions and layouts                                     #
	######################################################

#require "_def/".$localizationString."_desktop.def";
if(-e "_def/".$localizationString."_desktop.def"){ require "_def/".$localizationString."_desktop.def"; print OUTFILE "  *** !!! using special desktop function and layout file\n";}
	else {require "_def/default_desktop.def"; print OUTFILE "  *** no special desktop function and layout file. using default. \n";}

	######################################################
	# loading desktop html layout                                                    #
	######################################################

#require "_dsgn/".$localizationString."/desktop.base.dsgn"; # define portal design
if(-e "_dsgn/".$localizationString."/desktop.base.dsgn"){ require "_dsgn/".$localizationString."/desktop.base.dsgn"; print OUTFILE "  *** !!! using special desktop html layout\n";}
	else {require "_dsgn/default/desktop.base.dsgn"; print OUTFILE "  *** no special desktop html layout found. using default. _dsgn/".$localizationString."/desktop.base.dsgn\n";}

##########################################################################################
#%conf_cron=&GetConf("CRON");
#%conf_prtl=&GetConf("PRTL");
#%conf_admn=&GetConf("ADMN");

 ############################
 local $H=HP->new(%HTML_HEADER);
 $H->i($HTML_TEMP);

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
# &GetCookie;

# $cookie{name}=$cookie_name;
# &SetCookie(undef,"$host","/","0");

 print "Content-Type: text/html\n";

print "\n";
  print $H->HTML;

