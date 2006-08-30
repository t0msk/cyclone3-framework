#!/usr/bin/perl

  #$momR1++;$yearR1=$yearR1+1900;
  #$momR2++;$yearR2=$yearR2+1900;

    #$yearR1-=1900;
    #$yearR2-=1900;
    #$momR1--;
    #$momR2--;
$xval="1234567";


print "value - ".$xval."\n";

$xxval=substr $xval,0,1;
print "0,1 - ".$xxval."\n";

$xxval=substr $xval,3,1;
print "3,1 - ".$xxval."\n";

$xxval=substr $xval,6,1;
print "6,1 - ".$xxval."\n";

$xxval=substr $xval,-1,1;
print "-1,1 - ".$xxval."\n";