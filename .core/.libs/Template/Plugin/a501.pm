package Template::Plugin::a501;

use strict;
use warnings;
use base 'Template::Plugin';
use App::501::_init;

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

sub get_image_file {
	my $self = shift;
	my $env=shift;
	my %image=App::501::functions::get_image_file(%{$env});
	$image{'ID_entity'}=$image{'ID_entity_image'};
	return \%image;
}

1;