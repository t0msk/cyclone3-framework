#!/bin/perl
package Ext::TextHyphen;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

=head1 NAME

Extension TextHyphen

=head1 DESCRIPTION

Text Hyphenation

=cut

BEGIN
{
	main::_log("<={LIB} ".__PACKAGE__);
}

use charnames ':full';
our $soft_hyphen="\N{SOFT HYPHEN}";
our $nbsp="\N{NO-BREAK SPACE}";

#use Ext::TextHyphen::rules::sk;

sub get_hyphens
{
	my $text=shift;
	my %env=@_;
	
	# cleaning from previous marks
	$text=~s|$soft_hyphen||g;
	$text=~s|$nbsp| |g;
	
	$env{'lng'}=$tom::lng unless $env{'lng'};
	
	main::_log("hyphen with lng='$env{'lng'}'");
	
	my $local_package='Ext::TextHyphen::rules::'.$env{'lng'};
	
	if (!$local_package->VERSION)
	{
		return undef;
	}
	
	# asciize :-)
	$text=lc(Int::charsets::encode::UTF8_ASCII_lite($text));
	
	my @positions;
	while ($text=~m/([\w]+)/g)
	{
		my $word_ascii=$1;
		my $word_pos=$-[0];
		
		my $word_new;
		foreach my $word_part($local_package->word($word_ascii))
		{
			$word_new.=$word_part;
			if (length($word_new) < length($word_ascii))
			{
				push @positions,$word_pos+length($word_new);
#				main::_log(" \@".$positions[-1]." len=".length($word_new)." text=$word_new $word_part");
			}
		}
		
	}
	
	return @positions;
}

sub add_hyphens
{
	my $text=shift;
	my @positions=@_;
	
	unshift @positions,0;
	push @positions,length($text);
	my $placements=0;
	my $text_new;
	for (1..@positions-1)
	{
		my $text_part=substr($text, $positions[$placements], ($positions[$placements+1]-$positions[$placements]));
		
		$text_new.=$text_part;
		
		if ($placements+2 < @positions)
		{
			$text_new.=$soft_hyphen;
#			$text_new.='-';
		}
#		print "part=$text_part\n";
		
		$placements++;
	}
	
	return $text_new;
}

1;

=head1 AUTHOR

Comsultia (open@comsultia.com)

=cut
