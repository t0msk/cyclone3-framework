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

package CRON::error;
use CRON::error::email;
use Digest::MD5  qw(md5 md5_hex md5_base64);
use strict;

sub module
{
 my %env=@_;
 return undef unless $env{-MODULE};

 CRON::debug::log(5,"[CRON::$env{-MODULE}] $env{-ERROR}",1,"cron.err");

 my $var="#[$$]\n# module $env{-MODULE}\n# CRON $main::type\n# TIME $cron::time_current\n$env{-ERROR}\n";
 CRON::error::email::save
 (
  to_name	=>	"admin",
  to_email	=>	$TOM::contact_admin,
  time		=>	$cron::time_current,
  subj		=>	"[CRON::$main::type::$env{-MODULE}]",
  priority	=>	9,
  md5		=>	md5_hex("[CRON::$env{-MODULE}][$tom::H on $CRON::core_uname_n]"),
  error	=>	$var
 );

return 1}








1;
