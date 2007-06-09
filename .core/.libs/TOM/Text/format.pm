#!/bin/perl
package TOM::Text::format;
use strict;
#our @ISA=("App::0::SQL_old"); # pytam si abstrakciu

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

sub xml2plain
{
	my $text=shift;
	
	# odstranenie dvojiteho odriadkovania
	$text=~s|[\r\n]||g;
	#$text=~s|<p[ ]?[/]?>\n|\n|gsi;
	#$text=~s|<br[ ]?[/]?>\n|\n|gsi;
	
	# vytvorenie riadkov
	$text=~s|<div[ ]?[/]?>|\n|gsi;
	$text=~s|<p[ ]?[/]?>|\n|gsi;
	$text=~s|<br[ ]?[/]?>|\n|gsi;
	
	# rusenie trojitych odriatkovani
	1 while ($text=~s|\n\n\n|\n\n|g);
	
	1 while ($text=~s|^\n||g);
	
	1 while ($text=~s|\n\n$|\n|g);
	
	# vyhodime XML tagy
	$text=~s|<.*?>||gs;
	
	return $text;
}


sub plain_logical # uprava logiky textu
{
	my $text=shift;
	
	# odstranim zbytocne znaky za pomlckou na konci riadku
	$text=~s|-(\W+)\n|-\n|gs;
	
#	$text=~s|-(\W+)\n|-\n|gs;
	
	# spojenie rozdelenych slov na konci riadku
	#$text=~s|(\w+)-\n(\w+)|$1$2|gs;
	$text=~s|([\wáéíoúňčžšň]+)-[\s+]([\wáéíoúňčžšň]+)|$1$2|gs;
	
#	$text=~s|(\w+)- ||gs;
	
	return $text;
}



sub USmoney
{
	my $money=shift;
	$money=sprintf("%2.2f",$money);
	$money=~s|([^,\-])(\d\d\d)\.|$1,$2\.|;
	while ($money=~s|([^,\-])(\d\d\d),|$1,$2,|g){1};
	return $money;
}



sub bytes
{
	my $size=shift;
	my $size_symb='B';
	if ($size > 1024){$size=$size/1024;$size_symb='KB';}
	if ($size > 1024){$size=$size/1024;$size_symb='MB';}
	if ($size > 1024){$size=$size/1024;$size_symb='GB';}
	$size=int($size*10)/10;
	if ((not $size=~s|\.|,|) && ($size_symb ne "B")){$size.=',0'}
	return $size.' '.$size_symb;
}



use TOM::Net::URI::URL;
use Net::HTTP::CGI;
use MIME::Base64;
use enc3;

# TOM::Text::format::decode_URLS
sub decode_URLS
{
	my $text=shift;
	
	while ($text=~s/\?(__|\|\|)([a-zA-Z0-9\-\/]+)/<!TMPURLDEC!>/)
	{
		my $uri=$2;
		if ($uri=~/^(.*)-(.*?)-v([\d]+)$/)
		{
			my ($ver,$code,$url)=($3,$2,$1);
			if ($ver eq "2")
			{
				main::_log("unsupported enc2 encoding of url",1);
			}
			elsif ($ver eq "3")
			{
				
				while ($url=~/%/){$url=TOM::Net::URI::URL::url_decode($url)};
				$url=MIME::Base64::decode_base64($url."==");
				
				my $query=TOM::Net::URI::URL::url_decode(enc3::xor($url,$tom::code_keys{$code}{key}));
				my %form=Net::HTTP::CGI::GetQuery_l($query);
				# kontrola spravnosti rozparsovania - pravdepodobnosti normalnej linky
				my $bad;foreach (keys %form){$bad=1 if $_=/[^a-zA-Z0-9_\-]/;}
				if (!$bad)
				{
					$text=~s|<!TMPURLDEC!>|?\|?$query|;
				}
			}
		}
		else
		{
			#print "unknown link type\n";
		}
		#print "-$2\n";
		$text=~s|<!TMPURLDEC!>|?__$uri|;
	}
	
	return $text;
}







our %HTML_tag_attr=
(
	'table' => {'cellspacing'=>1, 'cellpadding'=>1, 'border'=>1},
	'a' => {'href' => 1},
);

our %HTML_tag_ok=
(
	'sup'=>1,
	'div'=>1,
	'span'=>1,
	'strong'=>1,
	'em'=>1,
	'table'=>1,
	'tbody'=>1,
	'tfoot'=>1,
	'tr'=>1,
	'td'=>1,
	'th'=>1,
	'caption'=>1,
	'p'=>1,
	'br'=>1,
	'hr'=>1,
	'blockquote'=>1,
	'address'=>1,
	'ul'=>1,
	'ol'=>1,
	'li'=>1,
	'dd'=>1,
	'dt'=>1,
	'dl'=>1,
	'a'=>1,
);


our %HTML_tag_translate=
(
	'b' => 'strong',
	'i' => 'em',
);


our %HTML_tag_unpair=
(
	'br' => 1,
	'hr' => 1,
);

# $text=TOM::Text::format::html_clean($text);
sub html_clean
{
	my $data=shift;
	
	$data=~s|[\n\r]||g;
	
	# mazanie zlych atributov
	while ($data=~s|<([/]?)(.*?)([/]?)>|!!!TAG!!!|)
	{
		my $pre=$1;
		my $tag=$2;$tag=~s|^(\w+)(.*)$|$1|;
		my $attr=$2;
		$tag="\L$tag";
		$tag=~s|^\s+||;$tag=~s|\s+$||;
		$attr=~s|style=["'].*?["']||;
		$attr=~s|^\s+||;$attr=~s|\s+$||;
		my $post=$3;
		
		# tento tag menim na iny
		if ($HTML_tag_translate{$tag})
		{
			$tag=$HTML_tag_translate{$tag};
		}
		
		# upravim neparovy tag
		if ($HTML_tag_unpair{$tag})
		{
			$pre="";
			$post=" /";
		}
		
		# ZAMENY
		
		if ($HTML_tag_ok{$tag})
		{
			my %attrs;
			my $attr_new;
			while ($attr=~s|(\w+)=((\w+)\|["'].*?["'])||)
			{
				my $a="\L$1";
				if ($HTML_tag_attr{$tag}{$a})
				{
					$attrs{$a}=$2;
				}
			}
			
			$attr="";
			foreach (keys %attrs)
			{
				$attr.=" ".$_."=\"".$attrs{$_}."\"";
			}
			
			$data=~s|!!!TAG!!!|!!![!!!$pre$tag$attr$post!!!]!!!|;
		}
		
		$data=~s|!!!TAG!!!||;
		
	}
	
	$data=~s|!!!\[!!!|<|g;
	$data=~s|!!!\]!!!|>|g;
	
	
	1 while ($data=~s|<([\w]+)></\1>||gs);
	
	# odstranenie zbytocnych DIV
	1 while ($data=~s|^<div><div>(.*)</div></div>$|<div>$1</div>|gs);
	
	
	# rozne necistoty logiky textu
	$data=~s|<br />&nbsp;<br />|<br /><br />|g;
	
	
	# logicke roztriedenie
	$data=~s|(<br />\|</div>\|</table>\|<table.*?>\|</tr>\|</td>\|<tr.*?>)|$1\n|g;
	$data=~s|(</p>\|</papa>)|$1\n\n|g;
	
	
		
	return $data;
}







1;