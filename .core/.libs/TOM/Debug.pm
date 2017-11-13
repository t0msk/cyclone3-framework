package TOM::Debug;

=head1 NAME

TOM::Debug

=head1 DESCRIPTION

Knižnica pre analýzy chovania Cyclone3

=cut

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DEPENDS

knižnice:

 TOM::Debug::logs
 TOM::Debug::breakpoints
 XML::Generator

=cut

#use TOM;
#use TOM::Debug::logs; # 300KB
use TOM::Debug::breakpoints;
use TOM::Debug::proc;
use XML::Generator; # 400KB

package main;


sub _obsolete {return 1;}

=head1 FUNCTIONS

=head2 main::_obsolete_func

Označenie funkcie ako obsolete:

 sub funkcia
 {
   main::_obsolete_func();
 }

Označenie knižnice ako obsolete:

 #!/bin/perl
 package SVGraph::Core;
 BEGIN{main::_log("<={LIB} ".__PACKAGE__);main::_obsolete_func();}

=cut

sub _obsolete_func
{
	my $msg=shift;
	my %env=@_;
	
	my ($package3, $filename3, $line3, $subroutine3) = caller(3);
	my ($package1, $filename1, $line1, $subroutine1) = caller(1);
	my ($package, $filename, $line) = caller(0);
	
	if ($subroutine1=~/::BEGIN$/)
	{
		$filename1 = $filename3;
	}
	
	main::_log("calling obsolete function '$subroutine1' $msg",4);
	if ($msg)
	{
		main::_log("func:'$filename:$line:$subroutine1' from:'$filename1:$line1' msg:{$msg}",4,"obsolete",1);
	}
	else
	{
		main::_log("func:'$filename:$line:$subroutine1' from:'$filename1:$line1'",4,"obsolete",1);
	}
	
	my $X = XML::Generator->new(':pretty');
	
	my $xml_msg=
	$X->obsolete(
		$X->type("function"),
		$X->timestamp(time()),
		$X->call_filename($filename1),
		$X->call_line($line1),
		$X->func_filename($filename),
		$X->func_line($line),
		$X->func($subroutine1)
	)."\n";
	
	open (HND_OBSOLETE,'>>'.$TOM::P.'/_logs/obsolete/'.$$.'.xml') || main::_log("obsolete $!");
	print HND_OBSOLETE $xml_msg;
	close (HND_OBSOLETE);
	
	return 1;
}


package TOM::Debug::hash;

sub TIEHASH
{
	my $class = shift;
	my ($package, $filename, $line) = caller;
	main::_log("TIE-TIEHASH from $filename:$line");
	return bless {}, $class;
}

sub DESTROY
{
	my $self = shift;
	my ($package, $filename, $line) = caller;
	
	main::_log("TIE-DESTROY from $filename:$line",3,"a301");
	
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
	my ($package, $filename, $line) = caller;
	main::_log("TIE-STORE change key '$key' to value '$value' from $filename:$line");
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
