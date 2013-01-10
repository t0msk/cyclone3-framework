#!/bin/perl
package Ext::Solr;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

=head1 NAME

Extension Apache Solr

=head1 DESCRIPTION

Interface with the Solr (Lucene) webservice  

=cut

BEGIN
{
	main::_log("<={LIB} ".__PACKAGE__);
}

BEGIN
{
	require WebService::Solr;
	$Ext::Solr=1;
}

BEGIN {shift @INC;}

#our $cache_available;
our $debug=0;
our $service;

=head1 FUNCTIONS

=head2 connection()

Return connection object to Solr

=cut

sub service
{
	return undef unless $Ext::Solr::url;
	if (!$service)
	{
		$service = WebService::Solr->new($Ext::Solr::url, { autocommit => $Ext::Solr::autocommit });
#		$service->commit(); # first commit to store previous uncommited sessions
	}
	return $service;
}

1;

=head1 AUTHOR

Comsultia, s.r.o. (open@comsultia.com)

=cut
