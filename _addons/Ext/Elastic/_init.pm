#!/bin/perl
package Ext::Elastic;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
use JSON;
use Ext::Redis::_init;
our $json = JSON->new->ascii->convert_blessed;
our $jsonc = JSON->new->ascii->canonical;

=head1 NAME

Extension Elasticsearch

=head1 DESCRIPTION

Interface to Elasticsearch

=cut

BEGIN
{
	main::_log("<={LIB} ".__PACKAGE__);
	eval {require Search::Elasticsearch};
	if ($@){main::_log("<={LIB} Search::Elasticsearch",1);undef $Ext::Elastic;}
	else {main::_log("<={LIB} Search::Elasticsearch");}
	$Ext::Elastic::async=0;
#	eval {require Search::Elasticsearch::Async;};
#	if ($@){main::_log("<={LIB} Search::Elasticsearch::Async",1);undef $Ext::Elastic::async;}
#	else {$Ext::Elastic::async=1;main::_log("<={LIB} Search::Elasticsearch::Async");}
}

our $debug=0;
our $service; # reference to object when created
our $service_async; # reference to async object
#our $cv = AnyEvent->condvar;

sub _connect
{
	my $service_;
	return undef unless $Ext::Elastic;
	my $t=track TOM::Debug("Ext::Elastic::connect",'attrs_'=>$Ext::Elastic::host);
	push @{$Ext::Elastic->{'plugins'}}, 'cache';
	if ($service_=Search::Elasticsearch->new($Ext::Elastic))
	{
		use Data::Dumper;
		main::_log("connected ".(join ",",@{$service_->{'transport'}->{'cxn_pool'}->{'seed_nodes'}}));
		$service_->{'nodes_info'}=$service_->nodes->info();
		foreach (keys %{$service_->{'nodes_info'}->{'nodes'}})
		{
			if ($service_->{'version_min'} gt $service_->{'nodes_info'}->{'nodes'}->{$_}->{'version'} || !$service_->{'version_min'})
			{
				$service_->{'version_min'} = $service_->{'nodes_info'}->{'nodes'}->{$_}->{'version'};
			}
		}
		main::_log("version_min=".$service_->{'version_min'});
		$service=$service_;
	}
	else
	{
		main::_log("can't connect any active node",1);
	}
	
	if ($Ext::Elastic::async)
	{
		$Ext::Elastic_async=$Ext::Elastic;
		$Ext::Elastic_async->{'cxn_pool'}='Async::Sniff'
			if $Ext::Elastic_async->{'cxn_pool'} eq 'Sniff';
		if (my $service__=Search::Elasticsearch::Async->new($Ext::Elastic_async))
		{
			main::_log("connected sync ".(join ",",@{$service__->{'transport'}->{'cxn_pool'}->{'seed_nodes'}}));
			$service_async=$service__;
		}
		else
		{
			main::_log("can't connect any active async node",1);
		}
	}
	
	$t->close();
	
	return $service_;
}

_connect(); # autoconnect


# only for exporting symbols
package Ext::Elastic::_init;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
use base 'Exporter';
our @EXPORT = qw($Elastic $Elastic_async);

our $Elastic=$Ext::Elastic::service;
our $Elastic_async=$Ext::Elastic::service_async;

package Search::Elasticsearch::Error::Missing;
sub TO_JSON{return undef}

1;

=head1 AUTHOR

Comsultia, s.r.o. (open@comsultia.com)

=cut
