#!/bin/perl
package App::401::mimetypes::html_fix;

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use App::401::_init;
use base "HTML::Parser";

sub text
{
	my ($self, $text) = @_;
	$self->{'out'}.=$text;
}

sub comment
{
	my ($self, $comment) = @_;
}

sub start
{
	my ($self, $tag, $attr, $attrseq, $origtext) = @_;
	
	if ($tag eq "p")
	{
		if (!$attr->{'id'})
		{
			# bezny tag s obsahom
			if (!$attr->{'entity_part'} || $self->{'entity_parts'}->{$attr->{'entity_part'}})
			{
				# chyba unikatne oznacenie, doplnime
				$attr->{'entity_part'}=Utils::vars::genhash_N(4);
				$self->{'entity_parts'}->{$attr->{'entity_part'}}++;
			}
			else
			{
				$self->{'entity_parts'}->{$attr->{'entity_part'}}++;
			}
		}
	}
	
	# rebuild a tag
	my %attrs_;
	my $out="<$tag";
	foreach (@{$attrseq})
	{
		next if $_ eq '/';
		next unless exists $attr->{$_};
		$out.=' '.$_.'="'.$attr->{$_}.'"';
		$attrs_{$_}=1;
	}
	foreach (keys %{$attr})
	{
		next if $_ eq '/';
		next if $attrs_{$_};
		$out.=' '.$_.'="'.$attr->{$_}.'"';
	}
	$out.=" /" if $attr->{'/'};
	$out.=">";
	
	$self->{'out'}.=$out;
}



sub end
{
	my ($self, $tag, $origtext) = @_;
	$self->{'out'}.=$origtext;
}


1;
