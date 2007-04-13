#!/usr/bin/perl
package TOM::Net::HTTP::referer;

=head1 NAME

TOM::Net::HTTP::referer

=cut

use strict;
use warnings;

=head1 DESCRIPTION

Analyze referers

=cut

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 VARIABLES

=head2 %table

 our %table=
 (
   'google.com'=>	
   {
     urls => ["google\."],
     domain_type	=>	'search engine',
     keywords_param =>	'q',
   },
   ...
 );

List of known search engines

 google.com
 zoohoo.sk
 search.centrum.sk
 hladaj.atlas.sk
 search.szm.sk
 zoznam.sk
 seznam.cz
 msn.com
 live.com
 yahoo.com
 aolsearch
 search.netscape
 mywebsearch.com
 freshmeat.net/search
 search.bearshare.com
 ask.com
 search.imesh.com
 search.myway.com
 best.sk
 azet.sk

=cut

our %table;

=head2 DOMAINS

=over

=item *

google.com

 urls => ["google\."]
 domain_type => 'search engine'
 keywords_param => 'q'

=cut
$table{'google.com'}=>
{
 urls => ["google\."],
 domain_type => 'search engine',
 keywords_param => 'q',
};


=item *

zoohoo.sk

 urls => ["zoohoo\.sk"],
 domain_type => 'search engine',
 keywords_param => 'q',

=cut
$table{'zoohoo.sk'}=>
{
 urls => ["zoohoo\.sk"],
 domain_type => 'search engine',
 keywords_param => 'q',
},

=back

=cut

%table=
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
		urls			=>	["search.*?\.centrum\.sk"],
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
	'live.com' => # 2007-04-12
	{
		urls => ["live\.com"],
		domain_type => 'search engine',
		keywords_param => 'q',
	},
	'search.bearshare.com' => # 2007-04-12
	{
		urls => ["search\.bearshare\.com"],
		domain_type => 'search engine',
		keywords_param => 'q',
	},
	'ask.com' => # 2007-04-12
	{
		urls => ["ask\.com"],
		domain_type => 'search engine',
		keywords_param => 'q',
	},
	'search.imesh.com' => # 2007-04-12
	{
		urls => ["search\.imesh\.com"],
		domain_type => 'search engine',
		keywords_param => 'q',
	},
	'search.myway.com' => # 2007-04-12
	{
		urls => ["search\.myway\.com"],
		domain_type => 'search engine',
		keywords_param => 'searchfor',
	},
	'best.sk' => # 2007-04-12
	{
		urls => ["best\.sk"],
		domain_type => 'search engine',
		keywords_param => 'searchfor',
	},
	'azet.sk' => # 2007-04-12
	{
		urls => ["azet\.sk"],
		domain_type => 'search engine',
		keywords_param => 'sq',
	},
);

=head1 FUNCTIONS

=head2 analyze

Analyzes domain name and returns name of known domain (search engine, etc...)

 my $domain=TOM::Net::HTTP::referer::analyze('www.google.com');
 main::_log("this domain is a ".$TOM::Net::HTTP::referer::table{$domain}{'domain_type'}); # search engine

=cut


sub extract_keywords
{
}

sub analyze
{
	return undef unless $_[0];
	foreach (keys %table)
	{
		foreach my $url (@{$table{$_}{urls}})
		{
			return $_ if $_[0]=~/$url/;
		}
	}
	return undef;
};

=head1 AUTHORS

Roman Fordinal (roman.fordinal@comsultia.com)

=cut

# END
1;# DO NOT CHANGE !
