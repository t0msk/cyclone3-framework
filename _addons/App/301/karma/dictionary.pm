#!/bin/perl
package App::301::karma::dictionary;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;



=head1 NAME

App::301::karma::dictionary

=head1 DESCRIPTION

Calculate karma diff from writed text

=cut

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 DEPENDS

=over

=item *

L<App::301::karma|app/"301/karma.pm">

=back

=cut

use App::301::karma;
use XML::XPath;
use XML::XPath::XMLParser;


=head1 FUNCTIONS

=head2 load()

 App::301::karma::dictionary::load()

=cut

our %sources;
our %rules;
our $debug=$App::301::karma::dictionary::debug || 0;

sub load
{
	
	foreach my $lng('default',@TOM::LNG_accept)
	{
		
		$rules{$lng}=[];
		
		my $filename=$TOM::P.'/_addons/App/301/karma/'.$lng.'.xml';
		next unless -e $filename;
		main::_log("opening karma dictionary file '$filename'");
		my $xp=XML::XPath->new(filename => $filename);
		
		my $nodeset = $xp->find('/karma/dictionary/rule'); # find all items
		
		foreach my $node ($nodeset->get_nodelist)
		{
			my %rule;
			
			# regexp
			my $nodeset2 = $node->find('regexp');
			
			foreach my $regexp ($nodeset2->get_nodelist)
			{
				my $regexp_value=$regexp->string_value();
				
				my $regexp_source=$regexp->getAttribute('source') || 'default';
				$sources{$regexp_source}=1 if $regexp_source;
				
				my $regexp_mode=$regexp->getAttribute('mode');
				
				push @{$rule{'regexp'}},
				{
					'value' => $regexp_value,
					'source' => $regexp_source,
					'mode' => $regexp_mode,
				};
			}
			
			# value
			my $nodeset2 = $node->find('value');
			my $value=($nodeset2->get_nodelist())[0];
			$rule{'value'}=$value->string_value() if $value;
			
#			main::_log("rule $rule{'regexp'}[0]{value}");
			
			push @{$rules{$lng}}, {%rule};
		}
		
	}
	
}


sub analyze_text
{
	my $text=shift;
	my $karma;
	my %text_src;
	
	foreach (keys %sources)
	{
#		main::_log("source $_");
		if ($_ eq "ascii")
		{
			$text_src{'ascii'}=Int::charsets::encode::UTF8_ASCII($text);
		}
		elsif ($_ eq "lowascii")
		{
			$text_src{'lowascii'}=Int::charsets::encode::UTF8_ASCII($text);
			$text_src{'lowascii'}=~tr/[A-Z]/[a-z]/;
		}
		else
		{
			$text_src{'default'}=$text;
		}
	}
	
	foreach my $lng('default',@TOM::LNG_accept)
	{
		my $i=0;
		foreach (@{$rules{$lng}})
		{
#			main::_log("rule {$lng} [$i] '$rules{$lng}[$i]{'regexp'}[0]{'value'}'");
			
			foreach my $regexp(@{$rules{$lng}[$i]{'regexp'}})
			{
				my $text=$text_src{$regexp->{'source'}};
				if (my $out=($text=~s/$regexp->{'value'}//gm))
				{
					main::_log("match [$lng][$i] /$regexp->{'value'}/ $rules{$lng}[$i]{'value'}*$out=".($rules{$lng}[$i]{'value'}*$out)) if $debug;
					$karma+=($rules{$lng}[$i]{'value'}*$out);
					last;
				}
				
			}
			
			$i++;
		}
	}
	main::_log("karma=$karma") if $debug;
	return $karma;
}


load();

=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
