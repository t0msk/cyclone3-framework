package Template::Plugin::Document;

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

sub title {
	my $self = shift;
	my $title = shift;
	$main::H->change_DOC_title($title);
	return
}

sub add_title {
	my $self = shift;
	my $title = shift;
	$main::H->add_DOC_title($title);
	return
}

sub description {
	my $self = shift;
	my $text = shift;
	$main::H->change_DOC_description($text);
	return
}

sub add_keywords {
	my $self = shift;
	
	foreach (@_)
	{
		$main::H->add_DOC_keywords($_);
	}
	return
}

sub add_meta {
	my $self = shift;
	
	use Data::Dumper;
	
	#my @arr=%{$_[0]};
	#main::_log("dump=".Dumper(@arr),3,"debug");
	#$main::H->add_DOC_meta(@{$_[0]});
	$main::H->add_DOC_meta(
		%{$_[0]}
	);
	return
}

1;
