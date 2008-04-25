#!/bin/perl
package ISO::3611;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our %code_a2;
our %code_a3;
our %code_rev;
our %code_lng;
our %code_lng_rev;
#our $P=($TOM::P || $CRON::P);

-e $TOM::P."/.core/.libs/ISO/3611/a3.txt" && do
{
	local $/;
	open (HNDI,"<".$TOM::P."/.core/.libs/ISO/3611/a3.txt") 
		|| die "cannot open ".$TOM::P."/.core/.libs/ISO/3611/a3.txt for ISO-3611 library";
	foreach my $line(split('\n',<HNDI>))
	{
		chomp($line);
		my @ref=split(';',$line);
		$code_a2{$ref[1]}=$ref[0];
		$code_a3{$ref[2]}=$ref[0];
		$code_rev{$ref[0]}={
			'a2'	=> $ref[1],
			'a3'	=> $ref[2]
		};
	};
};


sub lng_load
{
 return undef unless $_[0];
 return undef if $code_lng{$_[0]};
 
 -e $TOM::P."/.core/.libs/ISO/3611/".$_[0].".txt" && do
 {
  open (HNDI,"<".$TOM::P."/.core/.libs/ISO/3611/".$_[0].".txt") 
	|| die "cannot open ".$TOM::P."/.core/.libs/ISO/3611/".$_[0].".txt for ISO-3611 library";
  while (my $line=<HNDI>)
  {
   $line=~s|[\n\r]||g;  
   my @ref=split(';',$line);
   $code_lng{$_[0]}{$ref[0]}=$ref[1];
	$code_lng_rev{$_[0]}{$ref[1]}=$ref[0];
  };
 };  
}

sub lng_translate
{
 return undef unless $_[0];
 return undef unless $_[1];
 #return $_[0] unless $code_lng{$_[1]}{$_[0]};
 return ($code_lng{$_[0]}{$_[1]} || $_[1]);
}


1;
