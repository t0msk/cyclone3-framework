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

package CRON::debug;

use strict;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use TOM::Debug;

sub log
{
	main::_obsolete_func();
	my @env=@_;
	if ($env[0]=~/^\d+/)
	{
		shift @env;
	}
	main::_log(@env);
}

=head1
sub log
{
 my @get=@_;
 return undef unless $get[1];
 $get[3]="cron" unless $get[3];
 $get[1]=~s|[\n\r]||g;

 my @ref=("+","-");
 my (
	$Tsec,
	$Tmin,
	$Thour,
	$Tmday,
	$Tmom,
	$Tyear,
	$Twday,
	$Tyday,
	$Tisdst) = localtime(time);
 # doladenie casu
 $Tyear+=1900;$Tmom++;
 # formatujem cas

 my (
	$Fsec,
	$Fmin,
	$Fhour,
	$Fmday,
	$Fmom,
	$Fyear,
	$Fwday,
	$Fyday,
	$Fisdst
	) = (
	sprintf ('%02d', $Tsec),
	sprintf ('%02d', $Tmin),
	sprintf ('%02d', $Thour),
	sprintf ('%02d', $Tmday),
	sprintf ('%02d', $Tmom),
	$Tyear,
	$Twday,
	$Tyday,
	$Tisdst
	);

 my $file="$Fyear-$Fmom-$Fmday";
 if (($CRON::DEBUG_log_file>=$get[0])||($get[2])) # logujem v pripade ze som v ramci levelu alebo ide o ERROR
 {
  $get[0]=1 unless $get[0];
  #print ">>".$cron::P."/_logs/".$file.".".$get[3].".".$main::type.".log\n";
  open (HND,">>".$cron::P."/_logs/".$file.".".$get[3].".".$main::type.".log")
  	|| die "System cannot write debugging informations in to file log ".$cron::P."/_logs/".$file.".".$get[3].".".$main::type.".log ".$!."\n";
  print HND "[($CRON::core_uname_n) $$] [$Fhour:$Fmin:$Fsec]".(" " x $get[0]).$ref[$get[2]].$get[1]."\n";
  print "[($CRON::core_uname_n) $$] [$Fhour:$Fmin:$Fsec]".(" " x $get[0]).$ref[$get[2]].$get[1]."\n";
  close HND; # TENTO RIADOK MOZNO ZRUSIT!!!
 }
return 1}
=cut


1;
