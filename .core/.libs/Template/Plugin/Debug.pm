package Template::Plugin::Debug;

use strict;
#use warnings;
use base 'Template::Plugin';

our $VERSION = 1.00;
our $DEBUG   = 0 unless defined $DEBUG;
our $AUTOLOAD;

#==============================================================================
#                      -----  CLASS METHODS -----
#==============================================================================

sub new {
	my ($class, $context, $params) = @_;
	my ($key, $val);
	$params ||= { };

	bless { 
		_CONTEXT => $context, 
	}, $class;
}

sub log {
	my $self = shift;
#	my $env=shift;
	
	main::_log(@_);
	return undef;
#	my @relations=App::160::SQL::get_relations(%{$env});
#	return \@relations;
}

1;
