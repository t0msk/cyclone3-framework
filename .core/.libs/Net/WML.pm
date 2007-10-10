package Net::DOC;
use strict;
our @ISA=("Net::DOC::base"); # dedim z neho

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

our $content_type="text/vnd.wap.wml";
our $type='wml';
$pub::engine_disabling=0;

our $err_page=<<"HEADER";
<p align="center">ERROR</p>
<p>We apologize, this page is currently unavailable. Please, try to reload it in a few minutes.</p>
<!--ERROR-->
HEADER


our $err_mdl=<<"HEADER";
<p><%MODULE%> - This service is currently not available. We're trying to fix this problem at the moment and apologize for any incovnenience.</p>
<!-- <%MODULE%> - <%ERROR%> <%PLUS%> -->
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

sub message {return 1;}

sub prepare
{
	my $self=shift;
	
	$self->{ENV}{DOCTYPE} = "<!DOCTYPE wml PUBLIC \"-//WAPFORUM//DTD WML 1.1//EN\" \"http://www.wapforum.org/DTD/wml_1.1.xml\">" unless $self->{ENV}{DOCTYPE};
	
	$self->{OUT}{HEADER} .= "<?xml version=\"1.0\" encoding=\"<%CODEPAGE%>\"?>\n";
	
	$self->{OUT}{HEADER} .= $self->{ENV}{DOCTYPE}."\n";
	
	$self->{OUT}{HEADER} .= "<wml>\n";
	
	$self->{OUT}{HEADER} .= "<card id=\"XML\" title=\"<%TITLE%>\">";
	$self->{env}{DOC_title}=$self->{ENV}{'HEAD'}{'TITLE'};
	$self->{env}{DOC_title}=$tom::H unless $self->{env}{DOC_title};
	
	
	$self->{OUT}{FOOTER} = "</card>\n</wml>\n";
 
	return 1;
}


sub prepare_last
{
	my $self=shift;
	
	# aplikujem title
	$self->{OUT}{HEADER}=~s|<%TITLE%>|$self->{env}{DOC_title}|;
	
	return 1;
}


sub add_DOC_css_link {return 1}

1;