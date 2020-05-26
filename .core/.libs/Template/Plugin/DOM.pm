package Template::Plugin::DOM;

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
use warnings;
use base 'Template::Plugin';
use Data::Dumper;
use Mojo::DOM;

use POSIX ();

sub new {
   my ($class, $context, $params) = @_;
   bless {
      $params ? %$params : ()
   }, $class;
}

sub parse {
	my $self=shift;
	my $env=shift;
	return Mojo::DOM->new($env);
}

#sub now {
#	my $self=shift;
#	my $env=shift;
#	return DateTime->now(%{$env});
#}

#sub compare {
#	my $self=shift;
#	my $env0=shift;
#	my $env1=shift;
#	return DateTime->compare($env0, $env1);
#}

#sub last_day_of_month {
#	my $self=shift;
#	my $env=shift;
#	return DateTime->last_day_of_month(%{$env});
#}

1;
