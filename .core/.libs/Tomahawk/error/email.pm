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

package Tomahawk::error::email;
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

Project (domain): <%DOMAIN%>
Module owner: <%authors%>
Project manager: <%manager%>

<%VERSION%>
<%ERROR%>
<%URL%>
#### HTTP ENV ####
<%CLIENT%>#### HTTP ENV ####


HEADER


sub save
{
	#return 1;
	
	my %env=@_;
	return undef if $main::IAdm; # neposielat chyby emailom ak som IAdm
	$env{body}=$err_mailbody;
	$env{'time'}=$main::time_current unless $env{'time'};
	$env{error}=~s|'|\\'|g;
	
	(
		$tom::GTsec,
		$tom::GTmin,
		$tom::GThour,
		$tom::GTmday,
		$tom::GTmom,
		$tom::GTyear,
		$tom::GTwday,
		$tom::GTyday,
		$tom::GTisdst) = gmtime($tom::time_current);
	# doladenie casu
	$tom::GTyear+=1900;$tom::GTmom++;
	# formatujem cas
	(
		$tom::GFsec,
		$tom::GFmin,
		$tom::GFhour,
		$tom::GFmday,
		$tom::GFmom,
		$tom::GFyear,
		$tom::GFwday,
		$tom::GFyday,
		$tom::GFisdst
		) = (
		sprintf ('%02d', $tom::GTsec),
		sprintf ('%02d', $tom::GTmin),
		sprintf ('%02d', $tom::GThour),
		sprintf ('%02d', $tom::GTmday),
		sprintf ('%02d', $tom::GTmom),
		$tom::GTyear,
		$tom::GTwday,
		$tom::GTyday,
		$tom::GTisdst);
	
	$env{body}=~s|<%DOMAIN%>|$tom::H|g;
	$env{body}=~s|<%authors%>|$Tomahawk::module::authors|g;
	$env{body}=~s|<%manager%>|$TOM::contact{'manager'}|g;
	
	$env{body}=~s|<%DATE%>|$Utils::datetime::DAYS{en}[$tom::GTwday], $tom::GTmday $Utils::datetime::MONTHS{en}[$tom::GTmom-1] $tom::GFyear $tom::GFhour:$tom::GFmin:$tom::GFsec GMT|g;
	$env{body}=~s|<%VERSION%>|%Cyclone$TOM::core_version.$TOM::core_build (r$TOM::core_revision)|g;
	
	my %env0;
	foreach (split(';',$env{to_email})){$env0{$_}++ if $_;}
	$env{to_email}="";foreach (sort keys %env0){$env{to_email}.=$_.";";}$env{to_email}=~s|;$||;
	$env{to_email_parse}=$env{to_email};$env{to_email_parse}=~s|;|>,<|g;$env{to_email_parse}="<".$env{to_email_parse}.">";
	$env{body}=~s|<%TO%>|"$env{to_name}" $env{to_email_parse}|g;
	
	
	$env{body}=~s|<%SUBJ%>|$env{subj}|g;
	$env{body}=~s|<%ERROR%>|$env{error}|g;
	#  $env{body}=~s|<%URL%>|### URL: $tom::H_www/?$main::ENV{QUERY_STRING}\n### URL: $tom::H_www/?$main::ENV{REDIRECT_QUERY_STRING}\n### FROM: $main::ENV{HTTP_REFERER}|g;
	$env{body}=~s|<%URL%>|### URL(parsed): $tom::H_www/?$main::ENV{QUERY_STRING_FULL}\n### URL(origin): $tom::H_www$main::ENV{REQUEST_URI}\n### FROM: $main::ENV{HTTP_REFERER}|g;
	$env{body}=~s|<%FROM%>|"$TOM::core_uname_n($tom::H)" <TOM\@webcom.sk>|g;
	foreach(sort keys %main::ENV){$env{body}=~s|<%CLIENT%>|+$_=$main::ENV{$_}\n<%CLIENT%>|;}
	$env{body}=~s|<%CLIENT%>||;
	
	my $db0=$main::DBH->Query("
		SELECT body
		FROM TOM.a130_send
		WHERE
			ID_md5='$env{md5}'
			AND sendtime>$env{time}-$TOM::ERROR_email_maxlasttime
		LIMIT 1
	");
		
	#
	# TODO: [Aben] $TOM::ERROR_email_maxlasttime <- pozriet sa lepsie na tuto premennu
	#
	
	#
	# TODO: [Aben] Vytvorit superglobal konfiguraciu v ktorej by boli premenne pre kazdu farmu rovnake a syncovali by sa
	#
		
	if (my @db0_line=$db0->FetchRow())
	{
		$main::DBH->Query("
			UPDATE TOM.a130_send
			SET priority=priority+1
			WHERE ID_md5='$env{md5}'
			LIMIT 1
		");
	}
	else
	{
		$main::DBH->Query("
			INSERT INTO TOM.a130_send
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
				body
			)
			VALUES
			(
				'$env{md5}',
				'$env{time}',
				'$env{priority}',
				'TOM3',
				'TOM\@$TOM::hostname',
				'$tom::H',
				'TOM3',
				'$env{to_name}',
				'$env{to_email}',
				'$env{body}'
			)
		");
	}

return 1}


1;
