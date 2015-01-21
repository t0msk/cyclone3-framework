package Template::Plugin::SQL;

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

sub execute {
	my $self = shift;
#	my $env=shift;
	my %sth0=TOM::Database::SQL::execute(@_);
	return \%sth0;
}

sub query {
	my $self = shift;
	my %sth0=TOM::Database::SQL::execute(@_);
	my @rows;
	while (my %data=$sth0{'sth'}->fetchhash())
	{
		push @rows,\%data;
	}
	return \@rows;
}

1;
