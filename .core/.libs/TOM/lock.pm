package TOM::lock;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

=head1 NAME

TOM::lock

=cut

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


=head1 DESCRIPTION

Allow you to create indenpendent locks for running processes between system processes

For example, when you are datamining data into database, statistic outputs would be inconsistent, also this processes is locked.

=cut

=head1 SYNOPSIS

 my $lock=new TOM::lock("datamining") || die "this lock is in use";
 ... processing
 $lock->close();

Get pid

 my $pid=TOM::lock::get_pid("datamining");

Get pid file

 my $pidfile=TOM::lock::get_pidfile("datamining");

=cut

=head1 DEPENDS

=over

=item *

L<TOM::Debug|source-doc/".core/.libs/TOM/Debug.pm">

=back

=cut

use TOM::Debug;

sub new
{
	my $class=shift;
	my $self={};
	
	$self->{'name'}=shift;
	
	my $t=track TOM::Debug(__PACKAGE__."::new($self->{'name'})");
	
	$self->{'md5'}=Digest::MD5::md5_hex($self->{'name'});
	
	main::_log("request for lock named '$self->{name}' to PID '$$' md5 '$self->{'md5'}'");
	
	$self->{'filename'}=$TOM::P."/_temp/".$self->{'md5'}.".pid";
	main::_log("filename '$self->{'filename'}'");
	if (-e $self->{'filename'})
	{
		#main::_log("lock named '$self->{name}' is open");
		open (LOCK,"<".$self->{'filename'});
		my $pid=<LOCK>;$pid=~s|[\n\r]||g;
		main::_log("lock named '$self->{name}' is open in PID '$pid'");
		if ($pid && -e "/proc/$pid" && ($pid ne $$))
		{
			main::_log("concurrent PID '$pid' is running, also return undef");
			$t->close();
			return undef;
		}
	}
	
	main::_log("creating lock named '$self->{name}' with PID $$");
	
	open (LOCK,">".$self->{'filename'}) || return undef;
	print LOCK $$;
	close (LOCK);
	
	$self->{'PID'}=$$;
	
	$t->close();
	
	return bless $self, $class;
}



=head1 FUNCTIONS

=head2 get_pid()

Returns pid number of process which is using this lock

=cut

sub get_pid
{
	my $name=shift;
	my $filename=get_pidfile($name);
	open(PID,'<'.$filename);
	return <PID>;
}



=head2 get_pidfile

Returns filename of this lock, where is stored actual PID

=cut

sub get_pidfile
{
	my $name=shift;
	return $TOM::P."/_temp/".Digest::MD5::md5_hex($name).".pid";
}


sub close
{
	my $self=shift;
	unlink $self->{'filename'};
	return 1;
}


sub DESTROY
{
	my $self=shift;
	if ($self->{'PID'} == $$ && -e $self->{'filename'})
	{
		main::_log("destroying lock named '$self->{name}'");
		unlink $self->{'filename'};
	}
	elsif (-e $self->{'filename'})
	{
		main::_log("exiting lock, i can't destroy lock named '$self->{name}' (i'm another process)");
	}
	return 1;
}


1;
