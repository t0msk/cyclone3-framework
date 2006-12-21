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
	main::_log("SIG '$signame' [EXIT] (timeout $TOM::fcgi_timeout secs, lives ".(time()-$TOM::time_start)." secs, $tom::count requests) PID:$$ domain:$tom::H",3,"pub.mng",1);
	exit(0);
}

sub handler_check
{
	my $signame=shift;
	if ($main::sig_term) # proces je v stave ze moze byt ukonceny
	{
		print "Location: http://$ENV{HTTP_HOST}$ENV{REQUEST_URI}\n\n";
		main::_log("SIG '$signame' [CHECK-EXIT] (lives ".
			(time()-$TOM::time_start).
			" secs, $tom::count requests) PID:$$ domain:$tom::H ($@ $!)",3,"pub.mng",1);
		exit(0);
	}
	else
	{
		main::_log("SIG '$signame' [CHECK-WAIT] (lives ".
			(time()-$TOM::time_start).
			" secs, $tom::count requests) PID:$$ domain:$tom::H ($@ $!)",3,"pub.mng",1);
		$tom::HUP=2; # po dobehnuti tohto requestu na 100% exitnem
	};
}

sub handler_ignore
{
	my $signame = shift;
	print "Location: http://$ENV{HTTP_HOST}$ENV{REQUEST_URI}\n\n";
	main::_log("SIG '$signame' [IGNORE] (timeout $TOM::fcgi_timeout secs, lives ".(time()-$TOM::time_start)." secs, $tom::count requests) PID:$$ domain:$tom::H",3,"pub.mng",1);
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


our $action_check = POSIX::SigAction->new(
	\&TOM::Engine::pub::SIG::handler_check,
	$sigset,
	&POSIX::SA_NODEFER);
	
	
main::_log("registering SIG{ALRM} action to EXIT");
POSIX::sigaction(&POSIX::SIGALRM, $action_exit);

main::_log("registering SIG{HUP} action to CHECK");
POSIX::sigaction(&POSIX::SIGHUP, $action_check);

main::_log("registering SIG{TERM} action to CHECK");
POSIX::sigaction(&POSIX::SIGTERM, $action_check);

main::_log("start counting timeout $TOM::fcgi_timeout");
alarm($TOM::fcgi_timeout); # zacnem pocitat X sekund kym nedostanem request


1;
