#!/bin/perl
# TODO: [Aben] Trosku to tu precistit a mozno spravit objektove

=head1 PRIKLAD
TOM::Net::URI::rewrite::get($file);
TOM::Net::URI::rewrite::parse_hash(%form);
my $hash=TOM::Net::URI::rewrite::parse_URL("http://spravy.markiza.sk/~USRM/edit.html?asdfhojsdf-A1-v2");
=cut

package TOM::Net::URI::rewrite;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
use charnames ':full';

use Digest::MD5  qw(md5 md5_hex md5_base64);
use Int::charsets::encode;

our $debug=0;

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

sub parse_hash_old(\%)
#sub parse_hash
{
	
	my $hash=shift;
	#my $hash=\@_;
	
	# mam tu problem. odkial? -> zle napisana linka.
	my $null;delete $hash->{$null};
	
	main::_log("ideme na pravidla parse_hash") if $debug;
	foreach (keys %{$hash})
	{
		main::_log("key $_") if $debug;
	}
	
	for my $rule(0..@rules-1)
	{
		#print " pravidlo $rule\n" if $main::debug;
		main::_log("pravidlo $rule") if $debug;
#		main::_
		my $true=1;
		foreach my $kluc(keys %{$rules[$rule]{'GET'}})
		{
			#print "  vyzaduje key $kluc\n" if $main::debug;
			main::_log("vyzaduje key $kluc") if $debug;
			
			# porovnanie na hodnotu kluca
			if ($rules[$rule]{'GET'}{$kluc})
			{
				if ($rules[$rule]{'GET'}{$kluc} eq $hash->{$kluc})
				{
					next;
				}
				else
				{
					$true=0;
					last;
				}
			}
			# porovnanie na existenciu kluca
			else
			{
				if (exists $hash->{$kluc})
				{
					next;
				}
				$true=0;
				last
			}
		}
		
		if ($true)
		{
			#print " toto pravidlo preslo\n" if $main::debug;
			#print " idem tvorit URL\n" if $main::debug;
			main::_log("pravidlo preslo") if $debug;
			
			# VYTVORENIE LINKY
			my $URL;
			foreach my $reference(@{$rules[$rule]{'URL'}})
			{
				
				if ($reference->{dynamic}) # ak je tato cast dynamicka
				#if (!$rules[$rule]{'GET'}{$reference->{name}})
				{
					
					
#					if ($reference->{source} eq "cookies")
#					{
#						$hash->{$reference->{name}}=$main::COOKIES{$reference->{name}};
#					}
					
					#TYPE
					if (exists $hash->{$reference->{name}}) # ak obsahuje hash hodnotu pre tuto cast linky
					{
						$URL.=$reference->{before}.$hash->{$reference->{name}}.$reference->{after};
					}
					else
					{
						$URL.=$reference->{before}.$reference->{default}.$reference->{after} if exists $reference->{default};
						$URL.=$reference->{before}."index".$reference->{after} if not exists $reference->{default};
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
			main::_log("idem mazat nepotrebne kluce z hash") if $debug;
			foreach my $kluc(keys %{$rules[$rule]{'GET'}})
			{
#				if ($rules[$rule]{'GET'})
				main::_log("delete key $kluc") if $debug;
				delete $hash->{$kluc};
			}
			
			foreach my $kluc(@{$rules[$rule]{'URL'}})
			{
				#$i++;
				#print "  $i:".$kluc->{name}."\n" if $main::debug;
				if ($kluc->{dynamic}) # ak je tato premenna dynamicka
				{
					main::_log("delete key $kluc->{name}") if $debug;
					delete $hash->{$kluc->{name}};
				}
			}
			
			
			foreach (keys %{$hash})
			{
				main::_log("key $_") if $debug;
			}
			
			
			$URL=~s/\/$/.html/ if $rules[$rule]{type} eq "html";
			#print "URL=$URL\n";
			return $URL;
		}
		else
		{

		}
		
	}
	
	return "index.html";
	
}




sub parse_hash
{
	my $t=track TOM::Debug(__PACKAGE__."::parse_hash()") if $debug;
	
	my $H_www="";
	my $hash=shift;
	
	# problematic hash with undefined keyname
	my $null;delete $hash->{$null};
	
	foreach (keys %{$hash})
	{
		main::_log("input key '$_'='$hash->{$_}'") if $debug;
	}
	
	if ($hash->{'a210_path'})
	{
		
		foreach (grep {defined $_->{'a210_path_prefix'}} @tom::H_www_multi)
		{
			my $a210_path=$hash->{'a210_path'}.'/';
			if ($a210_path=~/^$_->{'a210_path_prefix'}\//)
			{
				$a210_path=~s|^$_->{'a210_path_prefix'}/||;
				$a210_path=~s|/$||;
				$hash->{'a210_path'}=$a210_path;
				
#				main::_log("$tom::H_www to ".$_->{'H'});
				$H_www=$tom::H_www;
				$H_www=~s/(https?:\/\/)(.*)/$1.$_->{'H'}/e;
				last;
			}
		}
		
	}
	
	for my $rule(0..@rules-1)
	{
		my $row=$rules[$rule]->{'row'};
		main::_log("#$row checking rule") if $debug;
		
		my $true=1;
		foreach my $kluc(keys %{$rules[$rule]{'GET'}})
		{
			
			#main::_log("[$rule] key '$kluc' exists") if exists $rules[$rule]{'GET'}{$kluc};
			#main::_log("[$rule] key '$kluc' defined") if defined $rules[$rule]{'GET'}{$kluc};
			
			# porovnanie na hodnotu kluca
			if ($rules[$rule]{'GET'}{$kluc})
			{
				main::_log("#$row proc key '$kluc' requested value '$rules[$rule]{'GET'}{$kluc}'") if $debug;
				if ($rules[$rule]{'GET'}{$kluc} eq $hash->{$kluc})
				{
					next;
				}
				else
				{
					$true=0;
					last;
				}
			}
			elsif (defined $rules[$rule]{'GET'}{$kluc})
			{
				main::_log("#$row proc key '$kluc' requested empty value ''") if $debug;
				if ($rules[$rule]{'GET'}{$kluc} eq $hash->{$kluc})
				{
					next;
				}
				else
				{
					$true=0;
					last;
				}
			}
			# porovnanie na existenciu kluca
			else
			{
				main::_log("#$row proc key '$kluc' requested any value") if $debug;
#				if (defined $hash->{$kluc})
				if ($hash->{$kluc})
				{
					next;
				}
				$true=0;
				last;
			}
		}
		
		if ($true)
		{
			main::_log("#$row rule equals") if $debug;
			
			# VYTVORENIE LINKY
			my $URL;
			foreach my $reference(@{$rules[$rule]{'URL'}})
			{
				
				
#				next unless $kluc->{'test'};
#				my $fnc=$kluc->{'test'};
#				main::_log(" test ".($i-1)." '".($url[$i-1])."' test='".$kluc->{'test'}."'") if $debug;
#				no strict 'refs';
#				if (!$fnc->($url[$i-1],\%hash))
#				{
#					undef $test;
#					last;
#				}
				if ($reference->{'test'})
				{
					my $fnc=$reference->{'test'};
					no strict 'refs';
					$fnc->(\$hash->{$reference->{'name'}},$hash);
					
					$URL.=$reference->{'before'}.$hash->{$reference->{'name'}}.$reference->{'after'};
					
					next;
				}
				elsif ($reference->{'dynamic'}) # ak je tato cast dynamicka
				{
					
					#TYPE
					if (exists $hash->{$reference->{name}}) # ak obsahuje hash hodnotu pre tuto cast linky
					{
						$URL.=$reference->{before}.$hash->{$reference->{name}}.$reference->{after};
					}
					else
					{
						$URL.=$reference->{before}.$reference->{default}.$reference->{after} if exists $reference->{default};
						$URL.=$reference->{before}."index".$reference->{after} if not exists $reference->{default};
						#$URL.="index/" unless $reference->{default};
					}
#					delete $hash->{$reference->{name}};
					next;
				}
				
				$URL.=$reference->{before}.$reference->{name}.$reference->{after};
				
			}
			
			# VYPRAZDNENIE NEPOTREBNEHO Z %HASH
			foreach my $kluc(keys %{$rules[$rule]{'GET'}})
			{
				# pokial na pravej strane pravidla je premennej priradena konkretna
				# hodnota, nemusime si tuto premennu posielat v linke, pretoze pri
				# uplatnovani tohto pravidla budeme vediet aku hodnotu priradit tejto
				# premennej. preto premennu z %form teraz vymazem aby som ju zbytocne
				# neposielal.
				if ($rules[$rule]{'GET'}{$kluc})
				{
					main::_log("delete key '$kluc'") if $debug;
					delete $hash->{$kluc};
				}
			}
			
			foreach my $kluc(@{$rules[$rule]{'URL'}})
			{
				if ($kluc->{dynamic}) # ak je tato premenna dynamicka
				{
					main::_log("delete key '$kluc->{name}'") if $debug;
					delete $hash->{$kluc->{name}};
				}
			}
			
			foreach (keys %{$hash})
			{
				main::_log("output key '$_'") if $debug;
			}
			
			$URL=~s/\/$/.html/ if $rules[$rule]{type} eq "html";
			
			main::_log("output URL '$URL'") if $debug;
			
			$t->close() if $debug;
			return $H_www,$URL;
		}
		else
		{
			
		}
		
	}
	
	main::_log("output default URL 'index.html'") if $debug;
	$t->close() if $debug;
	return $H_www,"index.html";
}


sub test
{
	my $string=shift;
	my $hash=shift;
	if ($string) # this is test
	{
		$hash->{'test'}='test';
		return 1;
	}
	else # this is link generation
	{
		$string='test';
		delete $hash->{'test'};
		return 1;
	}
}


sub parse_URL
{
	my $URL=shift;
	my %metahash;
	
	my $t=track TOM::Debug(__PACKAGE__."::parse_URL()",'timer'=>1);
	
	# odstranim woloviny
	#$URL=~s|^.*?~||;
	
	if ($tom::rewrite_RewriteBase)
	{
		main::_log("cleaning RewriteBase='$tom::rewrite_RewriteBase' from URL") if $debug;
		$URL=~s|^$tom::rewrite_RewriteBase||;
	}
	
	$URL=~s|^/||;
	$URL=~s|\?.*$||;
	
	#main::_log("rewriting '$URL'");
	
	#print "URL je $URL\n" if $main::debug;
	main::_log("URL='$URL'") if $debug;
	
	my @url=();
	
	#print "ideme na pravidla\n" if $main::debug;
	
	for my $rule(0..@rules-1)
	{
		my %hash;
		my $regexp=regexp($rule);
		my $true;
		
		main::_log("rule at row #".$rules[$rule]->{'row'}." '$URL'=~'$regexp'") if $debug;
		
		if (@url=($URL=~/$regexp/))
		{
			
			main::_log("convert by splitted GET") if $debug;
			foreach my $kluc(keys %{$rules[$rule]{'GET'}})
			{
				if ($rules[$rule]{'GET'}{$kluc})
				{
					main::_log("GET: '$kluc'='$rules[$rule]{'GET'}{$kluc}'") if $debug;
					$hash{$kluc}=$rules[$rule]{'GET'}{$kluc};
				}
			}
			
			main::_log("convert by splitted URL") if $debug;
			my $i=-1;
			foreach my $kluc(@{$rules[$rule]{'URL'}})
			{
				$i++;
				main::_log("part $i with variable named '".$kluc->{'name'}."'") if $debug;
				
				if ($kluc->{'dynamic'}) # ak je tato premenna dynamicka
				{
					if ($kluc->{'test'})
					{
						# will be defined by executing test
						next;
					}
					# ak je definovana defaultna hodnota a v URL je tato hodnota
					elsif ((exists $kluc->{'default'})&&($url[$i] eq $kluc->{'default'}))
					{
						next;
					}
					# ak nieje definovana defaultna hodnota a v URL je hodnota "default"
					elsif ((not exists $kluc->{'default'})&&($url[$i] eq "default"))
					{
						next;
					}
					# inak beriem hodnotu v URL ako danu a prevezmem ju
					if ($kluc->{'source'} eq "GET")
					{
						main::_log("GET: '".$kluc->{'name'}."'='".$url[$i]."'") if $debug;
						$hash{$kluc->{'name'}}=$url[$i];
					}
					next;
				}
			}
			
			my $i;
			my $test=1;
			foreach my $kluc(@{$rules[$rule]{'URL'}})
			{
				$i++;
				next unless $kluc->{'test'};
				my $fnc=$kluc->{'test'};
				main::_log(" test ".($i-1)." '".($url[$i-1])."' test='".$kluc->{'test'}."'") if $debug;
				no strict 'refs';
				if (!$fnc->(\$url[$i-1],\%hash))
				{
					undef $test;
					last;
				}
			}
			
			next unless $test;
			
			main::_log("apply rewrite.conf rule #".$rules[$rule]->{'row'}." ~/$regexp/");
			
			%{$metahash{'GET'}}=%hash;
			
			$t->close();
			return %metahash;
		}
		
#		if ($true)
#		{
#			main::_log("converting rule #".$rules[$rule]->{'row'}." to \%hash") if $debug;
#		}
#		else
#		{
#		}
		
	}
	
	main::_log("here is none rule");
	main::_log("here is none rule",0,"warn");
	
	$t->close();
	#main::_log("can't find rewrite rule for link '$URL'",1,"pub.warn") if $debug;
}



sub regexp
{
	my $rule=shift;
	my $regexp="^";
	foreach my $kluc(@{$rules[$rule]{'URL'}})
	{
		$regexp.=$kluc->{before};
		$regexp.="(".$kluc->{regexp}.")" if $kluc->{regexp};
		$regexp.=$kluc->{after};
	}
	$regexp.="\$";
	#main::_log("regexp of rule $rule: '".$regexp."'");
	return $regexp;
}



sub get
{
	my $t=track TOM::Debug(__PACKAGE__."::get()") if $debug;
	main::_log(__PACKAGE__."::get()") unless $debug;
	
	my $data=shift;
	#main::_log("get data to url_rewrite");
	
	@rules=();
	
	my $row;
	foreach my $line(split('\n',$data))
	{
		$row++;
		$line=~s|[\n\r]||g;
		
		my %rule;
		
		next if $line=~/^#/;
		$line=~s| #.*||;
		next unless $line;
		next unless $line=~/\|/;
		#print " spracuvam line: $line\n" if $main::debug;
		
		my $t_line=track TOM::Debug("line '$line'") if $debug;
		#main::_log("$line") unless $debug;
		
		my @sections=split('\|',$line);
		
		#print "  spracuvam sekciu URL: $sections[0]\n" if $main::debug;
		#main::_log("spracuvam sekciu URL: '$sections[0]'");
		
#		main::_log("URL '$sections[0]' GET '$sections[1]'") unless $debug;
		
		my $t_sec=track TOM::Debug("URL '$sections[0]'") if $debug;
		
		$rule{'URL'}=();
		$rule{'row'}=$row;
		
		my $no;$sections[0]=~s/({|})/ $1 eq "{" ? ("<curvy:".$no++.">") : ("<\/curvy:".--$no.">")/eg;
		while ($sections[0]=~s|^(.*?)<curvy:0>(.*?)</curvy:0>||)
		{
			my $before=$1;
			my $url=$2;
				$url=~s|<curvy:\d>|{|g;
				$url=~s|</curvy:\d>|}|g;
			
			main::_log("processing before:'$1' url:'$2'") if $debug;
			
			my %rule_url;
			
			
			$rule_url{'source'}="GET";
			$rule_url{'before'}=$before;
			if ($url=~/;/)
			{
				main::_log("var defined in depth: '$url'") if $debug;
				my @data=split(';',$url);
				$url=shift @data;
				if ($url=~s/^"(.*?)"$/$1/)
				{
					$rule_url{'test'}=$url;
					undef $rule_url{'name'};
				}
				foreach my $data(@data)
				{
					if ($data=~/^default="(.*)"/)
					{
						$rule_url{'default'}=$1;
						main::_log("default='$1'") if $debug;
						next;
					}
					if ($data=~/^regexp="(.*)"/)
					{
						$rule_url{'regexp'}=$1;
						main::_log("regexp='$1'") if $debug;
						next;
					}
					if ($data=~/^source="(.*)"/)
					{
						$rule_url{'source'}=$1;
						main::_log("source='$1'") if $debug;
						next;
					}
					if ($data=~/^test="(.*)"/)
					{
						$rule_url{'test'}=$1;
						main::_log("test='$1'") if $debug;
						next;
					}
				}
			}
			$rule_url{'dynamic'}=1;
			$rule_url{'name'}=$url;
				if ($url=~s/^"(.*?)"$/$1/)
				{
					$rule_url{'test'}=$url;
					undef $rule_url{'name'};
				}
			$rule_url{'regexp'}=".{1,}?" unless $rule_url{'regexp'};
			
			push @{$rule{'URL'}}, {%rule_url};
		}
		
		# nastavime after :))
		if ($rule{'URL'}[0])
		{
			$rule{'URL'}[-1]{after}=$sections[0];# $rule{'URL'}[0]{after}=$sections[0];# if $rule{'URL'}[0];
		}
		else
		{
			$rule{'URL'}[0]{after}=$sections[0];
		}
		
		$t_sec->close() if $debug;
		my $t_sec=track TOM::Debug("GET '$sections[1]'") if $debug;
		
		foreach my $get(split(';',$sections[1]))
		{
			main::_log("processing '$get'") if $debug;
			if ($get=~/(.*)="(.{0,})"/)
			{
				main::_log("exact '$1'='$2'") if $debug;
				$rule{'GET'}{$1}=$2;
			}
			elsif ($get=~/!(.*)/)
			{
				main::_log("empty '$1'") if $debug;
				$rule{'GET'}{$1}='';
			}
			else
			{
				main::_log("dynamic '$get'") if $debug;
				undef $rule{'GET'}{$get};
			}
		}
		
		$t_sec->close() if $debug;
		
		push @rules,{%rule};
		
		$t_line->close() if $debug;
		
	}
	
	$t->close() if $debug;
}




sub convert
{
	my $URL=shift;
	my %env=@_;
	
	$URL=Int::charsets::encode::UTF8_ASCII($URL); 
	$URL=lc($URL);# unless $env{'notlower'};
	
	# convert znakov ktore chcem zachovat v kontexte
#	$URL=~s|;|-|g;
#	$URL=~s|[/]|-|g;
	$URL=~s|\N{NO-BREAK SPACE}| |g;
	$URL=~s|[/\(\) \.;]|-|g;
	
	# uplne odstranenie nevhodnych znakov
	$URL=~s|[^a-zA-Z0-9\._\- ]||g;
	
	# odstranenie duplicit
#	1 while ($URL=~s|__|_|g);
	1 while ($URL=~s|_-|-|g);
	1 while ($URL=~s|-_|-|g);
	1 while ($URL=~s|--|-|g);
	
	# odstranit znaky na konci ktore niesu sucastou slova
	1 while ($URL=~s|[^a-zA-Z0-9]$||g);
	
	return $URL;
}

















1;
