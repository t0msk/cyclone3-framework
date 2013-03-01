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
	'product_sym.ID' => '', # product_cat.ID_entity
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
   'product_sym.ID' => '', # product_cat.ID_entity
 );

=cut

sub product_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::product_add()");
	
	$env{'product_sym.ID'} = $env{'product_cat.ID_entity'} if $env{'product_cat.ID_entity'};
	
	# PRODUCT AND PRODUCT MODIFICATION
	
	my %product;
	my $content_reindex;
	
	if ($env{'product.ID'})
	{
		$env{'product.ID'}=$env{'product.ID'}+0;
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
#			exit;
			#undef $env{'product.ID'};
			App::020::SQL::functions::new(
				'db_h' => "main",
				'db_name' => $App::910::db_name,
				'tb_name' => "a910_product",
				'columns' => {
					'ID' => $env{'product.ID'},
					'product_number' => "'".TOM::Security::form::sql_escape($env{'product.product_number'})."'", # if defined
					'datetime_publish_start' => 'NOW()'
				},
				'-journalize' => 1,
			);
			%product=App::020::SQL::functions::get_ID(
				'ID' => $env{'product.ID'},
				'db_h' => "main",
				'db_name' => $App::910::db_name,
				'tb_name' => "a910_product",
				'columns' => {'*'=>1}
			);
			$env{'product.ID_entity'}=$product{'ID_entity'};
		}
	}
	
	# find product by product_number
	if (!$env{'product.ID'} && $env{'product.product_number'})
	{
#		exit;
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
#		exit;
		my %columns;
		$columns{'ID_entity'}=$env{'product.ID_entity'} if $env{'product.ID_entity'};
		$env{'product.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product",
			'columns' => {%columns},
			'-journalize' => 1,
		);
		App::020::SQL::functions::update(
			'ID' => $env{'product.ID'},
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product",
			'columns' => {'product_number'=>"'NEW-".$env{'product.ID'}."'"},
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
		$content_reindex=1;
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
	$env{'product.price'}=sprintf("%.3f",$env{'product.price'}) if $env{'product.price'};
	$env{'product.price'}='' if $env{'product.price'} eq "0.000";
	$columns{'price'}="'".TOM::Security::form::sql_escape($env{'product.price'})."'"
		if (exists $env{'product.price'} && ($env{'product.price'} ne $product{'price'}));
	$columns{'price'}='NULL' if $columns{'price'} eq "''";
	# price_previous
	$env{'product.price_previous'}='' if $env{'product.price_previous'} eq "0.000";
	$columns{'price_previous'}="'".TOM::Security::form::sql_escape($env{'product.price_previous'})."'"
		if (exists $env{'product.price_previous'} && ($env{'product.price_previous'} ne $product{'price_previous'}));
	$columns{'price_previous'}='NULL' if $columns{'price_previous'} eq "''";
	# price_max
	$env{'product.price_max'}='' if $env{'product.price_max'} eq "0.000";
	$columns{'price_max'}="'".TOM::Security::form::sql_escape($env{'product.price_max'})."'"
		if (exists $env{'product.price_max'} && ($env{'product.price_max'} ne $product{'price_max'}));
	$columns{'price_max'}='NULL' if $columns{'price_max'} eq "''";
	# price_currency
	$columns{'price_currency'}="'".TOM::Security::form::sql_escape($env{'product.price_currency'})."'"
		if ($env{'product.price_currency'} && ($env{'product.price_currency'} ne $product{'price_currency'}));
	# datetime_process
	$columns{'datetime_process'}="'".TOM::Security::form::sql_escape($env{'product.datetime_process'})."'"
		if ($env{'product.datetime_process'} && ($env{'product.datetime_process'} ne $product{'datetime_process'}));
	$columns{'datetime_process'}="NULL" if $env{'product.datetime_process'} eq "NULL";
	# datetime_next_index
	$columns{'datetime_next_index'}="'".TOM::Security::form::sql_escape($env{'product.datetime_next_index'})."'"
		if (exists $env{'product.datetime_next_index'} && ($env{'product.datetime_next_index'} ne $product{'datetime_next_index'}));
	$columns{'datetime_next_index'}="NULL" if $columns{'datetime_next_index'} eq "''";
	# datetime_publish_start
	$columns{'datetime_publish_start'}="'".TOM::Security::form::sql_escape($env{'product.datetime_publish_start'})."'"
		if ($env{'product.datetime_publish_start'} && ($env{'product.datetime_publish_start'} ne $product{'datetime_publish_start'}));
	# datetime_publish_stop
	if ($env{'product.datetime_publish_stop'})
	{
		$columns{'datetime_publish_stop'}="'".TOM::Security::form::sql_escape($env{'product.datetime_publish_stop'})."'"
			if ($env{'product.datetime_publish_stop'} && ($env{'product.datetime_publish_stop'} ne $product{'datetime_publish_stop'}));
	} else
	{
		if (exists $env{'product.datetime_publish_stop'})
		{
			$columns{'datetime_publish_stop'} = "NULL";
		}
	}

	# supplier_org
	$columns{'supplier_org'}="'".TOM::Security::form::sql_escape($env{'product.supplier_org'})."'"
		if (exists $env{'product.supplier_org'} && ($env{'product.supplier_org'} ne $product{'supplier_org'}));
	$columns{'supplier_org'}='NULL' if $columns{'supplier_org'} eq "''";

	# supplier_person
	$columns{'supplier_person'}="'".TOM::Security::form::sql_escape($env{'product.supplier_person'})."'"
		if (exists $env{'product.supplier_person'} && ($env{'product.supplier_person'} ne $product{'supplier_person'}));
	
	# metadata
	my %metadata=App::020::functions::metadata::parse($product{'metadata'});
	
	foreach my $section(split(';',$env{'product.metadata.override_sections'}))
	{
		delete $metadata{$section};
	}
	
	if ($env{'product.metadata.replace'})
	{
		if (!ref($env{'product.metadata'}) && $env{'product.metadata'})
		{
			%metadata=App::020::functions::metadata::parse($env{'product.metadata'});
		}
		if (ref($env{'product.metadata'}) eq "HASH")
		{
			%metadata=%{$env{'product.metadata'}};
		}
	}
	else
	{
		if (!ref($env{'product.metadata'}) && $env{'product.metadata'})
		{
			# when metadata send as <metatree></metatree> then always replace
			%metadata=App::020::functions::metadata::parse($env{'product.metadata'});
#			my %metadata_=App::020::functions::metadata::parse($env{'product.metadata'});
#			delete $env{'product.metadata'};
#			%{$env{'product.metadata'}}=%metadata_;
		}
		if (ref($env{'product.metadata'}) eq "HASH")
		{
			# metadata overrride
			foreach my $section(keys %{$env{'product.metadata'}})
			{
				foreach my $variable(keys %{$env{'product.metadata'}{$section}})
				{
					$metadata{$section}{$variable}=$env{'product.metadata'}{$section}{$variable};
				}
			}
		}
	}
	
	$env{'product.metadata'}=App::020::functions::metadata::serialize(%metadata);
	
	$columns{'metadata'}="'".TOM::Security::form::sql_escape($env{'product.metadata'})."'"
	if (exists $env{'product.metadata'} && ($env{'product.metadata'} ne $product{'metadata'}));
	
	if ($columns{'metadata'})
	{
		App::020::functions::metadata::metaindex_set(
			'db_h' => 'main',
			'db_name' => $App::910::db_name,
			'tb_name' => 'a910_product',
			'ID' => $env{'product.ID'},
			'metadata' => {%metadata}
		);
	}
	# status_new
	$columns{'status_new'}="'".TOM::Security::form::sql_escape($env{'product.status_new'})."'"
		if ($env{'product.status_new'} && ($env{'product.status_new'} ne $product{'status_new'}));
	# status_sale
	$columns{'status_sale'}="'".TOM::Security::form::sql_escape($env{'product.status_sale'})."'"
		if ($env{'product.status_sale'} && ($env{'product.status_sale'} ne $product{'status_sale'}));
	# status_special
	$columns{'status_special'}="'".TOM::Security::form::sql_escape($env{'product.status_special'})."'"
		if ($env{'product.status_special'} && ($env{'product.status_special'} ne $product{'status_special'}));
	# status_recommended
	$columns{'status_recommended'}="'".TOM::Security::form::sql_escape($env{'product.status_recommended'})."'"
		if ($env{'product.status_recommended'} && ($env{'product.status_recommended'} ne $product{'status_recommended'}));

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
				product_number=?
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'bind'=>[$env{'product.product_number'}],'quiet'=>1);
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
		$content_reindex=1;
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
		$content_reindex=1;
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
				name=?
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1,'bind'=>[$env{'product_brand.name'}]);
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
			$content_reindex=1;
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
			$content_reindex=1;
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
	# priority_A
	$columns{'priority_A'}="'".TOM::Security::form::sql_escape($env{'product_ent.priority_A'})."'"
		if (exists $env{'product_ent.priority_A'} && ($env{'product_ent.priority_A'} ne $product_ent{'priority_A'}));
		$columns{'priority_A'}='NULL' if $columns{'priority_A'} eq "''";
	# priority_B
	$columns{'priority_B'}="'".TOM::Security::form::sql_escape($env{'product_ent.priority_B'})."'"
		if (exists $env{'product_ent.priority_B'} && ($env{'product_ent.priority_B'} ne $product_ent{'priority_B'}));
		$columns{'priority_B'}='NULL' if $columns{'priority_B'} eq "''";
	# priority_C
	$columns{'priority_C'}="'".TOM::Security::form::sql_escape($env{'product_ent.priority_C'})."'"
		if (exists $env{'product_ent.priority_C'} && ($env{'product_ent.priority_C'} ne $product_ent{'priority_C'}));
		$columns{'priority_C'}='NULL' if $columns{'priority_C'} eq "''";

	# product_type
	$columns{'product_type'}="'".TOM::Security::form::sql_escape($env{'product_ent.product_type'})."'"
		if (exists $env{'product_ent.product_type'} && ($env{'product_ent.product_type'} ne $product_ent{'product_type'}));
	
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
		$content_reindex=1;
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
		$content_reindex=1;
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
	$columns{'name_url'}="'".TOM::Security::form::sql_escape(TOM::Net::URI::rewrite::convert($env{'product_lng.name'},'notlower'=>1))."'"
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
		$content_reindex=1;
	}
	
	
	# PRODUCT_SYM
	
	if ($env{'product_sym.ID'})
	{
		$env{'product_sym.ID'}+=0;
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
			$content_reindex=1;
		}
		
		if ($env{'product_sym.replace'})
		{
			my $sql=qq{
				SELECT
					*
				FROM
					`$App::910::db_name`.`a910_product_sym`
				WHERE
					ID_entity=$env{'product.ID_entity'} AND
					ID != $env{'product_sym.ID'}
				LIMIT 1
			};
			my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
			while (my %db0_line=$sth0{'sth'}->fetchhash())
			{
				TOM::Database::SQL::execute(qq{
					DELETE FROM
						`$App::910::db_name`.a910_product_sym
					WHERE
						ID_entity=? AND
						ID=?
					LIMIT 1;
				},'bind'=>[
					$db0_line{'ID_entity'},
					$db0_line{'ID'}
				],'quiet'=>1);
				$content_reindex=1;
			}
			
		}
		
	}
	
#	main::_log("product_sym.ID='$env{'product_sym.ID'}'");
	
	if ($env{'prices'})
	{
		foreach my $price_level_name_code (keys %{$env{'prices'}})
		{
			# hladam cenovu hladinu
			my %sth0=TOM::Database::SQL::execute(qq{SELECT * FROM `$App::910::db_name`.`a910_price_level` WHERE name_code=? LIMIT 1},
				'bind'=>[$price_level_name_code],'quiet'=>1);
			my %price_level=$sth0{'sth'}->fetchhash();
			# nieje, vytvaram
			if (!$sth0{'rows'})
			{
				App::020::SQL::functions::new(
					'db_h' => "main",
					'db_name' => $App::910::db_name,
					'tb_name' => "a910_price_level",
					'columns' =>
					{
						'name_code' => "'".TOM::Security::form::sql_escape($price_level_name_code)."'",
						'status' => "'Y'",
					},
					'-journalize' => 1,
				);
				my %sth0=TOM::Database::SQL::execute(qq{SELECT * FROM `$App::910::db_name`.`a910_price_level` WHERE name_code=? LIMIT 1},
				'bind'=>[$price_level_name_code],'quiet'=>1);
				%price_level=$sth0{'sth'}->fetchhash();
			}
			# ???
			next unless $price_level{'ID_entity'};
			# hladam cenu
			my %sth0=TOM::Database::SQL::execute(qq{SELECT * FROM `$App::910::db_name`.`a910_product_price` WHERE ID_price=? AND ID_entity=? LIMIT 1},
				'bind'=>[$price_level{'ID_entity'},$product{'ID'}],'quiet'=>1);
			my %price=$sth0{'sth'}->fetchhash();
			
			if (ref($env{'prices'}{$price_level_name_code}) eq "HASH")
			{
				$env{'prices'}{$price_level_name_code}{'price'}=sprintf("%.3f",$env{'prices'}{$price_level_name_code}{'price'});
			}
			else
			{
				my $price=sprintf("%0.3f",$env{'prices'}{$price_level_name_code});
#				$env{'prices'}{$price_level_name_code}=sprintf("%0.3f",$env{'prices'}{$price_level_name_code});
				delete $env{'prices'}{$price_level_name_code};
				$env{'prices'}{$price_level_name_code}{'price'}=$price;
				$env{'prices'}{$price_level_name_code}{'price_full'}=$price;
			}
			
			if (!$sth0{'rows'})
			{
				App::020::SQL::functions::new(
					'db_h' => "main",
					'db_name' => $App::910::db_name,
					'tb_name' => "a910_product_price",
					'columns' =>
					{
						'ID_entity' => $product{'ID'},
						'ID_price' => $price_level{'ID_entity'},
						'price' => $env{'prices'}{$price_level_name_code}{'price'},
						'price_full' => $env{'prices'}{$price_level_name_code}{'price_full'},
						'status' => "'Y'",
					},
					'-journalize' => 1,
				);
				$content_reindex=1;
			}
			elsif ($price{'price'} ne $env{'prices'}{$price_level_name_code}{'price'})
			{
				main::_log("$price{'price'}<>$env{'prices'}{$price_level_name_code}{'price'}");
				App::020::SQL::functions::update(
					'ID' => $price{'ID'},
					'db_h' => "main",
					'db_name' => $App::910::db_name,
					'tb_name' => "a910_product_price",
					'columns' => {
						'price' => $env{'prices'}{$price_level_name_code}{'price'},
						'price_full' => $env{'prices'}{$price_level_name_code}{'price_full'},
					},
					'-journalize' => 1
				);
				$content_reindex=1;
			}
		}
	}
	
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
				'image_attrs.ID_category' => $App::910::thumbnail_cat_ID_entity,
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
	
	$env{'reindex'}=$content_reindex;
	
	if ($content_reindex)
	{
		App::020::SQL::functions::_save_changetime({
			'db_h'=>'main',
			'db_name'=>$App::910::db_name,
			'tb_name'=>'a910_product',
			'ID_entity'=>$env{'product.ID'}}
		);
		# reindex this product
		_product_index('ID'=>$env{'product.ID'}, 'commit' => $env{'commit'});
	}
	
	$t->close();
	return %env;
}


sub _product_index
{
	my %env=@_;
	return undef unless $env{'ID'}; # product.ID
	return undef unless $Ext::Solr;
	
	my $t=track TOM::Debug(__PACKAGE__."::_product_index($env{'ID'})",'timer'=>1);
	
	my @content_ent;
	my @content_id;
	
	my $status_string = $App::910::solr_status_index;

	$status_string =~ s/(\w)/\'$1\',/g; $status_string =~ s/,$//;

	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			*
		FROM
			$App::910::db_name.a910_product
		WHERE
			status IN ( $status_string ) AND
			ID=?
	},'quiet'=>1,'bind'=>[$env{'ID'}]);
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		$env{'ID_entity'}=$db0_line{'ID_entity'};
		
		push @content_ent,WebService::Solr::Field->new( 'product_number_s' => $db0_line{'product_number'} )
			if $db0_line{'product_number'};
		push @content_ent,WebService::Solr::Field->new( 'product_number_t' => $db0_line{'product_number'} )
			if $db0_line{'product_number'};
		
		push @content_ent,WebService::Solr::Field->new( 'amount_f' => $db0_line{'amount'} )
			if $db0_line{'amount'};
		
		push @content_ent,WebService::Solr::Field->new( 'status_new_s' => $db0_line{'status_new'} )
			if $db0_line{'status_new'};
		push @content_ent,WebService::Solr::Field->new( 'status_sale_s' => $db0_line{'status_sale'} )
			if $db0_line{'status_sale'};
		push @content_ent,WebService::Solr::Field->new( 'status_special_s' => $db0_line{'status_special'} )
			if $db0_line{'status_special'};
		push @content_ent,WebService::Solr::Field->new( 'status_recommended_s' => $db0_line{'status_recommended'} )
			if $db0_line{'status_recommended'};
		push @content_id,WebService::Solr::Field->new( 'status_s' => $db0_line{'status'} )
			if $db0_line{'status'};
		
		if ($db0_line{'datetime_next_index'})
		{
			$db0_line{'datetime_next_index'}=~s| (\d\d)|T$1|;
			$db0_line{'datetime_next_index'}.="Z";
			push @content_id,WebService::Solr::Field->new( 'next_index_tdt' => $db0_line{'datetime_next_index'} );
		}

		if ($db0_line{'datetime_publish_start'})
		{
			$db0_line{'datetime_publish_start'}=~s| (\d\d)|T$1|;
			$db0_line{'datetime_publish_start'}.="Z";
			push @content_id,WebService::Solr::Field->new( 'datetime_publish_start_tdt' => $db0_line{'datetime_publish_start'} );
		}

		if ($db0_line{'datetime_publish_stop'})
		{
			$db0_line{'datetime_publish_stop'}=~s| (\d\d)|T$1|;
			$db0_line{'datetime_publish_stop'}.="Z";
			push @content_id,WebService::Solr::Field->new( 'datetime_publish_stop_tdt' => $db0_line{'datetime_publish_stop'} );
		}

		my %metadata=App::020::functions::metadata::parse($db0_line{'metadata'});
		foreach my $sec(keys %metadata)
		{
			foreach (keys %{$metadata{$sec}})
			{
				next unless $metadata{$sec}{$_};
				if ($_=~s/\[\]$//)
				{
					# this is comma separated array
					foreach my $val (split(';',$metadata{$sec}{$_.'[]'}))
					{push @content_ent,WebService::Solr::Field->new( $sec.'.'.$_.'_sm' => $val)}
					push @content_ent,WebService::Solr::Field->new( 'metadata_used_sm' => $sec.'.'.$_);
					next;
				}
				
				push @content_ent,WebService::Solr::Field->new( $sec.'.'.$_.'_s' => "$metadata{$sec}{$_}" );
				if ($metadata{$sec}{$_}=~/^[0-9]{1,9}$/)
				{
					push @content_ent,WebService::Solr::Field->new( $sec.'.'.$_.'_i' => "$metadata{$sec}{$_}" );
				}
				if ($metadata{$sec}{$_}=~/^[0-9\.]{1,9}$/)
				{
					push @content_ent,WebService::Solr::Field->new( $sec.'.'.$_.'_f' => "$metadata{$sec}{$_}" );
				}
				
				# list of used metadata fields
				push @content_ent,WebService::Solr::Field->new( 'metadata_used_sm' => $sec.'.'.$_ );
			}
		}
		
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				$App::910::db_name.a910_product_ent
			WHERE
				ID_entity=?
		},'quiet'=>1,'bind'=>[$db0_line{'ID_entity'}]);
		if (my %db1_line=$sth1{'sth'}->fetchhash())
		{
			push @content_ent,WebService::Solr::Field->new( 'product_type_s' => $db1_line{'product_type'} );
			push @content_ent,WebService::Solr::Field->new( 'posix_owner_s' => $db1_line{'posix_owner'} );
			
			my %sth2=TOM::Database::SQL::execute(qq{
				SELECT
					name
				FROM
					`$App::910::db_name`.a910_product_brand
				WHERE
					ID=?
			},'quiet'=>1,'bind'=>[$db1_line{'ID_brand'}]);
			if (my %db2_line=$sth2{'sth'}->fetchhash())
			{
				push @content_ent,WebService::Solr::Field->new( 'brand_f' =>  $db1_line{'ID_brand'});
				push @content_ent,WebService::Solr::Field->new( 'brand_name_s' =>  $db2_line{'name'});
				push @content_ent,WebService::Solr::Field->new( 'brand_name_t' =>  $db2_line{'name'});
			}
		}
		
		# symlinks
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT
				a910_product_sym.ID
			FROM
				$App::910::db_name.a910_product_sym
			WHERE
				a910_product_sym.status='Y'
				AND a910_product_sym.ID_entity=?
		},'quiet'=>1,'bind'=>[$env{'ID_entity'}]);
		while (my %db1_line=$sth1{'sth'}->fetchhash())
		{
#			main::_log("cat $db1_line{'ID'}");
			push @content_ent,WebService::Solr::Field->new( 'cat' =>  $db1_line{'ID'}); # product_cat.ID_entity
		}
		
		# hits
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT
				COUNT(*) AS cnt
			FROM
				$App::910::db_name.a910_product_hit
			WHERE
				ID_product = ?
		},'quiet'=>1,'bind'=>[$env{'ID'}]);
		if (my %db1_line=$sth1{'sth'}->fetchhash())
		{push @content_ent,WebService::Solr::Field->new( 'hits_i' =>  $db1_line{'cnt'});}
		
		# hits 7days
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT
				COUNT(*) AS cnt
			FROM
				$App::910::db_name.a910_product_hit
			WHERE
				ID_product = ?
				AND datetime_event >= DATE_SUB(NOW(),INTERVAL 7 DAY)
		},'quiet'=>1,'bind'=>[$env{'ID'}]);
		if (my %db1_line=$sth1{'sth'}->fetchhash())
		{push @content_ent,WebService::Solr::Field->new( 'hits_7dy_i' =>  $db1_line{'cnt'})}
		
		# hits 24hr
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT
				COUNT(*) AS cnt
			FROM
				$App::910::db_name.a910_product_hit
			WHERE
				ID_product = ?
				AND datetime_event >= DATE_SUB(NOW(),INTERVAL 24 HOUR)
		},'quiet'=>1,'bind'=>[$env{'ID'}]);
		if (my %db1_line=$sth1{'sth'}->fetchhash())
		{push @content_ent,WebService::Solr::Field->new( 'hits_24hr_i' =>  $db1_line{'cnt'})}
		
		# rating_variable
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT
				a910_product_rating_variable.score_variable AS var,
				AVG(a910_product_rating_variable.score_value) AS val,
				COUNT(DISTINCT(a910_product_rating.ID_entity)) AS cnt
			FROM
				$App::910::db_name.a910_product_rating_variable
			INNER JOIN a910_product_rating ON
			(
				a910_product_rating.ID_entity = a910_product_rating_variable.ID_entity
			)
			WHERE
				a910_product_rating.score_basic IS NULL AND
				a910_product_rating.status='Y' AND
				a910_product_rating.ID_product = ?
			GROUP BY
				a910_product_rating_variable.score_variable
		},'quiet'=>1,'bind'=>[$env{'ID'}]);
		my $i_count;
		my $i_sum;
		my $i_avg;
		while (my %db1_line=$sth1{'sth'}->fetchhash())
		{
			main::_log("rating variable '$db1_line{'var'}' cnt='$db1_line{'cnt'}'");
			my $var=$db1_line{'var'};
			$var=lc(Int::charsets::encode::UTF8_ASCII($var));
			$var=~s|[^\w]||g;
			$i_count++;
			$i_sum+=$db1_line{'val'};
			push @content_ent,WebService::Solr::Field->new( 'Rating_variable.'.$var.'_i' =>  int($db1_line{'val'}+0));
		}
		
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT
				AVG(IF (rating.score_basic, rating.score_basic,
					(SELECT AVG(rating_variable.score_value) AS val FROM $App::910::db_name.a910_product_rating_variable AS rating_variable WHERE rating.ID_entity = rating_variable.ID_entity)))
					AS score,
				COUNT(rating.ID) AS ratings
			FROM
				$App::910::db_name.a910_product_rating AS rating
			WHERE
				rating.status='Y'
				AND rating.ID_product = ?
		},'quiet'=>1,'bind'=>[$env{'ID'}]);
		my %db1_line=$sth1{'sth'}->fetchhash();
		
		if ($db1_line{'ratings'})
		{
			$db1_line{'score'} = 0 unless $db1_line{'score'};
			main::_log("ratings avg='$db1_line{'score'}' count='$db1_line{'ratings'}'");
			push @content_ent,WebService::Solr::Field->new( 'Rating_variable_count_i' =>  int($db1_line{'ratings'}));
			push @content_ent,WebService::Solr::Field->new( 'Rating_variable_avg_i' =>  int($db1_line{'score'}));
			push @content_ent,WebService::Solr::Field->new( 'Rating_variable_avg_f' =>  $db1_line{'score'});
		}
		
		# rating in last 6months
		if ($db1_line{'ratings'})
		{
			my %sth1=TOM::Database::SQL::execute(qq{
				SELECT
					AVG(IF (rating.score_basic, rating.score_basic,
						(SELECT AVG(rating_variable.score_value) AS val FROM $App::910::db_name.a910_product_rating_variable AS rating_variable WHERE rating.ID_entity = rating_variable.ID_entity)))
						AS score,
					COUNT(rating.ID) AS ratings
				FROM
					$App::910::db_name.a910_product_rating AS rating
				WHERE
					rating.status='Y'
					AND rating.datetime_rating >= DATE_SUB(NOW(),INTERVAL 6 MONTH)
					AND rating.ID_product = ?
			},'quiet'=>1,'bind'=>[$env{'ID'}]);
			my %db1_line=$sth1{'sth'}->fetchhash();
			if ($db1_line{'ratings'})
			{
				main::_log("6mo ratings avg='$db1_line{'score'}' count='$db1_line{'ratings'}'");
				$db1_line{'score'} = 0 unless $db1_line{'score'};
				push @content_ent,WebService::Solr::Field->new( 'Rating_variable_6mo_count_i' =>  int($db1_line{'ratings'}));
				push @content_ent,WebService::Solr::Field->new( 'Rating_variable_6mo_avg_i' =>  int($db1_line{'score'}));
				push @content_ent,WebService::Solr::Field->new( 'Rating_variable_6mo_avg_f' =>  $db1_line{'score'});
			}
		}
		
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT
				COUNT(rating.ID) AS ratings
			FROM
				$App::910::db_name.a910_product_rating AS rating
			WHERE
				rating.status='Y'
				AND rating.posix_owner != ''
				AND rating.description IS NOT NULL
				AND rating.status_publish='Y'
				AND rating.ID_product = ?
		},'quiet'=>1,'bind'=>[$env{'ID'}]);
		my %db1_line=$sth1{'sth'}->fetchhash();
		if ($db1_line{'ratings'})
		{
			push @content_ent,WebService::Solr::Field->new( 'Rating_public_count_i' =>  int($db1_line{'ratings'}));
		}
		
		if (my $relation=(App::160::SQL::get_relations(
			'db_name' => $App::910::db_name,
			'l_prefix' => 'a910',
			'l_table' => 'product',
			'l_ID_entity' => $env{'ID'},
			'rel_type' => 'thumbnail',
			'r_prefix' => "a501",
			'r_table' => "image",
			'status' => "Y",
			'limit' => 1
		))[0])
		{
			push @content_ent,WebService::Solr::Field->new( 'is_thumbnail_i' => 1);
			push @content_ent,WebService::Solr::Field->new( 'is_thumbnail_s' => 'Y');
			push @content_ent,WebService::Solr::Field->new( 'thumbnail_i' => $relation->{'r_ID_entity'});
		}
		
		# prices
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT
				a910_product_price.*,
				a910_price_level.name_code
			FROM
				$App::910::db_name.a910_product_price
			INNER JOIN $App::910::db_name.a910_price_level ON
			(
				a910_product_price.ID_price = a910_price_level.ID_entity
			)
			WHERE
				a910_product_price.ID_entity = ?
		},'quiet'=>1,'bind'=>[$env{'ID'}]);
		while (my %db1_line=$sth1{'sth'}->fetchhash())
		{
			next if $db1_line{'price'} == 0;
			push @content_ent,WebService::Solr::Field->new( 'price.'.$db1_line{'name_code'}.'_f' =>  $db1_line{'price'});
#			push @content_ent,WebService::Solr::Field->new( 'price.'.$db1_line{'name_code'}.'_VAT_f' =>  );
			push @content_ent,WebService::Solr::Field->new( 'price.'.$db1_line{'name_code'}.'_full_f' =>  $db1_line{'price_full'} || $db1_line{'price'});
		}
		
		# set
		foreach my $relation (App::160::SQL::get_relations(
			'db_name' => $App::910::db_name,
			'l_prefix' => 'a910',
			'l_table' => 'product',
			'l_ID_entity' => $db0_line{'ID'},
			'r_prefix' => "a910",
			'r_table' => "product",
			'rel_type' => "product_set",
			'status' => "Y"
		))
		{
			
			push @content_id,WebService::Solr::Field->new( 'set_product_sm' =>  $relation->{'r_ID_entity'}.':'.$relation->{'quantifier'});
			
		}
		
	}
	
	my %content;
	
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			*
		FROM
			$App::910::db_name.a910_product_lng
		WHERE
			status='Y'
			AND ID_entity=?
	},'quiet'=>1,'bind'=>[$env{'ID'}]);
	while (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		my $lng=$db0_line{'lng'};
#		main::_log("product_lng ID='$db0_line{'ID'}' lng='$lng'");
		
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT
				a910_product_sym.ID,
				a910_product_cat.ID_charindex
			FROM
				$App::910::db_name.a910_product_sym
			INNER JOIN $App::910::db_name.a910_product_cat ON
			(
				a910_product_sym.ID = a910_product_cat.ID_entity
				AND a910_product_cat.lng = ?
			)
			WHERE
				a910_product_sym.status='Y'
				AND a910_product_sym.ID_entity=?
		},'quiet'=>1,'bind'=>[$db0_line{'lng'},$env{'ID_entity'}]);
		while (my %db1_line=$sth1{'sth'}->fetchhash())
		{
#			main::_log("cat+ $db1_line{'ID'} $db1_line{'ID_charindex'}");
			push @{$content{$lng}},WebService::Solr::Field->new( 'cat_charindex_sm' =>  $db1_line{'ID_charindex'}); # product_cat.ID_entity
		}
		
		# save original HTML values
		push @{$content{$db0_line{'lng'}}},WebService::Solr::Field->new( 'description_short_orig_s' => $db0_line{'description_short'} )
			if $db0_line{'description_short'};
		push @{$content{$db0_line{'lng'}}},WebService::Solr::Field->new( 'description_orig_s' => $db0_line{'description'} )
			if $db0_line{'description'};
		
		for my $part('description_short', 'description')
		{
			$db0_line{$part}=~s|<.*?>||gms;
			$db0_line{$part}=~s|&nbsp;| |gms;
			$db0_line{$part}=~s|  | |gms;
#			for (0,1,2,4,11,'B','0161','0165')
#			{$db0_line{$part}=~s|\x{$_}||g;}
		}
		
		push @{$content{$lng}},WebService::Solr::Field->new( 'lng_s' => $lng );
		
		push @{$content{$lng}},WebService::Solr::Field->new( 'name' => $db0_line{'name'} )
			if $db0_line{'name'};
		push @{$content{$lng}},WebService::Solr::Field->new( 'title' => $db0_line{'name'} )
			if $db0_line{'name'};
		push @{$content{$lng}},WebService::Solr::Field->new( 'name_url_s' => $db0_line{'name_url'} )
			if $db0_line{'name_url'};
		push @{$content{$lng}},WebService::Solr::Field->new( 'subject' => $db0_line{'name_long'} )
			if ($db0_line{'name_long'});
		
		push @{$content{$db0_line{'lng'}}},WebService::Solr::Field->new( 'description' => $db0_line{'description_short'} )
			if $db0_line{'description_short'};
		
#		print $db0_line{'description'}."\n";
#		my $len=9268;
#		print "!".ord(substr($db0_line{'description'},$len-1,1))."!\n";
#		print "!".ord(substr($db0_line{'description'},$len,1))."!\n";
#		print "!".ord(substr($db0_line{'description'},$len+1,1))."!\n";
#		$db0_line{'description'}=substr($db0_line{'description'},0,$len);
		
		push @{$content{$db0_line{'lng'}}},WebService::Solr::Field->new( 'text' => $db0_line{'description'} )
			if $db0_line{'description'};
		push @{$content{$db0_line{'lng'}}},WebService::Solr::Field->new( 'keywords' => $db0_line{'keywords'} )
			if $db0_line{'keywords'};
		
		if ($db0_line{'datetime_modified'})
		{
			$db0_line{'datetime_modified'}=~s| (\d\d)|T$1|;
			$db0_line{'datetime_modified'}.="Z";
			push @{$content{$lng}},WebService::Solr::Field->new( 'last_modified' => $db0_line{'datetime_modified'} );
		}
		
	}
	
	use Data::Dumper;
#	print Dumper(@content_ent);
	
	my $solr = Ext::Solr::service();
	
	# how many products of this type we have indexed?
	my $response = $solr->search( "+id:".$App::910::db_name.".a910_product.* +ID_i:$env{'ID'}" );
	for my $doc ( $response->docs )
	{
		my $lng=$doc->value_for( 'lng_s' );
		if (!$content{$lng})
		{
			$solr->delete_by_id($doc->value_for('id'));
		}
	}
	
	my $last_indexed=$tom::Fyear."-".$tom::Fmom."-".$tom::Fmday."T".$tom::Fhour.":".$tom::Fmin.":".$tom::Fsec."Z";
	foreach my $lng (keys %content)
	{
		my $id=$App::910::db_name.".a910_product.".$lng.".".$env{'ID'};
		main::_log("index id='$id'");
		
		my $doc = WebService::Solr::Document->new();
		
		$doc->add_fields((
			WebService::Solr::Field->new( 'id' => $id ),
			@content_ent,
			@content_id,
			@{$content{$lng}},
			WebService::Solr::Field->new( 'db_s' => $App::910::db_name ),
			WebService::Solr::Field->new( 'addon_s' => 'a910_product' ),
			WebService::Solr::Field->new( 'ID_i' => $env{'ID'} ),
			WebService::Solr::Field->new( 'last_indexed_tdt' => $last_indexed )
		));
		
		$solr->add($doc);
	}

	if ($env{'commit'})
	{
		$solr->commit();
	}
	
	$t->close();
}


sub _product_cat_index
{
	my %env=@_;
	return undef unless $env{'ID'};
	return undef unless $Ext::Solr;
	
	my $t=track TOM::Debug(__PACKAGE__."::_product_cat_index()",'timer'=>1);
	
	my $solr = Ext::Solr::service();
	
	my %content;
	
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			*
		FROM
			$App::910::db_name.a910_product_cat
		WHERE
			status IN ('Y','L')
			AND ID=?
	},'quiet'=>1,'bind'=>[$env{'ID'}]);
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		main::_log("found");
		
		my $id=$App::910::db_name.".a910_product_cat.".$db0_line{'lng'}.".".$db0_line{'ID'};
		main::_log("index id='$id'");
		
		my $doc = WebService::Solr::Document->new();
		
		$db0_line{'description'}=~s|<.*?>||gms;
		$db0_line{'description'}=~s|&nbsp;| |gms;
		$db0_line{'description'}=~s|  | |gms;
		
		$db0_line{'datetime_create'}=~s| (\d\d)|T$1|;
		$db0_line{'datetime_create'}.="Z";
		
		
		$doc->add_fields((
			WebService::Solr::Field->new( 'id' => $id ),
			
			WebService::Solr::Field->new( 'name' => $db0_line{'name'} ),
			WebService::Solr::Field->new( 'name_t' => $db0_line{'name'} ),
			WebService::Solr::Field->new( 'title' => $db0_line{'name'} ),
			WebService::Solr::Field->new( 'name_url_s' => $db0_line{'name_url'} || ''),
			WebService::Solr::Field->new( 'title' => $db0_line{'name'} ),
			
			WebService::Solr::Field->new( 'description' => $db0_line{'description'} ),
			
			WebService::Solr::Field->new( 'last_modified' => $db0_line{'datetime_create'} ),
			
			WebService::Solr::Field->new( 'db_s' => $App::910::db_name ),
			WebService::Solr::Field->new( 'addon_s' => 'a910_product_cat' ),
			WebService::Solr::Field->new( 'lng_s' => $db0_line{'lng'} ),
			WebService::Solr::Field->new( 'ID_i' => $db0_line{'ID'} ),
			WebService::Solr::Field->new( 'ID_entity_i' => $db0_line{'ID_entity'} ),
		));
		
		$solr->add($doc);
	}
	else
	{
		main::_log("not found active ID",1);
		my $response = $solr->search( "id:".$App::910::db_name.".a910_product_cat.* AND ID_i:$env{'ID'}" );
		for my $doc ( $response->docs )
		{
			$solr->delete_by_id($doc->value_for('id'));
		}
	}
	
	$t->close();
}


sub _product_brand_index
{
	my %env=@_;
	return undef unless $env{'ID'};
	return undef unless $Ext::Solr;
	
	my $t=track TOM::Debug(__PACKAGE__."::_product_brand_index()",'timer'=>1);
	
	my $solr = Ext::Solr::service();
	
	my %content;
	
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			*
		FROM
			$App::910::db_name.a910_product_brand
		WHERE
			status IN ('Y','L')
			AND ID=?
	},'quiet'=>1,'bind'=>[$env{'ID'}]);
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		main::_log("found '$db0_line{'name'}'");
		
		my $id=$App::910::db_name.".a910_product_brand.en.".$db0_line{'ID'};
		main::_log("index id='$id'");
		
		my $doc = WebService::Solr::Document->new();
		
#		$db0_line{'description'}=~s|<.*?>||gms;
#		$db0_line{'description'}=~s|&nbsp;| |gms;
#		$db0_line{'description'}=~s|  | |gms;
		
		$db0_line{'datetime_create'}=~s| (\d\d)|T$1|;
		$db0_line{'datetime_create'}.="Z";
		
		
		$doc->add_fields((
			WebService::Solr::Field->new( 'id' => $id ),
			
			WebService::Solr::Field->new( 'name' => $db0_line{'name'} ),
			WebService::Solr::Field->new( 'name_t' => $db0_line{'name'} ),
			WebService::Solr::Field->new( 'name_url_s' => $db0_line{'name_url'} || ''),
			WebService::Solr::Field->new( 'title' => $db0_line{'name'} ),
			
#			WebService::Solr::Field->new( 'description' => $db0_line{'description'} ),
			
			WebService::Solr::Field->new( 'last_modified' => $db0_line{'datetime_create'} ),
			
			WebService::Solr::Field->new( 'db_s' => $App::910::db_name ),
			WebService::Solr::Field->new( 'addon_s' => 'a910_product_brand' ),
			WebService::Solr::Field->new( 'lng_s' => 'en' ),
			WebService::Solr::Field->new( 'ID_i' => $db0_line{'ID'} ),
			WebService::Solr::Field->new( 'ID_entity_i' => $db0_line{'ID_entity'} ),
		));
		
		$solr->add($doc);
	}
	else
	{
		main::_log("not found active ID",1);
		my $response = $solr->search( "id:".$App::910::db_name.".a910_product_brand.* AND ID_i:$env{'ID'}" );
		for my $doc ( $response->docs )
		{
			$solr->delete_by_id($doc->value_for('id'));
		}
	}
	
	$t->close();
}


sub _a210_by_cat
{
	my $cats=shift;
	my %env=@_;
	
	$env{'lng'}=$tom::lng unless $env{'lng'};
	my $cache_key=$env{'lng'}.'::'.join('::',@{$cats});
	
	# changetimes
	my $changetime_a910=App::020::SQL::functions::_get_changetime({
		'db_name' => $App::910::db_name,
		'tb_name' => 'a910_product_cat',
	});
	my $changetime_a210=App::020::SQL::functions::_get_changetime({
		'db_name' => $App::210::db_name,
		'tb_name' => 'a210_page',
	});
	
	if ($TOM::CACHE && $TOM::CACHE_memcached && $main::FORM{'_rc'}!=-2)
	{
#		main::_log("get cached");
		my $cache=$Ext::CacheMemcache::cache->get(
			'namespace' => "fnc_cache",
			'key' => 'App::910::functions::_a210_by_cat::'.$cache_key
		);
		if (($cache->{'time'} > $changetime_a210) && ($cache->{'time'} > $changetime_a910))
		{
#			print "value=$cache->{'value'} time=$cache->{'time'} key=$cache_key\n";
#			main::_log("found, return");
			return $cache->{'value'};
		}
	}
	
	# find path
	my @categories;
	my %sql_def=('db_h' => "main",'db_name' => $App::910::db_name,'tb_name' => "a910_product_cat");
	foreach my $cat(@{$cats})
	{
#		print "mam $cat";
		my %sth0=TOM::Database::SQL::execute(
			qq{SELECT ID FROM $App::910::db_name.a910_product_cat WHERE ID_entity=? AND lng=? LIMIT 1},
			'bind'=>[$cat,$env{'lng'}],'log'=>0,'quiet'=>1,
			'-cache' => 600,
			'-cache_changetime' => App::020::SQL::functions::_get_changetime({
				'db_name' => $App::910::db_name,
				'tb_name' => 'a910_product_cat',
			})
		);
		next unless $sth0{'rows'};
		my %db0_line=$sth0{'sth'}->fetchhash();
		my $i;
		foreach my $p(
			App::020::SQL::functions::tree::get_path(
				$db0_line{'ID'},
				%sql_def,
				'-slave' => 1,
				'-cache' => 3600
				# autocached by changetime
			)
		)
		{
			push @{$categories[$i]},$p->{'ID_entity'};
			$i++;
		}
	}
	
#	print Dumper(\@categories);
	
	my $category;
	for my $i (1 .. @categories)
	{
		foreach my $cat (@{$categories[-$i]})
		{
#			push @{$product->{'log'}},"find $i ".$cat;
#			print "aha $i $cat\n";
			my %db0_line;
			foreach my $relation(App::160::SQL::get_relations(
				'db_name' => $App::210::db_name,
				'l_prefix' => 'a210',
				'l_table' => 'page',
				#'l_ID_entity' = > ???
				'r_prefix' => "a910",
				'r_table' => "product_cat",
				'r_ID_entity' => $cat,
				'rel_type' => "link",
				'status' => "Y"
			))
			{
#				print "fakt mam\n";
				# je toto relacia na moju jazykovu verziu a je aktivna?
				my %sth0=TOM::Database::SQL::execute(
				qq{SELECT ID FROM $App::210::db_name.a210_page WHERE ID_entity=? AND lng=? AND status IN ('Y','L') LIMIT 1},
				'bind'=>[$relation->{'l_ID_entity'},$env{'lng'}],'quiet'=>1,
					'-cache' => 600,
					'-cache_changetime' => App::020::SQL::functions::_get_changetime({
						'db_name' => $App::210::db_name,
						'tb_name' => 'a210_page',
					})
				);
				next unless $sth0{'rows'};
				%db0_line=$sth0{'sth'}->fetchhash();
				last;
			}
			
			next unless $db0_line{'ID'};
			
			$category=$db0_line{'ID'};
			
			last;
		}
		last if $category;
	}
	
	if ($TOM::CACHE && $TOM::CACHE_memcached)
	{
		$Ext::CacheMemcache::cache->set(
			'namespace' => "fnc_cache",
			'key' => 'App::910::functions::_a210_by_cat::'.$cache_key,
			'value' => {
				'time' => time(),
				'value' => $category
			},
			'expiration' => '3600S'
		);
	}
	
	return $category;
}

=head2 product_rating_add()

Adds / updates a product rating


	App::910::functions::product_rating_add(
		'product_rating.ID' => 2,
		'product_rating.description' => 'I have enjoyed this product very much.',
		'product_rating.score_basic' => 5,
		
		'product_rating.variables' =>
		{
			'advanced_rating' => 50,
			'personal_score' => 10
		}
	);

=cut

sub product_rating_add
{
	my %env=@_;
	return undef unless ($env{'product.ID'} || $env{'product_rating.ID'}); # product.ID or rating.ID
	
	my $t=track TOM::Debug(__PACKAGE__."::product_rating_add()");
	
	main::_log('product.ID='.$env{'product.ID'}." product_rating.ID=".$env{'product_rating.ID'}) if $debug;
	
	my %columns;
	
	$columns{'title'} = "'".TOM::Security::form::sql_escape($env{'product_rating.title'})."'" 
		if exists ($env{'product_rating.title'});
	$columns{'description'} = "'".TOM::Security::form::sql_escape($env{'product_rating.description'})."'" 
		if exists ($env{'product_rating.description'});
	$columns{'score_basic'} = "'".TOM::Security::form::sql_escape($env{'product_rating.score_basic'})."'" 
		if exists ($env{'product_rating.score_basic'});
	$columns{'helpful_Y'} = "'".TOM::Security::form::sql_escape($env{'product_rating.helpful_Y'})."'" 
		if exists ($env{'product_rating.helpful_Y'});
	$columns{'helpful_N'} = "'".TOM::Security::form::sql_escape($env{'product_rating.helpful_N'})."'" 
		if exists ($env{'product_rating.helpful_N'});
	$columns{'status_publish'} = "'".TOM::Security::form::sql_escape($env{'product_rating.status_publish'})."'" 
		if exists ($env{'product_rating.status_publish'});
	$columns{'posix_owner'} = "'".TOM::Security::form::sql_escape($env{'product_rating.posix_owner'})."'" 
		if $env{'product_rating.posix_owner'};
	$columns{'posix_owner'} = "'".$main::USRM{'ID_user'}."'" unless $env{'product_rating.posix_owner'};
	$columns{'lng'} = "'".$env{'lng'}."'" if exists $env{'lng'};
	$columns{'lng'} = "'".$env{'product_rating.lng'}."'" if exists $env{'product_rating.lng'};

	if (!$env{'product_rating.ID'})
	{
		# rating doesn't exist, create new
		if ($env{'product.ID'} =~ /^\d+$/)
		{
			$columns{'datetime_rating'}="'".$env{'product_rating.datetime_rating'}."'"
				if $env{'product_rating.datetime_rating'};
			$columns{'datetime_rating'}='NOW()' unless $columns{'datetime_rating'};
			$env{'product_rating.ID'} = App::020::SQL::functions::new(
				'db_h' => 'main',
				'db_name' => $App::910::db_name,
				'tb_name' => 'a910_product_rating',
				'columns' => 
				{
					'ID_product' => $env{'product.ID'},
#					'datetime_rating' => 'NOW()',
					%columns
				},
				'-journalize' => 1,
				'-posix' => 1
			);
		}

		# check if there are additional variables and append them to the existing rating, now that it exists
	
		if ($env{'product_rating.ID'})
		{
			if ($env{'product_rating.variables'})
			{
				my %variables = %{$env{'product_rating.variables'}};
				
				foreach my $variable (keys %variables)
				{
					my $score_variable = "'".TOM::Security::form::sql_escape($variable)."'";
					my $score_value = "'".TOM::Security::form::sql_escape($variables{$variable})."'";
					
					# update this variable
					my $variable_id = App::020::SQL::functions::new(
						'db_h' => 'main',
						'db_name' => $App::910::db_name,
						'tb_name' => 'a910_product_rating_variable',
						'columns' => 
						{
							'ID_entity' => $env{'product_rating.ID'},
							'score_variable' => $score_variable,
							'score_value' => $score_value
						},
						'-journalize' => 1,
						'-replace' => 1
					);
					
				}
			}
		}
	}
	else
	{
		# update an existing rating
		
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::910::db_name`.`a910_product_rating`
			WHERE
				ID = ?
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1, 'log'=>0, 'bind' => [$env{'product_rating.ID'}] );
		my %rating = $sth0{'sth'}->fetchhash();
		
		my %columns_update;
		
		$columns_update{'title'} = "'".TOM::Security::form::sql_escape($env{'product_rating.title'})."'" 
			if (exists ($env{'product_rating.title'})) && $env{'product_rating.title'} ne $rating{'title'};
		$columns_update{'description'} = "'".TOM::Security::form::sql_escape($env{'product_rating.description'})."'" 
			if (exists ($env{'product_rating.description'})) && $env{'product_rating.description'} ne $rating{'description'};
		$columns_update{'score_basic'} = "'".TOM::Security::form::sql_escape($env{'product_rating.score_basic'})."'" 
			if (exists ($env{'product_rating.score_basic'})) && $env{'product_rating.score_basic'} ne $rating{'score_basic'};
		
		$columns_update{'helpful_Y'} = "'".TOM::Security::form::sql_escape($env{'product_rating.helpful_Y'})."'" 
			if (exists ($env{'product_rating.helpful_Y'})) && $env{'product_rating.helpful_Y'} ne $rating{'helpful_Y'};
		$columns_update{'helpful_N'} = "'".TOM::Security::form::sql_escape($env{'product_rating.helpful_N'})."'" 
			if (exists ($env{'product_rating.helpful_N'})) && $env{'product_rating.helpful_N'} ne $rating{'helpful_N'};
		
		$columns_update{'status_publish'} = "'".TOM::Security::form::sql_escape($env{'product_rating.status_publish'})."'" 
			if (exists ($env{'product_rating.status_publish'})) && $env{'product_rating.status_publish'} ne $rating{'status_publish'};
		
		if (keys %columns_update)
		{
			App::020::SQL::functions::update(
				'ID' => $env{'product_rating.ID'},
				'db_h' => "main",
				'db_name' => $App::910::db_name,
				'tb_name' => "a910_product_rating",
				'columns' => {%columns_update},
					'-journalize' => 1,
					'-posix' => 1
			);
		}

		# also, if we are updating an existing rating, it's rating variables need to updated or trashed
		# rating_ID (entity): $env{'product_rating.ID'}
		# 

		# get a list of rating variables to be updated
		if (ref($env{'product_rating.variables'}) eq 'HASH')
		{
			my %variables = %{$env{'product_rating.variables'}};	
		
			my $sql_rating_vars=qq{
				SELECT
					*
				FROM
					`$App::910::db_name`.`a910_product_rating_variable`
				WHERE
					ID_entity = ?
			};
			my %sth_rating=TOM::Database::SQL::execute($sql_rating_vars,'quiet'=>1, 'log'=>0, 'bind' => [$env{'product_rating.ID'}] );
				
			# trash all rating variables
			while (my %rating_variable = $sth_rating{'sth'}->fetchhash())
			{
				# does the rating variable exist in the new list of variables to be updated?
				if (exists($variables{$rating_variable{'score_variable'}}))
				{
					# update this variable
					App::020::SQL::functions::update(
						'ID' => $rating_variable{'ID'},
						'db_h' => 'main',
						'db_name' => $App::910::db_name,
						'tb_name' => 'a910_product_rating_variable',
						'columns' => {
	
							'score_value' => "'".TOM::Security::form::sql_escape($variables{$rating_variable{'score_variable'}})."'",
							'status' => "'Y'"
						},
						'-journalize' => 0
					);
				} else
				{
					# trash this
					App::020::SQL::functions::to_trash(
						'ID' => $rating_variable{'ID'},
						'db_h' => 'main',
						'db_name' => $App::910::db_name,
						'tb_name' => 'a910_product_rating_variable',
						'-journalize' => 0
					);
				}
			}
		}
	}
	
	
	
	
	
	$t->close();
	
	return $env{'product_rating.ID'};
}

=head2 product_rating_remove()

Removes a product rating and all its variables


	App::910::functions::product_rating_remove(
		'product_rating.ID' => 2
	);

=cut

sub product_rating_remove
{
	# get this rating and get all rating-variables for this rating, then trash them and reindex the product
	my %env = @_;

	if ($env{'product_rating.ID'} =~ /^\d+$/)
	{
		$env{'ID'} = $env{'product_rating.ID'};

		my $sql=qq{
			SELECT
				*
			FROM
				`$App::910::db_name`.`a910_product_rating`
			WHERE
				ID = ?
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1, 'log'=>0, 'bind' => [$env{'ID'}] );

		if (my %rating = $sth0{'sth'}->fetchhash())
		{
			my $sql2=qq{
				SELECT
					*
				FROM
					`$App::910::db_name`.`a910_product_rating_variable`
				WHERE
					ID_entity = ?
			};
			my %sth1=TOM::Database::SQL::execute($sql2,'quiet'=>1, 'log'=>0, 'bind' => [$env{'ID'}] );
			
			# trash all rating variables
			while (my %rating_variable = $sth1{'sth'}->fetchhash())
			{
				main::_log('Vymazavam: '.$rating_variable{'ID'});

				App::020::SQL::functions::to_trash(
					'ID' => $rating_variable{'ID'},
					'db_h' => 'main',
					'db_name' => $App::910::db_name,
					'tb_name' => 'a910_product_rating_variable',
					'-journalize' => 0
				);
				
			}

			# trash the master rating (entity)
			
			App::020::SQL::functions::to_trash(
				'ID' => $env{'ID'},
				'db_h' => 'main',
				'db_name' => $App::910::db_name,
				'tb_name' => 'a910_product_rating',
				'-journalize' => 1,
			);
		}
	}
}

=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
