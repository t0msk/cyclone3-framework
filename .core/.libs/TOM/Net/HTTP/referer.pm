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

=cut

our %table;

=head1 KNOWN DOMAINS

=head2 Global domains

=over

=item *

google.com

 urls => ["google\."]
 domain_type => 'search engine'
 keywords_param => 'q'

=cut
$table{'google.com'}=
{
 urls => ["google\."],
 domain_type => 'search engine',
 keywords_param => 'q',
};


=item *

msn.com

 urls => ["msn\."],
 domain_type => 'search engine',
 keywords_param => 'q',

=cut
$table{'msn.com'}=
{
 urls => ["msn\."],
 domain_type => 'search engine',
 keywords_param => 'q',
};


=item *

live.com

added: 2007-04-12

 urls => ["live\.com"],
 domain_type => 'search engine',
 keywords_param => 'q',

=cut
$table{'live.com'}=
{
 urls => ["live\.com"],
 domain_type => 'search engine',
 keywords_param => 'q',
};


=item *

yahoo.com

 urls => ["yahoo\."],
 domain_type => 'search engine',
 keywords_param => 'p',

=cut
$table{'yahoo.com'}=
{
 urls => ["yahoo\."],
 domain_type => 'search engine',
 keywords_param => 'p',
};


=item *

aolsearch

 urls => ["aolsearch\.aol\.co\.uk"],
 domain_type => 'search engine',
 keywords_param => 'query',

=cut
$table{'aolsearch'}=
{
 urls => ["aolsearch\.aol\.co\.uk"],
 domain_type => 'search engine',
 keywords_param => 'query',
};


=item *

search.netscape

 urls => ["netscape\.com"],
 domain_type => 'search engine',
 keywords_param => 'query',

=cut
$table{'search.netscape'}=
{
 urls => ["netscape\.com"],
 domain_type => 'search engine',
 keywords_param => 'query',
};


=item *

mywebsearch.com

 urls => ["mywebsearch\.com"],
 domain_type => 'search engine',
 keywords_param => 'searchfor',

=cut
$table{'mywebsearch.com'}=
{
 urls => ["mywebsearch\.com"],
 domain_type => 'search engine',
 keywords_param => 'searchfor',
};


=item *

freshmeat.net/search

 urls => ["freshmeat\.net/search/"],
 domain_type => 'search engine',
 keywords_param => 'q',

=cut
$table{'freshmeat.net/search'}=
{
 urls => ["freshmeat\.net/search/"],
 domain_type => 'search engine',
 keywords_param => 'q',
};


=item *

search.bearshare.com

added: 2007-04-12

 urls => ["search\.bearshare\.com"],
 domain_type => 'search engine',
 keywords_param => 'q',

=cut
$table{'search.bearshare.com'}=
{
 urls => ["search\.bearshare\.com"],
 domain_type => 'search engine',
 keywords_param => 'q',
};


=item *

ask.com

added: 2007-04-12

 urls => ["ask\.com"],
 domain_type => 'search engine',
 keywords_param => 'q',

=cut
$table{'ask.com'}=
{
 urls => ["ask\.com"],
 domain_type => 'search engine',
 keywords_param => 'q',
};


=item *

search.imesh.com

added: 2007-04-12

 urls => ["search\.imesh\.com"],
 domain_type => 'search engine',
 keywords_param => 'q',

=cut
$table{'search.imesh.com'}=
{
 urls => ["search\.imesh\.com"],
 domain_type => 'search engine',
 keywords_param => 'q',
};


=item *

search.myway.com

added: 2007-04-12

 urls => ["search\.myway\.com"],
 domain_type => 'search engine',
 keywords_param => 'searchfor',

=cut
$table{'search.myway.com'}=
{
 urls => ["search\.myway\.com"],
 domain_type => 'search engine',
 keywords_param => 'searchfor',
};




=back

=head2 CZ domains

=over

=cut

=item *

seznam.cz

 urls => ["seznam\.cz"],
 domain_type => 'search engine',
 keywords_param => 'w',

=cut
$table{'seznam.cz'}=
{
 urls => ["seznam\.cz"],
 domain_type => 'search engine',
 keywords_param => 'w',
};




=back

=head2 SK domains

=over

=cut

=item *

zoznam.sk

 urls => ["zoznam\.sk"],
 domain_type => 'search engine',
 keywords_param => 's',

=cut
$table{'zoznam.sk'}=
{
 urls => ["zoznam\.sk"],
 domain_type => 'search engine',
 keywords_param => 's',
};


=item *

search.centrum.sk

 urls => ["search.*?\.centrum\.sk"],
 domain_type => 'search engine',
 keywords_param => 'q',

=cut
$table{'search.centrum.sk'}=
{
 urls => ["search.*?\.centrum\.sk"],
 domain_type => 'search engine',
 keywords_param => 'q',
};


=item *

hladaj.atlas.sk

 urls => ["hladaj\.atlas\.sk"],
 domain_type => 'search engine',
 keywords_param => 'phrase',

=cut
$table{'hladaj.atlas.sk'}=
{
 urls => ["hladaj\.atlas\.sk"],
 domain_type => 'search engine',
 keywords_param => 'phrase',
};


=item *

search.szm.sk

 urls => ["search\.szm\.sk"],
 domain_type => 'search engine',
 keywords_param => 'WS',

=cut
$table{'search.szm.sk'}=
{
 urls => ["search\.szm\.sk"],
 domain_type => 'search engine',
 keywords_param => 'WS',
};


=item *

zoohoo.sk

 urls => ["zoohoo\.sk"],
 domain_type => 'search engine',
 keywords_param => 'q',

=cut
$table{'zoohoo.sk'}=
{
 urls => ["zoohoo\.sk"],
 domain_type => 'search engine',
 keywords_param => 'q',
};


=item *

best.sk

added: 2007-04-12

 urls => ["best\.sk"],
 domain_type => 'search engine',

=cut
$table{'best.sk'}=
{
 urls => ["best\.sk"],
 domain_type => 'search engine',
};


=item *

azet.sk

added: 2007-04-12

 urls => ["azet\.sk"],
 domain_type => 'search engine',
 keywords_param => 'sq',

=cut
$table{'azet.sk'}=
{
 urls => ["azet\.sk"],
 domain_type => 'search engine',
 keywords_param => 'sq',
};


=back

=cut





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
