package Template::Plugin::Curl;

use strict;
#use warnings;
use base 'Template::Plugin';
use LWP::Curl;

our $VERSION = 1.00;
our $DEBUG   = 0 unless defined $DEBUG;
our $AUTOLOAD;

#==============================================================================
#                      -----  CLASS METHODS -----
#==============================================================================

our $curl=LWP::Curl->new();

sub new {
	my ($class, $context, $params) = @_;
	my ($key, $val);
	$params ||= { };

	bless { 
		_CONTEXT => $context
	}, $class;
}

sub get {
	my $self = shift;
#	my $env = shift;
	use Data::Dumper;
#	main::_log("param=".Dumper(\@_),3,"debug");
	$curl->timeout(5);
	return $curl->get(@_);
}

sub post {
	my $self = shift;
	$curl->timeout(5);
	my $data=eval{$curl->post(@_)};
	return $data;
}

1;
