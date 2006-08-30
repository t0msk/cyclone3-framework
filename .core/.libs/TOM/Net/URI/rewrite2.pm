#!/bin/perl
use strict;

# TODO: [Aben] Trosku to tu precistit a mozno spravit objektove

=head1 PRIKLAD
TOM::Net::URI::rewrite::get($file);
TOM::Net::URI::rewrite::parse_hash(%form);
my $hash=TOM::Net::URI::rewrite::parse_URL("http://spravy.markiza.sk/~USRM/edit.html?asdfhojsdf-A1-v2");
=cut

package TOM::Net::URI::rewrite;
my $debug;

our @rules;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1
# USRM
USRM/edit|type="usrm_edit";

# citanie clanku
clanok/{ID}|type="clanok";ID;
          
#obrazok/{ID;default="index";}|type="obrazok";

#spravy/domace/clanok/{ID}|type="clanok";ID;
#spravy/domace|type="kategoria";IDcategory="000A"; # toto neviemci pojde

#obrazok/{ID}|type="obrazok";ID;
# kategorie
#spravy/domace|type="kategoria";IDcategory="000A"; # toto neviemci pojde
# citanie clanku v kategorii
#spravy/domace/clanok/{ID}|type="clanok";ID;
#spravy/zahranicne/clanok/{ID}|type="clanok";ID;
#{type;default="default"}/{ID;default="index"}|


(
	{ #0
		'URL' =>
		[
			{'name'=>"USRM"},
			{'name'=>"edit"},
			{'name'=>"ID",'default'=>"index",'dynamic'=>1},
		],
		'GET' =>
		{
			'type' => "usrm_edit",
			'ID' => 0,
		}
	},
	...

=cut

sub parse_hash(\%)
{
	my $hash=shift;
	
	# mam tu problem. odkial? -> zle napisana linka.
	my $null;delete $hash->{$null};
	
	main::_log("ideme na pravidla parse_hash");
	foreach (keys %{$hash})
	{
		main::_log("key $_");
	}
	
	for my $rule(0..@rules-1)
	{
		#print " pravidlo $rule\n" if $main::debug;
		main::_log("pravidlo $rule");
#		main::_
		my $true=1;
		foreach my $kluc(keys %{$rules[$rule]{'GET'}})
		{
			#print "  vyzaduje key $kluc\n" if $main::debug;
			main::_log("vyzaduje key $kluc");
			
			# porovnanie na hodnotu kluca
			if ($rules[$rule]{'GET'}{$kluc})
			{
				print "   porovnanie hodnoty\n" if $main::debug;
				if ($rules[$rule]{'GET'}{$kluc} eq $hash->{$kluc})
				{
					print "    vyhovuje\n" if $main::debug;
					next;
				}
				else
				{
					print "    nevyhovuje\n" if $main::debug;
					$true=0;
					last;
				}
			}
			# porovnanie na existenciu kluca
			else
			{
				print "   porovnanie existencie\n" if $main::debug;
				if (exists $hash->{$kluc})
				{
					print "    vyhovuje\n" if $main::debug;
					next;
				}
				print "    nevyhovuje\n" if $main::debug;
				$true=0;
				last
			}
		}
		
		if ($true)
		{
			#print " toto pravidlo preslo\n" if $main::debug;
			#print " idem tvorit URL\n" if $main::debug;
			main::_log("pravidlo preslo");
			
			# VYTVORENIE LINKY
			my $URL;
			foreach my $reference(@{$rules[$rule]{'URL'}})
			{
				print "  ".$reference->{name}."\n" if $main::debug;
				
				if ($reference->{dynamic}) # ak je tato cast dynamicka
				#if (!$rules[$rule]{'GET'}{$reference->{name}})
				{
					print "   je dynamicka ".$reference->{name}."\n" if $main::debug;
					
					
#					if ($reference->{source} eq "cookies")
#					{
#						$hash->{$reference->{name}}=$main::COOKIES{$reference->{name}};
#					}
					
					#TYPE
					if (exists $hash->{$reference->{name}}) # ak obsahuje hash hodnotu pre tuto cast linky
					{
						print "    obsahuje hodnotu\n" if $main::debug;
						$URL.=$reference->{before}.$hash->{$reference->{name}}.$reference->{after};
					}
					else
					{
						print "    neobsahuje hodnotu, davam default\n" if $main::debug;
						$URL.=$reference->{before}.$reference->{default}.$reference->{after} if $reference->{default};
						$URL.=$reference->{before}."index".$reference->{after} unless $reference->{default};
						#$URL.="index/" unless $reference->{default};
					}
#					delete $hash->{$reference->{name}};
					next;
				}
				
				$URL.=$reference->{before}.$reference->{name}.$reference->{after};
				
			}
			
			# VYPRAZDNENIE NEPOTREBNEHO Z %HASH
=head1
			foreach my $kluc(keys %{$rules[$rule]{'GET'}})
			{
				main::_log("delete key $kluc");
				delete $hash->{$kluc};
			}
=cut
			main::_log("idem mazat nepotrebne kluce z hash");
			foreach my $kluc(keys %{$rules[$rule]{'GET'}})
			{
#				if ($rules[$rule]{'GET'})
				main::_log("delete key $kluc");
				delete $hash->{$kluc};
			}
			
			foreach my $kluc(@{$rules[$rule]{'URL'}})
			{
				#$i++;
				#print "  $i:".$kluc->{name}."\n" if $main::debug;
				if ($kluc->{dynamic}) # ak je tato premenna dynamicka
				{
					main::_log("delete key $kluc->{name}");
					delete $hash->{$kluc->{name}};
				}
			}
			
			
			foreach (keys %{$hash})
			{
				main::_log("key $_");
			}
			
			
			$URL=~s/\/$/.html/ if $rules[$rule]{type} eq "html";
			#print "URL=$URL\n";
			return $URL;
		}
		else
		{
			print " toto pravidlo nepreslo\n" if $main::debug;
		}
		
	}
	
	return "index.html";
	
}




sub parse_URL
{
	my $URL=shift;
	my %metahash;
	my %hash;
	my %hash_cookies;
	
	# odstranim woloviny
	#$URL=~s|^.*?~||;
	
	$URL=~s|^/||;
	#$URL=~s|^.*?-||;
#	$URL=~s|^(.*)\.html.*|$1|;
#	$URL=~s|\?.*$||;
	
	#main::_log("rewriting '$URL'");
	
	#print "URL je $URL\n" if $main::debug;
	main::_log("URL na spracovanie: $URL");
	
	my @url=();
	
	#print "ideme na pravidla\n" if $main::debug;
	
	for my $rule(0..@rules-1)
	{
		
		#main::_log("rule $rule");
		
		my $regexp=regexp($rule);
		my $true;
		
		main::_log("rule $rule '$URL'=~/$regexp/");
		
		if (@url=($URL=~/$regexp/))
		{
			main::_log("success");
			$true=1;
		}
		
		if ($true)
		{
			main::_log("plati pravidlo $rule, idem prevadzat na hash");
			#print " priradujem podla URL dynamicke\n" if $main::debug;
			
			# ------------------------------
			#return %metahash;
			# ------------------------------
			
			
			my $i=-1;
			foreach my $kluc(@{$rules[$rule]{'URL'}})
			{
				$i++;
				print "  $i:".$kluc->{name}."\n" if $main::debug;
				
				#main::_log("z regexp: $url[$i]");
				
				#next;
				
				if ($kluc->{dynamic}) # ak je tato premenna dynamicka
				{
					# ak je definovany defaultna hodnota a v URL je tato hodnota
					if (($kluc->{default})&&($url[$i] eq $kluc->{default}))
					{
						next;
					}
					# ak nieje definovana defaultna hodnota a v URL je hodnota "default"
					elsif ((!$kluc->{default})&&($url[$i] eq "default"))
					{
						next;
					}
					# inak beriem hodnotu v URL ako danu a prevezmem ju
					if ($kluc->{source} eq "GET")
					{
						print "    ".$kluc->{name}."=".$url[$i]."\n" if $main::debug;
						main::_log("G: ".$kluc->{name}."='".$url[$i]."'");
						$hash{$kluc->{name}}=$url[$i];
					}
#					elsif ($kluc->{source} eq "cookies")
#					{
#						print "    cookie ".$kluc->{name}."=".$url[$i]."\n" if $main::debug;
#						main::_log("C: ".$kluc->{name}."=".$url[$i]);
#						$hash_cookies{$kluc->{name}}=$url[$i];
#					}
					
					next;
				}
			}
			
			#print " priradujem podla GET staticke\n" if $main::debug;
			foreach my $kluc(keys %{$rules[$rule]{'GET'}})
			{
				#print "  kluc:$kluc\n" if $main::debug;
				if ($rules[$rule]{'GET'}{$kluc})
				{
					#print "   $kluc=$rules[$rule]{'GET'}{$kluc}\n" if $main::debug;
					main::_log("G: $kluc='$rules[$rule]{'GET'}{$kluc}'");
					$hash{$kluc}=$rules[$rule]{'GET'}{$kluc};
				}
			}
			
			%{$metahash{'GET'}}=%hash;
			#%{$metahash{'cookies'}}=%hash_cookies;
			return %metahash;
		}
		else
		{
			#main::_log("can't find rewrite rule for link '$URL'");
		}
		
	}
	
	main::_log("can't find rewrite rule for link '$URL'",1,"pub.warn");
	
}



sub regexp
{
	my $rule=shift;
	my $regexp="^";
	foreach my $kluc(@{$rules[$rule]{'URL'}})
	{
		$regexp.=$kluc->{before}."(".$kluc->{regexp}.")".$kluc->{after};
	}
	$regexp.="\$";
	#main::_log("regexp of rule $rule: '".$regexp."'");
	return $regexp;
}



sub get
{
	my $data=shift;
	main::_log("get data to url_rewrite");
#	my @rules;
	
	@rules=();
	
	foreach my $line(split('\n',$data))
	{
		my %rule;
		
		next if $line=~/^#/;
		$line=~s| #.*||;
		next unless $line;
		next unless $line=~/\|/;
		#print " spracuvam line: $line\n" if $main::debug;
		main::_log("line '$line'");
		
		my @sections=split('\|',$line);
		
		#print "  spracuvam sekciu URL: $sections[0]\n" if $main::debug;
		main::_log("spracuvam sekciu URL: '$sections[0]'");
		
		$rule{'URL'}=();
		
		while ($sections[0]=~s|^(.*?)\{(.*?)\}||)
		{
			my $before=$1;
			my $url=$2;
			
			main::_log("spracuvam before:'$1' url:'$2'");
			
			my %rule_url;
			
			
			$rule_url{source}="GET";
			$rule_url{before}=$before;
			if ($url=~/;/)
			{
				main::_log("hlbsie definovany var: '$url'");
				my @data=split(';',$url);
				$url=shift @data;
				foreach my $data(@data)
				{
					if ($data=~/default="(.*)"/)
					{
						$rule_url{default}=$1;
						main::_log("default='$1'");
						next;
					}
					if ($data=~/regexp="(.*)"/)
					{
						$rule_url{regexp}=$1;
						main::_log("regexp='$1'");
						next;
					}
					if ($data=~/source="(.*)"/)
					{
						$rule_url{source}=$1;
						main::_log("source='$1'");
						next;
					}
				}
			}
			$rule_url{dynamic}=1;
			$rule_url{name}=$url;
			$rule_url{regexp}=".*?" unless $rule_url{regexp};
			
			push @{$rule{'URL'}}, {%rule_url};
		}
		
		# nastavime after :))
		$rule{'URL'}[-1]{after}=$sections[0];
		
		#print "  spracuvam sekciu GET: $sections[1]\n" if $main::debug;
		main::_log("spracuvam sekciu GET: '$sections[1]'");
		foreach my $get(split(';',$sections[1]))
		{
			main::_log("spracuvam '$get'");
			#print "   spracuvam: $get\n" if $main::debug;
			if ($get=~/(.*)="(.*)"/)
			{
				main::_log("hard '$1'='$2'");
				#print "    hard: $1=$2\n" if $main::debug;
				$rule{'GET'}{$1}=$2;
			}
			else
			{
				main::_log("dynamic '$get'");
				#print "    dynamic: $get\n" if $main::debug;
				$rule{'GET'}{$get}=0;
			}
		}
		
		push @rules,{%rule};
		
	}
}























1;