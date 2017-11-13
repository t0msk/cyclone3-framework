package TOM::Engine::prove;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}
	
	use TOM;
	
	BEGIN
	{
		$TOM::Engine='prove';
#		$tom::addons_init=1;
#		$tom::templates_init=1;
	}
	
	use Mysql; # 3.5MB
	use MIME::Base64;
	use File::Type;
	
	# CORE Engine kniznice
	use TOM::Domain;
	
	BEGIN
	{
		# data adresar
#		mkdir $tom::P."/_data" if (! -e $tom::P."/_data");
	}
	
	use TOM::Warning;
	use TOM::Database::connect;
	
	# TOM libraries
	use TOM::Net::email;
	use TOM::Debug::breakpoints; # merania
	use TOM::Math;
	use TOM::Int::lng;
	use TOM::Utils::datetime;
	use TOM::Template; # is called already from TOM::Domain
	
	# default addons
	use App::020::_init; # standard 0
#	use App::301::_init;
	
	# new Cyclone libs
	use Cyclone;
	
#	use Ext::RabbitMQ::_init;
	
#	use TOM::Engine::job::cron;
	
package main;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
	
	
	use CML;
	use Int::charsets;
	use Int::charsets::encode;
	
	sub handler_exit
	{
		my $signame = shift;
		if ($signame eq "ALRM")
		{
			main::_log("SIG '$signame' (timeout) [EXIT] PID:$$ domain:$tom::H_orig",3,"job.mng",1);
		}
		exit(0);
	}
	
	sub handler_check_exit
	{
		my $signame = shift;
		main::_log_stdout("SIG '$signame' [CHECK-EXIT] PID:$$ domain:$tom::H_orig",3,"job.mng",1);
		if ($main::_canexit)
		{
			main::_log_stdout("exiting",3,"job.mng",1);
			exit;
		}
		main::_log_stdout("registered request to exit",3,"job.mng",1);
		$main::_exit=1; # request to exit
	}
	
	our $sigset = POSIX::SigSet->new();
	our $action_exit = POSIX::SigAction->new(
		\&handler_exit,
		$sigset,
		&POSIX::SA_NODEFER);

	our $action_check_exit = POSIX::SigAction->new(
		\&handler_check_exit,
		$sigset,
		&POSIX::SA_NODEFER);

	main::_log("registering SIG{ALRM} action to EXIT");
	POSIX::sigaction(&POSIX::SIGALRM, $action_exit);
	
	POSIX::sigaction(&POSIX::SIGHUP, $action_check_exit);
	POSIX::sigaction(&POSIX::SIGINT, $action_check_exit);
#	POSIX::sigaction(&POSIX::SIGPIPE, $action_check_exit);
	
	$main::_canexit=1;
1;
