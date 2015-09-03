#!/bin/perl
package App::950::functions;


use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



use App::950::_init;
use TOM::Security::form;
use App::160::SQL;
use POSIX qw(ceil);

our $debug=1;
our $quiet;$quiet=1 unless $debug;


sub offer_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::offer_add()");
	
	my %offer;
	
	if ($env{'offer.ID'})
	{
		$env{'offer.ID'}=$env{'offer.ID'}+0;
		undef $env{'offer.ID_entity'}; # ID_entity has lower priority as ID
		# when real ID_entity used, then read it from ID
		# when ID not found, undef ID_entity, because is invalid
		main::_log("finding offer.ID_entity by offer.ID='$env{'offer.ID'}'");
		%offer=App::020::SQL::functions::get_ID(
			'ID' => $env{'offer.ID'},
			'db_h' => "main",
			'db_name' => $App::950::db_name,
			'tb_name' => "a950_offer",
			'columns' => {'*'=>1}
		);
		if ($offer{'ID'})
		{
			$env{'offer.ID_entity'}=$offer{'ID_entity'};
			main::_log("found offer.ID_entity='$env{'offer.ID_entity'}'");
		}
		else
		{
			main::_log("not found offer.ID, undef",1);
			App::020::SQL::functions::new(
				'db_h' => "main",
				'db_name' => $App::950::db_name,
				'tb_name' => "a950_offer",
				'columns' => {
					'ID' => $env{'offer.ID'},
					'datetime_publish_start' => 'NOW()'
				},
				'-journalize' => 1,
			);
			%offer=App::020::SQL::functions::get_ID(
				'ID' => $env{'offer.ID'},
				'db_h' => "main",
				'db_name' => $App::950::db_name,
				'tb_name' => "a950_offer",
				'columns' => {'*'=>1}
			);
			$env{'offer.ID_entity'}=$offer{'ID_entity'};
		}
	}
	
	if (!$env{'offer.ID'})
	{
		main::_log("!offer.ID, create offer.ID (offer.ID_entity='$env{'offer.ID_entity'}')");
		my %columns;
		$columns{'ID_entity'}=$env{'offer.ID_entity'} if $env{'offer.ID_entity'};
		$env{'offer.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::950::db_name,
			'tb_name' => "a950_offer",
			'columns' => {%columns,'datetime_publish_start' => 'NOW()'},
			'-journalize' => 1,
		);
		%offer=App::020::SQL::functions::get_ID(
			'ID' => $env{'offer.ID'},
			'db_h' => "main",
			'db_name' => $App::950::db_name,
			'tb_name' => "a950_offer",
			'columns' => {'*'=>1}
		);
		$env{'offer.ID'}=$offer{'ID'};
		$env{'offer.ID_entity'}=$offer{'ID_entity'};
	}
	
	main::_log("offer.ID='$offer{'ID'}' offer.ID_entity='$offer{'ID_entity'}'");
	
	# update only if necessary
	my %columns;
	my %data;
	# price
	$env{'offer.price'}=sprintf("%.3f",$env{'offer.price'}) if $env{'offer.price'};
	$env{'offer.price'}='' if $env{'product.price'} eq "0.000";
	$columns{'price'}="'".TOM::Security::form::sql_escape($env{'offer.price'})."'"
		if (exists $env{'offer.price'} && ($env{'offer.price'} ne $offer{'price'}));
	$columns{'price'}='NULL' if $columns{'price'} eq "''";
	# price_currency
	$columns{'price_currency'}="'".TOM::Security::form::sql_escape($env{'offer.price_currency'})."'"
		if ($env{'offer.price_currency'} && ($env{'offer.price_currency'} ne $offer{'price_currency'}));
	# datetime_publish_start
	$columns{'datetime_publish_start'}="'".TOM::Security::form::sql_escape($env{'offer.datetime_publish_start'})."'"
		if ($env{'offer.datetime_publish_start'} && ($env{'offer.datetime_publish_start'} ne $offer{'datetime_publish_start'}));
	# datetime_publish_stop
	if ($env{'offer.datetime_publish_stop'})
	{
		$columns{'datetime_publish_stop'}="'".TOM::Security::form::sql_escape($env{'offer.datetime_publish_stop'})."'"
			if ($env{'offer.datetime_publish_stop'} && ($env{'offer.datetime_publish_stop'} ne $offer{'datetime_publish_stop'}));
	}
	elsif (exists $env{'offer.datetime_publish_stop'})
	{
		$columns{'datetime_publish_stop'} = "NULL"
			if ($env{'offer.datetime_publish_stop'} ne $offer{'datetime_publish_stop'});
	}

	# ID_org
	$columns{'ID_org'}="'".TOM::Security::form::sql_escape($env{'offer.ID_org'})."'"
		if (exists $env{'offer.ID_org'} && ($env{'offer.ID_org'} ne $offer{'ID_org'}));
	$columns{'ID_org'}='NULL' if $columns{'ID_org'} eq "''";

	# ID_user
	$columns{'ID_user'}="'".TOM::Security::form::sql_escape($env{'offer.ID_user'})."'"
		if (exists $env{'offer.ID_user'} && ($env{'offer.ID_user'} ne $offer{'ID_user'}));
	
	# alias_addon
	$columns{'alias_addon'}="'".TOM::Security::form::sql_escape($env{'offer.alias_addon'})."'"
		if (exists $env{'offer.alias_addon'} && ($env{'offer.alias_addon'} ne $offer{'alias_addon'}));
	
	# metadata
	my %metadata=App::020::functions::metadata::parse($offer{'metadata'});
	
	foreach my $section(split(';',$env{'offer.metadata.override_sections'}))
	{
		delete $metadata{$section};
	}
	
	if ($env{'offer.metadata.replace'})
	{
		if (!ref($env{'offer.metadata'}) && $env{'offer.metadata'})
		{
			%metadata=App::020::functions::metadata::parse($env{'offer.metadata'});
		}
		if (ref($env{'offer.metadata'}) eq "HASH")
		{
			%metadata=%{$env{'offer.metadata'}};
		}
	}
	else
	{
		if (!ref($env{'offer.metadata'}) && $env{'offer.metadata'})
		{
			# when metadata send as <metatree></metatree> then always replace
			%metadata=App::020::functions::metadata::parse($env{'offer.metadata'});
#			my %metadata_=App::020::functions::metadata::parse($env{'product.metadata'});
#			delete $env{'product.metadata'};
#			%{$env{'product.metadata'}}=%metadata_;
		}
		if (ref($env{'offer.metadata'}) eq "HASH")
		{
			# metadata overrride
			foreach my $section(keys %{$env{'offer.metadata'}})
			{
				foreach my $variable(keys %{$env{'offer.metadata'}{$section}})
				{
					$metadata{$section}{$variable}=$env{'offer.metadata'}{$section}{$variable};
				}
			}
		}
	}
	
	$env{'offer.metadata'}=App::020::functions::metadata::serialize(%metadata);
	
	$data{'metadata'}=$env{'offer.metadata'}
		if (exists $env{'offer.metadata'} && ($env{'offer.metadata'} ne $offer{'metadata'}));
	
	if (($main::RPC->{'offer_cat.ID'} || $main::RPC->{'offer_cat.ID_entity'}) && ($offer{'status'} eq "T"))
	{
		$env{'offer.status'}=$env{'offer.status'}||'N';
	}
	
	# status
	$data{'status'}=$env{'offer.status'}
		if ($env{'offer.status'} && ($env{'offer.status'} ne $offer{'status'}));
	
	if (keys %columns || keys %data)
	{
		App::020::SQL::functions::update(
			'ID' => $env{'offer.ID'},
			'db_h' => "main",
			'db_name' => $App::950::db_name,
			'tb_name' => "a950_offer",
			'columns' => {%columns},
			'data' => {%data},
			'-posix' => 1,
			'-journalize' => 1
		);
	}
	
	
	# LNG DETECTION
	if ($env{'offer_cat.ID'})
	{
		my $sql=qq{
			SELECT
				*
			FROM
				$App::950::db_name.a950_offer_cat
			WHERE
				ID=$env{'offer_cat.ID'}
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %offer_cat=$sth0{'sth'}->fetchhash();
		$env{'offer_cat.ID_entity'}=$offer_cat{'ID_entity'};
	}
	$env{'offer_cat.ID_entity'} = $env{'offer_cat.ID_entity'} || $env{'offer_rel_cat.ID_category'};
	
	my %offer_rel_cat;
	my %offer_cat;
	
	# check lng_param
	$env{'offer_lng.lng'}=$tom::lng unless $env{'offer_lng.lng'};
	main::_log("lng='$env{'offer_lng.lng'}'");
	
	# PRODUCT_LNG
	
	my %offer_lng;
	if (!$env{'offer_lng.ID'})
	{
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::950::db_name`.`a950_offer_lng`
			WHERE
				ID_entity=$env{'offer.ID'} AND
				lng='$env{'offer_lng.lng'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%offer_lng=$sth0{'sth'}->fetchhash();
		$env{'offer_lng.ID'}=$offer_lng{'ID'} if $offer_lng{'ID'};
	}
	
	if (!$env{'offer_lng.ID'}) # if product_lng not defined, create a new
	{
		main::_log("!offer_lng.ID, create offer_lng.ID (offer_lng.lng='$env{'offer_lng.lng'}')");
		my %data;
		$data{'ID_entity'}=$env{'offer.ID'};
		$data{'lng'}=$env{'offer_lng.lng'};
		$env{'offer_lng.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::950::db_name,
			'tb_name' => "a950_offer_lng",
			'data' => {%data},
			'-journalize' => 1,
		);
		%offer_lng=App::020::SQL::functions::get_ID(
			'ID' => $env{'offer_lng.ID'},
			'db_h' => "main",
			'db_name' => $App::950::db_name,
			'tb_name' => "a950_offer_lng",
			'columns' => {'*'=>1}
		);
		$env{'offer_lng.ID'}=$offer_lng{'ID'};
		$env{'offer_lng.ID_entity'}=$offer_lng{'ID_entity'};
	}
	
	main::_log("offer_lng.ID='$offer_lng{'ID'}' offer_lng.ID_entity='$offer_lng{'ID_entity'}'");
	
	# update only if necessary
	my %columns;
	my %data;
	# name
	$data{'name'}=$env{'offer_lng.name'}
		if ($env{'offer_lng.name'} && ($env{'offer_lng.name'} ne $offer_lng{'name'}));
	$data{'name_url'}=TOM::Net::URI::rewrite::convert($env{'offer_lng.name'},'notlower'=>1)
		if ($env{'offer_lng.name'} && ($env{'offer_lng.name'} ne $offer_lng{'name'}));
	# name_long
	$data{'name_long'}=$env{'offer_lng.name_long'}
		if ($env{'offer_lng.name_long'} && ($env{'offer_lng.name_long'} ne $offer_lng{'name_long'}));
	# abstract
	$data{'abstract'}=$env{'offer_lng.abstract'}
		if ($env{'offer_lng.abstract'} && ($env{'offer_lng.abstract'} ne $offer_lng{'abstract'}));
	# body
	$data{'body'}=$env{'offer_lng.body'}
		if ($env{'offer_lng.body'} && ($env{'offer_lng.body'} ne $offer_lng{'body'}));
	
	if (keys %columns || keys %data)
	{
		App::020::SQL::functions::update(
			'ID' => $env{'offer_lng.ID'},
			'db_h' => "main",
			'db_name' => $App::950::db_name,
			'tb_name' => "a950_offer_lng",
			'columns' => {%columns},
			'data' => {%data},
			'-journalize' => 1,
			'-posix' => 1,
		);
	}
	
	main::_log("offer_cat.ID_entity='$env{'offer_cat.ID_entity'}'");
	
	if ($env{'offer_cat.ID_entity'})
	{
		TOM::Database::SQL::execute(qq{
			REPLACE INTO `$App::950::db_name`.a950_offer_rel_cat
			(
				ID_offer,
				ID_category
			)
			VALUES
			(
				?,?
			)
		},'bind'=>[$env{'offer.ID'},$env{'offer_cat.ID_entity'}],'quiet'=>1);
	}
	
	$t->close();
	return %offer;
}


1;
