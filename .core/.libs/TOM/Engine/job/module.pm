package job;
sub jobify {return TOM::Engine::job::module::jobify(@_)}
sub call {my @r=@_;shift @r;$r[0]={'name'=>$r[0]} if scalar $r[0];return new TOM::Engine::job::module(@r)->execute()}
sub new {my @r=@_;shift @r;$r[0]={'name'=>$r[0]} if scalar $r[0];return new TOM::Engine::job::module(@r)}

package TOM::Engine::job::module;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use TOM;
use Cwd 'abs_path';
use Ext::Redis::_init;

sub jobify
{
	my $env;if ($_[3]){$env=$_[3];unshift @_;}
	return 1 if TOM::Engine::jobify(\@_,$env);my @r=@_;
	$r[1]={'name'=>$r[1]} if scalar $r[1];
	return new(@r)->execute();
}

sub new
{
	my $class=shift;
	my $conf=shift;
	my $env=shift;
	
	if ($conf->{'name'})
	{
		# try to find file by name
		
		unless ($conf->{'name'}=~s/^([ae])(.*?)\-//)
		{
			main::_log("unknown type of addon",1);
			return undef;
		}
		
		my $addon_type=$1;
		my $addon_name=$2;
		my $addon_path=$addon_type;
			if ($addon_path=~s/^a/App\/$addon_name/)
			{
			}
			elsif ($addon_path=~s/^e/Ext\/$addon_name/)
			{
			}
		
		my $file=$addon_type.$addon_name.'-'.$conf->{'name'}.'.job';
		
		my @inc;
		
		if ($tom::P ne $TOM::P)
		{
			push @inc,$tom::P.'/_addons/'.$addon_path.'/_mdl';
			push @inc,$tom::P.'/_jobs';
		}
		
		if ($tom::Pm && ($tom::P ne $tom::Pm))
		{
			push @inc,$tom::Pm.'/_addons/'.$addon_path.'/_mdl';
			push @inc,$tom::Pm.'/_jobs';
		}
		
		foreach my $dir_item (@TOM::Overlays::item)
		{
			if ($dir_item=~/^\//)
			{
				push @inc,$dir_item.'/_addons/'.$addon_path.'/_mdl';
				push @inc,$dir_item.'/_jobs';
			}
			else
			{
				push @inc,$TOM::P.'/_overlays/'.$dir_item.'/_addons/'.$addon_path.'/_mdl';
				push @inc,$TOM::P.'/_overlays/'.$dir_item.'/_mdl';
			}
		}

		push @inc,$TOM::P.'/_addons/'.$addon_path.'/_mdl';
		push @inc,$TOM::P.'/_mdl';
		
		foreach (@inc)
		{
			if (-e $_.'/'.$file)
			{
				$conf->{'file'}=$_.'/'.$file;
				last;
			}
		}
		
		if (!$conf->{'file'})
		{
			main::_log("can't find job file ".$file." in @inc",1);
		}
		
		delete $conf->{'name'};
	}
	
	if ($conf->{'file'})
	{
		my $abs_path=$conf->{'file'}=abs_path($conf->{'file'});
		
		if (!-e $conf->{'file'})
		{
			main::_log("file '$conf->{'file'}' not found",1);
			return undef;
		}
		
		my $m_time=(stat($conf->{'file'}))[9];
		
		my $shortify=$conf->{'file'};
			$shortify=~s|^$TOM::P/||;
			$shortify=~s|\.job$||;
			$shortify=~s/(_mdl|_addons|App|Ext)\///g;
			$shortify=~s|/|::|g;
			$shortify=~s|[\.\-]|_|g;
			$shortify=~s|[^a-zA-Z0-9_:]||g;
#		main::_log("shortify=".$shortify);
		
		my $extra_name;#=TOM::Digest::hash($conf->{'file'});
			$extra_name=$shortify;
		my $job_class='Cyclone3::job::'.$extra_name;
		
		if (!$job_class->VERSION() || ($job_class->VERSION() < $m_time))
		{
			# reload this class source
			my $job_data;
			do {
				open (JOBHND,'<'.$conf->{'file'}) || do {
					main::_log($!,1);
					return undef;
				};
				local $/;
				$job_data=<JOBHND>;
				close JOBHND;
			};
			
			$job_data=~s|^(#!/usr/bin/env.*?)(package Cyclone3::job);|$1package Cyclone3::job::$extra_name;\nour \$VERSION=$m_time;|ms || do {
				main::_log("can't load job module file",1);
				return undef;
			};
			
			eval $job_data;
			if ($@)
			{
				main::_log($@,1);
				return undef;
			}
		}
	
		delete $conf->{'name'};
		delete $conf->{'file'};
		
		my $job=new $job_class($conf,$env);
			$job->{'file'}=$abs_path;
		return $job;
	}
	else
	{
#		main::_log("can't find job ".($conf->{'file'} || $conf->{'name'}),1);
	}
	
	my $obj=bless {}, $class;
	
	$obj->{'conf'}=$conf;
	$obj->{'env'}=$env;
	
	return $obj;
#	return $obj->prepare;
}

sub env {return shift->{'env'}}

#sub job
#{
#	my $class=shift;
#	my %env=@_;
#	
#	my $obj=bless {}, $class;
#	
#	main::_log("calling create via job and execute"); # we are creating new 
#	
#	return $obj->execute;
#}


sub execute
{
	my $self=shift;
	
	main::_log("executing dummy execute",1);
	
	return $self;
}


sub reschedule
{
	my $self=shift;
	my $conf=shift;
	
	if ($self->{'conf'}->{'schedule-entry'}
		&& $self->{'conf'}->{'schedule-entry'}->{'filename'}
		&& $self->{'conf'}->{'schedule-entry'}->{'id'}
	)
	{
	}
	else
	{
		return 1;
	}
	
	my $now='NOW()';
	
	if ($conf->{'add'} && !ref($conf->{'add'}))
	{
		$now="DATE_ADD(NOW(),INTERVAL ".$conf->{'add'}." SECOND)";
	}
	
	main::_log("re-schedule job to '$now'");
	
	my %sth0=TOM::Database::SQL::execute(qq{
		UPDATE
			`TOM`.`a100_job_cron_schedule`
		SET
			`datetime_create` = NOW(),
			`datetime_next` = $now
		WHERE
			`filename`=? AND
			`id`=?
		LIMIT 1
	},'db_h'=>'sys','bind'=>[
		$self->{'conf'}->{'schedule-entry'}->{'filename'},
		$self->{'conf'}->{'schedule-entry'}->{'id'}
	],'quiet'=>1);
	
	return 1;
}


sub running
{
	my $self=shift;
	my $conf=shift;
	
	$conf->{'max'}=600 unless $conf->{'max'};
	
#	main::_log("check if already running '".(ref $self)."'");
	
	if ($Redis)
	{
		my $key_entity=(ref $self);
			$key_entity.='::'.$conf->{'unique'}
				if $conf->{'unique'};
			if (!$conf->{'domain'} && !$conf->{'unique'})
			{
				$key_entity.='::'.$tom::H;
			}
		$key_entity=TOM::Digest::hash($key_entity);
		
		$self->{'_running'}=$key_entity;
		
		my $is_running=$Redis->hget('C3|job|running|'.$key_entity,'PID');
		if ($is_running)
		{
#			main::_log("alresy lock of running job");
			my ($run_hostname,$run_PID)=split(':',$is_running);
			if ($run_hostname eq $TOM::hostname)
			{
				if (-e '/proc/'.$run_PID)
				{
					main::_log("this job is already running \@$run_hostname:$run_PID, skip");
					delete $self->{'_running'};
					return 1;
				}
			}
			else
			{
				main::_log("this job is already running \@$run_hostname:$run_PID, skip");
				delete $self->{'_running'};
				return 1;
			}
		}
		
		$Redis->hset('C3|job|running|'.$key_entity,'PID',$TOM::hostname.':'.$$,sub {});
		$Redis->expire('C3|job|running|'.$key_entity,($conf->{'max'}+60),sub {});
	}
	
	return undef;
}

sub DESTROY
{
	my $self=shift;
	
	if ($self->{'_running'} && $Redis)
	{
		$Redis->del('C3|job|running|'.$self->{'_running'},sub {});
#		main::_log("DESTROY");
	}
	
}

package TOM::Engine;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

use Coro;
use JSON;
use Ext::RabbitMQ::_init;
use Ext::Redis::_init;
use Encode;
our $json = JSON::XS->new->ascii();
our %queues;

sub jobify # prepare function call to background
{
	my $env=$_[1];
	
	if ($main::nojobify)
	{
		undef $main::nojobify;
		main::_log("can't jobify (main::nojobify), go to exec");
		return undef;
	}
	if (!$RabbitMQ)
	{
		main::_log("can't jobify (!RabbitMQ), go to exec");
		return undef;
	}
	if ($TOM::P ne $TOM::DP && $tom::devel) # don't allow sending jobs to backend in multidevelopment environment
	{
		main::_log("can't jobify (multidevel environment), go to exec");
		return undef;
	}
	
	if ($env->{'class'})
	{
		my $queue=$env->{'routing_key'} || $tom::H_orig || '_global';
			$queue.="::".$env->{'class'};
			
		$env->{'routing_key'}=$env->{'routing_key'} || $tom::H_orig || 'job';
		$env->{'routing_key'}.="::".$env->{'class'};
		
		my $queue_found=$queues{$queue};
		if ($Redis && !$queue_found)
		{
			$queues{$queue}=$queue_found=$Redis->hget('C3|Rabbit|queue|'.'cyclone3.job.'.$queue,'time');
		}
		if (!$queue_found)
		{async {main::_log("[RabbitMQ] declare_queue '".'cyclone3.job.'.$queue."'");eval{
			my $exists=$RabbitMQ->_channel->declare_queue(
				'exchange' => encode('UTF-8', 'cyclone3.job'),
				'queue' => encode('UTF-8', 'cyclone3.job.'.$queue),
#				'passive' => 1,
				'durable' => 1
			);
			main::_log("[RabbitMQ] bind_queue '".$env->{'routing_key'}."'");
			$RabbitMQ->_channel->bind_queue(
				'exchange' => encode('UTF-8', 'cyclone3.job'),
				'routing_key' => encode('UTF-8', $env->{'routing_key'}),
				'queue' => encode('UTF-8', 'cyclone3.job.'.$queue)
			);
			$Redis->hset('C3|Rabbit|queue|'.'cyclone3.job.'.$queue,'time',time());
			$Redis->expire('C3|Rabbit|queue|'.'cyclone3.job.'.$queue,3600);
		}};cede;}
	}
	else
	{
		$env->{'routing_key'}=$env->{'routing_key'} || $tom::H_orig || 'job';
	}
	
	my $id=TOM::Utils::vars::genhash(8);
	my (undef,undef,undef,$function)=caller 1;
	
	my %headers;
		$headers{'deduplication'}='true'
			if $env->{'deduplication'};
	
	if ($function eq "TOM::Engine::job::module::jobify" && $_[0][0] eq "job") # shortcut jobify job
	{
		main::_log("{jobify} job '".$_[0][1]."' routing_key='".($env->{'routing_key'})."' id='$id' deduplication=".$env->{'deduplication'});
		
		return $RabbitMQ->publish(
			'exchange'=>'cyclone3.job',
			'routing_key' => ($env->{'routing_key'} || $tom::H_orig || 'job'),
			'body' => $json->encode({'job' => {'name' => $_[0][1]},'args' => $_[0][2]}),
			'header' => {
				'headers' => {
					'message_id' => $id,
					'timestamp' => time(),
					%headers
	#				,'deduplication' => $env->{'deduplication'}
				}
			}
		);
	}
	else
	{
		main::_log("{jobify} function '$function' routing_key='".($env->{'routing_key'})."' id='$id' deduplication=".$env->{'deduplication'});
		
		return $RabbitMQ->publish(
			'exchange'=>'cyclone3.job',
			'routing_key' => ($env->{'routing_key'} || $tom::H_orig || 'job'),
	#		'body' => to_json({'function' => $function,'args' => $_[0]}),
			'body' => $json->encode({'function' => $function,'args' => $_[0]}),
			'header' => {
				'headers' => {
					'message_id' => $id,
					'timestamp' => time(),
					%headers
	#				,'deduplication' => $env->{'deduplication'}
				}
			}
		);
	}
	
	return undef;
}

1;
