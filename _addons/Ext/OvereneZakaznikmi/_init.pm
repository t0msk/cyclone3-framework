#!/bin/perl
package Ext::Heureka;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

=head1 NAME

Extension Heureka

=head1 DESCRIPTION

Library for Czech and Slovak price comparison and e-shop evaluation sites heureka.cz and heureka.sk

always provide apikey, language string and user email.

example usage:


if ($TOM::apikeys{'heureka-api-key'}) {
	main::_log("heureka overene zakaznikmi init");
	use Ext::OvereneZakaznikmi::_init;
	eval {
		my $overene = new HeurekaOverene('apiKey'=>$env{'heureka-api-key'},'lng'=>'sk');
		$overene->setEmail($main::USRM{'session'}{'order'}{'email'});
		
		foreach my $ID_product (@ID_product_list) {
			$overene->addProductId($ID_product);
			main::_log("heureka adding product $ID_product");
		}
		$overene->addOrderId($order_ID_entity);
		$overene->send();
		main::_log("heureka order $order_ID_entity sent");
	} or do {
		my $error = $@;
		main::_log("Heureka error message=$error");
	}
}

=cut

BEGIN
{
	main::_log("<={LIB} ".__PACKAGE__);
	my $dir=(__FILE__=~/^(.*)\//)[0].'/src';
	unshift @INC, $dir;
	
	require OvereneZakaznikmi::HeurekaOverene;
}

BEGIN {shift @INC;}


1;

=head1 AUTHOR

Radomír Laučík

=cut