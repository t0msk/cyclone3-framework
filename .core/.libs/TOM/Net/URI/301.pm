#!/bin/perl
use strict;

# TODO: [Aben] Trosku to tu precistit a mozno spravit objektove

=head1 PRIKLAD
TOM::Net::URI::rewrite::get($file);
TOM::Net::URI::rewrite::parse_hash(%form);
my $hash=TOM::Net::URI::rewrite::parse_URL("http://spravy.markiza.sk/~USRM/edit.html?asdfhojsdf-A1-v2");
=cut

package TOM::Net::URI::301;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

use Digest::MD5  qw(md5 md5_hex md5_base64);

my $debug=0;

our @rules;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

sub check
{
	my $URL=shift;
	my $form=shift;
	
	if ($tom::rewrite_RewriteBase)
	{
#		main::_log("cleaning RewriteBase='$tom::rewrite_RewriteBase' from URL");
		$URL=~s|^$tom::rewrite_RewriteBase||;
	}
	
	return undef unless $URL;
	
	foreach my $r(@rules)
	{
		my $regexp=$r->[0];
		
#=head1
		if ($regexp=~s/^'(.*?)'$/$1/)
		{
			main::_log("test query '$regexp'='$URL'");
			my %fform=TOM::Net::HTTP::CGI::GetQuery($regexp, '-lite' => 1);
			
			my $i;
			# i je prazdne ak je podmienka splnena
			# i je >0 ak podmienka nieje splnena
			foreach my $key (keys %fform)
			{
				$i++ if $fform{$key} ne $form->{$key};
			}
			
			next if $i;
			
			return $r->[1];
			
		}
#=cut
		
		if ($URL=~/$regexp/)
		{
			main::_log("test regexp '$regexp'='$URL'");
			return $r->[1];
		}
	}
	
	return undef;
}

sub get
{
	my $t=track TOM::Debug(__PACKAGE__."::get()");
	my $data=shift;
	
	@rules=();
	
	foreach my $line(split('\n',$data))
	{
		chomp($line);
		
		main::_log("reading line '$line'");
		
		#$line=~s| ||g;
		#$line=~s|\t||g;
		next if $line=~/^#/;
		
		#$line=~s/=[ \t]+(http|\?\|\?|-)/=$1/;
		
		next unless $line;
		
		my @ref;
		
		if ($line=~s/^('.*?')([\s]*?)=//)
		{
			$ref[0]=$1;
			#$ref[0]=~s|^'||;
			#$ref[0]=~s|'$||;
			$ref[1]=$line;
			main::_log("type line");
			#$line=~s|^'(.*?)'=||;
		}
		else
		{
			@ref=split('=',$line,2);
		}
		
		1 while ($ref[0]=~s|^\s||g);
		1 while ($ref[0]=~s|\s$||g);
		1 while ($ref[1]=~s|^\s||g);
		1 while ($ref[1]=~s|\s$||g);
		
		if ($ref[0]=~s|^"||)
		{
			$ref[0]=~s|"$||;
		}
		elsif ($ref[0]=~/^'/)
		{
		}
		else
		{
			$ref[0]='^'.$ref[0].'$';
		}
		
		$ref[1]=~s|^"||;
		$ref[1]=~s|"$||;
		
		main::_log("adding '$ref[0]' = '$ref[1]'");
		push @rules, [@ref];
		
	}
	
	$t->close();
	return 1;
}





1;