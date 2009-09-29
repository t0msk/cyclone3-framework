package Net::DOC;

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

our @ISA=("Net::DOC::base");

use TOM::Template;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our (
	undef,
	undef,
	undef,
	undef,
	undef,
	$year,
	undef,
	undef,
	undef) = localtime(time);$year+=1900;

our $content_type="text/html";
our $type='xhtml';
my $tpl=new TOM::Template(
	'level' => "auto",
	'name' => "default",
	'content-type' => $type
);

our $err_page=$tpl->{'entity'}->{'page.error'};
our $warn_page=$tpl->{'entity'}->{'page.warning'};
our $err_mdl=$tpl->{'entity'}->{'box.error'};
our $notfound_page=$tpl->{'entity'}->{'body.notfound'};


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





sub change_DOC_title
{
	my $self=shift;
	$self->{env}{DOC_title}=shift;
	return 1;
}

sub add_DOC_title
{
	my $self=shift;
	my $text=shift;
#	$self->{env}{DOC_title}.=" - ".shift;
	$self->{'env'}{'DOC_title'}=$text . " - " . $self->{'env'}{'DOC_title'};
	return 1;
}

sub change_DOC_keywords
{
	my $self=shift;
	$self->{env}{DOC_keywords}=shift;
	return 1;
}

sub add_DOC_keywords
{
	my $self=shift;
	$self->{env}{DOC_keywords}.=",".shift;
	return 1;
}

sub change_DOC_description
{
	my $self=shift;
	my $text=shift;
	my %env=@_;
	$env{lng}="null" unless $env{lng};
	main::_log("change_DOC_description='$text'");
	$self->{env}{DOC_description}{$env{lng}}=$text;
	return 1;
}

sub add_DOC_description
{
	my $self=shift;
	my $text=shift;
	my %env=@_;
	$env{lng}="null" unless $env{lng};
	main::_log("add_DOC_description='$text'");
	$self->{env}{DOC_description}{$env{lng}}.=$text;
	return 1;
}

sub add_DOC_css_link
{
	my $self=shift;
	my %env=@_; 
	push @{$self->{env}{DOC_css_link}},{%env};
	return 1;
}

sub change_DOC_robots
{
	my $self=shift;
	$self->{env}{DOC_robots}=shift;
	return 1;
}



sub prepare
{
	my $self=shift;
 
	$self->{'ENV'}{'DOCTYPE'} =
		"<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">"
		unless $self->{ENV}{DOCTYPE};
	
	$self->{'OUT'}{'HEADER'} .= $self->{'ENV'}{'DOCTYPE'}."\n";
	
	$self->{'OUT'}{'HEADER'} .=
		'<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="<%HEADER-LNG%>" lang="<%HEADER-LNG%>">'."\n";
	
	$self->{'OUT'}{'HEADER'} .= '<head>'."\n"; 
	
	
	# TITLE
	$self->{'OUT'}{'HEADER'} .= ' <title><%HEADER-TITLE%></title>'."\n";
 
	$self->{env}{DOC_title}=$self->{ENV}{'head'}{'title'};
	$self->{env}{DOC_title}=$tom::H unless $self->{env}{DOC_title};
	
	# STYLE
	if ($self->{ENV}{head}{style})
	{
		$self->{OUT}{HEADER} .= " <style type=\"text/css\">\n <!--\n";
		if (ref($self->{ENV}{head}{style}) eq "HASH")
		{
			foreach (keys %{$self->{ENV}{head}{style}})
			{
				$self->{OUT}{HEADER} .= "  " . $_ . " {" . $self->{ENV}{head}{style}{$_} . "}\n";
			}
		}
		else
		{
			$self->{OUT}{HEADER} .= $self->{ENV}{head}{style}."\n";
		}
		$self->{OUT}{HEADER} .= " -->\n </style>\n";
	}
 
	$self->{OUT}{HEADER} .= '<%KEYWORDS%>';
	$self->{env}{DOC_keywords}=$self->{ENV}{head}{meta}{keywords};
	delete $self->{ENV}{head}{meta}{Keywords};
	delete $self->{ENV}{head}{meta}{keywords};
 
	
	$self->{OUT}{HEADER} .= '<%DESCRIPTION%>';
	$self->{env}{DOC_description}=$self->{ENV}{head}{meta}{description};
	delete $self->{ENV}{head}{meta}{description};
	
 
	# META
 
	$self->{OUT}{HEADER} .= " <meta http-equiv=\"content-language\" content=\"<%HEADER-LNG%>\" />\n";
	$self->{OUT}{HEADER} .= " <meta http-equiv=\"cache-control\" content=\"no-cache\" />\n";
	$self->{OUT}{HEADER} .= " <meta http-equiv=\"content-type\" content=\"text/html; charset=<%CODEPAGE%>\" />\n"
	unless $self->{ENV}{head}{meta}{'content-type'};
	
	
	$self->{ENV}{head}{meta}{refresh}=$self->{ENV}{head}{meta}{Refresh} if $self->{ENV}{head}{meta}{Refresh};
	delete $self->{ENV}{head}{meta}{Refresh};
	
	$self->{OUT}{HEADER} .= " <meta http-equiv=\"refresh\" content=\"$self->{ENV}{head}{meta}{refresh}\" />\n"
	if $self->{ENV}{head}{meta}{refresh};delete $self->{ENV}{head}{meta}{refresh};
	
	$self->{OUT}{HEADER} .=
	" <meta name=\"copyright\" content=\"".$self->{ENV}{head}{meta}{copyright}."\" />\n"
	if $self->{ENV}{head}{meta}{copyright};delete $self->{ENV}{head}{meta}{copyright};
	
	$self->{ENV}{head}{meta}{robots}="index,follow" unless $self->{ENV}{head}{meta}{robots};
	$self->{env}{DOC_robots}=$self->{ENV}{head}{meta}{robots};
	$self->{ENV}{head}{meta}{robots}="<%HEADER-ROBOTS%>";
	
	$self->{OUT}{HEADER} .=
	" <meta name=\"generator\" content=\"Cyclone3 ".
	$TOM::core_version.".".
	$TOM::core_build.
	" \" />\n" unless $self->{ENV}{head}{meta}{generator};
	
	$self->{'OUT'}{'HEADER'} .=
	" <meta name=\"Cyclone3\" content=\"<%META-Cyclone3%>\" />\n" unless $self->{'ENV'}{'head'}{'meta'}{'Cyclone3'};
	
	foreach (sort keys %{$self->{ENV}{head}{meta}})
	{$self->{OUT}{HEADER} .= " <meta name=\"" . $_ . "\" content=\"" . $self->{ENV}{head}{meta}{$_} . "\" />\n";}
	
	$self->{OUT}{HEADER} .= " <meta name=\"domain\" content=\"<%domain%>\" />\n";
	
	foreach my $hash(@{$self->{ENV}{head}{link}})
	{
		$self->{OUT}{HEADER} .= " <link";
		foreach (sort keys %{$hash}){$self->{OUT}{HEADER} .= " ".$_ . "=\"".$$hash{$_}."\"";}
		$self->{OUT}{HEADER} .= " />\n";
	}
 
	if (ref($self->{ENV}{head}{script}) eq "ARRAY")
	{
		foreach my $hash(@{$self->{ENV}{head}{script}})
		{
			$self->{OUT}{HEADER} .= " <script";
			foreach (sort keys %{$hash}){$self->{OUT}{HEADER} .= " ".$_ . "=\"".$$hash{$_}."\"";}
			$self->{OUT}{HEADER} .= "></script>\n";
		}
	}
	elsif ($self->{ENV}{head}{script})
	{
		$self->{OUT}{HEADER} .= " <script type=\"text/javascript\">\n".$self->{ENV}{head}{script}." </script>\n";
	}
	
	if ($self->{ENV}{head}{comment})
	{
		$self->{OUT}{HEADER} .= "<!--".$self->{ENV}{head}{comment}."-->\n";
	}
	
	if ($self->{ENV}{head}{inline})
	{
		$self->{OUT}{HEADER} .= $self->{ENV}{head}{inline}."\n";
	}
	
	$self->{OUT}{HEADER} .= "</head>\n";
	
	# BODY
	$self->{OUT}{HEADER} .= "<body";
	
	foreach (keys %{$self->{ENV}{body}})
	{$self->{OUT}{HEADER} .= "\n " . $_ . "=" . "\"" . $self->{ENV}{body}{$_} . "\"";}
	$self->{OUT}{HEADER} .= ">\n";
	
	# FOOTER
	
	$self->{OUT}{FOOTER} = "</body>\n</html>\n";
	
 return 1;
}




sub prepare_last
{
	my $self=shift;
	my %env=@_;
 
	# aplikujem title
	$self->{OUT}{HEADER}=~s|<%HEADER-TITLE%>|$self->{env}{DOC_title}|;
	$self->{OUT}{HEADER}=~s|<%HEADER-ROBOTS%>|$self->{env}{DOC_robots}|;
	$self->{OUT}{HEADER}=~s|<%HEADER-LNG%>|$tom::lng|g;
	$self->{OUT}{HEADER}=~s|<%PAGE-CODE%>|$main::request_code|;
 
	if ($self->{env}{DOC_keywords})
	{
		my %keywords;
		$self->{env}{DOC_keywords}=~s|,|;|g;
		foreach my $key (split(';',$self->{env}{DOC_keywords}))
		{
			1 while($key=~s|^ ||);
			1 while($key=~s| $||);
			next unless $key;
			$keywords{$key}++
		}
		$self->{env}{DOC_keywords}='';
		
		foreach my $key(sort {$keywords{$b} <=> $keywords{$a}} keys %keywords)
		{
			$self->{env}{DOC_keywords}.=", ".$key;
		}
		
		$self->{env}{DOC_keywords}=~s|^, ||;
		
		$self->{OUT}{HEADER}=~s|<%KEYWORDS%>| <meta name="keywords" content="$self->{env}{DOC_keywords}" />\n|;
	}
	
	foreach my $key (keys %{$self->{env}{DOC_description}})
	{
		$self->{env}{DOC_description}{$key}=~s|^\. ||g;
		$self->{env}{DOC_description}{$key}=~s|^\s+||;
		$self->{env}{DOC_description}{$key}=~s|[\t\n\r]| |g;
		1 while ($self->{env}{DOC_description}{$key}=~s|  | |g);
		$self->{env}{DOC_description}{$key}=~s|"|'|g;
		if (length ($self->{env}{DOC_description}{$key})>250)
		{
			$self->{env}{DOC_description}{$key}=~/^(.{250})/;
			$self->{env}{DOC_description}{$key}=$1;
		}
		
		next unless $self->{env}{DOC_description}{$key};
		
		if ($key eq "null")
		{
			$self->{OUT}{HEADER}=~s|<%DESCRIPTION%>| <meta name="description" content="$self->{env}{DOC_description}{$key}" />\n<%DESCRIPTION%>|;
		}
		else
		{
			$self->{OUT}{HEADER}=~s|<%DESCRIPTION%>| <meta name="description" lang="$key" content="$self->{env}{DOC_description}{$key}" />\n<%DESCRIPTION%>|;
		}
	}
	
	# DOC_css_link
	my $DOC_css_link;
	foreach my $hash(@{$self->{env}{DOC_css_link}})
	{
		$DOC_css_link .= " <link";
		foreach (sort keys %{$hash}){$DOC_css_link .= " ".$_ . "=\"".$$hash{$_}."\"";}
		$DOC_css_link .= " />\n";
	}
	
	$self->{OUT}{HEADER}=~s|\n</head>|\n$DOC_css_link</head>| if $DOC_css_link;
	
	$self->{OUT}{HEADER}=~s|<%domain%>|$tom::H#$env{result}|;
	
	
 return 1;
}





1;