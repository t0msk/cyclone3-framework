package Net::DOC::base;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

sub message
{
 my $self=shift;
 foreach (@_)
 {
  $self->a("<!-- ".$_." -->");
 }
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
 $self->{env}{DOC_title}.=" - ".shift;
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
	$env{lang}="null" unless $env{lang};
	main::_log("change_DOC_description='$text'");
	$self->{env}{DOC_description}{$env{lang}}=$text;
	return 1;
}
sub add_DOC_description
{
	my $self=shift;
	my $text=shift;
	my %env=@_;
	$env{lang}="null" unless $env{lang};
	main::_log("add_DOC_description='$text'");
	$self->{env}{DOC_description}{$env{lang}}.=$text;
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




sub i # insert at begin
{
 my $self=shift;
 return undef unless my $code=shift;
 $self->{OUT}{BODY} = $code . "\n" . $self->{OUT}{BODY};
 return 1;
}

sub rh # replace in header
{
 my $self=shift;
 return undef unless my $what=shift;
 return undef unless my $code=shift;
 return undef unless $self->{OUT}{HEADER}=~s|$what|$code|g;
 return 1;
}

sub r # replace
{
 my $self=shift;
 return undef unless my $what=shift;
 return undef unless my $code=shift;
 return undef unless $self->{OUT}{BODY}=~s|$what|$code|g;
 return 1;
}

sub r_ # replace next
{
 my $self=shift;
 return undef unless my $what=shift;
 return undef unless my $code=shift;
 return undef unless $self->{OUT}{BODY}=~s|$what|$code\n$what|g;
 return 1;
}

sub a # append
{
 my $self=shift;
 return undef unless my $code=shift;
 $self->{OUT}{BODY} .= "\n" . $code;
 return 1;
}




sub OUT # get html code
{
 my $self=shift;
 return $self->{OUT}{HEADER}.$self->{OUT}{BODY}.$self->{OUT}{FOOTER};
}



sub BODY # get body code
{
 my $self=shift;
 return $self->{OUT}{BODY};
}



sub OUT_ # get clean html code
{
 my $self=shift;
#my @text=split('\n',$self->{body});
# my $out;
# foreach (@text)
# {
#  if ($_){$out .= $_."\n"}
# }
 $self->{OUT}{BODY}=~s|<%.*?%>||gs;
 $self->{OUT}{BODY}=~s|<#.*?#>||gs;
 $self->{OUT}{BODY}=~s|<![^-].*?!>||g;# unless $main::IAdm;
 $self->{OUT}{BODY}=~s|<!---->||g;# unless $main::IAdm;
 $self->{OUT}{HEADER}=~s|<%.*?%>||gs;
 $self->{OUT}{HEADER}=~s|<#.*?#>||gs;
 $self->{OUT}{HEADER}=~s|<!.*?!>||g;# unless $main::IAdm;
 #return $self->{OUT}{HEADER}."\n\n".$self->{OUT}{BODY}."\n\n".$self->{OUT}{FOOTER};
 my $doc=$self->{OUT}{HEADER}.$self->{OUT}{BODY}.$self->{OUT}{FOOTER};
 1 while ($doc=~s|\n\n$|\n|g);
 utf8::decode($doc);
 return $doc;
}


sub DESTROY
{
 my $self=shift; 
 $self={};
}

1;