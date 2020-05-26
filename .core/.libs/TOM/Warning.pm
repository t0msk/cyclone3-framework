package TOM::Warning;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

=head1 NAME

TOM::Warning

=cut

=head1 DESCRIPTION

Generates warning page when page can't be displayed or warning email when comudle can't be correctly displayed to user.

=cut

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DEPENDS

=over

=item *

L<TOM::Error::design|source-doc/".core/.libs/TOM/Error/design.pm">

=item *

L<TOM::Utils::datetime|source-doc/".core/.libs/TOM/Utils/datetime.pm">

=item *

L<TOM::Utils::vars|source-doc/".core/.libs/TOM/Utils/vars.pm">

=back

=cut

use TOM::Error::design;
use TOM::Utils::datetime;
use TOM::Utils::vars;


sub engine
{
	eval
	{
		if ($TOM::engine eq "pub")
		{
			engine_pub(@_);
		}
	};
}



sub engine_pub
{
	my $var=join(". ",@_);$var=~s|[\n\r]| |g;
	
	print "Status: 420 Enhance Your Calm\n";
	print "Content-Type: ".$TOM::Document::content_type."; charset=UTF-8\n\n";
	my $out=$TOM::Document::warn_page;
	TOM::Utils::vars::replace($out);
	$out=~s|<%message%>|$var|;
	utf8::encode($out)
		if utf8::is_utf8($out);
	print $out;
	
}



sub module
{
	if ($TOM::engine eq "pub")
	{
		module_pub(@_);
	}
}



sub module_pub
{
	my %env=@_;
	
	$env{'-MODULE'}=$Tomahawk::mdl_C{-category}."-".$Tomahawk::mdl_C{-name}."/".$Tomahawk::mdl_C{-version}."/".$Tomahawk::mdl_C{-global};
	$env{'-ERROR'}=$env{message};
	
	my $env_=$env{'ENV'};
	
	return undef unless $env{'-MODULE'};
	
	main::_log("[WARN::MDL::$env{-MODULE}] $env{-ERROR} $env{-PLUS}",1,"pub.warn",0); #local
	main::_log("[$tom::H][WARN::MDL::$env{-MODULE}] $env{-ERROR} $env{-PLUS}",4,"pub.warn",1); #global
	main::_log("[$tom::H][WARN::MDL::$env{-MODULE}] $env{-ERROR} $env{-PLUS}",4,"pub.warn",2) if ($tom::H ne $tom::Hm); #master
	
	my $date=TOM::Utils::datetime::mail_current;
	
	my $email_addr;
	my $email_name;
	
	$env{to}=@TOM::ERROR_email_send unless $env{to};
	
	foreach ("TOM", @{$env{to}})
	{
		$email_addr.=";".$TOM::contact{$_};
		$email_name.=$_."/";
	};$email_name=~s|/$||;$email_name=~s|TOM/TOM|TOM|;
	
	$email_addr=TOM::Utils::vars::unique_split($email_addr);
	
	if (($TOM::ERROR_module_email) && (!$main::IAdm))
	{
		my $email=$module_email;
		
		$email=~s|<%TYPE%>|WARN|;
		$email=~s|<%TYPE_%>|Warning|;
		$email=~s|<%DATE%>|$date|;
		$email=~s|<%SUBJ%>|[$env{-MODULE}]|;
		$email=~s|<%DOMAIN%>|$tom::H|g;
		#$email=~s|<%ERROR%>|$var|;
		$email=~s|<%TO%>|"$email_name" <TOM\@webcom.sk>|;
		$email=~s|<%ERROR%>|$env{-ERROR}|g;
		$email=~s|<%ERROR-PLUS%>|$env{-PLUS}|g;
		
		#$email=~s|<#PROJECT#>|$email_project|;
		$email=~s|<#PROJECT#>|$email_project\n$email_project_pub|;
		
		$email=~s|<#MODULE#>|$email_module|;
		
		$email=~s|<%MODULE%>|$env{-MODULE}|g;
		
		if ($main::IAdm || $main::ITst)
		{
			$email=~s|<%uri-parsed%>|(search do log)|g;
		}
		
		$email=~s|<%uri-parsed%>|$tom::H_www/?$main::ENV{QUERY_STRING_FULL}|g;
		$email=~s|<%uri-orig%>|$tom::H_www$main::ENV{REQUEST_URI}|g;
		$email=~s|<%uri-referer%>|$main::ENV{HTTP_REFERER}|g;
		
		foreach (sort keys %{$env_})
		{
			#main::_log("input '$_'='".$env_->{$_}."'");
			my $val=$env_->{$_};
			my $env=$email_ENV_;
			$env=~s|<%var%>|$_|g;
			$env=~s|<%value%>|$val|g;
			$email=~s|<#ENV#>|$env\n<#ENV#>|;
		}
		
		$email=~s|<%to%>|$email_addr;$Tomahawk::module::authors|;
		
		TOM::Utils::vars::replace($email);
		$email=~s|<#.*?#>||g;
		$email=~s|<%.*?%>||g;
	
		TOM::Net::email::send(
			'priority'=> 9,
			'from' => "TOM\@$TOM::hostname",
			'to' => $email_addr.";".$Tomahawk::module::authors,
			'body' => $email,
		);
	}
	
	return 1;
}





1;
