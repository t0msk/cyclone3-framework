package XML::structure;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}










sub serialize
{
	my %hash=@_;
	my %out=serialize_data(level=>0,data=>\%hash);
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

 
=head1
 if ((ref($env{data}) eq "HASH")&&(!%{$env{data}}))
 {
 	$env{data}="";
 } 
 if ((ref($env{data}) eq "ARRAY")&&(!@{$env{data}}))
 {
 	$env{data}="";
 }
=cut 
 
 if (ref($env{data}) eq "HASH")
# if (%{$env{data}})
 {
  print "".(" " x ($env{level}-1))."->hash\n" if $debug;
  #print "->hash\n" if $debug;
    
  
  $ret{type}="line_hash";
  #$ret{type}="block" if ($env{from} eq "ARRAY");
  #$ret{type}="line_hash" unless %{$env{data}};
  
#  if (not %{$env{data}})
#  {
#  	print "prazdne!\n";
#  }
  
  print "".(" " x ($env{level}-1))."+start type: !".($ret{type})."!\n" if $debug;
  
  my $null;
  %{$env{data}}=($null=>"") unless %{$env{data}}; # je definovane ze je hash, ale ani jedna polozka tam nieje
  
  my @arr;
  my $full;
  my $length;
  foreach (sort keys %{$env{data}})
  {
	$full++ if $_;
	print "".(" " x ($env{level}-1))."+serialize: !".(${$env{data}}{$_})."!\n" if $debug;
	
	my %in=serialize_data(level=>$env{level},data=>${$env{data}}{$_},from=>"HASH");
	$in{name}=$_;
	$ret{type}="block" if ($in{type} ne "varchar");
	push @arr,{%in};
	
	$length+=length($in{name})+length($in{data});
	
	print "".(" " x ($env{level}-1))."+add type: !".($ret{type})."!\n" if $debug;
  }
  
  #delete ${$env{data}}{$null};
  
#  $ret{data}.="[]" unless @arr;
  
  #$ret{data}
  
  #$ret{type}="block" if (($env{from} eq "ARRAY") && (@arr));
  
  #$ret{type}="block" if ($env{from} eq "ARRAY"); # toto predsa nemusim, nie?
  $ret{type}="block" if $env{level}==1;
  #$ret{type}="block" if @arr>5;
  $ret{type}="block" if $length>64;
  $ret{type}="line_hash" unless $full; # ak je pole prazdne, uuuplne prazdne
  
  # tomuto nerozumiem, zabudol som comment :((
  $ret{data}.="[]" if ((not @arr) && ($ret{type} ne "block"));
  
  print "".(" " x ($env{level}-1))."+final type: !".($ret{type})."! length $length\n" if $debug;
  
  foreach my $key(@arr)
  {
#  	print "-".(${$key}{data})."\n";
	next if ((!${$key}{name})&&($full)); # pokial v hashi bol prazdny kluc, a v tom hashi su este plne kluce, tak aby nebolo <[]>
	
	#print "-".(${$key}{type})."-".(${$key}{data})."\n" if $debug;
	
	print "".(" " x ($env{level}-1))."+collect HASH: !$key!".(${$key}{type})."!".(${$key}{data})."!\n" if $debug;
	
	if ($ret{type} eq "block")
	{
		if (${$key}{type} eq "block")
		{
			print "".(" " x ($env{level}-1))."+collect (block/block)\n" if $debug;
			$ret{data}.=("\t" x (${$key}{level}-1))."<".(${$key}{name})."=[BLOCK]>\n".(${$key}{data}).("\t" x (${$key}{level}-1))."<[BLOCK]>\n";
		}
		elsif (${$key}{type} eq "text")
		{
			print "".(" " x ($env{level}-1))."+collect (block/text)\n" if $debug;
			$ret{data}.=("\t" x (${$key}{level}-1))."<".(${$key}{name})."=[BLOCK]>\n".(${$key}{data})."\n".("\t" x (${$key}{level}-1))."<[BLOCK]>\n";
		}
		elsif (${$key}{type}=~/^line/)
		{
			print "".(" " x ($env{level}-1))."+collect (block/line)\n" if $debug;
			$ret{data}.=("\t" x (${$key}{level}-1))."<".(${$key}{name}).(${$key}{data}).">\n";
		}
		else
		{
			print "".(" " x ($env{level}-1))."+collect (block/othrs)\n" if $debug;
			${$key}{data}=~s|([\[\]])|\\\1|g;
			$ret{data}.=("\t" x (${$key}{level}-1))."<".(${$key}{name})."[".(${$key}{data})."]>\n";
		}
	}
	else
	{
		print "".(" " x ($env{level}-1))."+collect (/othrs)\n" if $debug;
		${$key}{data}=~s|([\[\]])|\\\1|g;
		$ret{data}.=":".(${$key}{name})."[".(${$key}{data})."]";
	}
	
  }
  #return $cvml;
  
  #print "$ret{data}\n";
  #exit(0);
  
 }
#=head1
 elsif (ref($env{data}) eq "ARRAY")
 {
#	print "->array\n" if $debug;
	print "".(" " x ($env{level}-1))."->array\n" if $debug;
#  my $cvml;
  	$ret{type}="line_array";
  	my @arr;
	
	@{$env{data}}=("") unless @{$env{data}}; # je definovane ze je array, ale ani jedna polozka tam nieje
		
	my $length;
  	foreach (@{$env{data}})
  	{
		print "".(" " x ($env{level}-1))."+serialize: !".($_)."!\n" if $debug;
		my %in=serialize_data(level=>$env{level},data=>$_,from=>"ARRAY");
		$ret{type}="block" if ($in{type} ne "varchar");
		push @arr,{%in};
		print "".(" " x ($env{level}-1))."+add type: !".($ret{type})."!\n" if $debug;
		
		#$length.=length($_);
		$length+=length($in{name})+length($in{data});
	}
	
#	@arr=[] unless @arr;

	$ret{type}="block" if $env{level}==1;
	#$ret{type}="block" if @arr>5;
	$ret{type}="block" if $length>64;
	$ret{type}="block" if @arr==1;
 
	foreach my $key(@arr)
	{
	#  	print "-".(${$key}{data})."\n";
		
		#print "-".(${$key}{type})."-".(${$key}{data})."\n" if $debug;
		print "".(" " x ($env{level}-1))."+collect ARRAY: !".(${$key}{type})."!".(${$key}{data})."!\n" if $debug;
		
		if ($ret{type} eq "block")
		{
			if (${$key}{type} eq "block")
			{
				print "".(" " x ($env{level}-1))."+collect (block/block)\n" if $debug;
				$ret{data}.=("\t" x (${$key}{level}-1))."<+=[BLOCK]>\n".(${$key}{data}).("\t" x (${$key}{level}-1))."<[BLOCK]>\n";
			}
			elsif (${$key}{type} eq "text")
			{
				print "".(" " x ($env{level}-1))."+collect (block/text)\n" if $debug;
				$ret{data}.=("\t" x (${$key}{level}-1))."<+=[BLOCK]>\n".(${$key}{data})."\n".("\t" x (${$key}{level}-1))."<[BLOCK]>\n";
			}
			elsif (${$key}{type}=~/^line/)
			{
				print "".(" " x ($env{level}-1))."+collect (block/line)\n" if $debug;
				$ret{data}.=("\t" x (${$key}{level}-1))."<+".(${$key}{data}).">\n";
			}
			else
			{
				print "".(" " x ($env{level}-1))."+collect (block/othrs)\n" if $debug;
				${$key}{data}=~s|([\[\]])|\\\1|g;
				$ret{data}.=("\t" x (${$key}{level}-1))."<+[".(${$key}{data})."]>\n";
			}
		}
		else
		{
			print "".(" " x ($env{level}-1))."+collect (/othrs)\n" if $debug;
			${$key}{data}=~s|([\[\]])|\\\1|g;
			$ret{data}.=(${$key}{name})."[".(${$key}{data})."]";
		}
	
	}
	
#	$ret{data}
#  return $cvml;
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
	print "".(" " x ($env{level}-1))."+setting type to $ret{type}\n" if $debug;
	$ret{data}=$env{data};
		
	#$ret{data}.="[]" if $env{level}==2;
	
	if ($ret{type}=~/^(varchar|text)$/)
	{
		$ret{data}=~s|([\[\]])|\\\1|g;
	}
 }
 
 $ret{data}=~s|\r||g; # \r v CVML niesu povolene
 #$ret{type}="varchar" unless $ret{type};
 print "".(" " x ($env{level}-1))."<-return:!$ret{data}!$ret{type}!\n" if $debug;
 #print "co je\n";
 return %ret;
}







1;
