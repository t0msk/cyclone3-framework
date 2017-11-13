package TOM::Document;
use strict;
our @ISA=("TOM::Document::base"); # dedim z neho
#use utf8;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our (	undef,
	undef,
	undef,
	undef,
	undef,
	$year,
	undef,
	undef,
	undef) = localtime(time);$year+=1900;

our $content_type="text/html";

our $err_page=<<"HEADER";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"><html>
<head>
  <title>Systémová chyba / System error</title>
  <meta http-equiv="content-type" content="text/html; charset=UTF-8" />
  <meta http-equiv="domain" content="<\$tom::H>#failed" />
  <meta name="author" content="Comsultia, Ltd. [www.comsultia.com]; e-mail: info\@comsultia.com" />
  <meta name="generator" content="Cyclone <\$TOM::core_version>/<\$TOM::core_build> at <\$TOM::hostname> [$$;<\$main::request_code>]" />

  <style type="text/css" media="screen">
  <!--
	body {
		font: small Arial, Helvetica, sans-serif;
		text-align: center;
		margin: 0; padding: 2em;
	}
	#page {
		width: 550px;
		margin: 0 auto;
		text-align: left;
		background: #FAFAFA;
		border: 1px solid #E1E1E1;
	}
	#page-i { padding: 10px; }
	a { color: red; }
	h1 { margin-top: 0; font-size: 120%; color: #7E7F82; }
	.right { text-align: right; }
  -->
  </style>
</head>


<body>

<div id="page"><div id="page-i">
	<div class="right">
		<img src="<\$TOM::H_grf>/cyclone-160x55.gif" alt="Cyclone" width="160" height="55" />
	</div>

	<h1>Systémová chyba</h1>
	<p>
		<strong>Ľutujeme, naša stránka je momentálne nedostupná, vyskúšajte ju obnoviť o niekoľko minút.</strong>
	</p>
	<p>
		Na odstránení chyby pracujeme. Ak problém pretrváva, môžete
		kontaktovať nášho administrátora na <a href="mailto:admin\@comsultia.com">admin\@comsultia.com</a>.
	</p>
	<hr />

	<h1>System error</h1>
	<p>
		<strong>We apologize, this page is currently unavailable. Please, try to reload it in a few minutes.</strong>
	</p>
	<p>
		We are currently working to fix this error.
		If the problem still persists, you can contact our administrator at <a href="mailto:admin\@comsultia.com">admin\@comsultia.com</a>.
	</p>
</div></div>
	
	<!--ERROR-->
	
	</body>
</html>
HEADER

our $err_mdl=<<"HEADER";
<table bgcolor='black' cellspacing='2' cellpadding='2'>
	<tr>
		<td style=\"FONT:bold 10px Verdana;COLOR:black;BACKGROUND:#F0F0F0;\">
			<img src="<\$TOM::H_grf>/errors/02.png" border='0' align='left'><%MODULE%> This service is currently not available. We're trying to fix this problem at the moment and apologize for any incovnenience. <%ERROR%> <%PLUS%>
		</td>
	</tr>
</table>
HEADER

sub new
{
 my $class=shift;
 my %env=@_;
 my $self={}; 
 %{$self->{ENV}}=%env;
 return bless $self,$class;
}


sub clone
{
 my $class=shift;
 my $self={};
 %{$self->{ENV}}=%{$class->{ENV}};
 %{$self->{env}}=%{$class->{env}};
 %{$self->{OUT}}=%{$class->{OUT}};
 return bless $self;
}


sub prepare
{
 my $self=shift;
 
 $self->{ENV}{DOCTYPE} = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">" unless $self->{ENV}{DOCTYPE};
 
 $self->{OUT}{HEADER} .= $self->{ENV}{DOCTYPE}."\n";

 $self->{OUT}{HEADER} .= "<HTML>\n";
 
 #------------------------------#
 # HEADER                         #
 #------------------------------#
 $self->{OUT}{HEADER} .= "<HEAD>\n"; 
 

 # TITLE
 $self->{OUT}{HEADER} .= " <TITLE><%TITLE%></TITLE>\n";
 $self->{env}{DOC_title}=$self->{ENV}{'HEAD'}{'TITLE'};
 $self->{env}{DOC_title}=$tom::H unless $self->{env}{DOC_title};

 # STYLE
 if ($self->{ENV}{HEAD}{STYLE})
 {
  $self->{OUT}{HEADER} .= " <style type=\"text/css\">\n <!--\n";
  if (ref($self->{ENV}{HEAD}{STYLE}) eq "HASH")
  {
   foreach (keys %{$self->{ENV}{HEAD}{STYLE}})
   {
    $self->{OUT}{HEADER} .= "  " . $_ . " {" . $self->{ENV}{HEAD}{STYLE}{$_} . "}\n";
   }
  }
  else
  {
   $self->{OUT}{HEADER} .= $self->{ENV}{HEAD}{STYLE}."\n";
  }
  $self->{OUT}{HEADER} .= " -->\n </style>\n";
 }
 
 
 $self->{OUT}{HEADER} .= " <META HTTP-EQUIV='Keywords' CONTENT='<%KEYWORDS%>'>\n";
 $self->{env}{DOC_keywords}=$self->{ENV}{HEAD}{META}{Keywords};
 $self->{env}{DOC_keywords}=$tom::H unless $self->{env}{DOC_keywords};
 delete $self->{ENV}{HEAD}{META}{Keywords};
 
 
 # META
 foreach (sort keys %{$self->{ENV}{HEAD}{META}})
 {$self->{OUT}{HEADER} .= " <META HTTP-EQUIV='" . $_ . "' CONTENT='" . $self->{ENV}{HEAD}{META}{$_} . "'>\n";}
 
 $self->{OUT}{HEADER} .=
	" <META HTTP-EQUIV='Content-Type' CONTENT='text/html; charset=<%CODEPAGE%>'>\n"
	unless $self->{ENV}{HEAD}{META}{'Content-Type'};

 
 # chybajuce powered
	
$self->{OUT}{HEADER} .=
	" <META HTTP-EQUIV='robots' CONTENT='index, follow'>\n"
	unless $self->{ENV}{HEAD}{META}{robots};


#=head1
 #my $var=`uname -ns`;chomp($var);
 $self->{OUT}{HEADER} .=
	" <META HTTP-EQUIV='powered' CONTENT='Cyclone publisher (".
	$TOM::core_name ." system)/".
	$TOM::core_version."/".
	$TOM::core_build." at ".$TOM::hostname.
	"'>\n" unless $self->{ENV}{HEAD}{META}{powered};

 $self->{OUT}{HEADER} .=
	" <META HTTP-EQUIV='build' CONTENT='on Linux desktop, MySQL 4.x, Perl 5.8.x'>\n"
	unless $self->{ENV}{HEAD}{META}{build};

 $self->{OUT}{HEADER} .= " <META HTTP-EQUIV='TOM-proc' CONTENT='$$'>\n";
 $self->{OUT}{HEADER} .= " <meta http-equiv='TOM-domain' content='<%TOM-domain%>' />\n";

 foreach my $hash(@{$self->{ENV}{HEAD}{LINK}})
 {
  $self->{OUT}{HEADER} .= " <LINK";
  foreach (sort keys %{$hash}){$self->{OUT}{HEADER} .= " ".$_ . "=\"".$$hash{$_}."\"";}
  $self->{OUT}{HEADER} .= ">\n";
 }
 
 
 
 if (ref($self->{ENV}{HEAD}{SCRIPT}) eq "ARRAY")
 {
 	foreach my $hash(@{$self->{ENV}{HEAD}{SCRIPT}})
 	{
  		$self->{OUT}{HEADER} .= " <SCRIPT";
  		foreach (sort keys %{$hash}){$self->{OUT}{HEADER} .= " ".$_ . "=\"".$$hash{$_}."\"";}
  		$self->{OUT}{HEADER} .= "></SCRIPT>\n";
 	}
 }
 elsif ($self->{ENV}{HEAD}{SCRIPT})
 {
  $self->{OUT}{HEADER} .= " <SCRIPT type=\"text/javascript\">\n".$self->{ENV}{HEAD}{SCRIPT}." </SCRIPT>\n";
 }

 $self->{OUT}{HEADER} .= "</HEAD>\n";

 # BODY
 $self->{OUT}{HEADER} .= "<BODY";

 foreach (keys %{$self->{ENV}{BODY}})
 {$self->{OUT}{HEADER} .= "\n " . $_ . "=" . "\"" . $self->{ENV}{BODY}{$_} . "\"";}
 $self->{OUT}{HEADER} .= ">\n";

 # FOOTER

 $self->{OUT}{FOOTER} = "</BODY>\n</HTML>\n";
#=cut
 
 return 1;
}




sub prepare_last
{
 my $self=shift;
 my %env=@_;
 
 # aplikujem title
 $self->{env}{DOC_title}=~s|\&(?!amp;)|&amp;|g;
 $self->{OUT}{HEADER}=~s|<%TITLE%>|$self->{env}{DOC_title}|;
 
 $self->{env}{DOC_keywords}=~s|^,||;
 $self->{env}{DOC_keywords}=~s|\&(?!amp;)|&amp;|g;
 $self->{OUT}{HEADER}=~s|<%KEYWORDS%>|$self->{env}{DOC_keywords}|;
 
 # aplikujem DOC_css_link
 my $DOC_css_link;
 foreach my $hash(@{$self->{env}{DOC_css_link}})
 {
  $DOC_css_link .= " <LINK";
  foreach (sort keys %{$hash}){$DOC_css_link .= " ".$_ . "=\"".$$hash{$_}."\"";}
  $DOC_css_link .= ">\n";
 }
 $self->{OUT}{HEADER}=~s|\n</HEAD>|\n$DOC_css_link</HEAD>| if $DOC_css_link;
 
 $self->{OUT}{HEADER}=~s|<%TOM-domain%>|$tom::H#$env{result}|;
 
 return 1;
}



1;













