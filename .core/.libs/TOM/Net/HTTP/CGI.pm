#!/usr/bin/perl
# DEFINUJEM PREMENNE V OBLASTI MODULOV
package TOM::Net::HTTP::CGI;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
use TOM::Net::URI::URL;
use Text::Iconv;
use MIME::Base64;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

my $ISO_UTF = Text::Iconv->new("ISO-8859-1", "UTF-8");
my $ISO2_UTF = Text::Iconv->new("ISO-8859-2", "UTF-8");



# maximalny import z GET, POSTU a zaroven i POST MULTIPART
## zvlada navyse polia, v pripade ?type[]=ahoj&type[]=bebebe
## sa vytvori pole $form{type}[0],$form{type}[1],...

sub GetQuery
{
	my $t=track TOM::Debug(__PACKAGE__."::GetQuery()");
	my $query=shift;
	my %env=@_;
	
	main::_log("GET processing '$query'");
	
	my %form;
	foreach (split('&',$query))
	{
		next unless $_;
		my ($name,$value)=split('=',$_);
		utf8::encode($value);
		utf8::decode($value);
		
		# neviem preco toto bolo predtym odkomentovane.
		# neviem preco som nepovoloval znak + v QUERY_STRING;
		#$value =~tr/+/ /;
		
		# su tu UTF-8 sekvencie
		if ($value=~/%(C3|C4|C5)%([0-9A-Fa-f]{2})/i)
		{
			main::_log("utf-8 sequence");
			utf8::encode($value);
			#$value=~s/%([0-9A-Fa-f]{2})/pack("C",hex($1))/eg;
			TOM::Net::URI::URL::url_decode_($value);
			utf8::decode($value);
		}
		
		# su tu ISO-8859-2 sekvencie
		if ($value=~/%([0-9A-Fa-f]{2})/)
		{
			main::_log("iso-8859-2 sequence");
			utf8::encode($value);
			#$value=~s/%([0-9A-Fa-f]{2})/pack("C",hex($1))/eg;
			TOM::Net::URI::URL::url_decode_($value);
			$value = $ISO2_UTF->convert($value);
			utf8::decode($value);
		}
		
		if ($name=~s/\[\]$//){push @{$form{$name}},$value;}else{$form{$name}=$value;}
		
		main::_log("'$name'='".$value."'");
	}
	
	
	if ($env{'-lite'})
	{
		$t->close();
		return %form;
	}
	
	
	my $ct=$ENV{CONTENT_TYPE};
	
	main::_log("CONTENT_TYPE='$ct'");
	
	if ($ct=~/^multipart/)
	{
		main::_log("POST MULTIPART processing");
		#read(STDIN,my $buffer,$ENV{'CONTENT_LENGTH'}); # POST
		
		my $i;
		my $boundary;if ($ct=~/boundary=(.*)$/i){$boundary=$1;}
		main::_log("boundary='$boundary'");
		read(STDIN,my $buffer,$ENV{'CONTENT_LENGTH'});
		main::_log("readed to buffer ($ENV{'CONTENT_LENGTH'} bytes)");
		
		foreach my $parse(split /\r?\n?--$boundary-?-?\r\n/, $buffer)
		{
			my ($head,$data) = split (/\r\n\r\n/,$parse,2);
			$form{multipart}.="head:$head\n";
			
			# v pripade ze nejde o poslany subor (teda binarne data)
			# tak na data zapinam utf8
			if (not $head=~/filename=/)
			{
				#main::_log("setting to '$head' utf8");
				utf8::decode($data);
			}
			
			if ($head=~/Content-Transfer-Encoding: base64/)
			{
				$data=MIME::Base64::decode_base64($data);
			}
			elsif ($head=~/Content-Transfer-Encoding: quoted-printable/)
			{
				#$data=MIME::Base64::decode_base64($data);
				TOM::Net::URI::URL::url_decode_($data);
			}
			
			if ($head=~/name="?([\w\[\]]+)"?/i)
			{
				my $name=$1;
				if ($name=~s/\[\]$//){push @{$form{$name}},$data;}else{$form{$name}=$data;}
				main::_log("'$name'='".$data."'");

				if ($TOM::DEBUG_log_file==99)
				{
					open(FOUT,">../_logs/_debug/".$main::request_code."-".$name);
					binmode(FOUT);
					print FOUT $data;
					close (FOUT);
				}

			}
			# pridam spracovanie filesov
			if ($head=~/filename=/)
			{

				#if ($name=~s/\[\]$//){push @{$form{$name}},$data;}else{$form{$name}=$data;}
				# v pripade ze ide o pole, treba poslednemu prvku v poli priradit
				# _filename='nieco'
				#main::_log("...filename");
			}
			else
			{
				#utf8::encode($value);
			}
		}
		
		
	}
	elsif ($ct=~/^text\/plain/)
	{
		main::_log("POST TEXT/PLAIN processing");
		read(STDIN,my $buffer,$ENV{'CONTENT_LENGTH'}); # POST
		$buffer=~s|\n|&|g;
		foreach (split('&',$buffer))
		{
			my ($name,$value)=split('=',$_);
			$value =~ s/[\n\r]//g;
			$value =~ s/\+/ /g;
			#$value=~s/%([0-9A-Fa-f]{2})/pack("C",hex($1))/eg;
			TOM::Net::URI::URL::url_decode_($value);
			if ($name=~s/\[\]$//){push @{$form{$name}},$value;}else{$form{$name}=$value;}
			main::_log("'$name'='".$value."'");
		}
	}
	elsif ($ENV{'CONTENT_LENGTH'})
	{
		main::_log("POST ??? processing");
		read(STDIN,my $buffer,$ENV{'CONTENT_LENGTH'}); # POST
		foreach (split('&',$buffer))
		{
			my ($name,$value)=split('=',$_);
			$value =~ s/\+/ /g;
			#$value=~s/%([0-9A-Fa-f]{2})/pack("C",hex($1))/eg;
			utf8::encode($value);
			TOM::Net::URI::URL::url_decode_($name);
			TOM::Net::URI::URL::url_decode_($value);
			utf8::decode($value);
			if ($name=~s/\[\]$//){push @{$form{$name}},$value;}else{$form{$name}=$value;}
			
			main::_log("'$name'='".$value."'");
		}
	}
 
 $t->close();
 return %form;
}

1;
