#!/usr/bin/perl
# áéíóú - USE UTF-8!!!
=head1 NAME

Tomahawk definitions - 3.0218
developed on Unix and Linux based systems and Perl 5.8.0 script language
=cut
=head1 COPYRIGHT

(c) 2003 WebCom s.r.o.
All right reserved!
Unauthorized access and modification prohibited!
=cut
=head1 CHANGES

Tomahawk 3.0218
	*)
=cut
=head1 SYNOPSIS
=cut
=head1 DESCRIPTION
=cut
=head1 WARNINGS & BUGS
	*) tak dufam ze ziadne :)

=cut

package CRON::error::email;
use Digest::MD5  qw(md5 md5_hex md5_base64);

use strict;
#use warnings;

our $err_mailbody=<<"HEADER";
From: <%FROM%>
To: <%TO%>
Subject: [ERR]<%SUBJ%>
Date: <%DATE%>
List-Id: TOM3
MIME-Version: 1.0
Content-Type: text/plain;charset="UTF-8"
Content-Transfer-Encoding: 7bit

<%VERSION%>
<%ERROR%>
HEADER


sub save
{
 my %env=@_;

 $env{body}=$err_mailbody;
 $env{time}=$cron::time_current unless $env{time};
 $env{error}=~s|'|\\'|g;
 #$env{error}=~s|\"|\\"|;

  my (
	$Tsec,
	$Tmin,
	$Thour,
	$Tmday,
	$Tmom,
	$Tyear,
	$Twday,
	$Tyday,
	$Tisdst) = localtime($cron::time_current);
  $Tyear+=1900;
  $Thour=sprintf ('%02d', $Thour);
  $Tmin=sprintf ('%02d', $Tmin);
  $Tsec=sprintf ('%02d', $Tsec);


  $env{body}=~s|<%DATE%>|$Utils::datetime::DAYS{en}[$Twday], $Tmday $Utils::datetime::MONTHS{en}[$Tmom] $Tyear $Thour:$Tmin:$Tsec +-200|g;
  $env{body}=~s|<%VERSION%>|%CRON system|g;
  $env{body}=~s|<%TO%>|"$env{to_name}" <$env{to_email}>|g;
  $env{body}=~s|<%SUBJ%>|$env{subj}|g;
  $env{body}=~s|<%ERROR%>|$env{error}|g;
  $env{body}=~s|<%FROM%>|"$CRON::core_uname_n($tom::H)" <CRON\@$CRON::core_uname_n>|g;
  
	#$env{body}=~s|\'|\\'|g;
	$env{error}=~s|\'|\\'|g;
	
  my $db0=$main::DBH->Query("
  	SELECT body
	FROM $TOM::DB_name_TOM.a130_send
	WHERE ID_md5='$env{md5}'
	AND sendtime>$env{time}-$TOM::ERROR_email_maxlasttime
	LIMIT 1");
  if (my @db0_line=$db0->FetchRow())
  {
=head1
   print "\n-update email\n";
   $db0_line[0]=~s|'|\'|g;
   my $sql="
   	UPDATE $TOM::DB_name_TOM.a130_send
	SET priority=priority+1, body='$db0_line[0]$env{error}'
	WHERE ID_md5='$env{md5}'
	LIMIT 1";
   $main::DBH->Query($sql);
   print "\n\n\n\n$sql\n\n\n\n";
=cut
  }
  else
  {
   print "\n-insert email\n";
	 $main::DBH->Query("
	 INSERT INTO $TOM::DB_name_TOM.a130_send
	 (
	  ID_md5,
	  sendtime,
	  priority,
	  from_name,
	  from_email,
	  from_host,
	  from_service,
	  to_name,
	  to_email,
	  body)
	 VALUES	(
	  '$env{md5}',
	  '$env{time}',
	  '$env{priority}',
	  'CRON',
	  'CRON\@$CRON::core_uname_n',
	  '$tom::H',
	  'CRON',
	  '$env{to_name}',
	  '$env{to_email}',
	  '$env{body}'
	 )");
  }

return 1}


1;
