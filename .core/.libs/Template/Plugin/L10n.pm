package Template::Plugin::L10n;

use strict;
use warnings;
use base 'Template::Plugin';
use Data::Dumper;

use POSIX ();

our $VERSION = 1.00;

sub new {
	my ($class, $context, @args) = @_;
	
	return undef unless $context->{'tpl'}->{'L10n'};
	
	my $lng=$context->{'tpl'}->{'ENV'}->{'lng'} || $tom::lng;
	
#	my $L10n=new TOM::L10n(
#		'level' => $context->{'tpl'}->{'L10n'}->{'level'},
#		'addon' => $context->{'tpl'}->{'L10n'}->{'addon'},
#		'name' => $context->{'tpl'}->{'L10n'}->{'name'},
#		'lng' => $lng,
#	);
	
#	print Dumper($context->{'tpl'}->{'L10n'}->{'obj'});
	
	return bless {
		'_CONTEXT' => $context,
		'_ARGS' => \@args,
		'L10n' => $context->{'tpl'}->{'L10n'}->{'obj'},
	}, $class;
}

sub msg
{
	my $self=shift;
	my $msg=shift;
	return $self->{'L10n'}->{'string'}->{$msg} || "{".$msg."}";
}