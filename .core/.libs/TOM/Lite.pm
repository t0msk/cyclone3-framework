package main;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

our $event_socket;

#eval {if ($Ext::Redis::logger){
#	# try to use RedisDB logging
#	use Ext::Redis::_init;
#}};


sub ctodatetime
{
	my $var=shift @_;
	my %env=@_;
	my %env0;
	(	$env0{sec},
		$env0{min},
		$env0{hour},
		$env0{mday},
		$env0{mom},
		$env0{year},
		$env0{wday},
		$env0{yday},
		$env0{isdst}) = localtime($var);
	# doladenie casu
	$env0{year}+=1900;$env0{mom}++;
	return %env0 unless $env{format};
	(	$env0{sec},
		$env0{min},
		$env0{hour},
		$env0{mday},
		$env0{mom},
		) = (
		sprintf ('%02d', $env0{sec}),
		sprintf ('%02d', $env0{min}),
		sprintf ('%02d', $env0{hour}),
		sprintf ('%02d', $env0{mday}),
		sprintf ('%02d', $env0{mom}),
	);
	$env0{mon}=$env0{mom};
return %env0}


our %HND;
our @log_sym=("+","-","+","+","-");
our $log_time;
our %log_date;
sub _log
{
	return undef if $TOM::DEBUG_log_file==-1;
	unshift @_, $TOM::Debug::track_level;
	
	my @get=@_;
	#$get[0] = level
	#$get[1] = message
	#$get[2] = mode
	#	0=norm	level	not
	#	1=error!	level	mustlog
	#	2=norm	level	mustlog
	#	3=norm	not	mustlog
	#	4=error	not	mustlog
	#$get[3] = engine, or logname
	#$get[4] = 0-local 1-global 2-master
	
	return undef unless $get[1];
	$get[0]=0 if $get[2]==3;
	$get[0]=0 if $get[2]==4;
	return undef if
	(
		($TOM::DEBUG_log_file < $get[0]) &&
		(!$get[2]) &&
		(!$main::debug) &&
		(!$main::stdout)
	);
	
	$get[3]=$TOM::engine unless $get[3];
	$get[1]=~s|[\n\r\t]| |g;
	
	my $tt=time();
	if ($tt > $log_time)
	{
		$log_time=$tt;
		%log_date=ctodatetime($log_time,format=>1);
	}
	
	my $msec=ceil((Time::HiRes::gettimeofday)[1]/100);
	
	my $msg="[".sprintf ('%06d', $$);# unless $main::stdout;
		$msg.=";$main::request_code" if ($TOM::Engine eq "pub" && !$main::stdout);
		$msg.="]["
			.$log_date{'hour'}.":".$log_date{'min'}.":".$log_date{'sec'}.".".sprintf("%04d",$msec)."] "
			.(" " x $get[0]).$log_sym[$get[2]].$get[1];
	
	if (length($msg)>8048)
	{
		$msg=substr($msg,1,8048);
		$msg.="...";
	}
	
#=head1
	if (
			($main::stdout && $main::debug && $get[3] eq $TOM::engine) ||
			($main::stdout && $get[3] eq "stdout")
		)
	{
		# only to stdout
		$msg=$log_sym[$get[2]].' '.$get[1] unless $main::debug;
		print color 'green';
		print color 'bold' if $get[1]=~/^</;
		print color 'red' if $log_sym[$get[2]] eq '-';
		print $msg."\n";
		print color 'reset';
		return 1 if $get[3] eq "stdout";
	}
	elsif ($main::stdout && $log_sym[$get[2]] eq '-' && $get[3] eq $TOM::engine)
	{
		my ($package, $filename, $line) = caller;
		# error to stderr
		print STDERR color 'red';
		print STDERR "CYCLONE3STDERR: ".$get[1]." at ".$filename." line ". $line ."\n";
		print STDERR color 'reset';
	}
#=cut
	
	if (
			($TOM::DEBUG_log_file>=$get[0])||
			($get[2])||
			($main::debug)
		) # logujem v pripade ze som v ramci levelu alebo ide o ERROR
	{
		return 1 if $get[3] eq "stdout";
#		if ($Redis && $Ext::Redis::logger)
#		{
#			print $msg."\n";
#			$Redis->publish('C3|log|'."test",
#				"message"
#				,sub {});
#			return 1;
#		}
		
		my $file;
		if ($TOM::path_log)
		{
			$file=$TOM::path_log;
			if ($get[4]==1) {} # global
			elsif ($tom::Pm && $get[4]==2) {$file.='/'.($tom::H_orig || $tom::Hm)} # master
			elsif ($tom::H) {$file.='/'.($tom::H_orig || $tom::H)} # local
			$file.='/'; # global
		}
		else
		{
			$file=$TOM::P."/_logs/";
			$file=$tom::P."/_logs/" if $tom::P;
			$file=$tom::Pm."/_logs/" if ($tom::Pm && $get[4]==2);
			$file=$TOM::P."/_logs/" if $get[4]==1;
		}
		
		$file.="[".$TOM::hostname."]" if $TOM::serverfarm;
		$file.="$log_date{year}-$log_date{mom}-$log_date{mday}";
#		$file.="-$log_date{hour}" if $TOM::DEBUG_log_file_frag; # rozlisenie na hodiny
		
		$get[0]=0 unless $get[0];
		
		my $filename_full=$file.".".$get[3].".log";
		if (!$HND{$filename_full})
		{
#			print "a '$filename_full'\n";
			if (! -e $file){mkdir $file;chmod (0777,$file)} # check directory
			use Fcntl;
			my $logfile_new;
			$logfile_new=1 unless -e $filename_full;
			# open this handler at first
			open ($HND{$filename_full},">>".$filename_full)
#			sysopen($HND{$filename_full},$filename_full,O_APPEND)
				|| print STDERR "Cyclone3 system can't write into logfile $filename_full $!\n";
			chmod (0666 , $filename_full) if $logfile_new;
		}
		syswrite($HND{$filename_full}, $msg."\n", length($msg."\n"));
#		print $HND{$filename_full} ($msg."\n");
#		print $HND{$filename_full} "test";
#		close($HND{$filename_full}); # close on every write (because logrotate)
	}
	
	return 1;
};

#sub _log {_log_lite(@_);}
sub _applog {_log(@_);}
sub _log_stdout
{
	return undef unless $main::stdout;
	$_[2]="stdout";
	_log(@_);
}
sub _deprecated
{
	#return 1;
	my ($package, $filename, $line) = caller;
	_log($_[0]." from $filename:$line",0,"deprecated",1);
}
sub _log_long
{
	my @get=@_;
	foreach my $msg(split('\n',$get[0]))
	{
		my @get0=@get;
		$get0[0]=$msg;
		_log(@get0);
	}
	return 1;
}

sub _event
{
	return undef unless $TOM::event_socket;
	return undef if
	(
		(!$_[0] || !$_[1])
	);
	
	return undef if $TOM::event_severity_disable{$_[0]};
	return undef if $TOM::event_facility_disable{$_[1]};
	
	if (!$event_socket)
	{
		my @peer=split(':',$TOM::event_socket);
		$event_socket = IO::Socket::INET->new(
			'PeerAddr' => $peer[0],
			'PeerPort' => $peer[1],
			'Proto'    => $peer[2] || "tcp",
			'Type'     => SOCK_STREAM)
		or do {undef $TOM::event_socket;return;};
	}
	
	tie my %hash, 'Tie::IxHash', (
		'timestamp' => time().int((Time::HiRes::gettimeofday)[1]/1000),
		'severity' => $_[0],
		'hostname' => $TOM::hostname,
		'PID' => $$,
		'facility' => $_[1],
		'engine' => $TOM::engine,
		do{('domain',$tom::H) if $tom::H},
		do{('request',$main::request_code) if $main::request_code},
		%{$_[2]}
	);
	
	if ($main::USRM{'ID_user'})
	{
		$hash{'user'}={
			'ID' => $main::USRM{'ID_user'} || $main::USRM{'IDhash'},
			'session' => $main::USRM{'ID_session'},
			'logged' => $main::USRM{'logged'}
		};
	}
	
	print $event_socket to_json(\%hash)."\n";
	
}

_event('debug','process.start',{
	'cmd' => $0.' '.(join " ",@ARGV),
	'UID' => $<,
	'perl' => "$^V",
	'osname' => $^O
});






package TOM;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__."::Lite (_log + conf)");};}





package TOM::Net::email;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__." (Lite)");};}

sub send
{
	my $ID=time()."-".$$."-".sprintf("%07d",int(rand(10)));
	my %env=@_;
	
	main::_log("saving email into file $ID");
	
	open(HND_mail,">".$TOM::P."/_temp/_email-".$ID) || die "can't send email over file!\n";
	print HND_mail "$env{from}\n";
	print HND_mail "$env{to}\n";
	print HND_mail $env{body}."\n";
	close (HND_mail);
	chmod 0666, $TOM::P."/_temp/_email-".$ID;
	
	return 1;
}





package TOM::Error;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__." (Lite)");};}

use MIME::Entity;

my $date=`date "+%a,%e %b %Y %H:%M:%S %z (%Z)"`;$date=~s|[\n\r]||g;

our $engine_email_lite=<<"HEADER";
<%ERROR%>
HEADER

sub engine_lite
{
	#
	#
	# Tato chyba moze nastat pri inicializovani core
	# teda pytani kniznic pomocou request "TOM::Engine::'engine'"
	#
	#
	
	my $var=join(". ",@_);$var=~s|\n| |g;
	
	main::_log("[ENGINE][".($tom::H?$tom::H:$tom::type?$tom::type:"?")." on $TOM::hostname] $var",1);
	main::_log("[ENGINE][".($tom::H?$tom::H:$tom::type?$tom::type:"?")." on $TOM::hostname] $var",1,$TOM::engine.".err",1);
	
	my $msg = MIME::Entity->build
	(
		'List-Id' => "Cyclone3",
		'Date'    => $date,
		'From'    => "Cyclone3 ('$tom::H' at '$TOM::hostname') <$TOM::contact{'from'}>",
		'To'      => '<'.$TOM::contact{'TOM'}.'>',
		'Subject' => "[ERR][ENGINE]",
		'Data'    => $var
	);
	
	TOM::Net::email::send(
		'priority'=>999,
		'from'=> $TOM::contact{'from'},
		'to'=> $TOM::contact{'TOM'},
		'body'=>$msg->as_string(),
	);
	
}

sub engine
{
	engine_lite(@_);
}







package TOM::Debug;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__." (trackpoints)");};}

our $track_level=0;
our @tracks;
our @tracks_obj;
our %namespace;

sub track
{
	my $class=shift;
	my $self={};
	
	$self->{'name'}=shift;
	my %env=@_;
	$self->{'quiet'}=$env{'quiet'} if $env{'quiet'};
	$self->{'timer'}=$env{'timer'} if $env{'timer'};
	
	if ($env{'attrs'})
	{
		$self->{'attrs'}=$env{'attrs'};
		main::_log("<$self->{name}> #$env{'attrs'}") unless $self->{'quiet'};
	}
	else
	{
		main::_log("<$self->{name}>") unless $self->{'quiet'};
	}
	
	$track_level++;# unless $self->{'quiet'};
	$self->{'level'}=$track_level;
	
	$tracks[$track_level]=$self->{'name'};
	
	($self->{'package'}, $self->{'filename'}, $self->{'line'}) = caller;
	
	$self->{'namespace'}=$env{'namespace'};
	
	if ($self->{'timer'})
	{
		$self->{'time'}{'req'}{'start'}=Time::HiRes::time();
		($self->{'time'}{'user'}{'start'},$self->{'time'}{'sys'}{'start'})=times;
			$self->{'time'}{'proc'}{'start'}=$self->{'time'}{'user'}{'start'}; # backward compatiblity
	}
	
	$tracks_obj[$track_level]=bless $self, $class;
	return $tracks_obj[$track_level];
}

sub DESTROY
{
	my $self=shift;
	
	if ($self->{DESTROY})
	{
		return undef;
	}
	else
	{
		$self->close();
	}
}


sub semiclose
{
	my $self=shift;
	$self->{'time'}{'req'}{'end'}=Time::HiRes::time();
	
	($self->{'time'}{'user'}{'end'},$self->{'time'}{'sys'}{'end'})=times;
		$self->{'time'}{'proc'}{'end'}=$self->{'time'}{'user'}{'end'}; # backward compatibility
		
	$self->{'time'}{'req'}{'duration'}=$self->{'time'}{'req'}{'end'}-$self->{'time'}{'req'}{'start'};
	$self->{'time'}{'user'}{'duration'}=$self->{'time'}{'user'}{'end'}-$self->{'time'}{'user'}{'start'};
	$self->{'time'}{'sys'}{'duration'}=$self->{'time'}{'sys'}{'end'}-$self->{'time'}{'sys'}{'start'};
	
	$self->{'time'}{'req'}{'duration'}=int($self->{'time'}{'req'}{'duration'}*10000)/10000;
	$self->{'time'}{'user'}{'duration'}=int($self->{'time'}{'user'}{'duration'}*1000)/1000;
	$self->{'time'}{'sys'}{'duration'}=int($self->{'time'}{'sys'}{'sys'}*1000)/1000;
		$self->{'time'}{'proc'}{'duration'}=$self->{'time'}{'user'}{'duration'}; # backward compatibility
}


sub close
{
	my $self=shift;
	
	if ($self->{'DESTROY'})
	{
		my ($package, $filename, $line) = caller;
		main::_log("Ooops! from '$filename:$line' This track named '$self->{name}' has been destroyed by calling from '$self->{'DESTROY_filename'}:$self->{'DESTROY_line'}'. Track is generated on '$self->{'filename'}:$self->{'line'}'",1);
		return undef;
	}
	
	if ($self->{'level'}<$track_level)
	{
		my ($package, $filename, $line) = caller;
		main::_log("Ooops! from '$filename:$line' Can't close this track! You must close first track named '$tracks[$track_level]'. Trying to close",1);
		$tracks_obj[$track_level]->close();
		$self->close();
		return undef;
	}
	
	$track_level--;# unless $self->{'quiet'};
	
	if ($self->{'timer'})
	{
		$self->{'time'}{'req'}{'end'}=Time::HiRes::time();
		
		($self->{'time'}{'user'}{'end'},$self->{'time'}{'sys'}{'end'})=times;
			$self->{'time'}{'proc'}{'end'}=$self->{'time'}{'user'}{'end'}; # backward compatibility
			
		$self->{'time'}{'req'}{'duration'}=$self->{'time'}{'req'}{'end'}-$self->{'time'}{'req'}{'start'};
		$self->{'time'}{'user'}{'duration'}=$self->{'time'}{'user'}{'end'}-$self->{'time'}{'user'}{'start'};
		$self->{'time'}{'sys'}{'duration'}=$self->{'time'}{'sys'}{'end'}-$self->{'time'}{'sys'}{'start'};
		
		$self->{'time'}{'duration'}=$self->{'time'}{'req'}{'duration'}=int($self->{'time'}{'req'}{'duration'}*10000)/10000;
		$self->{'time'}{'user'}{'duration'}=int($self->{'time'}{'user'}{'duration'}*1000)/1000;
		$self->{'time'}{'sys'}{'duration'}=int($self->{'time'}{'sys'}{'sys'}*1000)/1000;
			$self->{'time'}{'proc'}{'duration'}=$self->{'time'}{'user'}{'duration'}; # backward compatibility
		
	}
	
	if ($self->{'namespace'})
	{
		if ($tracks_obj[$track_level]->{'namespace'} ne $self->{'namespace'} && $self->{'timer'})
		{
			#main::_log("collect namespace '".$self->{'namespace'}."'");
			$namespace{$self->{'namespace'}}{'time'}{'duration'}=$namespace{$self->{'namespace'}}{'time'}{'req'}{'duration'}+=$self->{'time'}{'req'}{'duration'};
			$namespace{$self->{'namespace'}}{'time'}{'user'}{'duration'}+=$self->{'time'}{'user'}{'duration'};
				$namespace{$self->{'namespace'}}{'time'}{'proc'}{'duration'}=$namespace{$self->{'namespace'}}{'time'}{'user'}{'duration'}; # backward compatibility
			$namespace{$self->{'namespace'}}{'time'}{'sys'}{'duration'}+=$self->{'time'}{'sys'}{'duration'};
		}
	}
	
	$self->{'DESTROY'}=1;
	($self->{'DESTROY_package'}, $self->{'DESTROY_filename'}, $self->{'DESTROY_line'}) = caller;
	
	if (!$self->{'quiet'})
	{
		if ($self->{'timer'})
		{
			
			if ($self->{'attrs'})
			{
				main::_log("</$self->{name}> #".$self->{'attrs'}." (time:".($self->{'time'}{'duration'}*1000)."ms user:~".($self->{'time'}{'user'}{'duration'}*1000)."ms)")
			}
			else
			{
				main::_log("</$self->{name}> (time:".($self->{'time'}{'duration'}*1000)."ms user:~".($self->{'time'}{'user'}{'duration'}*1000)."ms)")
			}
		}
		else
		{
			if ($self->{'attrs'})
			{
				main::_log("</$self->{name}> #".$self->{'attrs'});
			}
			else
			{
				main::_log("</$self->{name}>")
			}
		}
	}
}


sub clear_namespaces
{
	%namespace=();
}

1;
