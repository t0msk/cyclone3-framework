package Template::Plugin::a520;

use strict;
#use warnings;
use base 'Template::Plugin';
use App::520::_init;

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

sub get_audio_part_file {
	my $self = shift;
	my $env=shift;
	my %video=App::520::functions::get_audio_part_file(%{$env});
	return \%video;
}

1;
