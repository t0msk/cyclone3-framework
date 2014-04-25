#!/bin/perl
package Ext::Elastic;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

=head1 NAME

Extension Elasticsearch

=head1 DESCRIPTION

Interface to Elasticsearch

=cut

BEGIN
{
	main::_log("<={LIB} ".__PACKAGE__);
	eval {require Search::Elasticsearch};
	if ($@)
	{
		main::_log("<={LIB} Search::Elasticsearch",1);
		undef $Ext::Elastic;
	}
	else
	{
		main::_log("<={LIB} Search::Elasticsearch");
	}
}

our $debug=0;
our $service; # reference to object when created

sub _connect
{
	my $service_;
	return undef unless $Ext::Elastic;
	my $t=track TOM::Debug("Ext::Elastic::connect",'attrs_'=>$Ext::Redis::host);
	if ($service_=Search::Elasticsearch->new($Ext::Elastic))
	{
		use Data::Dumper;
#		print Dumper($service_->{'transport'}->{'cxn_pool'}->{'seed_nodes'});
		main::_log("connected ".(join ",",@{$service_->{'transport'}->{'cxn_pool'}->{'seed_nodes'}}));
		$service=$service_;
#		my $index='cyclone3.'.$TOM::DB{'main'}{'name'};
#		main::_log("primary indice '$index'");
#		if (!$service->indices->exists('index'=>$index))
#		{
#			main::_log("creating index '".$index."'");
#			$service->indices->create('index'=>$index);
#		}
	}
	else
	{
		main::_log("can't connect any active node",1);
	}
	$t->close();
	
	return $service_;
}

_connect(); # autoconnect

# only for exporting symbols
package Ext::Elastic::_init;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
use base 'Exporter';
our @EXPORT = qw($Elastic);

our $Elastic=$Ext::Elastic::service;

package Search::Elasticsearch::Error::Missing;
sub TO_JSON{return undef}

1;

=head1 AUTHOR

Comsultia, s.r.o. (open@comsultia.com)

=cut
