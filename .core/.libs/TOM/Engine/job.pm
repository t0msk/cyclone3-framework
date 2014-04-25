package TOM::Engine::job;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}
	
	use TOM;
	
	BEGIN
	{
		$TOM::Engine='job';
		$tom::addons_init=1;
		$tom::templates_init=1;
	}
	
	use Mysql; # 3.5MB
	use MIME::Base64;
	use File::Type;
	
	# CORE Engine kniznice
	use TOM::Domain; # all addons will be initialized because $tom::addons_init is in true state
	
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
	use TOM::Engine::job::module;
	
	# default addons
	use App::020::_init; # standard 0
	
	# new Cyclone libs
	use Cyclone;
	
#	use Ext::RabbitMQ::_init;
	
package main;
use open ':utf8', ':std';
use encoding 'utf8';
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

	our $sigset = POSIX::SigSet->new();
	our $action_exit = POSIX::SigAction->new(
		\&handler_exit,
		$sigset,
		&POSIX::SA_NODEFER);

	main::_log("registering SIG{ALRM} action to EXIT");
	POSIX::sigaction(&POSIX::SIGALRM, $action_exit);
	
1;
