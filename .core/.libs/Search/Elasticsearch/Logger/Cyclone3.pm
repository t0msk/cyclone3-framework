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
		main::_log(sprintf($format,join(', ',@{$data})),3,"elastic");
	}
	else
	{
		main::_log(sprintf($format,$data),3,"elastic");
	}
}

sub info
{
	my $self=shift;
	main::_log(shift,3,"elastic");
}

sub debug
{
	my $self=shift;
	main::_log(shift,3,"elastic");
}

sub deprecation
{
	my $self=shift;
	my $warning=shift;
	my $request=shift;
	main::_log('[Deprecated] '.$warning.' in '.to_json($request),4,"elastic");
#	print Dumper($request);
}

sub trace_error
{
	my $self=shift;
	my $cxn=shift;
	my $error=shift;
	return undef unless $error->{'type'} eq "Internal";
#	main::_log('['.$error->{'type'}.'] '.$error->{'text'},4,"elastic");
	main::_log($error->{'text'},1);
}

sub throw_error
{
	my $self=shift;
	my $error=shift;
	return undef if $error->{'type'} eq "Internal";
	main::_log($error->{'msg'},4,"elastic");
}

sub throw_critical
{
	my $self=shift;
	my $error=shift;
	return undef if $error->{'type'} eq "Internal";
	main::_log($error->{'msg'},1);
	main::_log($error->{'msg'},4,"elastic");
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
		'severity' => 3,
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
