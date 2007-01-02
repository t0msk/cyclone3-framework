#!/bin/perl
package Ext::docbook4CMS;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

=head1 NAME

Extension DocBook4CMS

=head1 DESCRIPTION

Extension that supports DocBook standard in CMS

=cut

BEGIN
{
	main::_log("<={LIB} ".__PACKAGE__);
}

use XML::Sablotron;

our $DIR=(__FILE__=~/^(.*)\//)[0];



=head1 FUNCTIONS

=head2 docbook2xhtml('<?xml>')

Convert DocBook XML content into XHTML content

=cut

sub sab_MHMakeCode
{
	my ($self, $processor, $severity, $facility, $code)=@_;
	return $code; # I can deal with internal numbers
}

sub sab_MHLog
{
	my ($self, $processor, $code, $level, @fields)=@_;
	main::_log("[Sablot:$code][$level]\n" . (join "\n", @fields, ""));
}

sub sab_MHError
{
	sab_MHLog(@_);
	die "Dying from Sablotron errors, see log\n";
}

sub docbook2xhtml
{
	my $data=shift;
	my %env=shift;
	
	my $t=track TOM::Debug(__PACKAGE__."::docbook2xhtml()");
	
	my $sab = new XML::Sablotron();
	my $situa = new XML::Sablotron::Situation();
	
	$sab->RegHandler(0,
		{
			MHMakeCode => \&sab_MHMakeCode,
			MHLog => \&sab_MHLog,
			MHError => \&sab_MHError
		}
	);
	
	$sab->addArg($situa, 'data', $data);
	$sab->process($situa, $DIR.'/src/xsl/docbook2xhtml.xsl', 'arg:/data', 'arg:/output');
	my $output=$sab->getResultArg('arg:/output');
	$output=~s|^<\?xml.*?>||;
	main::_log("output=length(".(length($output)).")");
	$t->close();
	return $output;
}

1;
