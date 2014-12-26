#!/bin/perl
package Ext::DocBook4CMS;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
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
  	'dir_from' => '/www/TOM/_temp/', # ?
  	'dir_to' => '/www/TOM/!example.tld/!media/grf/temp',
  	'uri' => 'http://media.example.tld/grf/temp'
  }

  'translate_images' =>
  {
  	'prefix' => 'http://media.example.tld/grf/'
  }

  'translate_images' =>
  {
  	'uri_from' => 'http://media.example.tld/',
  	'dir_to' => '/www/TOM/!example.tld/!media/grf/temp',
  	'uri' => 'http://media.example.tld/grf/temp'
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
		$output=~s/<img(.*?)src="(.*?)"/'<img'.$1.'src="' . &_docbook2xhtml_translate_image($2,$env{'translate_images'}) . '"'/eg;
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
	
	# just add prefix to img uri
	if ($env->{'prefix'})
	{
		$uri_to=$env->{'prefix'}.'/'.$link;
	}
	# download image and copy it
	elsif ($env->{'uri_from'} && $env->{'dir_to'})
	{
		# links
		my $from=$env->{'uri_from'}.'/'.$link;
		my $hash=Digest::MD5::md5_base64($from);
		$link=~s|/|_|g;
		my $to=$env->{'dir_to'}.'/'.$hash.'-'.$link;
		$uri_to=$env->{'uri'}.'/'.$hash.'-'.$link;
		main::_log("from='$from' to='$to' uri_to='$uri_to'");
		
		# check if already available
		if (-e $to)
		{
			return $uri_to;
		}
		
		# download if not available
		main::_log("downloading '$from'");
		my $image=TOM::Temp::file->new();
		my $bin='/usr/bin/wget';
		if (-e '/usr/local/bin/wget'){$bin='/usr/local/bin/wget'}
		my $cmd="$bin -q $from -O $image->{'filename'}";
		system($cmd);
		
		# copy to target directory
		if (-e $image->{'filename'})
		{
			main::_log("downloaded");
			File::Copy::copy($image->{'filename'},$to);
			return $uri_to;
		}
		
	}
	# copy image to this directory
	elsif ($env->{'dir_to'})
	{
		my $hash=Utils::vars::genhash(8);
		my $from=$env->{'dir_from'}.'/'.$link;
		my $hash=Digest::MD5::md5_base64($from);
			$hash=~s|/|_|g;
		my $to=$env->{'dir_to'}.'/'.$hash.'-'.$link;
		$uri_to=$env->{'uri'}.'/'.$hash.'-'.$link;
		
		main::_log("from='$from' to='$to' uri_to='$uri_to'");
		
		if (-e $to)
		{
			return $uri_to;
		}
		
		File::Copy::copy($from,$to);
	}
	
	return $uri_to;
}



=head2 docbook2dc('<?xml>')

Convert DocBook XML content into Dublin Core metadata.

Function returns %hash:

 my %dc=docbook2dc('<?xml>');

Modyfiing output document by Dublin Core:

 $main::H->change_DOC_title($dc{'title'}) if $dc{'title'};
 $main::H->change_DOC_description($dc{'abstract'}) if $dc{'abstract'};

=cut

sub docbook2dc
{
	my $data=shift;
	my %env=@_;
	
	my $t=track TOM::Debug(__PACKAGE__."::docbook2dc()");
	
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
	$sab->process($situa, $DIR.'/src/xsl/docbook2dc.xsl', 'arg:/data', 'arg:/output');
	my $output=$sab->getResultArg('arg:/output');
	$output=~s|^<\?xml.*?>||;
	main::_log("output=length(".(length($output)).")");
	
	my %hash;
	$hash{'dc'}=$output;
	while ($output=~s|<dc:(.*?)>(.*?)</dc:\1>||s)
	{
		$hash{$1}=$2;
	}
	
	$t->close();
	return %hash;
}

1;
