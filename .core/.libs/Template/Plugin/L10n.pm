package Template::Plugin::L10n;

use strict;
use warnings;
use base 'Template::Plugin';
use Data::Dumper;
use Ext::Redis::_init;

use POSIX ();

our $VERSION = 1.00;

sub new {
	my ($class, $context, @args) = @_;
	
	return undef unless $context->{'tpl'}->{'L10n'};
	
	my $lng=$context->{'tpl'}->{'ENV'}->{'lng'} || $tom::lng;
	
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
	
	if ($TOM::L10n::stats && $Redis && $self->{'L10n'}->{'string'}->{$msg})
	{
		my $key_entity=TOM::Digest::hash(Encode::encode('UTF-8',
			$self->{'L10n'}->{'string_'}->{$msg}->{'location'}.'|'.$msg
		));
		$Redis->set('C3|L10n|use|'.$key_entity,time(),sub{});
		$Redis->expire('C3|L10n|use|'.$key_entity,(86400*7),sub{});
	}
	
	return $self->{'L10n'}->{'string'}->{$msg} || "{".$msg."}";
}
