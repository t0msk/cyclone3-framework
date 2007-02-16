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
use File::Copy;

our $DIR=(__FILE__=~/^(.*)\//)[0];



=head1 FUNCTIONS

=head2 docbook2xhtml('<?xml>')

Convert DocBook XML content into XHTML content

  'translate_images' =>
  {
  	'dir_from' => '/www/TOM/_temp/' ?
  	'dir_to' => '/www/TOM/!example.tld/!media/grf/temp'
  	'uri' => 'http://media.example.tld/grf/temp'
  }
  
  'translate_images' =>
  {
  	'prefix' => 'http://media.example.tld/grf/'
  }

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
	my %env=@_;
	
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
	
	# postprocessing
	if ($env{'translate_images'})
	{
		$output=~s/<img(.*?)src="(.*?)"/'<img'.$1.'src="'.(
			_docbook2xhtml_translate_image(
				$2,
				$env{'translate_images'}
			)
		).'"'/eg;
	}
	
	$t->close();
	return $output;
}


sub _docbook2xhtml_translate_image
{
	my $link=shift;
	my $env=shift;
	
	main::_log("input 'link'='$link'");
	foreach (keys %{$env})
	{
		main::_log("input '$_'='$env->{$_}'");
	}
	
	my $uri_to;
	
	if ($env->{'prefix'})
	{
		$uri_to=$env->{'prefix'}.'/'.$link;
	}
	elsif ($env->{'dir_to'})
	{
		my $hash=Utils::vars::genhash(8);
		my $from=$TOM::P.'/'.$env->{'dir_from'}.'/'.$link;
		my $hash=Digest::MD5::md5_base64($from);
		my $to=$env->{'dir_to'}.'/'.$hash.'-'.$link;
		my $uri_to=$env->{'uri'}.'/'.$hash.'-'.$link;
		
		main::_log("from='$from' to='$to'");
		
		if (-e $to)
		{
			return $uri_to;
		}
		
		File::Copy::copy($from,$to);
	}
	
=head1
=cut
	
	return $uri_to;
}


1;
