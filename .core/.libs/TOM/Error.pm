package TOM::Error;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


use TOM::Net::email;
use MIME::Entity;
use TOM::Error::design;
use TOM::Utils::datetime;
use TOM::Utils::vars;
use Utils::vars;
use CVML;

sub engine
{
	eval
	{
		$main::result="failed";
		if ($TOM::engine eq "pub")
		{
			engine_pub(@_);
			main::_event("error","engine.error",{
				'pub' => {
					'REMOTE_ADDR' => $main::ENV{'REMOTE_ADDR'},
					'REFERER' => $main::ENV{'HTTP_REFERER'},
					'HOST' => $main::ENV{'HTTP_HOST'},
					'REQUEST_URI' => $main::ENV{'REQUEST_URI'},
					'QUERY_STRING' => $main::ENV{'QUERY_STRING'},
#					'query' => {%main::FORM},
					'USER_AGENT' => $main::ENV{'HTTP_USER_AGENT'},
					'UserAgent' => $main::UserAgent_name,
					'UserAgent_type' => $TOM::Net::HTTP::UserAgent::table[$main::UserAgent]{'agent_type'}
				},
				'message'=> join(". ", @_)
			});
		}
		elsif ($TOM::engine=~/^cron/)
		{
			engine_cron(@_);
			main::_event("error","engine.error",{'message'=>[@_]});
		}
		else
		{
			engine_lite(@_);
			main::_event("error","engine.error",{'message'=>[@_]});
		}
	};
}


#
# uz som v stave ze mozem von vyplut aspon nejaku page
# ak sa vyskytol vazny problem
#
sub engine_pub
{
	my $var=join(". ",@_);$var=~s|[\n\r]| |g;
	
	main::_log("[ENGINE-$TOM::engine][$tom::H] $var",4);
	
	my $URI_base=$tom::H_www;my $request_uri=$main::ENV{'REQUEST_URI'};$request_uri=~s|^$tom::rewrite_RewriteBase||;
	
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
		'Subject' => "[ERR][$TOM::engine][URI::$request_uri]"
	);
	
	my $email=$engine_email || $TOM::Error::engine_email_lite;
	
	$email=~s|<%DATE%>|$date|;
	$email=~s|<%SUBJ%>||;
	$email=~s|<%DOMAIN%>|$tom::H|g;
	$email=~s|<%ERROR%>|$var|g;
	
	$email=~s|<#FARM#>|$email_farm|;
	
	$email=~s|<#PROJECT#>|$email_project\n$email_project_pub|;
	
	if ($main::IAdm || $main::ITst)
	{
		$email=~s|<%uri-parsed%>|(search do log)|g;
	}
	
	$email=~s|<%uri-parsed%>|$tom::H_www/?$main::ENV{'QUERY_STRING_FULL'}|g;
	
	$email=~s|<%uri-orig%>|$URI_base$request_uri|g;
	$email=~s|<%uri-referer%>|$main::ENV{'HTTP_REFERER'}|g;
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
	
	TOM::Utils::vars::replace($email);
	
	$email=~s|<#.*?#>||g;
	$email=~s|<%.*?%>||g;

	my $ticket_ok = 1;
	
	if ( $TOM::ERROR_ticket && $main::DB{'main'})
	{eval{
		
#		main::_log("Chcem vlozit ticket s errorom engine modulu $TOM::engine");
		# Zistim si emaily
		my $email_addr;
		foreach ("TOM",@TOM::ERROR_email_send)
		{
			if ( $TOM::contact{$_} )
			{
				$email_addr.=";" if $email_addr;
				$email_addr.="<".$TOM::contact{$_}.">";
			}
		}
		$email_addr=TOM::Utils::vars::unique_split( $email_addr );

		## Vyskladam CVML
		my %cvml_hash = (
			'ENV' => { %main::ENV },
			'ERROR' => { 'text' => $var },
			'Cyclone' => {
				'domain'=>"$tom::H_www",
				'hostname'=>"$TOM::hostname",
				'request_URI'=>$main::ENV{'REQUEST_URI'},
				'parsed_URI'=>"$tom::H_www/?$main::ENV{'QUERY_STRING_FULL'}",
				'orig_URI'=>"$URI_base$request_uri",
				'referer_URI'=>"$main::ENV{'HTTP_REFERER'}",
				'request_number'=>"$tom::count/$TOM::max_count",
				'unique_hash'=>$main::request_code,
				'TypeID'=>$main::FORM{'TID'},
			},
		);
		
		my $cvml = CVML::structure::serialize( %cvml_hash );
		TOM::Utils::vars::replace( $cvml );
		
		$ticket_ok = App::100::SQL::ticket_event_new(
			'domain' => $tom::H,
			'name' => "[$TOM::engine][URI::$main::ENV{REQUEST_URI}]",
			'emails' => $email_addr,
			'cvml' => $cvml,
		);
	}}
	
	if (
			($TOM::ERROR_email && $_[0]!=~/^silent/) # this is page generation error
			|| ($TOM::ERROR_page_email && $_[0]=~/^silent/) # page silent error (page not found)
			|| !$ticket_ok # ticket can't be created
		)
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
		main::_log("silent error");
	}
	elsif (!$TOM::Document::err_page)
	{
		main::_log("not defined TOM::Document::err_page, using buildin TOM::Error");
		# ak nemam ziadny kod, tak som "umrel" prilis v skorej faze a v tom
		# pripade nevyplujem ziaden kod a dam radsej rovno exit
		# ( email o chybe som poslal, tak dufam ze to bude niekto okamzite riesit )
		#
		# preco tu nechcem vyplut aspon default nenadesignovany error?
		#
		# mal by som vyplut aspon minimalny error v HTML 1.1
		#
		print "Status: 500 Internal Server Error\n";
		print "Content-Type: text/html; charset=ISO-8859-1\n";
		print "\n";
print qq{<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN"> 
<html>
	<head> 
		<title>500 Internal Server Error</title> 
	</head>
<body> 
<h1>Internal Server Error</h1>
<p>The server encountered an internal error or misconfiguration and was unable to start Cyclone3 Publisher engine.</p>};
print "<p><small>\n";print $_.". \n" foreach (@_);print "</small></p>\n";
print qq{<p>Please contact the server administrator, $TOM::contact{'TECH'} and inform them of the time the error occurred, and anything you might have done that may have caused the error.</p>
<p>More information about this error may be available in the Cyclone3 engine error log.</p>
<hr>
<address>$TOM::core_name/$TOM::core_version.$TOM::core_build Server at $TOM::hostname</address>
</body></html>
};
#		exit(1);
	}
	else
	{
		print "Content-Type: ".$TOM::Document::content_type."; charset=UTF-8\n\n";
		my $tpl=new TOM::Template(
			'level' => "auto",
			'name' => "default",
			'content-type' => $TOM::Document::type
		);
		my $page=$tpl->{'entity'}{'page.error'};
		TOM::Utils::vars::replace($page);
		$page=~s|<!--ERROR-->|<!-- $var -->|;
		$page=~s|<%message%>|$var|;
		print $page;
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
		'Subject' => "[ERR][$TOM::engine][$cron::type]"
	);
	
	$email=~s|<%DATE%>|$date|;
	$email=~s|<%DOMAIN%>|$tom::H|g;
	$email=~s|<%ERROR%>|$var|g;
	
	$email=~s|<#FARM#>|$email_farm|;
	
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
	
	TOM::Utils::vars::replace($email);
	
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

	if ( $TOM::ERROR_ticket )
	{
#		main::_log("Chcem vlozit ticket s errorom engine cronu $TOM::engine");
		# Zistim si emaily
		my $email_addr;
		foreach ("TOM",@TOM::ERROR_email_send)
		{
			if ( $TOM::contact{$_} )
			{
				$email_addr.=";" if $email_addr;
				$email_addr.="<".$TOM::contact{$_}.">";
			}
		}
		$email_addr=TOM::Utils::vars::unique_split( $email_addr );

		## Vyskladam CVML
		my %cvml_hash = (
			'ENV' => { %main::ENV },
			'ERROR' => { 'text' => $var },
			'Cyclone' => {
				'hostname'=>"$TOM::hostname",
				'unique_hash'=>$main::request_code,
				'TypeID'=>$main::FORM{'TID'}
			},
		);

		my $cvml = CVML::structure::serialize( %cvml_hash );
		TOM::Utils::vars::replace( $cvml );

		App::100::SQL::ticket_event_new(
			'domain' => $tom::H,
			'name' => "[$TOM::engine][$cron::type]",
			'emails' => $email_addr,
			'cvml' => $cvml,
		);
	}
}






sub module
{
	# zvysujem mieru logovania ak sa vyskytuje chyba
#	$TOM::DEBUG_log_file++;
	$main::result="failed";
	
	if ($TOM::engine eq "pub")
	{
		module_pub(@_);
		main::_event("error","module.error",{
			'pub' => {
				'REMOTE_ADDR' => $main::ENV{'REMOTE_ADDR'},
				'REFERER' => $main::ENV{'HTTP_REFERER'},
				'HOST' => $main::ENV{'HTTP_HOST'},
				'REQUEST_URI' => $main::ENV{'REQUEST_URI'},
				'QUERY_STRING' => $main::ENV{'QUERY_STRING'},
#				'query' => {%main::FORM},
				'USER_AGENT' => $main::ENV{'HTTP_USER_AGENT'},
				'UserAgent' => $main::UserAgent_name,
				'UserAgent_type' => $TOM::Net::HTTP::UserAgent::table[$main::UserAgent]{'agent_type'},
			},
			@_
		});
	}
	elsif ($TOM::engine=~/^cron/)
	{
		module_cron(@_);
		main::_event("error","module.error",{@_});
	}
	else
	{
#		engine_lite(@_);
		main::_event("error","module.error",{@_});
	}
}



sub module_pub
{
	my %env=@_;
	return undef unless $env{-MODULE};
	$env{-TMP}="ERROR" unless $env{-TMP};
	
	my $tpl=new TOM::Template(
		'level' => "auto",
		'name' => "default",
		'content-type' => $TOM::Document::type
	);
	my $box=$tpl->{'entity'}{'box.error'};
	
	TOM::Utils::vars::replace($box);
	
	$box=~s|<%MODULE%>|$env{-MODULE}|g;
	$box=~s|<%ERROR%>|$env{-ERROR}| if $tom::devel;
	$box=~s|<%PLUS%>|$env{-PLUS}| if $tom::devel;
	$box=~s|<%.*?%>||g;
	
	main::_log(($env{'-ERROR'} || "unknown error in module")." ".$env{'-PLUS'}." ".$env{'-MODULE'},1);
#	main::_log("$env{-MODULE} $env{-ERROR} $env{-PLUS}",1,"pub.err",0); #local
#	main::_log("[$tom::H]$env{-MODULE} $env{-ERROR} $env{-PLUS}",4,"pub.err",1); #global
#	main::_log("[$tom::H]$env{-MODULE} $env{-ERROR} $env{-PLUS}",4,"pub.err",2) if ($tom::H ne $tom::Hm); #master
	App::100::SQL::ircbot_msg_new("[ERR][$tom::H]$env{-MODULE} $env{-ERROR} $env{-PLUS}");
	
	my $URI_base=$tom::H_www;my $request_uri=$main::ENV{'REQUEST_URI'};$request_uri=~s|^$tom::rewrite_RewriteBase||;
	
	my $ticket_ok = 1;
	
	if ($TOM::ERROR_module_ticket)
	{
		#main::_log("Chcem vlozit ticket s errorom modulu $env{-MODULE}");
		
		# nebudem logovat informacie o tom ako zapisujem error
		local $TOM::DEBUG_log_file=-1;
		local $main::debug=0;
		
		# Zistim si emaily
		my $email_addr;
		foreach ("TOM",@TOM::ERROR_email_send)
		{
			if ( $TOM::contact{$_} )
			{
				$email_addr.=";" if $email_addr;
				$email_addr.="<".$TOM::contact{$_}.">";
			}
		}
		$email_addr=TOM::Utils::vars::unique_split( $email_addr );
		
		## Vyskladam CVML
		my %cvml_hash = (
			'ENV' => { %main::ENV },
			'ERROR' => {
				'text' => $env{'-ERROR'},
				'plus' => $env{'-PLUS'},
			},
			'Cyclone' => {
				'hostname'=>"$TOM::hostname",
				'request_URI'=>$main::ENV{'REQUEST_URI'},
				'parsed_URI'=>"$tom::H_www/?$main::ENV{'QUERY_STRING_FULL'}",
				'orig_URI'=>"$URI_base$request_uri",
				'referer_URI'=>"$main::ENV{'HTTP_REFERER'}",
				'request_number'=>"$tom::count/$TOM::max_count",
				'unique_hash'=>$main::request_code,
				'TypeID'=>$main::FORM{'TID'}
			},
		);
		
		my $cvml = CVML::structure::serialize( %cvml_hash );
		
		$ticket_ok = App::100::SQL::ticket_event_new(
			'domain' => $tom::H,
			'name' => "[$TOM::engine]$env{-MODULE}",
			'emails' => $email_addr,
			'cvml' => $cvml,
		);
		
	}
	
	
	if ((($TOM::ERROR_module_email) && (!$main::IAdm))||!$ticket_ok)
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
			'Subject' => "[ERR][$TOM::engine]$env{-MODULE}"
		);
		
		my $email=$module_email;
		
		$email=~s|<%TYPE_%>|Error|;
		$email=~s|<%DATE%>|$date|;
		$email=~s|<%DOMAIN%>|$tom::H|g;
		$email=~s|<%ERROR%>|$env{-ERROR}|g;
		$email=~s|<%ERROR-PLUS%>|$env{-PLUS}|g;
		
		$email=~s|<#FARM#>|$email_farm|;
		
		$email=~s|<#PROJECT#>|$email_project\n$email_project_pub|;
		
		$email=~s|<#MODULE#>|$email_module|;
		
		$email=~s|<%MODULE%>|$env{-MODULE}|g;
		
		if ($main::IAdm || $main::ITst)
		{
			$email=~s|<%uri-parsed%>|(search do log)|g;
		}
		
		$email=~s|<%uri-parsed%>|$tom::H_www/?$main::ENV{QUERY_STRING_FULL}|g;
		
		$email=~s|<%uri-orig%>|$URI_base$request_uri|g;
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
		
		TOM::Utils::vars::replace($email);
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
	
	return 1 if $main::H->r_("<!TMP-".$env{-TMP}."!>",$box);
	return 1 if $main::H->r_("<!TMP-ERROR!>",$box);
	$main::H->a($box);
}



sub module_cron
{
	my %env=@_;
	return undef unless $env{-MODULE};
	$env{-TMP}="ERROR" unless $env{-TMP};
	
	main::_log("$env{-ERROR} $env{-PLUS}",1); #local
	main::_log("[MDL::$env{-MODULE}] $env{-ERROR} $env{-PLUS}",1,"cron.err",0); #local
	main::_log("[$tom::H][MDL::$env{-MODULE}] $env{-ERROR} $env{-PLUS}",4,"cron.err",1); #global
	main::_log("[$tom::H][MDL::$env{-MODULE}] $env{-ERROR} $env{-PLUS}",4,"cron.err",2) if ($tom::H ne $tom::Hm); #master

	my $ticket_ok = 1;

	if ($TOM::ERROR_module_ticket)
	{
#		main::_log("Chcem vlozit ticket s errorom cronu $env{-MODULE}");
		
		# nebudem logovat informacie o tom ako zapisujem error
		local $TOM::DEBUG_log_file=-1;
		local $main::debug=0;
		
		# Zistim si emaily
		my $email_addr;
		foreach ("TOM",@TOM::ERROR_email_send)
		{
			if ( $TOM::contact{$_} )
			{
				$email_addr.=";" if $email_addr;
				$email_addr.="<".$TOM::contact{$_}.">";
			}
		}
		$email_addr=TOM::Utils::vars::unique_split( $email_addr );

		## Vyskladam CVML
		my %cvml_hash = (
			'ENV' => { %main::ENV },
			'ERROR' => {
				'text' => $env{'-ERROR'},
				'plus' => $env{'-PLUS'},
			},
			'Cyclone' => {
				'hostname'=>"$TOM::hostname",
				'request_number'=>"$tom::count/$TOM::max_count",
				'unique_hash'=>$main::request_code,
				'TypeID'=>$main::FORM{'TID'},
			},
		);

		my $cvml = CVML::structure::serialize( %cvml_hash );
		TOM::Utils::vars::replace( $cvml );
		
		$ticket_ok = App::100::SQL::ticket_event_new(
			'domain' => $tom::H,
			'name' => "[cron]$env{-MODULE}",
			'emails' => $email_addr,
			'cvml' => $cvml,
		);
		
	}
	
	if ($TOM::ERROR_module_email||!$ticket_ok)
	{
		
		my $date = TOM::Utils::datetime::mail_current();
		
		my $email_addr;
		foreach ("TOM",@TOM::ERROR_email_send)
		{
			$email_addr.=";".$TOM::contact{$_};
		}
		#$email_addr.=";".$Tomahawk::module::authors;
		$email_addr=TOM::Utils::vars::unique_split($email_addr);
		
		my $msg = MIME::Entity->build
		(
			'Type'    => "multipart/related",
			'List-Id' => "Cyclone3",
			'Date'    => $date,
			'From'    => "Cyclone3 ('$tom::H' at '$TOM::hostname') <$TOM::contact{'from'}>",
			'To'      => TOM::Net::email::convert_TO($email_addr),
			'Subject' => "[ERR][$TOM::engine]$env{-MODULE}"
		);
		
		my $email=$module_email;
		
		$email=~s|<%TYPE_%>|Error|;
		$email=~s|<%DATE%>|$date|;
		$email=~s|<%DOMAIN%>|$tom::H|g;
		$email=~s|<%ERROR%>|$env{-ERROR}|g;
		$email=~s|<%ERROR-PLUS%>|$env{-PLUS}|g;
		
		$email=~s|<#FARM#>|$email_farm|;
		
		$email=~s|<#PROJECT#>|$email_project|;
		
		$email=~s|<#MODULE#>|$email_module|;
		
		$email=~s|<%MODULE%>|$env{-MODULE}|g;
		
		foreach (sort keys %main::ENV)
		{
			my $val=$main::ENV{$_};
			my $env=$email_ENV_;
			$env=~s|<%var%>|$_|g;
			$env=~s|<%value%>|$val|g;
			$email=~s|<#ENV#>|$env\n<#ENV#>|;
		}
		
		$email=~s|<%to%>|$email_addr|;
		
		TOM::Utils::vars::replace($email);
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

	return 1;
}




1;
