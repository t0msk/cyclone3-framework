#!/usr/bin/perl
#use utf8;
#use encoding 'utf8';
use strict;

# DEFINUJEM PREMENNE V OBLASTI MODULOV
package Net::HTTP::CGI;
use strict;
#use warnings;
use vars qw/
	@ISA
	@EXPORT
	/;
use Exporter;
@ISA=qw/Exporter/;
@EXPORT=qw/
	GetQuery_l
	GetQuery_h
	GetQuery_h2
	/;
	
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

#@EXPORT_OK=qw/%form/; len ak si to vynutim

=head1
sub GetQuery_l
{
 my %form;
 my $name_value_pair;
 my @name_value_pairs=split('&',$ENV{'QUERY_STRING'}); # GET
 foreach $name_value_pair (@name_value_pairs)
 {
	my ($name,$value)=split('=',$name_value_pair);
	$value =~tr/+/ /;
	$value=~s/%([0-9A-Fa-f]{2})/pack("C",hex($1))/eg; # URL decode
	#$value =~s|\x7c|<--PIPE-->|g; # convert | to <--PIPE-->
	$form{$name}=$value;
 }

 read(STDIN,my $buffer,$ENV{'CONTENT_LENGTH'}); # POST
 @name_value_pairs=split('&',$buffer);
 foreach $name_value_pair (@name_value_pairs)
	{
	my ($name,$value)=split('=',$name_value_pair);       
	$value =~ s/\+/ /g;
	$value=~s/%([0-9A-Fa-f]{2})/pack("C",hex($1))/eg;
	#$value =~s|\x7c|<--PIPE-->|g;
	$form{$name}=$value;
	}
 return %form;
}
=cut
sub GetQuery_l
{
 my $query=shift;
 my %form;
 foreach my $pair (split('&',$query))
 {
	my ($name,$value)=split('=',$pair);
	$value =~tr/+/ /;
	$value=~s/%([0-9A-Fa-f]{2})/pack("C",hex($1))/eg; # URL decode
	#$value =~s|\x7c|<--PIPE-->|g; # convert | to <--PIPE-->
	$form{$name}=$value;
 }
 return %form;
}


sub GetQuery_h
{
 my %form;
 my $name_value_pair;
 my @name_value_pairs=split('&',$ENV{'QUERY_STRING'}); # GET
 foreach $name_value_pair (@name_value_pairs)
 {
	my ($name,$value)=split('=',$name_value_pair);   
	$value =~tr/+/ /;
	$value=~s/%([0-9A-Fa-f]{2})/pack("C",hex($1))/eg; # URL decode
	#$value =~s|\x7c|<--PIPE-->|g; # convert | to <--PIPE-->
	$form{$name}=$value;
 }

 my $ct=$ENV{CONTENT_TYPE};
 
 if ($ct=~/^multipart/)
 {
  $form{multipart}=$ct."<BR>";
  read(STDIN,my $buffer,$ENV{'CONTENT_LENGTH'}); # POST
  my $boundary;
  if ($ct=~/boundary=(.*)$/i){$boundary=$1;}
  $form{multipart}.="boundary:".$ct."<BR>";
  $form{multipart}.="boundary:".$boundary."<BR>";
  foreach my $parse(split /\r?\n?--$boundary-?-?\r\n/, $buffer)
  {
   my ($head,$data) = split (/\r\n\r\n/,$parse,2);
   $form{multipart}.="head:$head<BR>data:".length($data)."<BR>";
   if ($head=~/name="?(\w+)"?/i)
   {
    $form{$1}=$data;
   }
  } 
 }
 else
 {
  read(STDIN,my $buffer,$ENV{'CONTENT_LENGTH'}); # POST
  @name_value_pairs=split('&',$buffer);
  foreach $name_value_pair (@name_value_pairs)
 	{
	my ($name,$value)=split('=',$name_value_pair);       
	$value =~ s/\+/ /g;
	$value=~s/%([0-9A-Fa-f]{2})/pack("C",hex($1))/eg;
	#$value =~s|\x7c|<--PIPE-->|g;
	$form{$name}=$value;
	}
 }
 return %form;
}




# maximalny import z GET, POSTU a zaroven i POST MULTIPART
## zvlada navyse polia, v pripade ?type=ahoj&type=bebebe
## sa vytvori pole $form{type}[0],$form{type}[1],...
# polia som zrusil, boli priiiserne neprakticke :)
sub GetQuery_h2
{
 my $query=shift;
 my %form;
# my @name_value_pairs=split('&',$ENV{'QUERY_STRING'}); # GET
# foreach $name_value_pair (@name_value_pairs)
 #my $query=$ENV{'QUERY_STRING'};
 foreach (split('&',$query))
 {
	next unless $_;
	my ($name,$value)=split('=',$_);
	$value =~tr/+/ /;
	$value=~s/%([0-9A-Fa-f]{2})/pack("C",hex($1))/eg; # URL decode
	#$value =~s|\x7c|<--PIPE-->|g; # convert | to <--PIPE-->
	if ($name=~s/\[\]$//){push @{$form{$name}},$value;}else{$form{$name}=$value;}
	main::_log("GET $name=".$value);
#	Tomahawk::debug::log(9,"GET $name=".$value);
 }

 #main::_log("CONTENT_TYPE=".$ENV{CONTENT_TYPE});
 #main::_log("CONTENT_LENGTH=".$ENV{CONTENT_LENGTH});

 my $ct=$ENV{CONTENT_TYPE};

 if ($ct=~/^multipart/)
 {
   main::_log("multipart process..");
  #no strict;
#  $form{multipart}=$ct."<BR>";
  read(STDIN,my $buffer,$ENV{'CONTENT_LENGTH'}); # POST
  my $boundary;
  if ($ct=~/boundary=(.*)$/i){$boundary=$1;}
#  $form{multipart}.="boundary:".$ct."<BR>";
#  $form{multipart}.="boundary:".$boundary."<BR>";
  foreach my $parse(split /\r?\n?--$boundary-?-?\r\n/, $buffer)
  {
   my ($head,$data) = split (/\r\n\r\n/,$parse,2);
   $form{multipart}.="head:$head\n";
   if ($head=~/name="?([\w\[\]]+)"?/i)
   {
	my $name=$1;
	if ($name=~s/\[\]$//)
	{
		push @{$form{$name}},$data;
		main::_log("POST+ $name=".$data);
	}
	else
	{
		$form{$name}=$data;
		main::_log("POST $name=".$data);
	}
   }
  }
 }
 elsif ($ct=~/^text\/plain/)
 {
  main::_log("text/plain process..");
  #main::_log("read STDIN");
  read(STDIN,my $buffer,$ENV{'CONTENT_LENGTH'}); # POST
  #main::_log("buffer=".$buffer);
  #@name_value_pairs=split('&',$buffer);
  $buffer=~s|\n|&|g;
  foreach (split('&',$buffer))
	{
	 my ($name,$value)=split('=',$_);
	 $value =~ s/[\n\r]//g;
	 $value =~ s/\+/ /g;
	 $value=~s/%([0-9A-Fa-f]{2})/pack("C",hex($1))/eg;
	 #$value =~s|\x7c|<--PIPE-->|g;
	 #$form{$name}=$value;
	 if ($name=~s/\[\]$//){push @{$form{$name}},$value;}else{$form{$name}=$value;}
	 main::_log("POST $name=".$value);
#	 Tomahawk::debug::log(9,"POST $name=".$value);
	}
 }
 else
 {
  #main::_log("other process..");
  #main::_log("read STDIN");
  read(STDIN,my $buffer,$ENV{'CONTENT_LENGTH'}); # POST
  #main::_log("buffer=".$buffer);
  #@name_value_pairs=split('&',$buffer);
  foreach (split('&',$buffer))
 	{
	 my ($name,$value)=split('=',$_);
	 $value =~ s/\+/ /g;
	 $value=~s/%([0-9A-Fa-f]{2})/pack("C",hex($1))/eg;
	 #$value =~s|\x7c|<--PIPE-->|g;
	 #$form{$name}=$value;
	 if ($name=~s/\[\]$//){push @{$form{$name}},$value;}else{$form{$name}=$value;}
	 main::_log("POST $name=".$value);
	}
 }
 
# foreach (keys %form)
# {
# 	main::_log("$_ = $form{$_}");
# }
 
 return %form;
}

1;
