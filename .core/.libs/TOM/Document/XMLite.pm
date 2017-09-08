package TOM::Document;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
our @ISA=("TOM::Document::base"); # dedim z neho

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

our $content_type="text/xml";
our $type='xml';

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
	$self->{'OUT'}{'HEADER'} = "<?xml version=\"1.0\" encoding=\"<%CODEPAGE%>\"?>\n";
	$self->{'OUT'}{'HEADER'} .= qq{<!--
$TOM::Document::base::copyright
-->
} if $TOM::Document::base::copyright;
	
	$self->{'OUT'}{'BODY'} = qq{<!TMP-CONTENT!>} unless $self->{'OUT'}{'BODY'};
	return 1;
}


sub prepare_last
{
	my $self=shift;
	my %env=@_;
 
	$self->{OUT}{HEADER}=~s|<%HEADER-TITLE%>|$self->{env}{DOC_title}|;
	$self->{OUT}{HEADER}=~s|<%HEADER-LNG%>|$tom::lng|;
	$self->{OUT}{HEADER}=~s|<%PAGE-CODE%>|$main::request_code|;
	$self->{OUT}{HEADER}=~s|<%domain%>|$tom::H#$env{result}|;
	
 return 1;
}

sub message {}


1;
