package HeurekaOverene;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
use URI;
use URI::Escape;
use IO::Socket;


sub new {
   my $class=shift;
	my %env=@_;
	my $self={};
	$self->{'products'}=[];
	$self->{'productids'}=[];
	
# pre URL heureka.sk pouzi "sk", inak nastavi heureka.cz
	if ($env{'lng'} eq 'sk') {
		$self->{'HEUREKA_BASE_URL'} = 'http://www.heureka.sk/direct/dotaznik/objednavka.php';
	} else {
		$self->{'HEUREKA_BASE_URL'} = 'http://www.heureka.cz/direct/dotaznik/objednavka.php';
	}
	
	$self->{'apiKey'}=$env{'apiKey'};
	#main::_log("api key: $self->{'apiKey'}",1,"dbg");
	
	return bless $self, $class;
	#$self->{sendRequest}= $self->sendRequest;
}


sub setEmail {
	my $self=shift;
	my $env=@_[0];
   $self->{'email'}=$env;
	#return bless ($self);
}

sub addProduct {
	my $self=shift;
	my $env=@_[0];
	
   push(@{$self->{'products'}},$env);
}

sub addProductId {
	my $self=shift;
	my $env=@_[0];
	
	push(@{$self->{'productids'}},$env);
}

sub addOrderId {
	my $self=shift;
	my $env=@_[0];
	
   $self->{'orderId'}=$env;
}

sub getUrl {
	my $self=shift;
	my %env=@_;
	
	
	my $completeUrl = $self->{'HEUREKA_BASE_URL'}
		."?id=".$self->{'apiKey'}
		."&email=".uri_escape($self->{'email'});
		foreach my $product(@{$self->{'products'}}) {
			$completeUrl.="&produkt[]=".uri_escape_utf8($product);
		}
		foreach my $productid(@{$self->{'productids'}}) {
			$completeUrl.="&itemid[]=".uri_escape_utf8($productid);
		}
		$completeUrl.="&orderid=".$self->{'orderId'}; 
	
	#main::_log($completeUrl,1,"dbg");
	return $completeUrl;
}

sub sendRequest {
   my $self=shift;
	my $env=@_[0];
	
	my $url = URI->new($env);
	
	my $sock = new IO::Socket::INET ( 
		PeerHost => $url->host(), 
		PeerPort => '80',
		Proto => 'tcp',
		Timeout => '5',
		) or die "socket fail: $!";
	
	#my $new_sock = $sock->accept() or die "test: $!";
	#main::_log('socket: '.$new_sock,1,"debugg");
	
	if(!$sock) {
		main::_log("socket sa nenapojil: ".$!,3,"heureka.err");
	} else {
	my $out = "GET " . $url->path() . "?" . $url->query() . " HTTP/1.1\r\n" . 
	 "Host: " . $url->host() . "\r\n" . 
	 "Connection: Close\r\n\r\n";
	print $sock $out;
	}
	while(<$sock>) {
		main::_log("ODPOVED: $_");
	}
	close($sock);
}

sub send {
   my $self=shift;
	
	$self->sendRequest($self->getUrl);
}

return 1;
