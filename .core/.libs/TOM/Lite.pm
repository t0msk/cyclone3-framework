package main;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

our $event_socket;
use JSON;
our $json = JSON::XS->new->utf8->allow_blessed(1);

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

sub ctogmdatetime
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
		$env0{isdst}) = gmtime($var);
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

our $fluentd_socket;
BEGIN {eval {if ($TOM::DEBUG_log_fluentd){
	require Fluent::Logger;
	$fluentd_socket=Fluent::Logger->new(
		'host' => (split(':',$TOM::DEBUG_log_fluentd))[0],
		'port' => (split(':',$TOM::DEBUG_log_fluentd))[1],
		'tag_prefix' => "cyclone3"
	);
}};if ($@){undef $TOM::DEBUG_log_fluentd}};
our %HND;
our @log_sym=("","-","","","-");
our %log_file;
our $log_time;
our %log_date;
our $log_TTL=5;
sub _log
{
	return undef if $TOM::DEBUG_log_file==-1;
	unshift @_, $TOM::Debug::track_level;
	
	my @get=@_;
	#$get[0] = level
	#$get[1] = message
	#$get[2] = mode || ref
	#	0=norm	level	not
	#	1=error!	level	mustlog
	#	2=norm	level	mustlog
	#	3=norm	not	mustlog
	#	4=error	not	mustlog
	#$get[3] = engine, or logname
	#$get[4] = 0-local 1-global 2-master
	
	if (ref($get[2]) eq "HASH")
	{
#		print "hash\n";
		my $hash=$get[2];
		undef $get[2];
		$get[2] = $hash->{'severity'} || undef;
		$get[3] = $hash->{'facility'} || undef;
		$get[4] = do {
			if ($hash->{'level'} eq "global")
			{
				1;
			}
			elsif ($hash->{'level'} eq "master")
			{
				2;
			}
		} || undef;
		$get[5] = $hash->{'data'};
	}
	
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
#	$get[1]=~s|\r|\\r|g;
#	$get[1]=~s|\t|\\t|g;
#	$get[1]=~s|\n|\\n|g;
	
	my $tt=time();
	
	if ($tt > $log_time)
	{
#		print "aaaaaaaaaaa\n";
		$log_time=$tt;
		%log_date=ctodatetime($log_time,format=>1);
		foreach (keys %log_file)
		{
#			print "close $_\n";
			close ($HND{$log_file{$_}})
				if $HND{$log_file{$_}};
			delete $HND{$log_file{$_}};
			delete $log_file{$_};
		}
	}
	
	my $msec=ceil((Time::HiRes::gettimeofday)[1]/100);
		$msec=9999 if $msec==10000;
	
	my $msg;
		$msg.="[".sprintf ('%06d', $$) unless $main::stdout;
		$msg.=";$main::request_code" if ($TOM::Engine eq "pub" && !$main::stdout);
		$msg.="]" unless $main::stdout;
		$msg.="["
			.$log_date{'hour'}.":".$log_date{'min'}.":".$log_date{'sec'}.".".sprintf("%04d",$msec)."] "
			.(" " x $get[0]).$log_sym[$get[2]];
		my $msg_tab=length($msg);
		$msg.=$get[1];
	
	if (length($msg)>8048)
	{
		$msg=substr($msg,1,8048);
		$msg.="...";
	}
	
	$tom::last_log_engine ||= $TOM::engine;
	
	if (
			($main::stdout && $main::debug) || # && $get[3] eq $TOM::engine) ||
			($main::stdout && $get[3] eq "stdout")
		)
	{
		
		if ($get[3] ne $TOM::engine && $get[3] ne "stdout")
		{
			if ($tom::last_log_engine ne $get[3])
			{
				print color 'reset cyan';print $get[3].".log\n";print color 'reset';
				$tom::last_log_engine = $get[3];
			}
		}
		elsif ($tom::last_log_engine ne $get[3])
		{
			print color 'reset cyan';print $get[3].".log\n";print color 'reset';
			$tom::last_log_engine = $get[3];
		}
		
		# only to stdout
#		$msg=$log_sym[$get[2]].' '.$get[1] unless $main::debug;
#		$msg=$log_sym[$get[2]].$get[1] unless $main::debug;
		$msg=$get[1] unless $main::debug;
		print color 'green';
		print color 'bold' if $get[1]=~/^</;
		print color 'red' if $log_sym[$get[2]] eq '-';
#		$msg=~s|\\n|\n|g;
#		$msg=~s|\\t|\t|g;
		print $msg.do{"\n".(" " x $msg_tab).to_json($get[5]) if ref($get[5]) eq "HASH"}."\n";
		print color 'reset';
		
#		if ($get[3] ne $TOM::engine && $get[3] ne "stdout")
#		{
#			print color 'reset cyan';print $TOM::engine."\n";print color 'reset';
#		}
		
		return 1 if $get[3] eq "stdout";
	}
	elsif ($main::stdout && $log_sym[$get[2]] eq '-' && $get[3] eq $TOM::engine)
	{
		my ($package, $filename, $line) = caller;
		# error to stderr
		print STDERR color 'red';
		print STDERR $get[1]." at ".$filename." line ". $line ."\n";
		print STDERR color 'reset';
	}
	
	if (
			($TOM::DEBUG_log_file>=$get[0])||
			($get[2])||
			($main::debug)
		) # logujem v pripade ze som v ramci levelu alebo ide o ERROR
	{
		return 1 if $get[3] eq "stdout";
		
		if ($fluentd_socket)
		{
			local $@;
			local %log_date=ctogmdatetime($log_time,format=>1); # we are logging in GMT zone
			my $msg=$get[1];
				$msg =~ s/([^\x00-\xFF])/'\x'.ord($1)/ge;
			$fluentd_socket->post($get[3], {
				'@timestamp' =>
					$log_date{'year'}.'-'.$log_date{'mom'}.'-'.$log_date{'mday'}
					.'T'.$log_date{'hour'}.":".$log_date{'min'}.":".$log_date{'sec'}.".".sprintf("%03d",$msec/10).'Z',
				'o' => ++$main::log_o,
				'p' => $$,
				'h' => $TOM::hostname.'.'.($TOM::domain || 'undef'),
				'hd' => $TOM::domain,
				'l' => $get[0],
				'd' => do {
					if ($get[4]==1){undef;}
					elsif ($tom::Pm && $get[4]==2){$tom::H_orig || $tom::Hm;}
					else {$tom::H_orig;}
				},
				'dm' => do {if ($get[4]==1){undef;}else {$tom::Hm}},
				'c' => do {if ($main::request_code){$main::request_code;}else{undef;}},
				'e' => $TOM::engine,
				'f' => do {if ($get[2] == 1 || $get[2] == 4){'1';}else{undef;}},
#				't' => $get[3],
				"m" => $msg,
				'data' => $get[5]
			});
			return 1;# unless $tom::devel;
		}
		
		$get[0]=0 unless $get[0];
		
		my $file_spec=$get[3].':'.$get[4].":".$tom::H.":".$log_date{'mday'};
		my $filename_full=$log_file{$file_spec};
		if (!$log_file{$file_spec})
		{
			if ($TOM::path_log)
			{
				$filename_full=$TOM::path_log;
				if ($get[4]==1) {} # global
				elsif ($tom::Pm && $get[4]==2) {$filename_full.='/'.($tom::H_orig || $tom::Hm)} # master
				elsif ($tom::H) {$filename_full.='/'.($tom::H_orig || $tom::H)} # local
				$filename_full.='/'; # global
			}
			else
			{
				$filename_full=$TOM::P."/_logs/";
				$filename_full=$tom::P."/_logs/" if $tom::P;
				$filename_full=$tom::Pm."/_logs/" if ($tom::Pm && $get[4]==2);
				$filename_full=$TOM::P."/_logs/" if $get[4]==1;
			}
			
			$filename_full.="[".$TOM::hostname."]" if $TOM::serverfarm;
			$filename_full.="$log_date{year}-$log_date{mom}-$log_date{mday}";
		
			$filename_full=$filename_full.".".$get[3].".log";
			
			$filename_full=~/^(.*)\//;my $file_dir=$1;
			$log_file{$file_spec}=$filename_full;
#			print "$file_spec $file_dir file=$filename_full\n";
			
			if (! -e $file_dir){mkdir $file_dir;chmod (0777,$file_dir)} # check directory
			my $logfile_new;
			$logfile_new=1 unless -e $filename_full;
			# open this handler at first
			open ($HND{$filename_full},">>".$filename_full)
#			sysopen($HND{$filename_full},$filename_full,O_APPEND)
				|| print STDERR "Cyclone3 system can't write into logfile $filename_full $!\n";
			chmod (0666 , $filename_full) if $logfile_new;
		}
		
		$msg.="\n".(" " x $msg_tab).to_json($get[5]) if ref($get[5]) eq "HASH";
		syswrite($HND{$filename_full}, $msg."\n", length($msg."\n"));
		
	}
	
	return 1;
};

#sub _log {_log_lite(@_);}
sub _applog {_log(@_);}
sub _log_stdout
{
	if (!$_[2])
	{
		return undef unless $main::stdout;
		$_[2]="stdout";
		return _log(@_);
	}
	if ($main::stdout && !$main::debug)
	{
		_log($_[0],$_[1],'stdout');
	}
#	$_[2]="stdout";
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
	_log(@_);
#	my @get=@_;
#	foreach my $msg(split('\n',$get[0]))
#	{
#		my @get0=@get;
#		$get0[0]=$msg;
#		_log(@get0);
#	}
	return 1;
}

sub _event
{
	local $@;
	if (
		!$TOM::event_socket && # send events to socket
		(!$TOM::event_redis && !$Ext::Redis::service) && # send events to redis
		(!$TOM::event_elastic && !$Ext::Elastic::service) && # send events to elastic
		!$TOM::event_log # send events to "file log"/"fluentd log"
	)
	{
		return undef;
	}
	
	return undef if
	(
		(!$_[0] || !$_[1])
	);
	
	return undef if $TOM::event_severity_disable{$_[0]};
	return undef if $TOM::event_facility_disable{$_[1]};
	
	if (!$event_socket && $TOM::event_socket)
	{
		my @peer=split(':',$TOM::event_socket);
		$event_socket = IO::Socket::INET->new(
			'PeerAddr' => $peer[0],
			'PeerPort' => $peer[1],
			'Proto'    => $peer[2] || "tcp",
			'Type'     => SOCK_STREAM)
		or do {undef $TOM::event_socket;return;};
	}
	
	my $msec=int((Time::HiRes::gettimeofday)[1]/1000);
	tie my %hash, 'Tie::IxHash', (
		'timestamp' => time().'.'.$msec,
		'severity' => $_[0],
		'hostname' => $TOM::hostname,
		'PID' => $$,
		'facility' => $_[1],
		'engine' => $TOM::engine,
		%{$_[2]},
		do{('domain',$tom::H) if $tom::H},
		do{('request',$main::request_code) if $main::request_code},
	);
	
	if ($main::USRM{'ID_user'})
	{
		$hash{'user'}={
			'ID' => $main::USRM{'ID_user'} || $main::USRM{'IDhash'},
			'session' => $main::USRM{'ID_session'},
			'email' => $main::USRM{'email'},
			'logged' => $main::USRM{'logged'},
			'c3bid' => $main::COOKIES_all{'c3bid'}, # browser id
			'c3sid' => $main::COOKIES_all{'c3sid'}, # browser session id
		};
	}
	
	if ($event_socket && $TOM::event_socket)
	{
		print $event_socket $json->encode(\%hash)."\n";
	}
	
	# write to RabbitMQ to notice channel?
	
	# write to Elastic
	if ($TOM::event_elastic && $Ext::Elastic::service)
	{
#		print "event\n";
#		main::_log("event $hash{'serverity'} $hash{'facility'}",3,"event",1);
		my %log_date=ctodatetime(int($hash{'timestamp'}),format=>1);
#		my $service=$Ext::Elastic::service_async || $Ext::Elastic::service; # async when async library available
		if ($Ext::Elastic::service_async)
		{
			$Ext::Elastic::service_async->index(
				'index' => '.cyclone3.'.$log_date{'year'}.$log_date{'mon'},
				'type' => 'event',
				'body' => {
					'datetime' => $log_date{'year'}.'-'.$log_date{'mon'}.'-'.$log_date{'mday'}.' '.$log_date{'hour'}.':'.$log_date{'min'}.':'.$log_date{'sec'}.'.'.$msec,
					%hash
				},sub{}
			);
		}
		else
		{
#			print "sync write\n";
			$Ext::Elastic::service->index(
				'index' => '.cyclone3.'.$log_date{'year'}.$log_date{'mon'},
				'type' => 'event',
				'body' => {
					'datetime' => $log_date{'year'}.'-'.$log_date{'mon'}.'-'.$log_date{'mday'}.' '.$log_date{'hour'}.':'.$log_date{'min'}.':'.$log_date{'sec'}.'.'.$msec,
					%hash
				}
			);
		}
	}
	
	if ($TOM::event_log)
	{
		my $msg=$hash{'facility'};
		my $log_type='event.'.$hash{'severity'};
		delete $hash{'timestamp'};
		delete $hash{'PID'};
		delete $hash{'facility'};
		delete $hash{'hostname'};
		delete $hash{'engine'};
		delete $hash{'domain'};
		delete $hash{'request'};
		delete $hash{'severity'};
		$hash{'ef_s'}=$msg;
		# can't override datetime?
		if ($tom::test)
		{
			use Data::Dumper;
			print Dumper(\%hash);
		}
		main::_log($msg, {
			'facility' => $log_type,
			'severity' => 3,
			'data' => {
				%hash
			}
		});
	}
	
}

_event('debug','process.start',{
	'cmd' => $0.' '.(join " ",@ARGV),
	'UID' => $<,
	'perl' => "$^V",
	'osname' => $^O
});






package TOM;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

our $TTL=5;
our %mfiles;
our %files_modified;

BEGIN {eval{
	main::_log("init '$0' ".join(",",@ARGV));
	main::_log("<={LIB} ".__PACKAGE__."::Lite (_log + conf)");main::_log("TOM::P=$TOM::P TOM::DP=$TOM::DP");
};}

sub file_mtime
{
	my $file=shift;
	my $time=time();
	if ($mfiles{$file}{'ctime'} <= $time-$TTL)
	{
		$mfiles{$file}{'ctime'} = $time;
		if (-e $file)
		{
			$mfiles{$file}{'mtime'}=(stat($file))[9];
			return $mfiles{$file}{'mtime'};
		}
		else
		{
			return undef; # not exists
		}
	}
	return $mfiles{$file}{'mtime'};
}

sub file_modified
{
	my $file=shift;
	my $class=shift || 'default';
	my $mtime=file_mtime($file);
	$files_modified{$class}{$file}||=$mtime;
	return $files_modified{$class}{$file}=$mtime
		if ($files_modified{$class}{$file} < $mtime);
	return undef;
}

sub files_modified
{
	foreach (@{$_[0]})
	{
		file_modified($_) && return $_;
	}
}

package TOM::Net::email;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
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
use if $] < 5.018, 'encoding','utf8';
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
use if $] < 5.018, 'encoding','utf8';
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
			main::_log("</$self->{name}>".do{
				" #".$self->{'attrs'} if $self->{'attrs'};
			},{
				'data' => {
					'duration_f' => $self->{'time'}{'duration'},
					'duration_user_f' => $self->{'time'}{'user'}{'duration'}
				}
			});
		}
		else
		{
			main::_log("</$self->{name}>".do{
				" #".$self->{'attrs'} if $self->{'attrs'};
			});
		}
	}
}


sub clear_namespaces
{
	%namespace=();
}



package TOM::hash_config;


sub TIEHASH
{
	my $class = shift;
	my $data = shift || {};
	return bless $data, $class;
}

sub DESTROY
{
	my $self = shift;
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
	$self->{'.modified'}=1;
	delete $self->{$key};
	return 1;
}

sub STORE
{
	my ($self,$key,$value)=@_;
	$self->{'.modified'}=1;
#	print "store key $key value $value\n";
	$self->{$key}=$value;
}

sub CLEAR
{
	my $self=shift;
	%$self=();
	$self->{'.modified'}=1;
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

my %data=%TOM::DEBUG_log_type;tie %TOM::DEBUG_log_type, 'TOM::hash_config', \%data;

1;
