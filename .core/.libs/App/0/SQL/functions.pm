#!/bin/perl
package App::0::SQL::functions;
use App::0::SQL;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

#
# robi COLLECT veci do SELECT * ako SELECT a400.nieco,a400.nieco
#
sub s_what_collect
{
 my $self=shift;
 my %hash;
 $self->{s_what}="";
 foreach my $line(@_){$hash{$line}=1}
 foreach (keys %hash){$self->{s_what}.=$_.",";}
 $self->{s_what}=~s|,$||;  
}

#
# generujem syntax WHERE do QUERY z $self->{Query_hash} aby som zachytil
# unikatnost riadku podla PRIMARY kluca definovaneho v poli @PRIMARY
# v objecte tabulky (App::400::SQL::a400)
#
sub generate_primarywhere
{
 my $self=shift;
 die "object not defined" unless $self;
 die "cannot generate_primarywhere out of select" unless $self->{Query_hash};
 my $s_where;
 foreach (@{$self->{PRIMARY}})
 {
  my ($key,$pre)=($_);
  $key=~s|^(.*?)\.|| && do {$pre="$1."};
  $s_where.="AND ".$pre.$key."='".$self->{Query_hash}{$key}."' ";
 }
 $s_where=~s|^AND ||;
 
 return $s_where;
}

sub normalize_select
{
	my $text=shift;
	my $no=0;my %string;
	while ($text=~s|([^\\])(["'])(.*?)([^\\])\2|<!REGEXP-$no!>|){$string{$no}=$1.$2.$3.$4.$2;$string{$no}=~s|([()])|\\$1|g;$no++;}
	1 while ($text=~s|([()])([()])|$1 $2|g);
	$text=~s|<!REGEXP-(\d+)!>|$string{$1}|g;
	
	# uprava podla vnorenia
	my $no;$text=~s/([^\\])([()])/ $2 eq "(" ? ($1."({".$no++."} ") : ($1." {".--$no."})")/eg;
	
	# aby som mohol parsovat...
	$text=";".$text.";";
	
	# definicia pola
	my @arr;
	
	# najprv vyparsujem vnorene zatvorky
	while ($text=~s|(.*)[,;](.*?\(\{0\}.*?\{0\}\).*?)[,;]|$1;|)
	{
		my $value=$2;
		next unless $value;
		# zrusim jedno lomenie (
		$value=~s|\\([()])|$1|g;
		# zrusim hlbky
		$value=~s|\({\d+} |(|g;
		$value=~s| {\d+}\)|)|g;
		push @arr,$value;
	}
	
	# zrusim jedno lomenie (
	$text=~s|\\([()])|$1|g;
	# zrusim hlbky
	$text=~s|\({\d+} |(|g;
	$text=~s| {\d+}\)|)|g;
	# zrusim dvojite ; alebo ,
	$text=~s|([;,])\s+|$1|g;
	$text=~s|\s+([;,])|$1|g;
	$text=~s|[;,][;,]|;|g;
	$text=~s|^[;,]||;
	$text=~s|[;,]$||;
	
	# potom normalne parsovanie
	push @arr,split(',|;',$text);
	return @arr;
}

1;
