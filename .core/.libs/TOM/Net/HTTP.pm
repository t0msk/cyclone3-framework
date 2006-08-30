#!/usr/bin/perl

package TOM::Net::HTTP;
use strict;
use warnings;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

sub domain_clear
{
 my $domain=shift;
 
 $domain=~s|^http[s]?://||;
 $domain=~s|^(.*?)\?(.*)$|$1|;
 my $query=$2;
 $domain=~s|^(.*)/.*$|$1|;
 $domain=~s|/.*$||;
 $domain=~s|^www\.||;
 $domain=~tr/A-Z/a-z/;
 
 return ($domain,$query);
}



# END
1;# DO NOT CHANGE !
