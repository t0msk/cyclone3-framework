package Template::Plugin::DateTime;

use strict;
use warnings;
use base 'Template::Plugin';
use Data::Dumper;

use POSIX ();

sub new {
   my ($class, $context, $params) = @_;
   bless {
      $params ? %$params : ()
   }, $class;
}

sub init {
	my $self=shift;
	my $env=shift;
	return DateTime->new(%{$env});
}

sub now {
	my $self=shift;
	my $env=shift;
	return DateTime->now(%{$env});
}

sub compare {
	my $self=shift;
	my $env0=shift;
	my $env1=shift;
	return DateTime->compare($env0, $env1);
}

sub last_day_of_month {
	my $self=shift;
	my $env=shift;
	return DateTime->last_day_of_month(%{$env});
}

1;
