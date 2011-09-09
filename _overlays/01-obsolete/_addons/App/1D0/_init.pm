#!/bin/perl
package App::1D0;
#use App::1B0::SQL; # pytam si SQL a SQL si pyta vsetko pod nim
use strict;
use Time::Local;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}






sub getnexttime
{

#	my $text="min:*/25 hour:*/2 wday:* mday:*";

	my $input=shift;
	my %env0;
	(	$env0{sec},
		$env0{min},
		$env0{hour},
		$env0{mday},
		$env0{mom},
		$env0{year},
		$env0{wday},
		$env0{yday},
		$env0{isdst}) = localtime($main::time_current);
#	$env0{min}=58;
	#$env0{min}++;
#	$env0{min}=0 if $env0{min}==60;
	#print "teraz je: min:$env0{min} hour:$env0{hour} wday:$env0{wday} mday:$env0{mday} mom:$env0{mom} year:$env0{year}\n";
	#print "vyzadujem: $text\n";
	
	my %env1;
	foreach my $a(split(' ',$input))
	{
		my @b=split(':',$a);
		$env1{$b[0]}=$b[1];
	}
	
	$env1{min}="*" unless exists $env1{min};
	$env1{hour}="*" unless exists $env1{hour};
	$env1{wday}="*" unless exists $env1{wday};
	$env1{mday}="*" unless exists $env1{mday};
	
	
	my %env2=%env0;
	
	
	if ($env1{min} ne "*")
	{
		if ($env1{min}=~s/^\*\///)
		{
			$env1{min}=59 if $env1{min}>59;
#			print " -delitelne $env1{min}\n"; # treba najst dalsie cislo delitelne cislom $env2{mday}
			my $i=$env2{min};
			#$i=1 if $i>59;
			while (1)
			{
				$i++;
				if ($i>60){$env2{hour}++;$i=1;}
#				print "--$i $env2{hour}\n";
				last unless $i % $env1{min};
			}
			$env2{min}=$i;
			$env2{min}=0 if $env2{min}==60;
		}
		elsif ($env1{min}=~/(\d+)-(\d+)/)
		{
#			print " -rozsah $env1{min}\n";
			my $a=$1;
			my $b=$2;
			if (($env2{min}>=$a) && ($env2{min}<=$b))
			{
			}
			else
			{
				$env2{min}=$a;
				$env2{hour}++;
			}
		}
		else
		{
			$env2{min}=$env1{min};
			if ($env2{min}<$env0{min}){$env2{hour}++;}
		}
	}
	else
	{
		#$env2{min}=$env0{min};
	}

	if ($env2{hour}>23){$env2{mday}++;$env2{hour}=0;}
	my $starttime;eval {$starttime=Time::Local::timelocal(0,0,12,$env2{mday},$env2{mom},$env2{year},undef,undef,undef)};
	if (!$starttime){$env2{mom}++;$env2{mday}=1;}
	if ($env2{mom}>11){$env2{year}++;$env2{mom}=0;}

main::_log("priebezne: min:$env2{min} hour:$env2{hour} wday:$env2{wday} mday:$env2{mday} mom:$env2{mom} year:$env2{year}");

	if ($env1{hour} ne "*")
	{
		if ($env1{hour}=~s/^\*\///)
		{
			#print "menim hour\n";
			$env1{hour}=23 if $env1{hour}>23;
#			print " -delitelne $env1{hour}\n"; # treba najst dalsie cislo delitelne cislom $env2{mday}
			my $i=$env2{hour};#$i=1 if !$i;
=head1
			while ($i % $env1{hour})
			{
				$i++;
				if ($i>23)
				{
					$i=1;
					$env2{mday}++;
				}
			}
			$env2{hour}=$i;
=cut
			while (1)
			{
				if ($i>24){$env2{day}++;$i=1;}
				#print "--$i $env2{day}\n";
				last unless $i % $env1{hour};
				$i++;
			}
			$env2{hour}=$i;
			#$env2{hour}=0 if $env2{hour}==24;
			
		}
		elsif ($env1{hour}=~/(\d+)-(\d+)/)
		{
#			print " -rozsah $env1{hour}\n";
			my $a=$1;
			my $b=$2;
			if (($env2{hour}>=$a) && ($env2{hour}<=$b))
			{
			}
			else
			{
				$env2{hour}=$a;
				$env2{mday}++;
			}
		}
		else
		{
			$env2{hour}=$env1{hour};
			if ($env2{hour}<$env0{hour}){$env2{mday}++;}
		}
	}
	else
	{
		#$env2{hour}=$env0{hour};
	}
	
	if ($env2{hour}>23){$env2{mday}++;$env2{hour}=0;}
	
	my $starttime;eval {$starttime=Time::Local::timelocal(0,0,12,$env2{mday},$env2{mom},$env2{year},undef,undef,undef)};
	if (!$starttime){$env2{mom}++;$env2{mday}=1;}
	if ($env2{mom}>11){$env2{year}++;$env2{mom}=0;}

#print "min old:$env0{min} new:$env2{min}\n";
#print "priebezne: min:$env2{min} hour:$env2{hour} wday:$env2{wday} mday:$env2{mday} mom:$env2{mom} year:$env2{year}\n";


#print "-mday\n";
	if ($env1{mday} ne "*")
	{
		if ($env1{mday}=~s/^\*\///)
		{
			$env1{hour}=31 if $env1{hour}>31;
#			print " -delitelne $env1{mday}\n"; # treba najst dalsie cislo delitelne cislom $env2{mday}
			my $i=$env2{mday};#$i=1 if !$i;
=head1
			while (1)
			{
			
			
				if ($i>24){$env2{day}++;$i=1;}
				
				
				print "--$i $env2{day}\n";
				
				
				last unless $i % $env1{hour};
				
				
				$i++;
			}
			$env2{hour}=$i;
			$env2{hour}=0 if $env2{hour}==24;
=cut	
#=head1
			while ($i % $env1{mday})
			{
				$i++;
				my $starttime;eval {$starttime=Time::Local::timelocal(0,0,12,$env2{mday},$env2{mom},$env2{year},undef,undef,undef)};
				if (!$starttime){$env2{mom}++;$env2{mday}=1;}
				if ($env2{mom}>11){$env2{year}++;$env2{mom}=0;}
			}
			$env2{mday}=$i;
#=cut	
			
		}
		elsif ($env1{mday}=~/(\d+)-(\d+)/)
		{
#			print " -rozsah $env1{mday}\n";
			my $a=$1;
			my $b=$2;
			if (($env2{mday}>=$a) && ($env2{mday}<=$b))
			{
			}
			else
			{
				$env2{mday}=$a;
				$env2{mom}++;
			}
		}
		else
		{
			$env2{mday}=$env1{mday};
			if ($env2{mday}<$env0{mday}){$env2{mom}++;}
		}
	}
	else
	{
		#$env2{mday}=$env0{mday};
	}

	if ($env2{mom}>11){$env2{year}++;$env2{mom}=0;}


	#print "\n\n";
	main::_log("povodne: min:$env0{min} hour:$env0{hour} wday:$env0{wday} mday:$env0{mday} mom:$env0{mom} year:$env0{year}\n");
	main::_log("dostanem: min:$env2{min} hour:$env2{hour} wday:$env2{wday} mday:$env2{mday} mom:$env2{mom} year:$env2{year}\n");

	my $starttime;
	eval 
	{
		$starttime=Time::Local::timelocal(0,$env2{min},$env2{hour},$env2{mday},$env2{mom},$env2{year},undef,undef,undef)
	};
	return $starttime if $starttime;
	return undef;
}






















sub get_import
{
	my $name=shift;
	my $db0=$main::DB{main}->Query("
	SELECT 
		imports.ID AS ID,
		manager.ID AS IDimport,
		imports.import AS import
	FROM TOM.a1D0_imports AS imports
	LEFT JOIN TOM.a1D0_manager AS manager
	ON	(
			(
				manager.domain=''
				OR
				(
					manager.domain='$tom::Hm'
					AND (manager.domain_sub='$tom::H' OR manager.domain_sub='')
				)
			)
			AND
			manager.name='$name'
		)
	WHERE manager.ID=imports.IDimport
	ORDER BY imports.ID DESC
	LIMIT 1");
	if (my %db0_line=$db0->fetchhash)
	{
#		print "-$db0_line{ID} $db0_line{IDimport} $db0_line{import}\n";
		$main::DB{main}->Query("
			UPDATE TOM.a1D0_imports
			SET time_use='$main::time_current', uses=uses+1
			WHERE ID='$db0_line{ID}'
			LIMIT 1
		");
		return $db0_line{import};
	}
	return undef;
}






1;


=head1
App::1B0::IsBanned(
	IP		=>	"192.168.0.1",
	a300		=>	"NyJsqrmgh",
	-type		=>	"app",
	-what	=>	"820",
);
=cut