package Net::DOC::base;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use vars qw{$AUTOLOAD};



sub message
{
	my $self=shift;
	foreach (@_)
	{
		$self->a("<!-- ".$_." -->");
	}
}



sub i # insert at begin
{
	my $self=shift;
	return undef unless my $code=shift;
	$self->{OUT}{BODY} = $code . "\n" . $self->{OUT}{BODY};
	return 1;
}

sub rh # replace only in header
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


sub OUT # get full code
{
	my $self=shift;
	return $self->{OUT}{HEADER}.$self->{OUT}{BODY}.$self->{OUT}{FOOTER};
}



sub BODY # get body code
{
	my $self=shift;
	return $self->{OUT}{BODY};
}


sub OUT_ # get clean code
{
	my $self=shift;
	$self->{OUT}{BODY}=~s|<%.*?%>||gs;
	$self->{OUT}{BODY}=~s|<#.*?#>||gs;
	$self->{OUT}{BODY}=~s|<![^-].*?!>||g;# unless $main::IAdm;
	$self->{OUT}{BODY}=~s|<!---->||g;# unless $main::IAdm;
	$self->{OUT}{HEADER}=~s|<%.*?%>||gs;
	$self->{OUT}{HEADER}=~s|<#.*?#>||gs;
	$self->{OUT}{HEADER}=~s|<!.*?!>||g;# unless $main::IAdm;
	my $doc=$self->{OUT}{HEADER}.$self->{OUT}{BODY}.$self->{OUT}{FOOTER};
	1 while ($doc=~s|\n\n$|\n|g);
	utf8::decode($doc) unless utf8::is_utf8($doc);
	return $doc;
}


sub AUTOLOAD
{
	my $self = shift;
	my $name = $AUTOLOAD;
	main::_log("Unknown Net::DOC method '$name'",1);
}


sub DESTROY
{
	my $self=shift; 
	$self={};
}

1;