#!/bin/perl
package App::24;
use CVML;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

sub parse_menu
{
	my %hash=@_;
	
#	foreach (keys %hash)
#	{
#		print "<-$_\n";
#	}
#	my %hash=parse_menu_($text);

	my @arr=parse_menu_(level=>0,path=>[0],data=>\%hash);
	
	return @arr;
}

# rekurzia
sub parse_menu_
{
	my %env=@_;
	my @arr;
	$env{level}++;
	
	#print "".(" " x $env{level})."[$env{level}]<-$env{data}\n";
	
	
	if (ref($env{data}) eq "HASH")
	{
		#print "<- H:$env{data}\n";
		#print "".(" " x $env{level})."[$env{level}] H (som v menu)\n";
		
		my %env0;
		my @arr_last;
		$env0{level}=(($env{level}-1)/2);
		foreach (keys %{$env{data}})
		{
			#print "".(" " x $env{level})."[$env{level}] key '$_'\n";
			
			if (($_ eq "menu") && (ref($env{data}{$_}) eq "ARRAY"))
			{
				#print "".(" " x $env{level})."[$env{level}] ->\n";
				push @arr_last,parse_menu_(level=>$env{level},data=>$env{data}{$_});
			}
			else
			{
				# 
				$env0{$_}=$env{data}{$_};
			}

		}
		push @arr,{%env0} if $env{level}>1;
		push @arr,@arr_last;
	}
	elsif ((ref($env{data}) eq "ARRAY")&&($env{level}>1))
	{
		#print "".(" " x $env{level})."[$env{level}] A (toto je zoznam menus)\n";
		
#		push @arr,parse_menu_(level=>$env{level},data=>$env{data}{$_});
		
#=head1
		foreach my $arr0(@{$env{data}})
		{
#			print "arr: $arr0\n";
			print "".(" " x $env{level})."[$env{level}] ->\n" if $main::debug;
			
			push @arr,parse_menu_(level=>$env{level},data=>$arr0);
		}
#=cut

		
#		foreach (keys %{$env{data}})
#		{
#			print "key $_\n";
#		}
	}
	
	return @arr;
}








1;
