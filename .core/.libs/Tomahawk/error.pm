#!/usr/bin/perl
package Tomahawk::error;
use Tomahawk::error::email;
use Digest::MD5  qw(md5 md5_hex md5_base64);
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

sub module
{
	my %env=@_;
	return undef unless $env{-MODULE};
	$env{-TMP}="ERROR" unless $env{-TMP};
	
	main::_deprecated(0,"calling Tomahawk::error::module($env{-MODULE})");
	
	my $out=$Net::DOC::err_mdl;
	Utils::vars::replace($out);
	$out=~s|<%MODULE%>|$env{-MODULE}|;
	$out=~s|<%ERROR%>|$env{-ERROR}| if $main::IAdm;
	$out=~s|<%PLUS%>|$env{-PLUS}| if $main::IAdm;
	$out=~s|<%.*?%>||g;
	
	main::_log("[MDL::$env{-MODULE}] $env{-ERROR} $env{-PLUS}",1,"pub.err",0); #local
	main::_log("[MDL::$env{-MODULE}] $env{-ERROR} $env{-PLUS}",1,"pub.err",1); #master
	main::_log("[MDL::$env{-MODULE}] $env{-ERROR} $env{-PLUS}",1,"pub.err",2); #global
	
	# TODO:[fordinal] tu musi pribudnut poslanie na mail a to ci vobec mam chyby zapisovat do HTML kodu
	if ($TOM::ERROR_module_email)
	{
		my $var="# process [$$]\n# page $main::request_code\n# module $env{-MODULE}\n# TMP $env{-TMP}\n# TID $main::FORM{TID}\n# TIME $tom::time_current\n$env{-ERROR}\n$env{-PLUS}\n";
		
		my $email_addr;
		my $email_name;
		foreach ("TOM",@TOM::ERROR_email_send)
		{
			$email_addr.=";".$TOM::contact{$_};
			$email_name.=$_."/";
		}$email_name=~s|/$||;$email_name=~s|TOM/TOM|TOM|;
		
		Tomahawk::error::email::save
		(
			'to_name'	=>	"$email_name/authors",
			'to_email'	=> $email_addr.";".$Tomahawk::module::authors,
			'time'		=>	$tom::time_current,
			'subj'		=>	"[MDL::$env{-MODULE}]",
			'priority'	=>	9,
			'md5'		=>	md5_hex("[MDL::$env{-MODULE}][$tom::H on $TOM::core_uname_n]"),
			'error'	=>	$var
		);
		
	}

 return 1 if $main::H->r_("<!TMP-".$env{-TMP}."!>",$out);
 return 1 if $main::H->r_("<!TMP-ERROR!>",$out);
 $main::H->a($out);

return 1}



sub page
{
	my $var;
	foreach my $err(@_){$var.=$err};$var.=" ".$@." ".$!;
	eval
	{
		main::_log("[PAGE][$tom::H on $TOM::core_uname_n] ??? $var",1);
		main::_log("[PAGE][$tom::H on $TOM::core_uname_n] ??? $var",1,"pub.err",1);
	};
	
	print "Content-Type: ".$Net::DOC::content_type."; charset=UTF-8\n\n";
	
	my $out=$Net::DOC::err_page;
	Utils::vars::replace($out);
	
	foreach my $err(@_)
	{
		$out=~s|<!--ERR-->|$err\n<!--ERR-->|;
	}
	
	print $out;
	
	eval
	{
		if ($TOM::ERROR_page_email)
		{
			
			my $email_addr;
			my $email_name;
			foreach (@TOM::ERROR_email_send)
			{
				$email_addr.=";".$TOM::contact{$_};
			}
			
			Tomahawk::error::email::save
			(
				'to_name'	=>	"$email_name",
				'to_email'	=> $email_addr,
				'time'	=>	time,
				subj	=>	"[PAGE]",
				priority	=>	99,
				md5		=>	md5_hex("[PAGE][$tom::H on $TOM::core_uname_n]"),
				error	=>	"# Tomahawk3 was down!!!\n$var"
			);
		}
	};
}








sub page_warn
{
 my $var;
 #foreach my $err(@_){$var.=$err};$var.=" ".$@." ".$!;
 #eval {Tomahawk::debug::log(0,"[PAGE] ??? $var",1,"tom3_err");};
 print "Content-type: text/html\n\n";
 print <<"HEADER";
 <HTML>
 <HEAD>
  <TITLE>Tomahawk system warning</TITLE>
 </HEAD>
 <BODY>
 <table>
  <tr>
   <td valign=top><img src="$TOM::H_grf/errors/01.png" width=64 height=64 border=0></td>
   <td width=100% valign=top>
    <div style="FONT:bold 28px Verdana;height:50px;">Tomahawk system warning</div>
    <hr>
HEADER
 foreach my $err(@_){print "<div style=\"FONT:15px Arial;\">".$err."</div><BR>\n";}
 print "<div style=\"FONT:15px Arial;\">Please contact the tech support at <a href=\"$TOM::contact_admin\">$TOM::contact_admin</a>!</div><BR>";
 print "<hr>";
 print "<div style=\"FONT:italic 14px Arial;\">Cyclone publisher (". $TOM::core_name ." system)/".$TOM::core_version."/".$TOM::core_build." at ".(`uname -ns`)."</div>\n";
 print <<"HEADER";
   </td>
  </tr>
 </table>
 </BODY>
 </HTML>
HEADER
}


















=head1
sub robot
{
 print "Content-type: text/html\n\n";
 print <<" HEADER";
 <HTML>
 <HEAD>
  <TITLE>Tomahawk error</TITLE>
 </HEAD>
 <BODY>
 <table>
  <tr>
   <td valign=top><img src="$TOM::H_grf/errors/01.png" width=64 height=64 border=0></td>
   <td width=100% valign=top>
    <div style="FONT:bold 28px Verdana;height:50px;">Tomahawk system error</div>
    <hr>
 HEADER
 print "<div style=\"FONT:15px Arial;\">Sorry, but you robot is too agressive :(</div><BR>\n";
 print "<div style=\"FONT:15px Arial;\">Please contact the system administrator at <a href=\"admin\@web.markiza.sk\">admin\@web.markiza.sk</a>!</div><BR>";
 print "<hr>";
 print "<div style=\"FONT:italic 14px Arial;\">Cyclone publisher (". $TOM::core_name ." system)/".$TOM::core_version."/".$TOM::core_build." at ".(`uname -ns`)."</div>\n";
 print <<" HEADER";
   </td>
  </tr>
 </table>
 </BODY>
 </HTML>

 HEADER
}
=cut


1;
