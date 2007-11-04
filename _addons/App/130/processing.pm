#!/bin/perl
package App::130::processing;
use open ':utf8', ':std';
use Encode;
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our $debug=1;

use MIME::Base64;
use MIME::Parser;
use MIME::Entity;
use TOM::Text::format;

=head1 FUNCTIONS

=cut

sub get_cleanresponse
{
	my $body=shift;
	
	my $processed=0;
	my $parser = new MIME::Parser;
	$parser->output_to_core(1);
	$parser->extract_uuencode(1);
	$parser->decode_headers(1);
	
	my $entity = $parser->parse_data($body);
	
	# From
	my $from=$entity->head->get('From');chomp($from);
	main::_log("From='".$from."'") if $debug;
	
	# Subject
	my $subject=$entity->head->get('Subject');chomp($subject);
	main::_log("Subject='".$subject."'") if $debug;
	
	my $data=_proctextpart(\$entity);
	
	# finding text/plain or text/html attachment
	if (!$data)
	{
		my @parts=$entity->parts();
		foreach my $part(@parts)
		{
			$data=_proctextpart(\$part);
			last if $data;
		}
	}
	
	return undef unless $data;
	
	$data=_cleanresponse($data);
	
	return $data;
}


sub _proctextpart
{
	my $part=shift;
	
	my $content_type=$$part->head->get('Content-Type');
	$content_type=~/charset=(.*?)[;\n]/;
	my $charset=$1;
	main::_log("part content_type='$content_type' charset='$charset'") if $debug;
	
	# get the text data
	my $data;
	
	# this is text/plain part
	if ($content_type=~/text\/plain/)
	{
		my $body = $$part->bodyhandle;
		$data = $body->as_string;
		if ($charset ne "UTF-8")
		{
			main::_log("convert") if $debug;
			$data=iconv::convert($data, $charset, "UTF-8");
		}
	}
	elsif ($content_type=~/text\/html/)
	{
		my $body = $$part->bodyhandle;
		$data = $body->as_string;
		
		#print $data;
		
		$data = TOM::Text::format::xml2plain($data);
		if ($charset ne "UTF-8")
		{
			main::_log("convert") if $debug;
			$data=iconv::convert($data, $charset, "UTF-8");
		}
	}
	
	return $data;
}


sub _cleanresponse
{
	my $data=shift;
	
	$data=~s|-- \n(.*)$||s;
	$data=~s|-----BEGIN PGP.*?Hash.*?\n||s;
	#print $data;
	$data=~s|^(.*)\n(.*?)(wrote\|napisal).*?$|\1|s;
	#$data=~s|\n> (.*)$||s;
	$data.="\n";
	# line with wrote
	
	1 while($data=~s|^\n||);
	1 while ($data=~s|\n$||);
	
	return $data;
}

=head2 GetGroups(IDhash)

=cut


1;
