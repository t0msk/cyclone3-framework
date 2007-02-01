package TOM::lock;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use TOM::Debug;

sub new
{
	my $class=shift;
	my $self={};
	
	my $t=track TOM::Debug(__PACKAGE__."::new($class)");
	
	$self->{'name'}=shift;
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
		if ($pid && -e "/proc/$pid")
		{
			main::_log("concurrent PID '$pid' is running, also return undef");
			$t->close();
			return undef;
		}
	}
	
	main::_log("creating lock named '$self->{name}'");
	
	open (LOCK,">".$self->{'filename'});
	print LOCK $$;
	close (LOCK);
	
	$t->close();
	
	return bless $self, $class;
}


sub get_pid
{
	my $name=shift;
	my $filename=get_pidfile($name);
	open(PID,'<'.$filename);
	return <PID>;
}

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


1;
