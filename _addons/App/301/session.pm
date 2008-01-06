#!/bin/perl
package App::301::session;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our $debug=1;
our $serialize=1;
our $IDsession;
our $session_save;
our $performance=0;

sub TIEHASH
{
	my $class = shift;
	main::_log("TIE-TIEHASH a301::session") if $debug;
	$IDsession=$main::USRM{'ID_session'};
	$session_save=$main::USRM{'session_save'};
	return bless {}, $class;
}

sub DESTROY
{
	my $self = shift;
	main::_log("TIE-DESTROY a301::session") if $debug;
	
	# pokial nemam jednoznacny identifikator danej session je
	# zbytocne nieco serializovat a ukladat to, ked sa to vlastne
	# nikam neulozi
	return undef unless $IDsession;
	
		main::_log("TIE-serializing '$IDsession'") if $debug;
		my $cvml=CVML::structure::serialize(%{$self});
		
		return undef if (($cvml eq $session_save) && $performance);
		
		$cvml=~s|\'|\\'|g;
		
		main::_log("TIE-cvml:='$cvml'") if $debug;
		
		TOM::Database::SQL::execute(qq{
			UPDATE
				TOM.a301_user_online
			SET
				session='$cvml'
			WHERE
				ID_session='$IDsession'
			LIMIT 1
		});
		
		main::_log("TIE-serialized") if $debug;
	
	return undef;
}

sub FETCH
{
	my ($self,$key) = @_;
	return $self->{$key};
}

sub DELETE
{
	my ($self,$key) = @_;
	delete $self->{$key};
	return 1;
}

sub STORE
{
	my ($self,$key,$value)=@_;
	main::_log("TIE-STORE a301::session change key '$key' to value '$value'") if $debug;
	$self->{$key}=$value;
}

sub CLEAR
{
	my $self=shift;
	%$self=();
}

sub FIRSTKEY
{
	my $self=shift;
	scalar keys %$self;
	return scalar each %$self;
}

sub NEXTKEY
{
	my $self=shift;
	return scalar each %$self;
}

1;