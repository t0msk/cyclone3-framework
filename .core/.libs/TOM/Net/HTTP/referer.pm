#!/usr/bin/perl

package TOM::Net::HTTP::referer;
use strict;
use warnings;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our %table=
(
	'google.com'=>	
	{
		urls			=>	["google\."],
		domain_type	=>	'search engine',
		keywords_param =>	'q',
#		regexp_keywords	=>	'q=(.*?)\&',
	},
	'zoohoo.sk'	=>	
	{
		urls			=>	["zoohoo\.sk"],
		domain_type	=>	'search engine',
		keywords_param =>	'q',
#		regexp_keywords	=>	'(.*?)',
	},
	'search.centrum.sk'	=>	
	{
		urls			=>	["search\.centrum\.sk"],
		domain_type	=>	'search engine',
		keywords_param =>	'q',
#		regexp_keywords	=>	'(.*?)',
	},
	'hladaj.atlas.sk'	=>	
	{
		urls			=>	["hladaj\.atlas\.sk"],
		domain_type	=>	'search engine',
		keywords_param =>	'phrase',
#		regexp_keywords	=>	'(.*?)',
	},
	'search.szm.sk'	=>	
	{
		urls			=>	["search\.szm\.sk"],
		domain_type	=>	'search engine',
		keywords_param =>	'WS',
#		regexp_keywords	=>	'(.*?)',
	},
	'zoznam.sk'	=>	
	{
		urls			=>	["zoznam\.sk"],
		domain_type	=>	'search engine',
		keywords_param =>	's',
#		regexp_keywords	=>	'(.*?)',
	},
	'seznam.cz'	=>	
	{
		urls			=>	["seznam\.cz"],
		domain_type	=>	'search engine',
		keywords_param =>	'w',
#		regexp_keywords	=>	'(.*?)',
	},
	'msn.com'	=>	
	{
		urls			=>	["msn\."],
		domain_type	=>	'search engine',
		keywords_param =>	'q',
#		regexp_keywords	=>	'(.*?)',
	},
	'yahoo.com'	=>	
	{
		urls			=>	["yahoo\."],
		domain_type	=>	'search engine',
		keywords_param =>	'p',
#		regexp_keywords	=>	'[&\?]p=(.*?)(\&|$)',
	},
	'aolsearch'	=>	
	{
		urls			=>	["aolsearch\.aol\.co\.uk"],
		domain_type	=>	'search engine',
		keywords_param =>	'query',
#		regexp_keywords	=>	'[&\?]p=(.*?)(\&|$)',
	},
	'search.netscape'	=>	
	{
		urls			=>	["netscape\.com"],
		domain_type	=>	'search engine',
		keywords_param =>	'query',
#		regexp_keywords	=>	'[&\?]p=(.*?)(\&|$)',
	},
	'mywebsearch.com' =>
	{
		urls			=>	["mywebsearch\.com"],
		domain_type	=>	'search engine',
		keywords_param =>	'searchfor',
#		regexp_keywords	=>	'[&\?]p=(.*?)(\&|$)',
	},
	'freshmeat.net/search' =>
	{
		urls			=>	["freshmeat\.net/search/"],
		domain_type	=>	'search engine',
		keywords_param =>	'q',
#		regexp_keywords	=>	'[&\?]p=(.*?)(\&|$)',
	},
	
	
);


sub extract_keywords
{
}

sub analyze
{
 return undef unless $_[0];
# my $var=0;
 foreach (keys %table)
 {
  foreach my $url (@{$table{$_}{urls}})
  {
   return $_ if $_[0]=~/$url/;
  }
 }
 return undef;
 #my @ref=@_;
};


# END
1;# DO NOT CHANGE !
