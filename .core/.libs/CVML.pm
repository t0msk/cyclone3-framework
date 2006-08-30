package CVML;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our $debug=0;


sub new
{
 my $class=shift;
 my $self={};
 my %env=@_;

 $self->{data}=$env{data};
 my $no;
 $self->{data}=~s/(=|<)\[(.[^\n]{0,50}?)\]/ $1 eq "=" ? ("=[".$2."-L".$no++."]") : ("<[".$2."-L".--$no."]")/eg;
 $self->{data}=~s|\r||g;

 $self->{hash}=CVML::microparser::parse($self->{data});
 $self->{hash}={} unless $self->{hash};

 print "+END\n" if $debug;
 print "+PUBLISH\n" if $debug;

 return bless $self, $class;
}










package CVML::microparser;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


sub parse
{
 my $data=shift;
 my %arr;
 my $env;
 my $W='[ \t\n\r]{0,255}?';

 my $var=$data;$var=~s|[\n\r]||g;
 print "+input with $var\n\n" if $debug;
 print "+parsing\n" if $debug;
 #while ($data=~s|^(.*?)<(#?)([a-zA-Z0-9_ \-\.\+]{1,255}?)$W(=?)([\[:].*?[^\\]\])>||s) #]/
 while ($data=~s|^(.*?)<(#?)([a-zA-Z0-9_ \-\.\+]{0,255}?)$W(=?)([\[:].*?[^\\]?\])>||s) #]/
 {
  my ($deathblock,$com,$name,$block,$head)=($1,$2,$3,$4,$5);
  my $head_in=$head;$head_in=~s|^\[(.*?)\]$|\1| if $block;

  print "+parse ? death:".length($deathblock)." com:$com name:$name block:$block head:$head\n" if $debug;

  if ($block)
  {
   print " +block\n" if $debug;
   if (not $data=~s|^(.*?)<\[$head_in\]>||s){die "  -not parsed (.*?)<\[$head_in\]> $data\n";}
   my $data_in=$1;
   next if $com eq "#";

   # spracovanie
   if ($name eq "+") # ide len o pridanie array
   {
    print " + +array\n" if $debug;    
    #my @out=CVML::microparser::parse_line($data_in);
    my @out=CVML::microparser::parse($data_in);
    push @{$env},@out;
    next;
   }
   if (defined ${$env}{$name})
   {
    print "  +exist\n" if $debug;
    if (!$arr{$name})
    {
     print "  +not arr\n" if $debug;
     my $var=${$env}{$name};delete ${$env}{$name};${$env}{$name}[0]=$var;
    }
    print "  +arr\n" if $debug;
    push @{${$env}{$name}},CVML::microparser::parse($data_in);$arr{$name}=1;
   }
   else {${$env}{$name}=CVML::microparser::parse($data_in);}
   next;
  }

  print " +normal $head\n" if $debug;
  if ($name eq "+") # ide len o pridanie array
  {
   print " + +array line\n" if $debug;
   my @out=CVML::microparser::parse_line($head);
   push @{$env},@out;
   next;
  }
  if (defined ${$env}{$name})
  {
   if (!$arr{$name}){my $var=${$env}{$name};delete ${$env}{$name};${$env}{$name}[0]=$var;}
   push @{${$env}{$name}},CVML::microparser::parse_line($head);$arr{$name}=1;
  }
  else {${$env}{$name}=CVML::microparser::parse_line($head);}

  next;
 }

 
 if ($env)
 {
  print "-return ref\n" if $debug;
  return $env;
 }
 
 my $var=$data;$var=~s|[\n\r]||g; 
 
 $data=~s|^\n||g;
 #$data=~s|\s+$||g; # kvoli typu TEXT
 $data=~s|\n[\t ]+$||g; # kvoli typu TEXT
 
 $data=~s|\\([\[\]])|\1|g;
 print "-return data !$data!\n" if $debug;
 #return undef unless $data;
 return $data;
}















sub parse_line
{
	my $data=shift;
	my $W='[ \t\n\r]*?';
	
	my $env;
	print "     +line $data\n" if $debug;
	if ($data=~s/^\[(.*?)\]$/\1/s) # array
	{
		#print "      +array\n" if $debug;
		if ($data=~/[^\\]\].*?[^\\]\[/s)
		{
			$data=~s|([^\\])\]$W\[|\1\]\[|gs;
			print "      +array !$data!\n" if $debug;
			
			@{$env}=split('\]\[',$data);
			foreach (@{$env}){$_=~s|\\([\[\]])|\1|gs;} # osetrujem spet vykomentovane znaky []
			
			return $env;
		}
		else
		{
			#${$env}[0]=undef;
			print "      +standard !$data!\n" if $debug;
			#$data=~s/\\(\[|\])/\1/gs;
			$data=~s|\\([\[\]])|\1|gs; # osetrujem spet vykomentovane znaky []
			
			print "       +standard !$data!\n" if $debug;
		}
		
#  foreach (@{$env})
#  {
#  	print "+kontrola prazdnosti\n";
#  }
  
 }
 elsif ($data=~s/^:(.*?)\]$/\1/s) # hash
 {
 
  $data=~s|([^\\])\]$W:|\1\]:|gs;
  
  print "      +hash $data\n" if $debug;
	foreach my $line(split(/\]:/,$data))
	{
		my @ref=split(/\[/,$line,2);
		$ref[0]=~s|$W||g;
		next unless $ref[0]; # osetrujem tento pripad -> <key:[]>, teda ked ide o prazdny hash
		$ref[1]=~s|\\([\[\]])|\1|gs; # osetrujem spet vykomentovane znaky []
		print "       +$ref[0] = $ref[1]\n" if $debug;
		${$env}{$ref[0]}=$ref[1];
	}
	$env={} unless $env;
 }
 if(!$env)
 {
  #$data=~s|\\([\[\]])|\1|g;
  print "-return data !$data!\n" if $debug;
  #return undef if ((!$data));
  #print "-return\n";
  return $data;
 }
 return $env;
}







sub parse_line2
{
 my $data=shift;
 my %env;
 my $env;

 print "     +line $data\n" if $debug;

 if ($data=~s/^\[(.*?)\]$/\1/) # array
 {
  if ($data=~/[^\\]\[/)
  {
   print "      +array !$data!\n" if $debug;
   #$data=~s|\]\[|,|g;
   #my $ref;
   #($ref)=split('\]\[',$data);
   #my $ref2=ref($ref);
   #print "       +ref $ref2\n";
   #$ref2[0][0]=$ref[0];
   #$ref2[0][1]=$ref[1];
   #return ($ref);

   #my @ref=split('\]\[',$data);
   #return \@ref;

   @{$env}=split('\]\[',$data);
   return $env;

   #return ${ref(split('\]\[',$data))};
   #return $(@ref);
   #print "      +array $data @ref\n";
  }
  else
  {
   print "      +standard $data\n" if $debug;
   $data=~s|\\(\[\|\])|\1|g;
   #print "      +standard $data\n";
  }
 }
 elsif ($data=~s/^:(.*?)\]$/\1/) # hash
 {
  print "      +hash $data\n" if $debug;
  foreach(split('\]:',$data))
  {
   my @ref=split('\[',$_);
   #$env{$ref[0]}=$ref[1];
   ${$env}{$ref[0]}=$ref[1];
  }
 }


 #if(!%env){print "-return data $data\n";return $data;}
 #return \%env;

 if(!$env){
 print "-return data $data\n" if $debug;
 return $data;
 }
 return $env;
}















=head1
sub new
{
 my $class=shift;
 my $self={};
 my %env=@_;

 #my $in=<STDIN>;
 print "+input with $env{data}\n\n" if $debug;

 print "+blocks\n" if $debug;
 while ($env{data}=~s|<(.[^\n]{1,255}?)=\[(.*?)\](.*?)>(.*?)<\[\2\]>||s)
 {
  my $name=$1;
  my $blockname=$2;
  my $aftername=$3;
  my $block=$4;
  1 while($block=~s|(^\n\|\n$)||);

  print "+block $name=$block\n\n" if $debug;

  $self->{$name}=CVML::microparser->new(data=>$block);

  #push @{$self->{data}},CVML::microparser->new(data=>$block);
 }
 print "+normals\n" if $debug;
 print "+others\n" if $debug;
 return bless $self;
}
=cut








package CVML::structure;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

sub publish
{
 my %env=@_;
 print "=>$env{level},$env{data} ref=".(ref($env{data}))."\n";
 $env{level}++;

 if (ref($env{data}) eq "HASH")
 {
  print "->hash\n";
  #print "ref=$ref\n";
  foreach (sort keys %{$env{data}})
  {
   #print "[$env{level}] $_ = \"${$env{data}}{$_}\"\n";
   print "[$env{level}]"." " x $env{level}." +$_ = ${$env{data}}{$_}\n";# if $debug;
   publish(level=>$env{level},data=>${$env{data}}{$_});
  }
 }
 elsif (ref($env{data}) eq "ARRAY")
 {
  #print "->array\n";
  foreach (@{$env{data}})
  {
   #print "[$env{level}] $_\n";
   print "[$env{level}]"." " x $env{level}." +$_\n";# if $debug;
   publish(level=>$env{level},data=>$_);
  }
 }
 else
 {
  print "[$env{level}]"." " x $env{level}." +$env{data}\n";
 }
}




sub serialize
{
	my %hash=@_;
#	return "" if 
	my %out=serialize_data(level=>0,data=>\%hash);
	#return "<:[]>" if $out{data} eq "[]";
	return "<:[]>" if $out{data} eq ":[]";
	#return "<:[]>" if $out{data} eq ":[:[]]";
	return $out{data};
}


sub serialize_data
{
	#my $t=track TOM::Debug("serialize_data()");
	
	my %env=@_;
	my %ret;
	
	print "".(" " x ($env{level}))."=>input:!$env{data}!\n" if $debug;
	
	$ret{level}=$env{level};
	$env{level}++;
	
	if (ref($env{data}) eq "HASH")
	{
		print "".(" " x ($env{level}-1))."->hash\n" if $debug;
		$ret{type}="line_hash";
		print "".(" " x ($env{level}-1))."+start type: !".($ret{type})."!\n" if $debug;
		
		my $null;
		#delete $env{data}{$null};
		
		# ak ide o hash v ktorom nieje ani jedina polozka
		if (not %{$env{data}})
		{
			print "".(" " x ($env{level}-1))."+empty hash\n" if $debug;
			%{$env{data}}=($null=>"");
		}
		#%{$env{data}}=($null=>"") unless %{$env{data}};
		
		my @arr;
		my $full;
		my $length;
		foreach (sort keys %{$env{data}})
		{
			#next unless $_;
			#delete $env{data}{$_} unless $_;
			#next unless $_;
			#$_='NIL' unless $_;
		
			$full++ if $_;
			print "".(" " x ($env{level}-1))."+serialize: !".(${$env{data}}{$_})."!\n" if $debug;
			
			my %in=serialize_data(level=>$env{level},data=>${$env{data}}{$_},from=>"HASH") if $_;
			$in{name}=$_;
			$ret{type}="block" if ($in{type} ne "varchar");
			push @arr,{%in};
			
			$length+=length($in{name})+length($in{data});
			
			print "".(" " x ($env{level}-1))."+add type: !".($ret{type})."!\n" if $debug;
		}
		
		$ret{type}="block" if $env{level}==1;
		
		$ret{type}="block" if $length>64;
		
		# ak je pole prazdne, uuuplne prazdne
		$ret{type}="line_hash" unless $full;
		
		# tomuto nerozumiem, zabudol som comment :((
		# 2006-03-06 - tak to je vazne krasne - ziram co som kedysi mohol napisat
		$ret{data}.="[]" if ((not @arr) && ($ret{type} ne "block"));
		
		print "".(" " x ($env{level}-1))."+final type: !".($ret{type})."! length $length\n" if $debug;
		
		foreach my $key(@arr)
		{
			# pokial v hashi bol prazdny kluc, a v tom hashi su este plne kluce, tak aby nebolo <[]>
			next if ((!${$key}{name})&&($full));
			
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
=head1
			elsif ($env{level}==1)
			{
				print "".(" " x ($env{level}-1))."+collect (block/othrs)\n" if $debug;
				${$key}{data}=~s|([\[\]])|\\\1|g;
				$ret{data}.=("\t" x (${$key}{level}-1))."<".(${$key}{name}).":[".(${$key}{data})."]>\n";
			}
=cut
			else
			{
				print "".(" " x ($env{level}-1))."+collect (/othrs)\n" if $debug;
				${$key}{data}=~s|([\[\]])|\\\1|g;
				$ret{data}.=":".(${$key}{name})."[".(${$key}{data})."]";
			}
			
		}
	}
	
	
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
