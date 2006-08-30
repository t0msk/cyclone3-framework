#!/bin/perl
package TOM::Int::lng;
use ISO::639;
use Geo::IP;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our @ISA=("ISO::639");

sub browser_autodetect
{
	my $useragent=shift;
	my $t=track TOM::Debug(__PACKAGE__."::browser_autodetect()");
	
	main::_log("lng browser autodetection '$main::ENV{'HTTP_ACCEPT_LANGUAGE'}'");
	#main::_log("teeeeeeeeeeeest");
	
	foreach my $lng(split(',',$main::ENV{'HTTP_ACCEPT_LANGUAGE'}))
	{
		$lng=~s| ||;
		$lng=~s|;.*||g;
		
		# preklady blbosti
		$lng="en" if $lng=~/^en-/;
		$lng="de" if $lng=~/^de-/;
		
		foreach (@TOM::LNG_accept)
		{
			main::_log("$_ equal $lng ?");
			
			if ($lng eq $_)
			{
				main::_log("selected '$_'");
				$t->close();
				return $_;
			}
		}
	}
	
=head1
	if ($useragent=~/\((.*?)\)/)
	{
		$useragent=$1;
		foreach my $cast (split(';',$useragent))
		{
			$cast=~s|\s+||g;
			main::_log("test lng $cast");
			foreach (@TOM::LNG_accept){return $_ if $cast eq $_;}
		}
	}
=cut
	
	my $gi = Geo::IP->new(GEOIP_STANDARD);
	my $country = $gi->country_code_by_addr($ENV{'REMOTE_ADDR'});$country="\L$country";
	
	main::_log("Geoip $ENV{'REMOTE_ADDR'} country: '$country'");
	
	if ($TOM::Int::lng::table_ISO639_2{$country})
	{
		foreach (@TOM::LNG_accept)
		{
		
			if ($TOM::Int::lng::table_ISO639_2{$country} eq $_)
			{
				main::_log("selected '$_'");
				$t->close();
				return $_;
			}
		
#			return $_ if $TOM::Int::lng::table_ISO639_2{$country} eq $_;
		}
	}
	
	main::_log("can't autodetect");
	$t->close();
	return undef;
}

# convert country to language
our %table_ISO639_2=
(
	'sk' => 'sk',
	'cz' => 'cs',
	'at' => 'de',
	'us' => 'en',
);


1;
