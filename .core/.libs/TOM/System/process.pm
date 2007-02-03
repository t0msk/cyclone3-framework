#!/bin/perl
package TOM::System::process;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

=head1 NAME

TOM::System::process

=cut

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use Proc::ProcessTable;
use IPC::Open3;

=head1 FUNCTIONS

=head2 @processes=find(regex=>['process','param1','param2'])

Find processes by regex

=cut

sub find
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::find()");
	my @processes;
	
	my $pt = new Proc::ProcessTable;
	foreach my $p (@{$pt->table})
	{
		if ($env{'regex'})
		{
			my $true=1;
			foreach my $regex(@{$env{'regex'}})
			{
				$true=$p->cmndline=~/$regex/;
				last unless $true;
			}
			if ($true)
			{
				push @processes,$p;
				main::_log("process pid='".$p->pid()."'");
			}
		}
	}
	
	$t->close();
	return @processes;
}

=head2 $pid=start(${cmd})

Starts defined process and returns it's pid

=cut

sub start
{
	my $cmd=shift;
	my $pid;
	my $t=track TOM::Debug(__PACKAGE__."::start()");
	
	main::_log("starting cmd='$cmd'");
	
	my($wtr, $rdr, $err);
	$pid = open3($wtr, $rdr, $err, $cmd);
	
	main::_log("started pid='$pid'");
	
	$t->close();
}

1;