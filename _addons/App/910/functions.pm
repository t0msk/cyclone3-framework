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
use App::160::SQL;

our $debug=1;
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
	
	$env{'product_sym.ID'} = $env{'product_cat.ID_entity'} if $env{'product_cat.ID_entity'};
	
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
	
	# find product by product_number
	if (!$env{'product.ID'} && $env{'product.product_number'})
	{
		# check if this product_number not already used by another product
		my $sql=qq{
			SELECT
				ID,
				ID_entity
			FROM
				`$App::910::db_name`.a910_product
			WHERE
				product_number='$env{'product.product_number'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %db0_line=$sth0{'sth'}->fetchhash();
		$env{'product.ID'} = $db0_line{'ID'} if $db0_line{'ID'};
		$env{'product.ID_entity'} = $db0_line{'ID_entity'} if $db0_line{'ID_entity'};
		%product=App::020::SQL::functions::get_ID(
			'ID' => $env{'product.ID'},
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product",
			'columns' => {'*'=>1}
		);
		main::_log("found product.ID='$env{'product.ID'}'");
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
	# amount_unit
	$columns{'amount_unit'}="'".TOM::Security::form::sql_escape($env{'product.amount_unit'})."'"
		if (exists $env{'product.amount_unit'} && ($env{'product.amount_unit'} ne $product{'amount_unit'}));
	# amount_availability
	$columns{'amount_availability'}="'".TOM::Security::form::sql_escape($env{'product.amount_availability'})."'"
		if (exists $env{'product.amount_availability'} && ($env{'product.amount_availability'} ne $product{'amount_availability'}));
	# amount_limit
	$columns{'amount_limit'}="'".TOM::Security::form::sql_escape($env{'product.amount_limit'})."'"
		if (exists $env{'product.amount_limit'} && ($env{'product.amount_limit'} ne $product{'amount_limit'}));
	# amount_order_min
	$columns{'amount_order_min'}="'".TOM::Security::form::sql_escape($env{'product.amount_order_min'})."'"
		if ($env{'product.amount_order_min'} && ($env{'product.amount_order_min'} ne $product{'amount_order_min'}));
	# amount_order_max
	$columns{'amount_order_max'}="'".TOM::Security::form::sql_escape($env{'product.amount_order_max'})."'"
		if (exists $env{'product.amount_order_max'} && ($env{'product.amount_order_max'} ne $product{'amount_order_max'}));
	# amount_order_div
	$columns{'amount_order_div'}="'".TOM::Security::form::sql_escape($env{'product.amount_order_div'})."'"
		if (exists $env{'product.amount_order_div'} && ($env{'product.amount_order_div'} ne $product{'amount_order_div'}));
	# price
	$env{'product.price'}='' if $env{'product.price'} eq "0.000";
	$columns{'price'}="'".TOM::Security::form::sql_escape($env{'product.price'})."'"
		if (exists $env{'product.price'} && ($env{'product.price'} ne $product{'price'}));
	$columns{'price'}='NULL' if $columns{'price'} eq "''";
	# price_max
	$env{'product.price_max'}='' if $env{'product.price_max'} eq "0.000";
	$columns{'price_max'}="'".TOM::Security::form::sql_escape($env{'product.price_max'})."'"
		if (exists $env{'product.price_max'} && ($env{'product.price_max'} ne $product{'price_max'}));
	$columns{'price_max'}='NULL' if $columns{'price_max'} eq "''";
	# price_currency
	$columns{'price_currency'}="'".TOM::Security::form::sql_escape($env{'product.price_currency'})."'"
		if ($env{'product.price_currency'} && ($env{'product.price_currency'} ne $product{'price_currency'}));
	# metadata
	if ((not exists $env{'product.metadata'}) && (!$product{'metadata'})){$env{'product.metadata'}=$App::910::metadata_default;}
	$columns{'metadata'}="'".TOM::Security::form::sql_escape($env{'product.metadata'})."'"
		if (exists $env{'product.metadata'} && ($env{'product.metadata'} ne $product{'metadata'}));
	#if ($env{'product.metadata'})
	if ($columns{'metadata'})
	{
		App::020::functions::metadata::metaindex_set(
			'db_h' => 'main',
			'db_name' => $App::910::db_name,
			'tb_name' => 'a910_product',
			'ID' => $env{'product.ID'},
			'metadata' => {App::020::functions::metadata::parse($env{'product.metadata'})}
		);
	}
	# status
	$columns{'status'}="'".TOM::Security::form::sql_escape($env{'product.status'})."'"
		if ($env{'product.status'} && ($env{'product.status'} ne $product{'status'}));
	
	if ($env{'product.product_number'} && ($env{'product.product_number'} ne $product{'product_number'}))
	{
		# check if this product_number not already used by another product
		my $sql=qq{
			SELECT
				ID
			FROM
				`$App::910::db_name`.a910_product
			WHERE
				product_number='$env{'product.product_number'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		$columns{'product_number'}="'".TOM::Security::form::sql_escape($env{'product.product_number'})."'" unless $sth0{'rows'};
	}
	
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
	# brand
	if ($env{'product_brand.name'})
	{
		my $sql=qq{
			SELECT
				ID,ID_entity
			FROM
				`$App::910::db_name`.a910_product_brand
			WHERE
				name='$env{'product_brand.name'}'
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %product_brand=$sth0{'sth'}->fetchhash();
		$env{'product_brand.ID'}=$product_brand{'ID'};
		if (!$product_brand{'ID'})
		{
			$env{'product_brand.ID'}=App::020::SQL::functions::new(
				'db_h' => "main",
				'db_name' => $App::910::db_name,
				'tb_name' => "a910_product_brand",
				'columns' => {
					'name' => "'".TOM::Security::form::sql_escape($env{'product_brand.name'})."'",
					'name_url' => "'".TOM::Security::form::sql_escape(TOM::Net::URI::rewrite::convert($env{'product_brand.name'}))."'"
				},
				'-journalize' => 1,
			);
		}
	}
	$columns{'ID_brand'}="'".TOM::Security::form::sql_escape($env{'product_brand.ID'})."'"
		if (exists $env{'product_brand.ID'} && ($env{'product_brand.ID'} ne $product_ent{'ID_brand'}));
	# family
	if ($env{'product_family.name'})
	{
		my $sql=qq{
			SELECT
				ID,ID_entity
			FROM
				`$App::910::db_name`.a910_product_family
			WHERE
				name='$env{'product_family.name'}'
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %product_family=$sth0{'sth'}->fetchhash();
		$env{'product_family.ID'}=$product_family{'ID'};
		if (!$product_family{'ID'})
		{
			$env{'product_family.ID'}=App::020::SQL::functions::new(
				'db_h' => "main",
				'db_name' => $App::910::db_name,
				'tb_name' => "a910_product_family",
				'columns' => {
					'name' => "'".TOM::Security::form::sql_escape($env{'product_family.name'})."'",
					'name_url' => "'".TOM::Security::form::sql_escape(TOM::Net::URI::rewrite::convert($env{'product_family.name'}))."'"
				},
				'-journalize' => 1,
			);
		}
	}
	$columns{'ID_family'}="'".TOM::Security::form::sql_escape($env{'product_family.ID'})."'"
		if (exists $env{'product_family.ID'} && ($env{'product_family.ID'} ne $product_ent{'ID_family'}));
	# posix_owner
	$columns{'posix_owner'}="'".TOM::Security::form::sql_escape($env{'product_ent.posix_owner'})."'"
		if (exists $env{'product_ent.posix_owner'} && ($env{'product_ent.posix_owner'} ne $product_ent{'posix_owner'}));
	# VAT
	$columns{'VAT'}="'".TOM::Security::form::sql_escape($env{'product_ent.VAT'})."'"
		if (exists $env{'product_ent.VAT'} && ($env{'product_ent.VAT'} ne $product_ent{'VAT'}));
	
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
	
	# generate keywords
	if ($env{'product_lng.keywords'})
	{
		my @ref=split(' # ',$product_lng{'keywords'});
		$ref[1]=$env{'product_lng.keywords'};
		$env{'product_lng.keywords'}=$ref[0].' # '.$ref[1];
	}
	else {$env{'product_lng.keywords'}=$product_lng{'keywords'};}
	if ( $env{'product_lng.description_short'} || $env{'product_lng.description'})
	{
		my @ref=split(' # ',$env{'product_lng.keywords'});
		$ref[0]='';
		my %keywords=App::401::keywords::html_extract($env{'product_lng.description_short'}.' '.$env{'product_lng.description'});
		foreach (keys %keywords)
		{$ref[0].=", ".$_;}
		$ref[0]=~s|^, ||;
		$env{'product_lng.keywords'}=$ref[0].' # '.$ref[1];
	}
	$env{'product_lng.keywords'}='' if ($env{'product_lng.keywords'} eq ' # ');
	
	# update only if necessary
	my %columns;
	# name
	$columns{'name'}="'".TOM::Security::form::sql_escape($env{'product_lng.name'})."'"
		if ($env{'product_lng.name'} && ($env{'product_lng.name'} ne $product_lng{'name'}));
	$columns{'name_url'}="'".TOM::Security::form::sql_escape(TOM::Net::URI::rewrite::convert($env{'product_lng.name'}))."'"
		if ($env{'product_lng.name'} && ($env{'product_lng.name'} ne $product_lng{'name'}));
	# name_long
	$columns{'name_long'}="'".TOM::Security::form::sql_escape($env{'product_lng.name_long'})."'"
		if ($env{'product_lng.name_long'} && ($env{'product_lng.name_long'} ne $product_lng{'name_long'}));
	# name_label
	$columns{'name_label'}="'".TOM::Security::form::sql_escape($env{'product_lng.name_label'})."'"
		if ($env{'product_lng.name_label'} && ($env{'product_lng.name_label'} ne $product_lng{'name_label'}));
	# description_short
	$columns{'description_short'}="'".TOM::Security::form::sql_escape($env{'product_lng.description_short'})."'"
		if ($env{'product_lng.description_short'} && ($env{'product_lng.description_short'} ne $product_lng{'description_short'}));
	# description
	$columns{'description'}="'".TOM::Security::form::sql_escape($env{'product_lng.description'})."'"
		if ($env{'product_lng.description'} && ($env{'product_lng.description'} ne $product_lng{'description'}));
	# keywords
	$columns{'keywords'}="'".TOM::Security::form::sql_escape($env{'product_lng.keywords'})."'"
		if ($env{'product_lng.keywords'} && ($env{'product_lng.keywords'} ne $product_lng{'keywords'}));
	
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
	
	
	# THUMBNAIL
	
	if ($env{'thumbnail'} && -e $env{'thumbnail'} && not -d $env{'thumbnail'})
	{
		
		if (my $relation=(App::160::SQL::get_relations(
			'db_name' => $App::910::db_name,
			'l_prefix' => 'a910',
			'l_table' => 'product',
			'l_ID_entity' => $env{'product.ID'},
			'rel_type' => 'thumbnail',
			'r_prefix' => "a501",
			'r_table' => "image",
			'status' => "Y",
			'limit' => 1
		))[0])
		{
			
			my %image=App::501::functions::image_add(
				'image.ID_entity' => $relation->{'r_ID_entity'},
				'image_attrs.name' => $env{'product.product_number'} || $env{'product.ID'} || $env{'thumbnail'},
				'file' => $env{'thumbnail'}
			);
			
			if ($image{'image.ID'})
			{
				App::501::functions::image_regenerate(
					'image.ID' => $image{'image.ID'}
				);
			}
			
		}
		else
		{
			
			my %image=App::501::functions::image_add(
				'image_attrs.name' => $env{'product.product_number'} || $env{'product.ID'} || $env{'thumbnail'},
				'image_attrs.ID_category' => $App::910::thumbnail_cat_ID_entity,
				'image_attrs.status' => 'Y',
				'file' => $env{'thumbnail'}
			);
			
			if ($image{'image.ID'})
			{
				
				App::501::functions::image_regenerate(
					'image.ID' => $image{'image.ID'}
				);
				
				my ($ID_entity,$ID)=App::160::SQL::new_relation(
					'l_prefix' => 'a910',
					'l_table' => 'product',
					'l_ID_entity' => $env{'product.ID'},
					'rel_type' => 'thumbnail',
					'r_db_name' => $App::501::db_name,
					'r_prefix' => 'a501',
					'r_table' => 'image',
					'r_ID_entity' => $image{'image.ID_entity'},
					'status' => 'Y',
				);
				
			}
			
		}
		
	}
	
	
	$t->close();
	return %env;
}



=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
