package TOM::Engine::job::cron;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use TOM;

use Time::ParseDate;

our @WDAYS = qw(
	Sunday
	Monday
	Tuesday
	Wednesday
	Thursday
	Friday
	Saturday
	Sunday
);

our @ALPHACONV = (
	{ },
	{ },
	{ },
	{ qw(jan 1 feb 2 mar 3 apr 4 may 5 jun 6 jul 7 aug 8 sep 9 oct 10 nov 11 dec 12) },
	{ qw(sun 0 mon 1 tue 2 wed 3 thu 4 fri 5 sat 6)},
	{ }
);

our @RANGES = (
	[ 0,59 ],
	[ 0,23 ],
	[ 0,31 ],
	[ 0,12 ],
	[ 0,7  ],
	[ 0,59 ]
);

our @LOWMAP = ( 
	{},
	{},
	{ 0 => 1},
	{ 0 => 1},
	{ 7 => 0},
	{},
);

# based on Schedule::Cron ... roland
sub get_next_execution_time 
{
#	my $self = shift;
	my $cron_entry = shift;
	my $time = shift;
	
	$cron_entry = [ split /\s+/,$cron_entry ] unless ref($cron_entry);
	
	# Expand and check entry:
	# =======================
	if ($#$cron_entry != 4 && $#$cron_entry != 5)
	{
		main::_log("Exactly 5 or 6 columns has to be specified for a crontab entry ! (not ".scalar(@$cron_entry).")",1);
		return undef;
	}
	
	my @expanded;
	my $w;
	
	for my $i (0..$#$cron_entry) 
	{
		my @e = split /,/,$cron_entry->[$i];
		my @res;
		my $t;
		
		while (defined($t = shift @e)) {
			# Subst "*/5" -> "0-59/5"
			$t =~ s|^\*(/.+)$|$RANGES[$i][0]."-".$RANGES[$i][1].$1|e; 
			
			if ($t =~ m|^([^-]+)-([^-/]+)(/(.*))?$|) 
			{
				my ($low,$high,$step) = ($1,$2,$4);
				$step = 1 unless $step;
				if ($low !~ /^(\d+)/) 
				{
					$low = $ALPHACONV[$i]{lc $low};
				}
				if ($high !~ /^(\d+)/) 
				{
					$high = $ALPHACONV[$i]{lc $high};
				}
				if (! defined($low) || !defined($high) ||  $low > $high || $step !~ /^\d+$/) 
				{
					die "Invalid cronentry '",$cron_entry->[$i],"'";
				}
				my $j;
				for ($j = $low; $j <= $high; $j += $step) 
				{
					push @e,$j;
				}
			} 
			else 
			{
				$t = $ALPHACONV[$i]{lc $t} if $t !~ /^(\d+|\*)$/;
				$t = $LOWMAP[$i]{$t} if exists($LOWMAP[$i]{$t});
				
				if (!defined($t) || ($t ne '*' && ($t < $RANGES[$i][0] || $t > $RANGES[$i][1])))
				{
					main::_log("Invalid cronentry '".$cron_entry->[$i]."'",1);
					return undef;
				}
				
				push @res,$t;
			}
		}
		push @expanded, ($#res == 0 && $res[0] eq '*') ? [ "*" ] : [ sort {$a <=> $b} @res];
	}
	
	# Check for strange bug
	_verify_expanded_cron_entry($cron_entry,\@expanded) || return undef;
	
	# Calculating time:
	# =================
	my $now = $time || time;
	
	if ($expanded[2]->[0] ne '*' && $expanded[4]->[0] ne '*') 
	{
		# Special check for which time is lower (Month-day or Week-day spec):
		my @bak = @{$expanded[4]};
		$expanded[4] = [ '*' ];
		my $t1 = _calc_time($now,\@expanded);
		$expanded[4] = \@bak;
		$expanded[2] = [ '*' ];
		my $t2 = _calc_time($now,\@expanded);
#		dbg "MDay : ",scalar(localtime($t1))," -- WDay : ",scalar(localtime($t2)) if $DEBUG;
#		main::_log("conflict possible");
		return $t1 < $t2 ? $t1 : $t2;
	} 
	else 
	{
		# No conflicts possible:
#		main::_log("no conflict possible");
		return _calc_time($now,\@expanded);
	}

}


sub _verify_expanded_cron_entry {
#	my $self = shift;
	my $original = shift;
	my $entry = shift;
	
	unless (ref($entry) eq "ARRAY")
	{
		main::_log("Internal: Not an array ref. Orig: ".Dumper($original). ", expanded: ".Dumper($entry),1);
		return undef;
	}

	for my $i (0 .. $#{$entry})
	{
		unless (ref($entry->[$i]) eq "ARRAY")
		{
			main::_log("Internal: Part $i of entry is not an array ref. Original: ".Dumper($original).", expanded: ".Dumper($entry),1);
			return undef;
		}	
	}
	return 1;
}


sub _calc_time 
{
#	my $self = shift;
	my $now = shift;
	my $expanded = shift;
	
	my $offset = ($expanded->[5] ? 1 : 60);
	my ($now_sec,$now_min,$now_hour,$now_mday,$now_mon,$now_wday,$now_year) = 
	(localtime($now+$offset))[0,1,2,3,4,6,5];
	$now_mon++; 
	$now_year += 1900;
	
	# Notes on variables set:
	# $now_... : the current date, fixed at call time
	# $dest_...: date used for backtracking. At the end, it contains
	#            the desired lowest matching date
	
	my ($dest_mon,$dest_mday,$dest_wday,$dest_hour,$dest_min,$dest_sec,$dest_year) = 
	($now_mon,$now_mday,$now_wday,$now_hour,$now_min,$now_sec,$now_year);
	
	# dbg Dumper($expanded);
	
	# Airbag...
	while ($dest_year <= $now_year + 1) 
	{
#		dbg "Parsing $dest_hour:$dest_min:$dest_sec $dest_year/$dest_mon/$dest_mday" if $DEBUG;
		
		# Check month:
		if ($expanded->[3]->[0] ne '*') 
		{
			unless (defined ($dest_mon = _get_nearest($dest_mon,$expanded->[3]))) 
			{
				$dest_mon = $expanded->[3]->[0];
				$dest_year++;
			} 
		} 

		# Check for day of month:
		if ($expanded->[2]->[0] ne '*') 
		{           
			if ($dest_mon != $now_mon) 
			{      
				$dest_mday = $expanded->[2]->[0];
			} 
			else 
			{
				unless (defined ($dest_mday = _get_nearest($dest_mday,$expanded->[2]))) 
				{
					# Next day matched is within the next month. ==> redo it
					$dest_mday = $expanded->[2]->[0];
					$dest_mon++;
					if ($dest_mon > 12) 
					{
						$dest_mon = 1;
						$dest_year++;
					}
#					dbg "Backtrack mday: $dest_mday/$dest_mon/$dest_year" if $DEBUG;
					next;
				}
			}
		} 
		else 
		{
			$dest_mday = ($dest_mon == $now_mon ? $dest_mday : 1);
		}

		# Check for day of week:
		if ($expanded->[4]->[0] ne '*') 
		{
			$dest_wday = _get_nearest($dest_wday,$expanded->[4]);
			$dest_wday = $expanded->[4]->[0] unless $dest_wday;

			my ($mon,$mday,$year);
			#      dbg "M: $dest_mon MD: $dest_mday WD: $dest_wday Y:$dest_year";
			$dest_mday = 1 if $dest_mon != $now_mon;
			my $t = parsedate(sprintf("%4.4d/%2.2d/%2.2d",$dest_year,$dest_mon,$dest_mday));
			($mon,$mday,$year) =  
			  (localtime(parsedate("$WDAYS[$dest_wday]",PREFER_FUTURE=>1,NOW=>$t-1)))[4,3,5]; 
			$mon++;
			$year += 1900;

#			dbg "Calculated $mday/$mon/$year for weekday ",$WDAYS[$dest_wday] if $DEBUG;
			if ($mon != $dest_mon || $year != $dest_year) {
#				dbg "backtracking" if $DEBUG;
				$dest_mon = $mon;
				$dest_year = $year;
				$dest_mday = 1;
				$dest_wday = (localtime(parsedate(sprintf("%4.4d/%2.2d/%2.2d",
					$dest_year,$dest_mon,$dest_mday))))[6];
				next;
			}

			$dest_mday = $mday;
		} 
		else 
		{
			unless ($dest_mday) 
			{
				$dest_mday = ($dest_mon == $now_mon ? $dest_mday : 1);
			}
		}


		# Check for hour
		if ($expanded->[1]->[0] ne '*') 
		{
			if ($dest_mday != $now_mday || $dest_mon != $now_mon || $dest_year != $now_year) 
			{
				$dest_hour = $expanded->[1]->[0];
			} 
			else 
			{
				#dbg "Checking for next hour $dest_hour";
				unless (defined ($dest_hour = _get_nearest($dest_hour,$expanded->[1]))) 
				{
					# Hour to match is at the next day ==> redo it
					$dest_hour = $expanded->[1]->[0];
					my $t = parsedate(sprintf("%2.2d:%2.2d:%2.2d %4.4d/%2.2d/%2.2d",
						$dest_hour,$dest_min,$dest_sec,$dest_year,$dest_mon,$dest_mday));
					($dest_mday,$dest_mon,$dest_year,$dest_wday) = 
					 (localtime(parsedate("+ 1 day",NOW=>$t)))[3,4,5,6];
					$dest_mon++; 
					$dest_year += 1900;
					next; 
				}
			}
		} 
		else 
		{
			$dest_hour = ($dest_mday == $now_mday ? $dest_hour : 0);
		}
		# Check for minute
		if ($expanded->[0]->[0] ne '*') 
		{
			if ($dest_hour != $now_hour || $dest_mday != $now_mday || $dest_mon != $dest_mon || $dest_year != $now_year) 
			{
				$dest_min = $expanded->[0]->[0];
			} 
			else 
			{
				unless (defined ($dest_min = _get_nearest($dest_min,$expanded->[0]))) 
				{
					# Minute to match is at the next hour ==> redo it
					$dest_min = $expanded->[0]->[0];
					my $t = parsedate(sprintf("%2.2d:%2.2d:%2.2d %4.4d/%2.2d/%2.2d",
						$dest_hour,$dest_min,$dest_sec,$dest_year,$dest_mon,$dest_mday));
					($dest_hour,$dest_mday,$dest_mon,$dest_year,$dest_wday) = 
					(localtime(parsedate(" + 1 hour",NOW=>$t)))  [2,3,4,5,6];
					$dest_mon++;
					$dest_year += 1900;
					next;
				}
			}
		} 
		else 
		{
			if ($dest_hour != $now_hour ||
				$dest_mday != $now_mday ||
				$dest_year != $now_year) {
				$dest_min = 0;
			} 
		}
		# Check for seconds
		if ($expanded->[5])
		{
			if ($expanded->[5]->[0] ne '*')
			{
				if ($dest_min != $now_min) 
				{
					$dest_sec = $expanded->[5]->[0];
				} 
				else 
				{
					unless (defined ($dest_sec = _get_nearest($dest_sec,$expanded->[5]))) 
					{
						# Second to match is at the next minute ==> redo it
						$dest_sec = $expanded->[5]->[0];
						my $t = parsedate(sprintf("%2.2d:%2.2d:%2.2d %4.4d/%2.2d/%2.2d",
						  $dest_hour,$dest_min,$dest_sec,
						  $dest_year,$dest_mon,$dest_mday));
						($dest_min,$dest_hour,$dest_mday,$dest_mon,$dest_year,$dest_wday) = 
							(localtime(parsedate(" + 1 minute",NOW=>$t)))  [1,2,3,4,5,6];
						$dest_mon++;
						$dest_year += 1900;
						next;
					}
				}
			} 
			else 
			{
				$dest_sec = ($dest_min == $now_min ? $dest_sec : 0);
			}
		}
		else
		{
			$dest_sec = 0;
		}

		# We did it !!
		my $date = sprintf("%2.2d:%2.2d:%2.2d %4.4d/%2.2d/%2.2d",
			$dest_hour,$dest_min,$dest_sec,$dest_year,$dest_mon,$dest_mday);
#		dbg "Next execution time: $date ",$WDAYS[$dest_wday] if $DEBUG;
		my $result = parsedate($date, VALIDATE => 1);
		# Check for a valid date
		if ($result)
		{
			# Valid date... return it!
			return $result;
		}
		else
		{
			# Invalid date i.e. (02/30/2008). Retry it with another, possibly
			# valid date            
			my $t = parsedate($date); # print scalar(localtime($t)),"\n";
			($dest_hour,$dest_mday,$dest_mon,$dest_year,$dest_wday) =
				(localtime(parsedate(" + 1 second",NOW=>$t)))  [2,3,4,5,6];
			$dest_mon++;
			$dest_year += 1900;
			next;
		}
	}
	
	# Die with an error because we couldnt find a next execution entry
	my $dumper = new Data::Dumper($expanded);
	$dumper->Terse(1);
	$dumper->Indent(0);
	
	die "No suitable next execution time found for ",$dumper->Dump(),", now == ",scalar(localtime($now)),"\n";
}


# get next entry in list or 
# undef if is the highest entry found
sub _get_nearest 
{ 
#  my $self = shift;
  my $x = shift;
  my $to_check = shift;
  foreach my $i (0 .. $#$to_check) 
  {
      if ($$to_check[$i] >= $x) 
      {
          return $$to_check[$i] ;
      }
  }
  return undef;
}



1;
