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

package Tomahawk::layers;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

sub get
{
 my %env=@_;
 my $var=$tom::P;
 my $null;
 $env{IDcategory}=~s/^m// && do # chcem master layer
 {if ($tom::Pm){$var=$tom::Pm;$null="m";}};
 # global layer
 $env{IDcategory}=~s/^g// && do {$var=$TOM::P;$null="g";};
 #Tomahawk::debug::log(0,"layer ".$var."/_type/".$null.$env{IDcategory}.".cml_gen");
 if (-e $var."/_type/".$null.$env{IDcategory}.".cml_gen")
 {
  #Tomahawk::debug::log(0,"opening ".$var."/_type/".$null.$env{IDcategory}.".cml_gen");
  open (HND,"<".$var."/_type/".$null.$env{IDcategory}.".cml_gen") || die "cannot open layer ".$null.$env{IDcategory}."\n";#return undef;
  while ($env{file_line}=<HND>){$env{file_data}.=$env{file_line};}
  return $env{file_data};
 }
 else
 {
  die "cannot find layer ".$null.$env{IDcategory}."\n";
 }

return 1}











1;
