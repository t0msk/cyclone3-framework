#!/bin/perl
package Search::Elasticsearch::Logger::Cyclone3;
$Search::Elasticsearch::Logger::Cyclone3::VERSION = '6.00';

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
use Data::Dumper;
use JSON;

use Search::Elasticsearch::Util qw(parse_params to_list);
use TOM::Logger;

sub new
{
	my $class=shift;
	my $self={};
	return bless $self, $class;
}

sub infof
{
	my $self=shift;
	my $format=shift;
	my $data=shift;
	if (ref($data) eq "ARRAY")
	{
		main::_log(sprintf($format,join(', ',@{$data})),LOG_INFO_FORCE_NODEPTH,"elastic");
	}
	else
	{
		main::_log(sprintf($format,$data),LOG_INFO_FORCE_NODEPTH,"elastic");
	}
}

sub info
{
	my $self=shift;
	main::_log(shift,LOG_INFO_FORCE_NODEPTH,"elastic");
}

sub debug
{
	my $self=shift;
	main::_log(shift,LOG_INFO_FORCE_NODEPTH,"elastic");
}

sub deprecation
{
	my $self=shift;
	my $warning=shift;
	my $request=shift;
	main::_log('[Deprecated] '.$warning.' in '.to_json($request),LOG_WARNING_FORCE_NODEPTH,"elastic");
#	print Dumper($request);
}

sub trace_error
{
	my $self=shift;
	my $cxn=shift;
	my $error=shift;
	return undef unless $error->{'type'} eq "Internal";
#	main::_log('['.$error->{'type'}.'] '.$error->{'text'},4,"elastic");
	main::_log($error->{'text'},LOG_ERROR);
}

sub throw_error
{
	my $self=shift;
	my $error=shift;
	return unless ref($error);
	return undef if $error->{'type'} eq "Internal";
	main::_log($error->{'msg'},LOG_ERROR_FORCE_NODEPTH,"elastic");
}

sub throw_critical
{
	my $self=shift;
	my $error=shift;
	return undef if $error->{'type'} eq "Internal";
	main::_log($error->{'msg'},LOG_ERROR);
	main::_log($error->{'msg'},LOG_ERROR_FORCE_NODEPTH,"elastic");
}

sub trace_request
{
	my $self=shift;
	my $cxn=shift;
	my $request=shift;
	$self->{'last_request'}=$request;
#	main::_log($request->{'method'}.' '.$request->{'path'},0,"elastic");
}

sub trace_response
{
	my $self=shift;
	my $cxn=shift;
	my $code=shift;
	my $response=shift;
	my $took=shift;$took=int($took * 10000)/10000;
	main::_log($self->{'last_request'}->{'method'}.' '.$self->{'last_request'}->{'path'},{
		'severity' => LOG_INFO_FORCE_NODEPTH,
		'facility' => 'elastic',
		'data' => {
			'method_s' => $self->{'last_request'}->{'method'},
			'response_code_i' => $code,
			'host_s' => $cxn->{'host'},
			'duration_f' => $took,
		}
	});
	
#	print Dumper($cxn);
}

1;
