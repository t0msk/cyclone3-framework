#!/bin/perl
package Ext::Solr;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
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
	$Ext::Solr=1 if $Ext::Solr::url;
}

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
#		$service = Ext::Solr::service->new($Ext::Solr::url, { 'autocommit' => $Ext::Solr::autocommit,agent => LWP::UserAgent->new(
#			keep_alive => 1,
#			timeout => 3600
#		) });
		$service = Ext::Solr::service->new();
	}
	return $service;
}



package Ext::Solr::service;
use vars qw{$AUTOLOAD};

sub new
{
	my $class=shift;
	my $self={};
	
#	$self->{'service'} = Ext::Solr::webservice->new($Ext::Solr::url, { 'autocommit' => $Ext::Solr::autocommit });
	
	my $t=track TOM::Debug("solr connect");
	
	foreach my $host (sort keys %Ext::Solr::hosts)
	{
#		main::_log("host=$host");
		$self->{'services'}{$host} = Ext::Solr::webservice->new(
			$Ext::Solr::hosts{$host}{'url'}, { 'autocommit' => $Ext::Solr::autocommit }
		);
		if ($self->{'services'}{$host}->ping())
		{
			main::_log("Solr '$host' \@$Ext::Solr::hosts{$host}{'url'} with $Ext::Solr::hosts{$host}{'roles'} role connected and respondig");
			$self->{'services'}{$host}->{'host_name'} = $host;
			if ($Ext::Solr::hosts{$host}{'roles'} eq 'rw' &&  !$self->{'service'})
			{
				$self->{'service'}=$self->{'services'}{$host};
			}
		}
		else
		{
			main::_log("can't connect Solr '$host' \@$Ext::Solr::hosts{$host}{'url'}",1);
			delete $self->{'services'}{$host};
		}
	}
	
	if (!keys %Ext::Solr::hosts)
	{
		$self->{'service'} = Ext::Solr::webservice->new(
			$Ext::Solr::url, {
				'autocommit' => $Ext::Solr::autocommit,
				'agent' => LWP::UserAgent->new(
#					'keep_alive' => 1,
					'timeout' => 600
				)
			});
		if ($self->{'service'}->ping())
		{
			main::_log("Solr \@$Ext::Solr::url connected and respondig");
		}
	}
	
	$t->close();
	
	return bless $self, $class;
}


sub DESTROY { }

sub AUTOLOAD
{
	my $self=shift;
	
	(my $method = $AUTOLOAD ) =~ s{.*::}{};
	
	my $role='r';
	if ($method=~/^(add|commit)$/)
	{
		$role='w';
	}
	
#	if (ref($_[1]) eq "HASH" && $_[1]->{'-cluster'} && $self->{'services'})
	if (ref($_[1]) eq "HASH" && $_[1]->{'-cluster'} && keys %{$self->{'services'}})
	{
		my $hosts=scalar grep {$Ext::Solr::hosts{$_}{'roles'}=~/$role/} keys %{$self->{'services'}};
		my $hosts_selected = int(rand($hosts));
		my $hosts_selected_name = (grep {$Ext::Solr::hosts{$_}{'roles'}=~/$role/} keys %{$self->{'services'}})[$hosts_selected];
		return $self->{'services'}{$hosts_selected_name}->$method(@_);
	}
	
	# others
	return $self->{'service'}->$method(@_);
}



package Ext::Solr::webservice;

use parent 'WebService::Solr';

sub commit
{
	my $self=shift;
	
	my ($package, $filename, $line) = caller(0);
	
#	main::_log("[solr".do{':'.$self->{'host_name'} if $self->{'host_name'}}."] COMMIT",3,"solr");
	main::_log("commit",{
		'facility' => 'solr',
		'severity' => 3,
		'data' => {
			'action' => 'commit',
			'hostname' => $self->{'host_name'}
		}
	});
#	main::_log(do{'@'.$self->{'host_name'}.' ' if $self->{'host_name'}}."COMMIT from $package at $filename:$line",3,"solr");
#	main::_log("[$tom::H] ".do{'@'.$self->{'host_name'} if $self->{'host_name'}}." COMMIT from $package at $filename:$line",3,"solr",1);
#	main::_log("[$tom::H] ".do{'@'.$self->{'host_name'} if $self->{'host_name'}}." COMMIT from $package at $filename:$line",3,"solr",2) if $tom::H ne $tom::Hm;
	
	$self->SUPER::commit();
}


sub search
{
	my $self=shift;
#	my ($package, $filename, $line) = caller(0);
	
	if (exists $_[1]->{'start'} && !$_[1]->{'start'})
	{
		delete $_[1]->{'start'};
	}
	
	# call
	my $response;
	eval{$response=$self->SUPER::search(@_)};
	
	# process
	if ($response)
	{
		my $numfound=$response->content->{'response'}->{'numFound'};

		if ($_[1]->{'group'} && $_[1]->{'group.field'})
		{
			$numfound=$response->content->{'grouped'}->{$_[1]->{'group.field'}}->{'matches'};
		}
		
		my $qtime=$response->content->{'responseHeader'}->{'QTime'};
		if (!$_[1]->{'quiet'})
		{
			my ($package, $filename, $line) = caller(1);
			main::_log("search '$_[0]'",{
				'facility' => 'solr',
				'severity' => 3,
				'data' => {
					'caller' => [
						{'p_s' => $package,'f_s' => $filename,'l_i' => $line},
					],
					'action' => 'search',
					'hostname' => $self->{'host_name'},
					'duration_f' => ($qtime/1000),
					'rows_i' => $numfound
				}
			});
		}
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
	
	main::_log("add '$id'",{
		'facility' => 'solr',
		'severity' => 3,
		'data' => {
			'action' => 'add',
			'hostname' => $self->{'host_name'},
			'ID_s' => $id
		}
	});
#	main::_log(do{':'.$self->{'host_name'}.' ' if $self->{'host_name'}}."add '$id' from $package at $filename:$line",3,"solr");
#	main::_log("[$tom::H] ".do{'@'.$self->{'host_name'} if $self->{'host_name'}}." add '$id' from $package at $filename:$line",3,"solr",1);
#	main::_log("[$tom::H] ".do{'@'.$self->{'host_name'} if $self->{'host_name'}}." add '$id' from $package at $filename:$line",3,"solr",2) if $tom::H ne $tom::Hm;
	
	return $response;
}

package WebService::Solr::Field;

sub TO_JSON { return { %{ shift() } }; }

1;

=head1 AUTHOR

Comsultia, s.r.o. (open@comsultia.com)

=cut
