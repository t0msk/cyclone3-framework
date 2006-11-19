package TOM::Engine::pub::SIG;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


sub handler_exit
{
	my $signame = shift;
	print "Location: http://$ENV{HTTP_HOST}$ENV{REQUEST_URI}\n\n";
	main::_log("SIG '$signame' (relocation) (timeout $TOM::fcgi_timeout secs, lives ".(time()-$TOM::time_start)." secs, $tom::count requests) PID:$$ domain:$tom::H",3,"pub.mng",1);
	exit(0);
}

sub handler_wait
{
	my $signame=shift;
	main::_log("REQUEST SIG '$signame' (lives ".
			(time()-$TOM::time_start).
			" secs, $tom::count requests) PID:$$ domain:$tom::H ($@ $!)",3,"pub.mng",1);
	if ($main::sig_term)
	{
		print "Location: http://$ENV{HTTP_HOST}$ENV{REQUEST_URI}\n\n";
		main::_log("ACCEPTING SIG '$signame'",3,"pub.mng",1);
		exit(0);
	}
	else
	{
		$tom::HUP=2; # po dobehnuti tohto requestu na 100% exitnem
	};
}

sub handler_ignore
{
	my $signame = shift;
	print "Location: http://$ENV{HTTP_HOST}$ENV{REQUEST_URI}\n\n";
	main::_log("IGNORE SIG '$signame' (timeout $TOM::fcgi_timeout secs, lives ".(time()-$TOM::time_start)." secs, $tom::count requests) PID:$$ domain:$tom::H",3,"pub.mng",1);
}


our $sigset = POSIX::SigSet->new();


our $action_exit = POSIX::SigAction->new(
	\&TOM::Engine::pub::SIG::handler_exit,
	$sigset,
	&POSIX::SA_NODEFER);


our $action_ignore = POSIX::SigAction->new(
	\&TOM::Engine::pub::SIG::handler_ignore,
	$sigset,
	&POSIX::SA_NODEFER);


our $action_wait = POSIX::SigAction->new(
	\&TOM::Engine::pub::SIG::handler_wait,
	$sigset,
	&POSIX::SA_NODEFER);
	
	
main::_log("registering SIG{ALRM} action to exit");
POSIX::sigaction(&POSIX::SIGALRM, $action_exit);

main::_log("registering SIG{HUP} action to exit");
POSIX::sigaction(&POSIX::SIGHUP, $action_exit);

main::_log("registering SIG{TERM} action to ignore");
POSIX::sigaction(&POSIX::SIGTERM, $action_ignore);

main::_log("start counting timeout $TOM::fcgi_timeout");
alarm($TOM::fcgi_timeout); # zacnem pocitat X sekund kym nedostanem request


1;
