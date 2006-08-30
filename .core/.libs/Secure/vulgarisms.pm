package Secure::vulgarisms;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our $v_0='.{0,2}?';
our $v_1='[ \.\+\*]{0,2}?';
our $vv_i='[iíÍ]';
our $vv_c='[cčČ]';

our %words=
(
 'sk'=>[
#	'koko[td]',
#	"[kc]$v_0\[o0]$v_0\[kc]$v_0\o$v_0\[td]",
#	"[^\w]p[ily]c[auo]",
	"kurv",
	"jeb[nuaeo]",
#	"j$v_0\[e]$v_0\[b]$v_0\[nuaeo]",
	"debil",
	"buzerant",
	"curak",
	"[^\w]pic[aeiou]",
	"dement",
	"bastard",
	"cicin[au]",
	"kreten",
	"(vy|)mrda[nť]",
	"k$v_1\[o0]$v_1\[k]$v_1\[o0]$v_1\[t]",
 ],
 'en'=>[
 	'fuck',
 ],
);



sub convert
{
 my $lng=shift @_;
 foreach (@_)
 {
  foreach my $regexp(@{$words{$lng}})
  {
   $_=~s/($regexp)/"*" x length($1)/eig;
  }
 }
return 1}



1;
