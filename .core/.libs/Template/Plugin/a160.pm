package Template::Plugin::a160;

use strict;
#use warnings;
use base 'Template::Plugin';
use App::160::_init;

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

sub get_relations {
	my $self = shift;
	my $env=shift;
	my @relations=App::160::SQL::get_relations(%{$env});
	return \@relations;
}

1;