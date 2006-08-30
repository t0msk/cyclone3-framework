#!/bin/perl
package enc;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1
sub cde
{
	local $ret;
	local $c=ord($_[0]);
	local $post;
	local $pre;
	
#	print "\n>> ",$c;
	$pre=int($c/59);
	$c=$c%59;

	if ($c<=9) { $post=$c+ord("0"); }
	elsif ($c<=34) { $post=$c+ord("A")-9; }
	elsif ($c<=59) { $post=$c+ord("a")-34; }
	else { return "" };
	
	if ($pre==1) { $pre="-"; }
	elsif ($pre==2) { $pre=":"; }
	elsif ($pre==3) { $pre="_"; }
	elsif ($pre==4) { $pre="."; }
	else { $pre=""; }
		
#	print " | ",$pre.chr($post);
	return $pre.chr($post);
}

sub dcde
{
	local $c1=ord($_[0]);
	local	$c2=ord($_[1]);
	local $mul=0;
	local $b;
	
	if ($c1==ord("-")) { $mul=1; }
	elsif ($c1==ord(":")) { $mul=2; }
	elsif ($c1==ord("_")) { $mul=3; }
	elsif ($c1==ord(".")) { $mul=4; }
	
	$b=$c1;
	if ($mul>0) { $b=$c2; }
	
	if (ord("0") <= $b && $b <= ord("9")) { $b-=ord("0"); }
	elsif (ord("A") <= $b && $b <= ord("Z")) { $b-=ord("A")-9; }
	elsif (ord("a") <= $b && $b <= ord("z")) { $b-=ord("a")-34; }
	else { return (($mul>0)? 2:1,""); }
	
	$b+=$mul*59;
	
	return (($mul>0)? 2:1, chr($b));
}

sub enc
{
	local $S=$_[0];
	local $Key=$_[1];
	local $Ret="";
	
	local $l_s=length($S);
	local $l_k=length($Key);
	
	local $i_k=0;
	local $i_s=0;
	
	#print $S," | ",$Key,"\n";
	#print $l_s," | ",$l_k;
	while ($i_s<$l_s)
	{
		$Ret.=cde(chr(ord(substr($S,$i_s++,1))^ord(substr($Key,$i_k++,1))));
#		print "\nCoded ",substr($S,$i_s-1,1)," WITH ",substr($Key,$i_k-1,1);
		if ($i_k>=$l_k) { $i_k-=$l_k; }
	}
	return $Ret;
}

sub dec
{
	local $S=$_[0];
	local $Key=$_[1];
	local $Ret="";

	local $l_s=length($S);
	local $l_k=length($Key);
	
	local $i_k=0;
	local $i_s=0;
	
	local $err;
	local $val;
	while($i_s<$l_s)
	{
		
		($err,$val) = dcde(substr($S,$i_s,1),substr($S,$i_s+1,1));
		
		if (!$err) 
		{ 
			$Ret='';
			return $Ret;
		}
		
		$i_s+=$err;
		$val=$val^substr($Key,$i_k++,1);
		$Ret.=$val;

		if ($i_k>=$l_k) { $i_k-=$l_k; }
	}
	return $Ret;
}
=cut


sub cde
{
	my $ret;
	my $c=ord($_[0]);
	my $post;
	my $pre;
	
#	print "\n>> ",$c;
	$pre=int($c/59);
	$c=$c%59;

	if ($c<=9) { $post=$c+ord("0"); }
	elsif ($c<=34) { $post=$c+ord("A")-9; }
	elsif ($c<=59) { $post=$c+ord("a")-34; }
	else { return "" };
	
=head1
	$pre=do
	{
	 ($pre==1) ? "-":
	 ($pre==2) ? ":":
	 ($pre==3) ? "_":
	 ($pre==4) ? ".":
	 ""
	};
=cut
=head1
	if ($pre==1) { $pre="-"; }
	elsif ($pre==2) { $pre=":"; }
	elsif ($pre==3) { $pre="_"; }
	elsif ($pre==4) { $pre="."; }
	else { $pre=""; }
=cut
	
#	print " | ",$pre.chr($post);
#	return $pre.chr($post);

	return do {($pre==1) ? "-":($pre==2) ? ":":($pre==3) ? "_":($pre==4) ? ".":""}.chr($post);
}

sub dcde
{
	my $c1=ord($_[0]);
	my	$c2=ord($_[1]);
#	my $mul=0;
	my $b;
	
	my $mul=do
	{
		 ($c1==ord("-")) ? 1:
		 ($c1==ord(":")) ? 2:
		 ($c1==ord("_")) ? 3:
		 ($c1==ord("."))  ? 4:
		 0
	};
	
#	if ($c1==ord("-")) { $mul=1; }
#	elsif ($c1==ord(":")) { $mul=2; }
#	elsif ($c1==ord("_")) { $mul=3; }
#	elsif ($c1==ord(".")) { $mul=4; }
	
	$b=$c1;
	#if ($mul>0) { $b=$c2; }
	$b=$c2 if $mul;
	
	if (ord("0") <= $b && $b <= ord("9")) { $b-=ord("0"); }
	elsif (ord("A") <= $b && $b <= ord("Z")) { $b-=ord("A")-9; }
	elsif (ord("a") <= $b && $b <= ord("z")) { $b-=ord("a")-34; }
	else { return (($mul>0)? 2:1,""); }
	
	$b+=$mul*59;
	
	return (($mul>0)? 2:1, chr($b));
}

sub enc
{
	my $S=$_[0];
	my $Key=$_[1];
	my $Ret;
	
	my $l_s=length($S);
	my $l_k=length($Key);
	
	my $i_k=0;
	my $i_s=0;
	
	#print $S," | ",$Key,"\n";
	#print $l_s," | ",$l_k;
	while ($i_s<$l_s)
	{
		$Ret.=cde(chr(ord(substr($S,$i_s++,1))^ord(substr($Key,$i_k++,1))));
#		print "\nCoded ",substr($S,$i_s-1,1)," WITH ",substr($Key,$i_k-1,1);
		if ($i_k>=$l_k) { $i_k-=$l_k; }
	}
	return $Ret;
}

sub dec
{
	my $S=$_[0];
	my $Key=$_[1];
	my $Ret="";

	my $l_s=length($S);
	my $l_k=length($Key);
	
	my $i_k=0;
	my $i_s=0;
	
	my $err;
	my $val;
	while($i_s<$l_s)
	{
		
		($err,$val) = dcde(substr($S,$i_s,1),substr($S,$i_s+1,1));
		
		if (!$err) 
		{ 
			$Ret='';
			return $Ret;
		}
		
		$i_s+=$err;
		$val=$val^substr($Key,$i_k++,1);
		$Ret.=$val;

		if ($i_k>=$l_k) { $i_k-=$l_k; }
	}
	return $Ret;
}









1;
