#!/bin/perl
package App::910::functions;

=head1 NAME

App::910::functions

=head1 DESCRIPTION



=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 DEPENDS

=over

=item *

L<App::910::_init|app/"910/_init.pm">

=item *

L<TOM::Security::form|lib/"TOM/Security/form.pm">

=back

=cut

use App::910::_init;
use TOM::Security::form;

our $debug=0;
our $quiet;$quiet=1 unless $debug;

=head2 product_add()

Adds new product to category, or updates old one

Add new product

 product_add
 (
   'product.product_number' => '',
	'product.status' => '', # Y/N/T
   'product_lng.lng' => '',
   'product_lng.name' => '',
	'product_lng.description' => '',
	'product_sym.ID' => '', # product_cat.ID
 );

Change product number (displayed in catalog)

 product_add
 (
   'product.ID' => '',
   'product.product_number' => '',
 );
 
Create new product modification

 product_add
 (
   'product.ID_entity' => '',
   'product_lng.lng' => '',
	'product_lng.description' => '',
	'product_lng.metadata' => '',
 );
 
Create or update language version of product modification

 product_add
 (
   'product.ID' => '',
   'product_lng.lng' => '',
	'product_lng.description' => '',
	'product_lng.metadata' => '',
 );
 
Add new product symlink into category

 product_add
 (
   'product.ID_entity' => '',
   'product_sym.ID' => '', # product_cat.ID
 );

=cut

sub product_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::product_add()");
	
	# PRODUCT AND PRODUCT MODIFICATION
	
	my %product;
	if ($env{'product.ID'})
	{
		undef $env{'product.ID_entity'}; # ID_entity has lower priority as ID
		# when real ID_entity used, then read it from ID
		# when ID not found, undef ID_entity, because is invalid
		main::_log("finding product.ID_entity by product.ID='$env{'product.ID'}'");
		%product=App::020::SQL::functions::get_ID(
			'ID' => $env{'product.ID'},
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product",
			'columns' => {'*'=>1}
		);
		if ($product{'ID'})
		{
			$env{'product.ID_entity'}=$product{'ID_entity'};
			main::_log("found product.ID_entity='$env{'product.ID_entity'}'");
		}
		else
		{
			main::_log("not found product.ID, undef",1);
			undef $env{'product.ID'};
		}
	}
	
	if (!$env{'product.ID'}) # if modification not defined, create a new
	{
		main::_log("!product.ID, create product.ID (product.ID_entity='$env{'product.ID_entity'}')");
		my %columns;
		$columns{'ID_entity'}=$env{'product.ID_entity'} if $env{'product.ID_entity'};
		$env{'product.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product",
			'columns' => {%columns},
			'-journalize' => 1,
		);
		%product=App::020::SQL::functions::get_ID(
			'ID' => $env{'product.ID'},
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product",
			'columns' => {'*'=>1}
		);
		$env{'product.ID'}=$product{'ID'};
		$env{'product.ID_entity'}=$product{'ID_entity'};
	}
	
	main::_log("product.ID='$product{'ID'}' product.ID_entity='$product{'ID_entity'}'");
	
	# update only if necessary
	my %columns;
	# amount
	$columns{'amount'}="'".TOM::Security::form::sql_escape($env{'product.amount'})."'"
		if (exists $env{'product.amount'} && ($env{'product.amount'} ne $product{'amount'}));
	# amount_availability
	$columns{'amount_availability'}="'".TOM::Security::form::sql_escape($env{'product.amount'})."'"
		if (exists $env{'product.amount_availability'} && ($env{'product.amount_availability'} ne $product{'amount_availability'}));
	# price
	$columns{'price'}="'".TOM::Security::form::sql_escape($env{'product.price'})."'"
		if (exists $env{'product.price'} && ($env{'product.price'} ne $product{'price'}));
	
	if (keys %columns)
	{
		App::020::SQL::functions::update(
			'ID' => $env{'product.ID'},
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product",
			'columns' => {%columns},
			'-journalize' => 1
		);
	}
	
	
	
	# PRODUCT_ENT
	
	my %product_ent;
	my $product_ent_=(App::020::SQL::functions::get_ID_entity
	(
		'ID_entity' => $env{'product.ID_entity'},
		'db_h' => 'main',
		'db_name' => $App::910::db_name,
		'tb_name' => 'a910_product_ent',
		'columns' => {'*'=>1}
	))[0];
	%product_ent=%{$product_ent_} if $product_ent_->{'ID'}; # convert hash_ref to hash
	$env{'product_ent.ID'}=$product_ent{'ID'};
	
	if (!$env{'product_ent.ID'}) # if product_ent not defined, create a new
	{
		main::_log("!product_ent.ID, create product_ent.ID (product_ent.ID_entity='$env{'product.ID_entity'}')");
		my %columns;
		$columns{'ID_entity'}=$env{'product.ID_entity'};
		$env{'product_ent.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product_ent",
			'columns' => {%columns},
			'-journalize' => 1,
		);
		%product_ent=App::020::SQL::functions::get_ID(
			'ID' => $env{'product_ent.ID'},
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product_ent",
			'columns' => {'*'=>1}
		);
		$env{'product_ent.ID'}=$product_ent{'ID'};
		$env{'product_ent.ID_entity'}=$product_ent{'ID_entity'};
	}
	
	main::_log("product_ent.ID='$product_ent{'ID'}' product_ent.ID_entity='$product_ent{'ID_entity'}'");
	
	if (!$product_ent{'posix_owner'} && !$env{'product_ent.posix_owner'})
	{
		$env{'product_ent.posix_owner'}=$main::USRM{'ID_user'};
	}
	
	# update only if necessary
	my %columns;
	# posix_owner
	$columns{'posix_owner'}="'".TOM::Security::form::sql_escape($env{'product_ent.posix_owner'})."'"
		if (exists $env{'product_ent.posix_owner'} && ($env{'product_ent.posix_owner'} ne $product_ent{'posix_owner'}));
	
	if (keys %columns)
	{
		App::020::SQL::functions::update(
			'ID' => $env{'product_ent.ID'},
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product_ent",
			'columns' => {%columns},
			'-journalize' => 1
		);
	}
	
	
	
	# LNG DETECTION
	
	# check symlink
	my %product_sym;
	my %product_cat;
	if (!$env{'product_lng.lng'} && $env{'product_sym.ID'})
	{
		%product_cat=App::020::SQL::functions::get_ID(
			'ID' => $env{'product_sym.ID'},
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product_cat",
			'columns' => {'*'=>1}
		);
		$env{'product_lng.lng'}=$product_cat{'lng'} if $product_cat{'ID'};
		main::_log("setting lng='$env{'product_lng.lng'}' from product_sym.ID='$env{'product_sym.ID'}'");
	}
	# check lng_param
	$env{'product_lng.lng'}=$tom::lng unless $env{'product_lng.lng'};
	main::_log("lng='$env{'product_lng.lng'}'");
	
	
	
	# PRODUCT_LNG
	
	my %product_lng;
	if (!$env{'product_lng.ID'})
	{
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::910::db_name`.`a910_product_lng`
			WHERE
				ID_entity=$env{'product.ID'} AND
				lng='$env{'product_lng.lng'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%product_lng=$sth0{'sth'}->fetchhash();
		$env{'product_lng.ID'}=$product_lng{'ID'} if $product_lng{'ID'};
	}
	
	if (!$env{'product_lng.ID'}) # if product_lng not defined, create a new
	{
		main::_log("!product_lng.ID, create product_lng.ID (product_lng.lng='$env{'product_lng.lng'}')");
		my %columns;
		$columns{'ID_entity'}=$env{'product.ID'};
		$columns{'lng'}="'".$env{'product_lng.lng'}."'";
		$env{'product_lng.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product_lng",
			'columns' => {%columns},
			'-journalize' => 1,
		);
		%product_lng=App::020::SQL::functions::get_ID(
			'ID' => $env{'product_lng.ID'},
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product_lng",
			'columns' => {'*'=>1}
		);
		$env{'product_lng.ID'}=$product_lng{'ID'};
		$env{'product_lng.ID_entity'}=$product_lng{'ID_entity'};
	}
	
	main::_log("product_lng.ID='$product_lng{'ID'}' product_lng.ID_entity='$product_lng{'ID_entity'}'");
	
	# update only if necessary
	my %columns;
	# name
	$columns{'name'}="'".TOM::Security::form::sql_escape($env{'product_lng.name'})."'"
		if ($env{'product_lng.name'} && ($env{'product_lng.name'} ne $product_lng{'name'}));
	$columns{'name_url'}="'".TOM::Security::form::sql_escape(TOM::Net::URI::rewrite::convert($env{'product_lng.name'}))."'"
		if ($env{'product_lng.name'} && ($env{'product_lng.name'} ne $product_lng{'name'}));
	
	if (keys %columns)
	{
		App::020::SQL::functions::update(
			'ID' => $env{'product_lng.ID'},
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product_lng",
			'columns' => {%columns},
			'-journalize' => 1
		);
	}
	
	
	# PRODUCT_SYM
	
	if ($env{'product_sym.ID'})
	{
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::910::db_name`.`a910_product_sym`
			WHERE
				ID_entity=$env{'product.ID_entity'} AND
				ID=$env{'product_sym.ID'}
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		if (!$sth0{'rows'})
		{
			$env{'product_sym.ID'}=App::020::SQL::functions::new(
				'db_h' => "main",
				'db_name' => $App::910::db_name,
				'tb_name' => "a910_product_sym",
				'columns' =>
				{
					'ID' => $env{'product_sym.ID'},
					'ID_entity' => $env{'product.ID_entity'},
				},
				'-journalize' => 1,
			);
		}
	}
	
	main::_log("product_sym.ID='$env{'product_sym.ID'}'");
	
	
	$t->close();
	return %env;
}







=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
