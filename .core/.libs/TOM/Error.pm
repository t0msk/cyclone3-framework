package TOM::Error;
use TOM::Error::design;
use Utils::vars;
use TOM::Utils::datetime;
use TOM::Utils::vars;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


use MIME::Entity;


sub engine
{
	$main::result="failed";
	if ($TOM::engine eq "pub")
	{
		engine_pub(@_);
	}
	elsif ($TOM::engine eq "cron")
	{
		engine_cron(@_);
	}
	else
	{
		engine_lite(@_);
	}
}


#
# uz som v stave ze mozem von vyplut aspon nejaku page
# ak sa vyskytol vazny problem
#
sub engine_pub
{
	my $var=join(". ",@_);$var=~s|[\n\r]| |g;
	
	main::_log("[ENGINE-$TOM::engine][$tom::H] $var",1);
	main::_log("[ENGINE-$TOM::engine][$tom::H] $var",4,"$TOM::engine.err");
	main::_log("[ENGINE-$TOM::engine][$tom::H] $var",4,"$TOM::engine.err",2) if ($tom::H ne $tom::Hm);
	main::_log("[ENGINE-$TOM::engine][$tom::H] $var",4,"$TOM::engine.err",1);
	
	# poslem email co najskor
	my $date=TOM::Utils::datetime::mail_current();
	
	my $email_addr;
	foreach ("TOM",@TOM::ERROR_email_send)
	{
		$email_addr.=";".$TOM::contact{$_};
	};
	$email_addr=TOM::Utils::vars::unique_split($email_addr);
	
	my $msg = MIME::Entity->build
	(
		'Type'    => "multipart/related",
		'List-Id' => "Cyclone3",
		'Date'    => $date,
		'From'    => "Cyclone3 ('$tom::H' at '$TOM::hostname') <$TOM::contact{'from'}>",
		'To'      => TOM::Net::email::convert_TO($email_addr),
		'Subject' => "[ERR][ENGINE-$TOM::engine]"
	);
	
	my $email=$engine_email || $TOM::Error::engine_email_lite;
	
	$email=~s|<%DATE%>|$date|;
	$email=~s|<%SUBJ%>||;
	$email=~s|<%DOMAIN%>|$tom::H|g;
	$email=~s|<%ERROR%>|$var|g;
	
	$email=~s|<#PROJECT#>|$email_project\n$email_project_pub|;
	
	if ($main::IAdm || $main::ITst)
	{
		$email=~s|<%uri-parsed%>|(search do log)|g;
	}
	
	$email=~s|<%uri-parsed%>|$tom::H_www/?$main::ENV{QUERY_STRING_FULL}|g;
	$email=~s|<%uri-orig%>|$tom::H_www$main::ENV{REQUEST_URI}|g;
	$email=~s|<%uri-referer%>|$main::ENV{HTTP_REFERER}|g;
	#$email=~s|<%page_code%>|$main::request_code|g;
	
	foreach (sort keys %main::ENV)
	{
		my $val=$main::ENV{$_};
		
		if (($main::IAdm || $main::ITst)&& ($_=~/^(QUERY|HTTP_COOKIE)/))
		{$val="(search do log)";}
		
		my $env=$email_ENV_;
		$env=~s|<%var%>|$_|g;
		$env=~s|<%value%>|$val|g;
		$email=~s|<#ENV#>|$env\n<#ENV#>|;
		
	}
	
	$email=~s|<%to%>|$email_addr|;
	
	Utils::vars::replace($email);
	
	$email=~s|<#.*?#>||g;
	$email=~s|<%.*?%>||g;
	
	if ($TOM::ERROR_email)
	{
		$msg->attach
		(
			'Data' => $email,
			'Type' => 'text/html;charset="UTF-8"',
			'Encoding' => "8bit",
		);
		my $email_body=$msg->as_string();
		TOM::Net::email::send(
			'priority'=>99,
			'to'=>$email_addr,
			'body'=>$email_body,
		);
	}
	
	# aky kod budem vypluvat?
	# stihol som uz nacitat?
	if ($_[0]=~/^silent/)
	{
		
	}
	elsif (!$Net::DOC::err_page)
	{
		# ak nemam ziadny kod, tak som "umrel" prilis v skorej faze a v tom
		# pripade nevyplujem ziaden kod a dam radsej rovno exit
		# ( email o chybe som poslal, tak dufam ze to bude niekto okamzite riesit )
		#
		# preco tu nechcem vyplut aspon default nenadesignovany error?
		#
		# mal by som vyplut aspon minimalny error v HTML 1.1
		#
		exit(1);
	}
	else
	{
		print "Content-Type: ".$Net::DOC::content_type."; charset=UTF-8\n\n";
		my $out=$Net::DOC::err_page;
		Utils::vars::replace($out);
		$out=~s|<!--ERROR-->|<!-- $var -->|;
		print $out;
	}
	
}



#
# uz som v stave ze mozem von vyplut aspon nejaky lepsi email
# ak sa vyskytol vazny problem
#
sub engine_cron
{
	my $var=join(". ",@_);$var=~s|[\n\r]| |g;
	
	main::_log("[ENGINE-$TOM::engine][$cron::type/$tom::H] $var",1);
	main::_log("[ENGINE-$TOM::engine][$cron::type/$tom::H] $var",4,"$TOM::engine.err",1);
	
	# poslem email co najskor
	my $date=TOM::Utils::datetime::mail_current;
	
	my $email=$engine_email || $TOM::Error::engine_email_lite;
	
	my $email_addr;
	foreach ("TOM",@TOM::ERROR_email_send)
	{
		$email_addr.=";".$TOM::contact{$_};
	};
	$email_addr=TOM::Utils::vars::unique_split($email_addr);
	
	my $msg = MIME::Entity->build
	(
		'Type'    => "multipart/related",
		'List-Id' => "Cyclone3",
		'Date'    => $date,
		'From'    => "Cyclone3 ('$tom::H' at '$TOM::hostname') <$TOM::contact{'from'}>",
		'To'      => TOM::Net::email::convert_TO($email_addr),
		'Subject' => "[ERR][ENGINE-$TOM::engine][$cron::type]"
	);
	
	$email=~s|<%DATE%>|$date|;
	$email=~s|<%DOMAIN%>|$tom::H|g;
	$email=~s|<%ERROR%>|$var|g;
	
	
	if ($tom::H)
	{
		# som uz v domene, nacital som asi local.conf
		# tak poslem info o chybe i vsade inde
		# ohladne projektu
		$email=~s|<#PROJECT#>|$email_project|;
		
	}
	
	foreach (sort keys %main::ENV)
	{
		my $val=$main::ENV{$_};
		
		if (($main::IAdm || $main::ITst)&& ($_=~/^(QUERY|HTTP_COOKIE)/))
		{$val="(search do log)";}
		
		my $env=$email_ENV_;
		$env=~s|<%var%>|$_|g;
		$env=~s|<%value%>|$val|g;
		$email=~s|<#ENV#>|$env\n<#ENV#>|;
		
	}
	
	$email=~s|<%to%>|$email_addr|;
	
	Utils::vars::replace($email);
	
	$email=~s|<#.*?#>||g;
	$email=~s|<%.*?%>||g;
	
	$msg->attach
	(
		'Data' => $email,
		'Type' => 'text/html;charset="UTF-8"',
		'Encoding' => "8bit",
	);
	my $email_body=$msg->as_string();
	TOM::Net::email::send(
		'priority'=>99,
		'to'=>$email_addr,
		'body'=>$email_body,
	);
	
}






sub module
{
	
	
	# zvysujem mieru logovania ak sa vyskytuje chyba
	$TOM::DEBUG_log_file++;
	$main::result="failed";
	
	if ($TOM::engine eq "pub")
	{
		module_pub(@_);
	}
#	else
#	{
#		engine_lite(@_);
#	}
}



sub module_pub
{
	my %env=@_;
	return undef unless $env{-MODULE};
	$env{-TMP}="ERROR" unless $env{-TMP};
	
	my $out=$Net::DOC::err_mdl;
	Utils::vars::replace($out);
	
	$out=~s|<%MODULE%>|$env{-MODULE}|;
	$out=~s|<%ERROR%>|$env{-ERROR}| if $main::IAdm;
	$out=~s|<%PLUS%>|$env{-PLUS}| if $main::IAdm;
	$out=~s|<%.*?%>||g;
	
	main::_log("$env{-ERROR} $env{-PLUS}",1); #local
	main::_log("[MDL::$env{-MODULE}] $env{-ERROR} $env{-PLUS}",1,"pub.err",0); #local
	main::_log("[$tom::H][MDL::$env{-MODULE}] $env{-ERROR} $env{-PLUS}",4,"pub.err",1); #global
	main::_log("[$tom::H][MDL::$env{-MODULE}] $env{-ERROR} $env{-PLUS}",4,"pub.err",2) if ($tom::H ne $tom::Hm); #master
	
	if (($TOM::ERROR_module_email) && (!$main::IAdm))
	{
		
		my $date = TOM::Utils::datetime::mail_current();
		
		my $email_addr;
		foreach ("TOM",@TOM::ERROR_email_send)
		{
			$email_addr.=";".$TOM::contact{$_};
		}
		$email_addr.=";".$Tomahawk::module::authors;
		$email_addr=TOM::Utils::vars::unique_split($email_addr);
		
		my $msg = MIME::Entity->build
		(
			'Type'    => "multipart/related",
			'List-Id' => "Cyclone3",
			'Date'    => $date,
			'From'    => "Cyclone3 ('$tom::H' at '$TOM::hostname') <$TOM::contact{'from'}>",
			'To'      => TOM::Net::email::convert_TO($email_addr),
			'Subject' => "[ERR][MODULE-$TOM::engine][$env{-MODULE}]"
		);
		
		my $email=$module_email;
		
		$email=~s|<%TYPE_%>|Error|;
		$email=~s|<%DATE%>|$date|;
		$email=~s|<%DOMAIN%>|$tom::H|g;
		$email=~s|<%ERROR%>|$env{-ERROR}|g;
		$email=~s|<%ERROR-PLUS%>|$env{-PLUS}|g;
		
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
		
		foreach (sort keys %main::ENV)
		{
			my $val=$main::ENV{$_};
			if (($main::IAdm || $main::ITst)&& ($_=~/^(QUERY|HTTP_COOKIE)/))
			{$val="(search do log)";}
			my $env=$email_ENV_;
			$env=~s|<%var%>|$_|g;
			$env=~s|<%value%>|$val|g;
			$email=~s|<#ENV#>|$env\n<#ENV#>|;
		}
		
		$email=~s|<%to%>|$email_addr|;
		
		Utils::vars::replace($email);
		$email=~s|<#.*?#>||g;
		$email=~s|<%.*?%>||g;
		
		$msg->attach
		(
			'Data' => $email,
			'Type' => 'text/html;charset="UTF-8"',
			'Encoding' => "8bit",
		);
		my $email_body=$msg->as_string();
		
		TOM::Net::email::send(
			'priority'=>99,
			'to'=>$email_addr,
			'body'=>$email_body,
		);
	}
	
	return 1 if $main::H->r_("<!TMP-".$env{-TMP}."!>",$out);
	return 1 if $main::H->r_("<!TMP-ERROR!>",$out);
	$main::H->a($out);
}





1;
