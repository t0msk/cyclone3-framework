#!/bin/perl
package Search::Elasticsearch::Plugin::cache::cyclone3;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
use Compress::Zlib;
use JSON;
use Ext::Redis::_init;

our $json = JSON->new;
our $jsonc = JSON->new->ascii->canonical;

sub search
{
	my $self=shift;
	use Data::Dumper;
	my %env=@_;
	
	my $cache=$env{'-cache'};delete $env{'-cache'};
	
	my $key=TOM::Digest::hash($jsonc->encode(\%env));
	
	if (my $output=$Redis->get('C3|elastic|'.$key))
	{
		Ext::Redis::_uncompress(\$output);
		return $json->decode($output);
	}
	
	my $cache_time=60;
	if ($cache=~/^(\d+)D$/i) {$cache_time=86400*$1}
	elsif ($cache=~/^(\d+)H$/i) {$cache_time=3600*$1}
	elsif ($cache=~/^(\d+)M$/i) {$cache_time=60*$1}
	elsif ($cache=~/^(\d+)S$/i) {$cache_time=$1}
	else {$cache_time=$cache}
	
	my $output=$self->{'es'}->search(%env);
	$Redis->set('C3|elastic|'.$key,
		Ext::Redis::_compress(\$json->encode($output))
		,sub{}
	);
	$Redis->expire('C3|elastic|'.$key,$cache_time,sub{});
	return $output;
}


package Search::Elasticsearch::Plugin::cache::5_0;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
use Moo::Role;
use namespace::clean;

has 'cache' => ( is => 'rw', default => sub {
	my $self={};
	$self->{'es'} = shift;
	return bless $self, 'Search::Elasticsearch::Plugin::cache::cyclone3';
});


package Search::Elasticsearch::Plugin::cache;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
use Moo;
use Search::Elasticsearch;

our $VERSION = '5.00';

sub _init_plugin {
	my ( $class, $params ) = @_;
	
	my $api_version = $params->{client}->api_version;
	
	Moo::Role->apply_roles_to_object( $params->{client},
		"Search::Elasticsearch::Plugin::cache::5_0" );
}


1;
