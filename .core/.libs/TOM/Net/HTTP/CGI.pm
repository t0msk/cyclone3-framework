#!/usr/bin/perl
# DEFINUJEM PREMENNE V OBLASTI MODULOV
package TOM::Net::HTTP::CGI;

=head1 NAME

TOM::Net::HTTP::CGI

=cut

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DESCRIPTION

Functions above CGI to handle it actions

=cut

=head1 DEPENDS

=over

=item *

Text::Iconv

=item *

MIME::Base64

=item *

L<TOM::Net::URI::URL|source-doc/".core/.libs/TOM/Net/URI/URL.pm">

=back

=cut

$CGI::POST_MAX=1024*1024*200; # 200MB
$CGI::POST_MAX_USE=1024*1024*20; # 20MB

use Text::Iconv;
use MIME::Base64;
use TOM::Net::URI::URL;
use Data::Dumper;


my $ISO_UTF = Text::Iconv->new("ISO-8859-1", "UTF-8");
my $ISO2_UTF = Text::Iconv->new("ISO-8859-2", "UTF-8");



=head1 FUNCTIONS

=head2 GetQuery()

Returns %form from parsed QUERY_STRING and STDIN ( the old way )

=cut

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
		if ($value=~/%(C2|C3|C4|C5)%([0-9A-Fa-f]{2})/i)
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
		
		my $i;
		my $boundary;if ($ct=~/boundary=(.*)$/i){$boundary=$1;}
		main::_log("boundary='$boundary'");
		read(STDIN,my $buffer,$ENV{'CONTENT_LENGTH'});
		main::_log("readed to buffer ($ENV{'CONTENT_LENGTH'} bytes)");
		
		foreach my $parse(split /\r?\n?--$boundary-?-?\r\n/, $buffer)
		{
			my ($head,$data) = split (/\r\n\r\n/,$parse,2);
			$form{multipart}.="head:$head\n";
			
			if (not $head=~/filename=/)
			{
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
				
#				if ($head=~/filename=/)
#				{
#					$form{$name}->{'location'}="file://$name";
#				}
#				else
#				{
					if ($name=~s/\[\]$//){push @{$form{$name}},$data;}else{$form{$name}=$data;}
#				}
				
				if (length($data)<1024)
				{main::_log("'$name'='".$data."'");}
				else {main::_log("'$name'=length(".length($data).")");}
				
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




sub get_QUERY_STRING
{
	my $query=shift;
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::get_QUERY_STRING()") unless $env{'quiet'};
	
	main::_log("GET processing '$query'") unless $env{'quiet'};
	
	my %form;
	foreach (split('&',$query))
	{
		next unless $_;
		my ($name,$value)=split('=',$_);
		
		# NAME
		
		utf8::encode($name);
		utf8::decode($name);
		# su tu UTF-8 sekvencie
		if ($name=~/%(D0|D1|C2|C3|C4|C5)%([0-9A-Fa-f]{2})/i)
		{
			main::_log("utf-8 sequence") unless $env{'quiet'};
			utf8::encode($name);
			TOM::Net::URI::URL::url_decode_($name);
			utf8::decode($name);
		}
		# su tu ISO-8859-2 sekvencie
		elsif ($name=~/%([0-9A-Fa-f]{2})/)
		{
			main::_log("iso-8859-2 sequence") unless $env{'quiet'};
			utf8::encode($name);
			TOM::Net::URI::URL::url_decode_($name);
			$name = $ISO2_UTF->convert($name);
			utf8::decode($name);
		}
		else
		{
			# decode only '+'
			$name=~s|\+| |g;
		}
		
		# VALUE
		
		utf8::encode($value);
		utf8::decode($value);
		# su tu UTF-8 sekvencie
		if ($value=~/%(D0|D1|C2|C3|C4|C5)%([0-9A-Fa-f]{2})/i)
		{
			main::_log("utf-8 sequence") unless $env{'quiet'};
			utf8::encode($value);
			TOM::Net::URI::URL::url_decode_($value);
			utf8::decode($value);
		}
		# su tu ISO-8859-2 sekvencie
		elsif ($value=~/%([0-9A-Fa-f]{2})/)
		{
			main::_log("iso-8859-2 sequence") unless $env{'quiet'};
			utf8::encode($value);
			TOM::Net::URI::URL::url_decode_($value);
			$value = $ISO2_UTF->convert($value);
			utf8::decode($value);
		}
		else
		{
			# decode only '+'
			$value=~s|\+| |g;
		}
		
		if ($name=~/\[\]$/){
			push @{$form{$name}},$value;
			}else{$form{$name}=$value;
		}
		
		main::_log("'$name'='".$value."'") unless $env{'quiet'};
	}
 
	$t->close() unless $env{'quiet'};
	return %form;
}



=head2 get_CGI()

by CGI.pm returns hash with parsed INPUT and QUERY_STRING

=cut

sub get_CGI
{
	my $t=track TOM::Debug(__PACKAGE__."::get_CGI()");
	my $query=shift;
	my %form;
	
	main::_log("query='$query'") if $query;
	
	# parse GET method
	
	my %form_qs;
		%form_qs=get_QUERY_STRING($query) if $query;
	foreach my $key(keys %form_qs)
	{
		$form{$key}=$form_qs{$key};
	}
	
	# parse POST method
	
	my @names = $main::CGI->param;
	foreach my $name(@names)
	{
		
		if (my $fh=CGI::upload($name))
		{
			# file
			main::_log("param '$name' is uploaded file");
			
			$form{$name.'_file'}=$main::CGI->param($name);
			$form{$name}=$main::CGI->param($name);
			
			# backward compatibility (ugly hack)
			$form{'multipart'}.="name=\"$name\"; filename=\"$form{$name}\" ___ ";
			
			# get file informations
			my $fileinfo=CGI::uploadInfo($form{$name.'_file'});
			foreach my $key(keys %{$fileinfo})
			{
				main::_log("key $key='".$fileinfo->{$key}."'");
			}
			
			# check if file exists
			my $tmpfilename = $main::CGI->tmpFileName($form{$name.'_file'});
			my $size=(stat($tmpfilename))[7];
			main::_log("tmpfilename='$tmpfilename' size='$size'");
			if (not -e $tmpfilename){main::_log("file not exists",1);}
			else
			{
				main::_log("file exists");
				# fill content from file if is small
				if ($size<$CGI::POST_MAX_USE)
				{
					main::_log("attaching file into memory value form{$name}");
					do
					{
						local $/;
						open(CGI_FILE,'<'.$tmpfilename) || main::_log("can't open this filename");
						binmode(CGI_FILE);
						$form{$name}=<CGI_FILE>;
					};
					main::_log("attached length(".length($form{$name}).")");
				}
			}
		}
		else
		{
			# classical variable
#			main::_log("reading $name");
			if ($name=~/\[\]$/)
			{
#				main::_log("get array $name");
				delete $form{$name};
				foreach my $param($main::CGI->param($name))
				{
					utf8::decode($param);
					push @{$form{$name}},$param;
				}
			}
			else
			{
				$form{$name}=$main::CGI->param($name);
				utf8::decode($form{$name});
			}
			
#			utf8::encode($value);
#			utf8::decode($form{$name});
			
		}
		
		if (length($form{$name})<1024)
		{
			if (ref($form{$name}) eq "ARRAY")
			{
				main::_log("name '$name'=".Dumper($form{$name}));
			}
			else
			{
				main::_log("name '$name'='".$form{$name}."'");
			}
		}
		else {main::_log("name '$name'=length(".length($form{$name}).")");}
		
	}
	
	
	if ($form{'POSTDATA'})
	{
		main::_log("received POSTDATA");
		# process SOAP data
		if ($TOM::Document::type eq "soap")
		{
			main::_log("received SOAP POSTDATA, parsing");
			
			require SOAP::Lite;
			require JSON;
			main::_log($form{'POSTDATA'});
			
			if ($form{'POSTDATA'}=~/^{/) # JSON?
			{eval{
				main::_log(" type=json");
				utf8::encode($form{'POSTDATA'});
				%{$main::RPC}=%{JSON::decode_json($form{'POSTDATA'})};
			};if($@){main::_log("error=".$@)}}
			else
			{eval{
				my $som = SOAP::Deserializer->deserialize($form{'POSTDATA'});
				my $body = $som->body;
				
				$form{'type'}=(keys %{$body})[0];
				
				main::_log("SOAP type='$form{'type'}'");
				
				if (ref($body->{$form{'type'}}) eq "HASH")
				{
					main::_log("SOAP parse HASH");
					
					my $gensym;
					foreach (keys %{$body->{$form{'type'}}})
					{
						if ($_=~/^c\-gensym/)
						{
							$gensym=$_;
							last;
						}
					}
					
					if ($gensym)
					{
						main::_log("SOAP parse ugly perl $gensym");
						%{$main::RPC}=%{$body->{$form{'type'}}->{$gensym}};
					}
					
					else
					{
						%{$main::RPC}=%{$body->{$form{'type'}}};
					}
				}
			}};
		}
		elsif ($TOM::Document::type eq "json" && (
			($form{'POSTDATA'}=~/^{/ && $form{'POSTDATA'}=~/}$/)
			|| ($form{'POSTDATA'}=~/^\[/ && $form{'POSTDATA'}=~/\]$/)
		)) # JSON?
		{eval{
			main::_log(" type=json");
			utf8::encode($form{'POSTDATA'});
#			%{$main::RPC}=%{JSON::decode_json($form{'POSTDATA'})};
			$main::RPC={};
			$main::RPC=JSON::decode_json($form{'POSTDATA'});
		};if($@){main::_log("error=".$@)}}
		# process XML-RPC data
		elsif ($TOM::Document::type eq "xmlrpc")
		{
			main::_log("received XML-RPC POSTDATA, parsing");
			
			require XMLRPC::Lite;
			
			my $som = XMLRPC::Deserializer->deserialize($form{'POSTDATA'});
			my $body = $som->body;
			
			$form{'type'}=$som->method;
			
			main::_log("XML-RPC type='$form{'type'}'");
			
			%{$main::RPC}=%{$som->paramsin};
			
		}
		
#		delete $form{'POSTDATA'};
	}
	
	if ($form{'PUTDATA'})
	{
		main::_log("received PUTDATA");
		# process SOAP data
		if ($TOM::Document::type eq "soap")
		{
			main::_log("received SOAP PUTDATA, parsing");
			
			require SOAP::Lite;
			require JSON;
			main::_log($form{'PUTDATA'});
			
			if ($form{'PUTDATA'}=~/^{/) # JSON?
			{eval{
				main::_log(" type=json");
				utf8::encode($form{'PUTDATA'});
				%{$main::RPC}=%{JSON::decode_json($form{'PUTDATA'})};
			};if($@){main::_log("error=".$@)}}
			else
			{eval{
				my $som = SOAP::Deserializer->deserialize($form{'PUTDATA'});
				my $body = $som->body;
				
				$form{'type'}=(keys %{$body})[0];
				
				main::_log("SOAP type='$form{'type'}'");
				
				if (ref($body->{$form{'type'}}) eq "HASH")
				{
					main::_log("SOAP parse HASH");
					
					my $gensym;
					foreach (keys %{$body->{$form{'type'}}})
					{
						if ($_=~/^c\-gensym/)
						{
							$gensym=$_;
							last;
						}
					}
					
					if ($gensym)
					{
						main::_log("SOAP parse ugly perl $gensym");
						%{$main::RPC}=%{$body->{$form{'type'}}->{$gensym}};
					}
					
					else
					{
						%{$main::RPC}=%{$body->{$form{'type'}}};
					}
				}
			}};
		}
		elsif ($TOM::Document::type eq "json" && (
			($form{'PUTDATA'}=~/^{/ && $form{'PUTDATA'}=~/}$/)
			|| ($form{'PUTDATA'}=~/^\[/ && $form{'PUTDATA'}=~/\]$/)
		)) # JSON?
		{eval{
			main::_log(" type=json");
			utf8::encode($form{'PUTDATA'});
#			%{$main::RPC}=%{JSON::decode_json($form{'PUTDATA'})};
			$main::RPC={};
			$main::RPC=JSON::decode_json($form{'PUTDATA'});
		};if($@){main::_log("error=".$@)}}
		# process XML-RPC data
		elsif ($TOM::Document::type eq "xmlrpc")
		{
			main::_log("received XML-RPC PUTDATA, parsing");
			
			require XMLRPC::Lite;
			
			my $som = XMLRPC::Deserializer->deserialize($form{'PUTDATA'});
			my $body = $som->body;
			
			$form{'type'}=$som->method;
			
			main::_log("XML-RPC type='$form{'type'}'");
			
			%{$main::RPC}=%{$som->paramsin};
			
		}
		
#		delete $form{'PUTDATA'};
	}
	
	$t->close();
	return %form;
}


1;
