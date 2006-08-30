#!/bin/perl
# TODO: [Aben] Trosku to tu precistit a mozno spravit objektove

=head1 PRIKLAD
TOM::Net::URI::rewrite::get($file);
TOM::Net::URI::rewrite::parse_hash(%form);
my $hash=TOM::Net::URI::rewrite::parse_URL("http://spravy.markiza.sk/~USRM/edit.html?asdfhojsdf-A1-v2");
=cut

package TOM::Net::URI::rewrite;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

use Digest::MD5  qw(md5 md5_hex md5_base64);
use Int::charsets::encode;

my $debug=0;

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
#sub parse_hash
{
	my $t=track TOM::Debug(__PACKAGE__."::parse_hash()");
	
	#my $hash=shift;
	my $hash=shift;
	
	# mam tu problem. odkial? -> zle napisana linka.
	my $null;delete $hash->{$null};
	
	foreach (keys %{$hash})
	{
		main::_log("input key '$_'='$hash->{$_}'") if $debug;
	}
	
	main::_log("finding right rule") if $debug;
	
	for my $rule(0..@rules-1)
	{
		#print " pravidlo $rule\n" if $main::debug;
		main::_log("rule '$rule'") if $debug;
#		main::_
		my $true=1;
		foreach my $kluc(keys %{$rules[$rule]{'GET'}})
		{
			#print "  vyzaduje key $kluc\n" if $main::debug;
			main::_log("vyzaduje key '$kluc'") if $debug;
			
#			if ('type' eq $kluc)
#			{
#				main::_log("0 type=type");
#			}
			
#			if (exists $hash->{$kluc})
#			{
#				main::_log("1 existuje key '$kluc'");
#			}
			
#			if (exists $hash->{'type'})
#			{
#				main::_log("2 existuje key 'type'");
#			}
			
			# porovnanie na hodnotu kluca
			if ($rules[$rule]{'GET'}{$kluc})
			{
				main::_log("vyzadovana hodnota '$rules[$rule]{'GET'}{$kluc}'") if $debug;
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
				main::_log("vyzadovana existencia '$kluc'='".($hash->{$kluc})."' ") if $debug;
				#if (exists $hash->{$kluc})
				if (exists $hash->{$kluc})
				{
					main::_log("existuje") if $debug;
					next;
				}
				main::_log("neexistuje") if $debug;
				$true=0;
				last;
			}
		}
		
		if ($true)
		{
			main::_log("rule with number $rule is the right") if $debug;
			
			# VYTVORENIE LINKY
			my $URL;
			foreach my $reference(@{$rules[$rule]{'URL'}})
			{
				
				if ($reference->{dynamic}) # ak je tato cast dynamicka
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
=head1
			foreach my $kluc(keys %{$rules[$rule]{'GET'}})
			{
				main::_log("delete key $kluc");
				delete $hash->{$kluc};
			}
=cut
			#main::_log("idem mazat nepotrebne kluce z hash");
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
				main::_log("output key '$_'") if $debug;
			}
			
			
			$URL=~s/\/$/.html/ if $rules[$rule]{type} eq "html";
			#print "URL=$URL\n";
			
			main::_log("output URL '$URL'") if $debug;
			
			$t->close();
			return $URL;
		}
		else
		{

		}
		
	}
	
	main::_log("output default URL 'index.html'") if $debug;
	$t->close();
	return "index.html";
}




sub parse_URL
{
	my $URL=shift;
	my %metahash;
	my %hash;
	my %hash_cookies;
	
	my $t=track TOM::Debug(__PACKAGE__."::parse_URL()");
	
	# odstranim woloviny
	#$URL=~s|^.*?~||;
	
	if ($tom::rewrite_RewriteBase)
	{
		main::_log("cleaning RewriteBase='$tom::rewrite_RewriteBase' from URL") if $debug;
		$URL=~s|^$tom::rewrite_RewriteBase||;
	}
	
	$URL=~s|^/||;
	#$URL=~s|^.*?-||;
#	$URL=~s|^(.*)\.html.*|$1|;
	$URL=~s|\?.*$||;
	
	#main::_log("rewriting '$URL'");
	
	#print "URL je $URL\n" if $main::debug;
	main::_log("URL='$URL'") if $debug;
	
	my @url=();
	
	#print "ideme na pravidla\n" if $main::debug;
	
	for my $rule(0..@rules-1)
	{
		
		#main::_log("rule $rule");
		
		my $regexp=regexp($rule);
		my $true;
		
		main::_log("rule $rule '$URL'=~'$regexp'") if $debug;
		
		if (@url=($URL=~/$regexp/))
		{
			main::_log("success") if $debug;
			$true=1;
		}
		
		if ($true)
		{
			main::_log("converting rule '$rule' to \%hash") if $debug;
			#print " priradujem podla URL dynamicke\n" if $main::debug;
			
			# ------------------------------
			#return %metahash;
			# ------------------------------
			
			
			main::_log("convert by splitted URL");
			my $i=-1;
			foreach my $kluc(@{$rules[$rule]{'URL'}})
			{
				$i++;
				main::_log("part $i with variable named '".$kluc->{name}."'") if $debug;
				
				if ($kluc->{dynamic}) # ak je tato premenna dynamicka
				{
					# ak je definovany defaultna hodnota a v URL je tato hodnota
					if ((exists $kluc->{default})&&($url[$i] eq $kluc->{default}))
					{
						next;
					}
					# ak nieje definovana defaultna hodnota a v URL je hodnota "default"
					elsif ((not exists $kluc->{default})&&($url[$i] eq "default"))
					{
						next;
					}
					# inak beriem hodnotu v URL ako danu a prevezmem ju
					if ($kluc->{source} eq "GET")
					{
						main::_log("GET: '".$kluc->{name}."'='".$url[$i]."'") if $debug;
						$hash{$kluc->{name}}=$url[$i];
					}
					next;
				}
			}
			
			main::_log("convert by splitted GET");
			foreach my $kluc(keys %{$rules[$rule]{'GET'}})
			{
				if ($rules[$rule]{'GET'}{$kluc})
				{
					main::_log("GET: '$kluc'='$rules[$rule]{'GET'}{$kluc}'") if $debug;
					$hash{$kluc}=$rules[$rule]{'GET'}{$kluc};
				}
			}
			
			%{$metahash{'GET'}}=%hash;
			
			$t->close();
			return %metahash;
		}
		else
		{
		}
		
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
	my $t=track TOM::Debug(__PACKAGE__."::get()");
	
	my $data=shift;
	main::_log("get data to url_rewrite");
	
	@rules=();
	
	foreach my $line(split('\n',$data))
	{
		$line=~s|[\n\r]||g;
		
		my %rule;
		
		next if $line=~/^#/;
		$line=~s| #.*||;
		next unless $line;
		next unless $line=~/\|/;
		#print " spracuvam line: $line\n" if $main::debug;
		
		my $t_line=track TOM::Debug("line '$line'");
		
		my @sections=split('\|',$line);
		
		#print "  spracuvam sekciu URL: $sections[0]\n" if $main::debug;
		#main::_log("spracuvam sekciu URL: '$sections[0]'");
		
		my $t_sec=track TOM::Debug("URL '$sections[0]'");
		
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
			#$rule_url{regexp}=".{1,}?" unless $rule_url{regexp};
			$rule_url{regexp}=".{1,}?" unless $rule_url{regexp};
			
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
		
		$t_sec->close();
		my $t_sec=track TOM::Debug("GET '$sections[1]'");
		
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
		
		$t_sec->close();
		
		push @rules,{%rule};
		
		$t_line->close();
		
	}
	
	$t->close();
}




sub convert
{
	my $URL=shift;
	my %env=@_;
	
	$URL=Int::charsets::encode::UTF8_ASCII($URL); 
	$URL="\L$URL" unless $env{'notlower'};
	$URL=~s|\s|-|g;
	$URL=~s|[;,]|_|g;
	$URL=~s|[/\(\)\.]|-|g;
	1 while ($URL=~s|--|-|g);
	
	$URL=~s|[_-]$||g;
	
	return $URL;
}

















1;