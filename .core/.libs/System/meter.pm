#!/bin/perl
package System::meter;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

#die "could not find 'vmstat' in system" unless `vmstat`;
#our $vmstat_VERSION=`vmstat -V`;
#$vmstat_VERSION=~s|^.*?(\d)|\1|;$vmstat_VERSION=~s|[\n\r]||g;


#print "mam $vmstat_VERSION\n";


sub getVmstat
{
	my %env;
	#$env{swpd}=`/sbin/sysctl -n `;chomp($env{swpd});
	return %env;
 #my $out=`vmstat`;
 #print "$out\n";
 
# $vmstat_VERSION=~/^$/
 
 
 
=head1
 $vmstat_VERSION=~/^2\.0\./ && do
 {
  $out=~s|\n$||;
  $out=~s|.*\n||s;
  ($env{r},
   $env{b},
   $env{w},
   $env{swpd},
   $env{free},
   $env{buff},
   $env{cache},
   $env{si},
   $env{so},
   $env{bi},
   $env{bo},
   $env{in},
   $env{cs},
   $env{us},
   $env{sy},
   $env{id})
  =
  ($out=~/^\W+(\d+)
		\W+(\d+)
		\W+(\d+)
		\W+(\d+)
		\W+(\d+)
		\W+(\d+)
		\W+(\d+)
		\W+(\d+)
		\W+(\d+)
		\W+(\d+)
		\W+(\d+)
		\W+(\d+)
		\W+(\d+)
		\W+(\d+)
		\W+(\d+)
		\W+(\d+)/x);
  return %env;
 };
 
 $vmstat_VERSION=~/^3\.1\./ && do
 {
  $out=~s|\n$||;
  $out=~s|.*\n||s;
  ($env{r},
   $env{b},
   $env{swpd},
   $env{free},
   $env{buff},
   $env{cache},
   $env{si},
   $env{so},
   $env{bi},
   $env{bo},
   $env{in},
   $env{cs},
   $env{us},
   $env{sy},
   $env{id},
   $env{wa})
  =
  ($out=~/^\W+(\d+)
		\W+(\d+)
		\W+(\d+)
		\W+(\d+)
		\W+(\d+)
		\W+(\d+)
		\W+(\d+)
		\W+(\d+)
		\W+(\d+)
		\W+(\d+)
		\W+(\d+)
		\W+(\d+)
		\W+(\d+)
		\W+(\d+)
		\W+(\d+)
		\W+(\d+)/x);
  return %env;
 };

 die "not supported version ($vmstat_VERSION) of vmstat"; 
=cut
}







#our $proc;
#$proc=1 if -e '/proc/loadavg';

sub getLoad
{

=head1
 my @env;
 $proc && do
 {
  @env=(`cat /proc/loadavg`=~/^(.*?) (.*?) (.*?) /);
  return @env;
 }; 
 @env=(`uptime`=~/.* (.*?), (.*?), (.*?)$/);
 return @env;
=cut
	my @env;
#	@env=(`/sbin/sysctl -n vm.loadavg`=~/(\d+\.\d+) (\d+\.\d+) (\d+\.\d+)/);
	@env=(`/usr/bin/uptime`=~/(\d+\.\d+), (\d+\.\d+), (\d+\.\d+)/);
}



1;