package TOM::Data::XML;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our $debug=0;
#our $strict=1;
#our $s="  ";
our $s="\t";

sub serialize
{
	my %hash=@_;
	my %out=serialize_data(level=>0,data=>\%hash);
	return $out{data};
}

sub serialize_enh
{
	my %env=@_;
	my %hash=$env{data};
	my %out=serialize_data(level=>0,data=>$env{data},strict=>$env{strict});
	return $out{data};
}

sub serialize_data
{
 my %env=@_;
 my %ret;
 
 #print "=>$env{level},$env{data}\n" if $debug;
 print "".(" " x ($env{level}))."=>input:!$env{data}!\n" if $debug;
 
 $ret{level}=$env{level};
 $env{level}++;
 
 if (ref($env{data}) eq "HASH")
# if (%{$env{data}})
 {
  print "".(" " x ($env{level}-1))."->hash\n" if $debug;
  #print "->hash\n" if $debug;
    
  $ret{type}="block";
  
  
  my $null;
  %{$env{data}}=($null=>"") unless %{$env{data}}; # je definovane ze je hash, ale ani jedna polozka tam nieje
  
  my @arr;
  my $full;
  #my $length;
  foreach (sort keys %{$env{data}})
  {
	$full++ if $_;
	print "".(" " x ($env{level}-1))."+serialize: !".(${$env{data}}{$_})."!\n" if $debug;
	
	my %in=serialize_data(level=>$env{level},data=>${$env{data}}{$_},from=>"HASH",strict=>$env{strict});
	$in{name}=$_;
	
	
	if ($env{strict})
	{
		if ($in{data})
		{
			$ret{data}.="<".$in{name}.">".$in{data}."</".$in{name}.">";
		}
		else
		{
			$ret{data}.="<".$in{name}."/>";
		}
	}
	elsif ($in{type} eq "text")
	{
		$ret{data}.=($s x ($env{level}-1))."<".$in{name}.">\n".$in{data}."\n".($s x ($env{level}-1))."</".$in{name}.">\n";
	}
	elsif ($in{type} eq "block")
	{
		$ret{data}.=($s x ($env{level}-1))."<".$in{name}.">\n".$in{data}.($s x ($env{level}-1))."</".$in{name}.">\n";
	}
	else
	{
		$ret{data}.=($s x ($env{level}-1))."<".$in{name}.">".$in{data}."</".$in{name}.">\n";
	}
  }
  

 }
#=head1
 elsif (ref($env{data}) eq "ARRAY")
 {
#	print "->array\n" if $debug;
	print "".(" " x ($env{level}-1))."->array\n" if $debug;
#  my $cvml;
  	$ret{type}="block";
	my @arr;
	
	@{$env{data}}=("") unless @{$env{data}}; # je definovane ze je array, ale ani jedna polozka tam nieje
		
#	my $length;
	my $i=1;
	foreach (@{$env{data}})
	{
		print "".(" " x ($env{level}-1))."+serialize: !".($_)."!\n" if $debug;
		my %in=serialize_data(level=>$env{level},data=>$_,from=>"ARRAY",strict=>$env{strict});
#		$ret{type}="block" if ($in{type} ne "varchar");
#		push @arr,{%in};
		print "".(" " x ($env{level}-1))."+add type: !".($ret{type})."!\n" if $debug;
		
#		$ret{data}.=("\t" x $env{level})."<item>".$in{data}."</item>\n";
		
		if ($env{strict})
		{
			$ret{data}.="<item id=\"$i\">".$in{data}."</item>";
		}
		elsif ($in{type} eq "text")
		{
			$ret{data}.=($s x ($env{level}-1))."<item id=\"$i\">\n".$in{data}."\n".($s x ($env{level}-1))."</item>\n";
		}
		elsif ($in{type} eq "block")
		{
			$ret{data}.=($s x ($env{level}-1))."<item id=\"$i\">\n".$in{data}.($s x ($env{level}-1))."</item>\n";
		}
		else
		{
			$ret{data}.=($s x ($env{level}-1))."<item id=\"$i\">".$in{data}."</item>\n";
		}
		$i++;
	}

 }
 
#=cut
 else
 {
  	print "".(" " x ($env{level}-1))."->text:!$env{data}!\n" if $debug;
	
	#$ret{data}=~s|\r||g;
	$ret{type}="varchar";
	if (($env{data}=~/[\n\r]/) || (length($env{data})>64))
	{
		$ret{type}="text";
	}
#	print "".(" " x ($env{level}-1))."+setting type to $ret{type}\n" if $debug;
	$ret{data}=$env{data};
	
	$ret{data}=~s|&|&amp;|g;
	$ret{data}=~s|<|&lt;|g;
	$ret{data}=~s|>|&gt;|g;
 }
 
 $ret{data}=~s|\r||g; # \r v CVML niesu povolene
 #$ret{type}="varchar" unless $ret{type};
 print "".(" " x ($env{level}-1))."<-return:!$ret{data}!$ret{type}!\n" if $debug;
 #print "co je\n";
 return %ret;
}







1;
