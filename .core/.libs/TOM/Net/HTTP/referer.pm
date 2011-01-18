#!/usr/bin/perl
package TOM::Net::HTTP::referer;

=head1 NAME

TOM::Net::HTTP::referer

=cut

use strict;
#use warnings;

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
	ref_type => 'search',
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
	ref_type => 'search',
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
	ref_type => 'search',
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
	ref_type => 'search',
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
	ref_type => 'search',
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
	ref_type => 'search',
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
	ref_type => 'search',
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
	ref_type => 'search',
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
	ref_type => 'search',
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
	ref_type => 'search',
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
	ref_type => 'search',
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
	ref_type => 'search',
	keywords_param => 'searchfor',
};


=item *

facebook.com

added: 2009-10-20

 urls => ["facebook\.com"],
 domain_type => 'social portal',
 ref_type => 'social',

=cut
$table{'facebook.com'}=
{
	urls => ["facebook\.com"],
	domain_type => 'social portal',
	ref_type => 'social',
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
	ref_type => 'search',
	keywords_param => 'q',
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
	ref_type => 'search',
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
	ref_type => 'search',
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
	ref_type => 'search',
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
	ref_type => 'search',
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
	ref_type => 'search',
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
	ref_type => 'search',
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
	ref_type => 'search',
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


sub analyze
{
	return undef unless $_[0];
	foreach (keys %table)
	{
		foreach my $url (@{$table{$_}{'urls'}})
		{
			return $_ if $_[0]=~/$url/;
		}
	}
	return undef;
};



=head2 extract_keywords

Analyzes referer and extract keywords when referer is from known search engine

 my %data=TOM::Net::HTTP::referer::extract_keywords('http://www.google.sk/search?hl=sk&q=cyclone3');
 # $data{'phrase'}
 # %{$data{'keywords'}}

=cut

sub extract_keywords
{
	my $referer=shift;
	return undef unless $referer;
	
	my %data;
	
	# parsing domain name
	my ($domain,$query)=TOM::Net::HTTP::domain_clear($referer);
	# check type of domain
	if (my $dom=TOM::Net::HTTP::referer::analyze($domain))
	{
		# check if it is a know search engine
		if (
				($TOM::Net::HTTP::referer::table{$dom}{'domain_type'} eq "search engine")
				&&($TOM::Net::HTTP::referer::table{$dom}{'keywords_param'})
			)
		{
			# in which parameter are stored keywords?
			my $keyword_param=$TOM::Net::HTTP::referer::table{$dom}{'keywords_param'};
			
			# parse query from QUERY_STRING into %hash
			my %FORM=TOM::Net::HTTP::CGI::get_QUERY_STRING($query,'quiet'=>1);
			
			# don't analyze queries from google cache
			next if $FORM{$keyword_param}=~/^cache/;
			next if $FORM{$keyword_param}=~/^site:/;
			next unless $FORM{$keyword_param};
			
			# convert keywords to ASCII
			$FORM{$keyword_param}=Int::charsets::encode::UTF8_ASCII($FORM{$keyword_param});
			#main::_log("phrase '$FORM{$keyword_param}'");
			
			# this is a corrupted encoding (i can't say why)
			next if $FORM{$keyword_param}=~/\\utf\{65533\}/;
			
			# convert to lowercase
			#$FORM{$keyword_param}=~tr/A-Z/a-z/;
			
			# prepare string for split keywords
			$FORM{$keyword_param}=~s|["&]||g;
			#$FORM{$keyword_param}=~s|\W| |g;
			$FORM{$keyword_param}=~s|[ \+]|;|g;
			$FORM{$keyword_param}=~s|^;||;$FORM{$keyword_param}=~s|;$||;
			1 while ($FORM{$keyword_param}=~s|;;|;|);
			
			# keywords
			#@{$data{'keywords'}}=split ';',$FORM{$keyword_param};
			foreach my $word(split ';',$FORM{$keyword_param})
			{
				next if ((length($word)<3) && (not $word=~/^[A-Z0-9]$/));
				$word=~tr/A-Z/a-z/;
				push @{$data{'keywords'}},$word;
			}
			# phrase
			$data{'phrase'}=join ' ', sort split ';',$FORM{$keyword_param};
			$data{'phrase'}=~tr/A-Z/a-z/;
		}
		
	}
	
	return %data;
}



=head2 extract_domainsource

Analyzes referer and extracts domain name

 my $domain=TOM::Net::HTTP::referer::extrac_domainsource(referer => 'http://www.google.sk/search?hl=sk&q=cyclone3');

=cut

sub extract_domainsource
{
	my %env=@_;
	
	my ($domain,$query)=TOM::Net::HTTP::domain_clear($env{'referer'});
	
	# check if refering domain is not the same
	if ($env{'domain'})
	{
		return undef if $domain=~/^$env{'domain'}/;
	}
	
	if ($domain=~/google\./)
	{
		$domain="google.*";
	}
	
	if (!$env{'page_code_referer'} && !$env{'referer'})
	{
		return '(Direct)';
	}
	
	# bot?
	if (!$env{'referer'})
	{
		return undef;
	}
	
	return $domain;
}




=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut



# END
1;# DO NOT CHANGE !