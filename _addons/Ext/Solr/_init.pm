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
#		$service = WebService::Solr->new($Ext::Solr::url, { autocommit => $Ext::Solr::autocommit });
		$service = Ext::Solr::service->new($Ext::Solr::url, { autocommit => $Ext::Solr::autocommit });
#		$service->commit(); # first commit to store previous uncommited sessions
	}
	return $service;
}

package Ext::Solr::service;

use parent 'WebService::Solr';

sub commit
{
	my $self=shift;
	
	my ($package, $filename, $line) = caller(0);
	
	main::_log("[solr] COMMIT");
	main::_log("COMMIT from $package at $filename:$line",3,"solr");
	main::_log("[$tom::H] COMMIT from $package at $filename:$line",3,"solr",1);
	main::_log("[$tom::H] COMMIT from $package at $filename:$line",3,"solr",2) if $tom::H ne $tom::Hm;
	
	$self->SUPER::commit();
}


sub search
{
	my $self=shift;
	my ($package, $filename, $line) = caller(0);
	
	if (exists $_[1]->{'start'} && !$_[1]->{'start'})
	{
		delete $_[1]->{'start'};
	}
	
	# call
	my $response=$self->SUPER::search(@_);
	
	# process
	if ($response)
	{
		my $numfound=$response->content->{'response'}->{'numFound'};
		my $qtime=$response->content->{'responseHeader'}->{'QTime'};
		main::_log("[solr] search '$_[0]' found='$numfound' qtime='$qtime'");
		main::_log("search '$_[0]' found='$numfound' qtime='$qtime' from $package at $filename:$line",3,"solr");
		main::_log("[$tom::H] search '$_[0]' found='$numfound' qtime='$qtime' from $package at $filename:$line",3,"solr",1);
		main::_log("[$tom::H] search '$_[0]' found='$numfound' qtime='$qtime' from $package at $filename:$line",3,"solr",2) if $tom::H ne $tom::Hm;
	}
	else
	{
		main::_log("search '$_[0]'");
	}
	
	return $response;
}


sub add
{
	my $self=shift;
	my ($package, $filename, $line) = caller(0);
	
	my $id;
	if ($_[0]->{'fields'}){foreach (@{$_[0]->{'fields'}}){if ($_->{'name'} eq "id"){$id=$_->{'value'};last;}}}
	
	# call
	my $response=$self->SUPER::add(@_);
	
	main::_log("[solr] add '$id'");
	main::_log("add '$id' from $package at $filename:$line",3,"solr");
	main::_log("[$tom::H] add '$id' from $package at $filename:$line",3,"solr",1);
	main::_log("[$tom::H] add '$id' from $package at $filename:$line",3,"solr",2) if $tom::H ne $tom::Hm;
	
	return $response;
}

1;

=head1 AUTHOR

Comsultia, s.r.o. (open@comsultia.com)

=cut
