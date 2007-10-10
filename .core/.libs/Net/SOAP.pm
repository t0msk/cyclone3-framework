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

our $content_type="text/xml";
our $type='soap';
my $tpl=new TOM::Template(
	'level' => "auto",
	'name' => "default",
	'content-type' => $type
);
our $err_page=$tpl->{'entity'}->{'page.error'};

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
	%{$self->{OUT}}=%{$class->{OUT}};
	return bless $self;
}



sub prepare
{
	my $self=shift;
	
	$self->{'OUT'}{'HEADER'} = qq{<?xml version="1.0" encoding="<%CODEPAGE%>"?>\n};
	$self->{'OUT'}{'HEADER'} .= qq{<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">\n};
	$self->{'OUT'}{'HEADER'} .= qq{<SOAP-ENV:Body>\n};
	
	# body
	
	$self->{'OUT'}{'FOOTER'} = qq{\n</SOAP-ENV:Body>\n};
	$self->{'OUT'}{'FOOTER'} .= qq{</SOAP-ENV:Envelope>\n};
	
	return 1;
}




sub prepare_last
{
	my $self=shift;
	my %env=@_;
	
	# aplikujem title
	$self->{'OUT'}{'HEADER'}=~s|<%HEADER-TITLE%>|$self->{env}{DOC_title}|;
	$self->{'OUT'}{'HEADER'}=~s|<%HEADER-LNG%>|$tom::lng|g;
	$self->{'OUT'}{'HEADER'}=~s|<%HEADER-CODE%>|$main::request_code|;
	
	return 1;
}



1;