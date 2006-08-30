#!/usr/bin/perl
=head1 NAME

Cyclone Core -
Developed on Linux based systems and Perl 5.6.0 scripting language

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

$debug=0;

##

BEGIN
{
 push @INC,"/usr/www/TOM/.core/.libs";
}

sub _log
{
	print "$_[0]-$_[1]\n" if $main::debug;
}

#chdir "../_core";
# PERL MODULES
#use FCGI;

use Mysql;
use Time::Local; # pre opacnu konverziu casu
use Utils::datetime;
use Database::connect;
use Net::HTTP::CGI;
#use strict;

############################################ logging feature ##########################################

#open (HND0,">>/var/www/TOM/!markiza.sk/!test/!admin/_logs/admin.log");
 #print HND0 "zapisujem akoze nieco do loga :o) a este raaaaz :o)\n";

#######################################################################################################

#chdir "../";
#require "local.conf.old"; # get mysql,domain names,cookie host...
#chdir "!admin";

#die "huuuuuuuuuu";

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

	open (OUTFILE, ">>_logs/CORE_log-".$localizationString.".log");

	my %logtime=Utils::datetime::ctodatetime(time,format=>1);

	print OUTFILE "---- log opened at: $logtime{hour}:$logtime{min}.$logtime{sec} - $logtime{mday}. $logtime{mom}, $logtime{year}\n";
	print OUTFILE "---- localization string: $localizationString\n";

	require "/usr/www/TOM/.core/_config/TOM3.conf" || die "!!!!! !!!!! !!!!! no TOM3 config found !!!!! !!!!! !!!!!"; # get mysql,domain names,cookie host...


	######################################################
	# loading configuration file                                                        #
	######################################################

	#require "_conf/".$localizationString.".conf"; # get mysql,domain names,cookie host...
	if(-e "_conf/".$localizationString.".conf"){ require "_conf/".$localizationString.".conf"; print OUTFILE "  *** !!! using special configuration file\n";}
		else {require "_conf/default.conf"; print OUTFILE "  *** no special configuration file found. using default.\n";}
	#die "!!!!! !!!!! !!!!! no local config found !!!!! !!!!! !!!!!"

	######################################################
	# loading html librariy                                                               #
	######################################################

	#require "_libs/".$localizationString."/_html.m";
	if(-e "_libs/".$localizationString."/_html.m"){ require "_libs/".$localizationString."/_html.m"; print OUTFILE "  *** !!! using special html library\n";}
		else {require "_libs/default/_html.m"; print OUTFILE "  *** no special html library available. using default.\n";}

	######################################################
	# loading boxes library                                                             #
	######################################################

	#require "_libs/".$localizationString."/_box.m";
	if(-e "_libs/".$localizationString."/_box.m"){ require "_libs/".$localizationString."/_box.m"; print OUTFILE "  *** !!! using special boxes definitions library.\n";}
		else {require "_libs/default/_box.m"; print OUTFILE "  *** no special boxes definitions library. using default designs.\n";}

	######################################################
	# loading desktop functions and layouts                                     #
	######################################################

	#require "_def/".$localizationString."_desktop.def";
	if(-e "_def/".$localizationString."_core.def"){ require "_def/".$localizationString."_core.def"; print OUTFILE "  *** !!! using special desktop function and layout file\n";}
		else {require "_def/default_core.def"; print OUTFILE "  *** no special desktop function and layout file. using default. \n";}

	######################################################
	# loading desktop html layout                                                    #
	######################################################

	#require "_dsgn/".$localizationString."/desktop.base.dsgn"; # define portal design
	if(-e "_dsgn/".$localizationString."/core.dsgn"){ require "_dsgn/".$localizationString."/core.dsgn"; print OUTFILE "  *** !!! using special desktop html layout\n";}
		else {require "_dsgn/default/core.dsgn"; print OUTFILE "  *** no special desktop html layout found. using default. _dsgn/".$localizationString."/core.dsgn\n";}

	Database::connect::all();

	$time_start=(times)[0]; # START COUNTING TIME

	%conf_cron=&GetConf("CRON");
	%conf_prtl=&GetConf("PRTL");
	%conf_admn=&GetConf("ADMN");

	#exit;

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

	my $output;

	#&GetCookie;

 	######################################################
	# loading desktop html layout                                                    #
	######################################################

#require "_dsgn/".$localizationString."/desktop.base.dsgn"; # define portal design
	if(-e "_dsgn/".$localizationString."/core.dsgn"){ require "_dsgn/".$localizationString."/core.dsgn"; print OUTFILE "  *** !!! using special desktop html layout\n";}
		else {require "_dsgn/default/core.dsgn"; print OUTFILE "  *** no special desktop html layout found. using default. _dsgn/".$localizationString."/core.dsgn\n";}

 	######################################################
	# LOADING REQUESTED MODULE                                          #
	######################################################

	if (not -e "_mdl/".$localizationString."/$form{type}.mdl")
	{
		print OUTFILE "  *** !!! _mdl/".$localizationString."/$form{type}.mdl not found. is this an ERROR? switching to the default '$form{type}' module!\n";

		if (not -e "_mdl/default/$form{type}.mdl")
		{
			print OUTFILE "  *** !!! _mdl/default/$form{type}.mdl not found. is this an ERROR? switching to the default '$form{type}' module!\n";

			eval
			{
				local $SIG{__WARN__} = sub {return};
				local $SIG{__DIE__} = sub {return};
				local $SIG{ALRM} = sub {return};
				alarm 5;
				do "_mdl/default.mdl";
				$output=&BaseModul;
				alarm 0;
			};
		}
		else
		{
			print "you should not see this message.<br /><br />please contact your administrator and report what were you doing before this message appeared. thank you.";
=head1
			eval
			{
				local $SIG{__WARN__} = sub {return};
				local $SIG{__DIE__} = sub {return};
				local $SIG{ALRM} = sub {return};
				alarm 5;
				do "_mdl/default/$form{type}.mdl";
				$output=&BaseModul;
				alarm 0;
			};
=cut
		}
	}
	else
	{
		eval
		{
			local $SIG{__WARN__} = sub {return};
			local $SIG{__DIE__} = sub {return};
			local $SIG{ALRM} = sub {return};
			alarm 5;
			if($form{type} eq "default")
			{do "_mdl/default.mdl";}
			else
			{do "_mdl/".$localizationString."/$form{type}.mdl" if($form{type} eq "default");}
			$output=&BaseModul;
			alarm 0;
		};
	}










=head1
	if (not -e "_mdl/".$localizationString."/$form{type}.mdl")
	{
		print OUTFILE "  *** !!! _mdl/".$localizationString."/$form{type}.mdl not found. is this an ERROR? switching to the default '$form{type}' module!\n";
		if (not -e "_mdl/default/$form{type}.mdl")
		{
			print OUTFILE "  *** !!! _mdl/default/$form{type}.mdl not found. is this an ERROR? switching to the default '$form{type}' module!\n";
			print "you should not see this message.<br /><br />please contact your administrator and report what were you doing before this message appeared. thank you.";
		}

		eval
		{
			local $SIG{__WARN__} = sub {return};
			local $SIG{__DIE__} = sub {return};
			local $SIG{ALRM} = sub {return};
			alarm 5;
			do "_mdl/default.mdl";
			$output=&BaseModul;
			alarm 0;
		};
	}
	else
	{

	}
=cut
	if ($@){$output="ERROR:$@";}

	$H=HP->new(%HTML_HEADER);
	$H->i($output);

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
