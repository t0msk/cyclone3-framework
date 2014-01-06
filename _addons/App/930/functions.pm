#!/bin/perl
package App::930::functions;

=head1 NAME

App::930::functions

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

L<App::930::_init|app/"930/_init.pm">

=item *

L<TOM::Security::form|lib/"TOM/Security/form.pm">

=back

=cut

use App::930::_init;
use TOM::Security::form;
use App::160::SQL;
use POSIX qw(ceil);

our $debug=1;
our $quiet;$quiet=1 unless $debug;


sub rfp_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::rfp_add()");
	
	my %rfp;
	
	if ($env{'rfp.ID'})
	{
		$env{'rfp.ID'}=$env{'rfp.ID'}+0;
		undef $env{'rfp.ID_entity'}; # ID_entity has lower priority as ID
		# when real ID_entity used, then read it from ID
		# when ID not found, undef ID_entity, because is invalid
		main::_log("finding rfp.ID_entity by rfp.ID='$env{'rfp.ID'}'");
		%rfp=App::020::SQL::functions::get_ID(
			'ID' => $env{'rfp.ID'},
			'db_h' => "main",
			'db_name' => $App::930::db_name,
			'tb_name' => "a930_rfp",
			'columns' => {'*'=>1}
		);
		if ($rfp{'ID'})
		{
			$env{'rfp.ID_entity'}=$rfp{'ID_entity'};
			main::_log("found rfp.ID_entity='$env{'rfp.ID_entity'}'");
		}
		else
		{
			main::_log("not found rfp.ID, undef",1);
			App::020::SQL::functions::new(
				'db_h' => "main",
				'db_name' => $App::930::db_name,
				'tb_name' => "a930_rfp",
				'columns' => {
					'ID' => $env{'rfp.ID'},
					'datetime_publish_start' => 'NOW()'
				},
				'-journalize' => 1,
			);
			%rfp=App::020::SQL::functions::get_ID(
				'ID' => $env{'rfp.ID'},
				'db_h' => "main",
				'db_name' => $App::930::db_name,
				'tb_name' => "a930_rfp",
				'columns' => {'*'=>1}
			);
			$env{'rfp.ID_entity'}=$rfp{'ID_entity'};
		}
	}
	
	if (!$env{'rfp.ID'})
	{
		main::_log("!rfp.ID, create rfp.ID (rfp.ID_entity='$env{'rfp.ID_entity'}')");
		my %columns;
		$columns{'ID_entity'}=$env{'rfp.ID_entity'} if $env{'rfp.ID_entity'};
		$env{'rfp.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::930::db_name,
			'tb_name' => "a930_rfp",
			'columns' => {%columns,'datetime_publish_start' => 'NOW()'},
			'-journalize' => 1,
		);
		%rfp=App::020::SQL::functions::get_ID(
			'ID' => $env{'rfp.ID'},
			'db_h' => "main",
			'db_name' => $App::930::db_name,
			'tb_name' => "a930_rfp",
			'columns' => {'*'=>1}
		);
		$env{'rfp.ID'}=$rfp{'ID'};
		$env{'rfp.ID_entity'}=$rfp{'ID_entity'};
	}
	
	main::_log("rfp.ID='$rfp{'ID'}' rfp.ID_entity='$rfp{'ID_entity'}'");
	
	# update only if necessary
	my %columns;
	my %data;
	# price
	$env{'rfp.price'}=sprintf("%.3f",$env{'rfp.price'}) if $env{'rfp.price'};
	$env{'rfp.price'}='' if $env{'product.price'} eq "0.000";
	$columns{'price'}="'".TOM::Security::form::sql_escape($env{'rfp.price'})."'"
		if (exists $env{'rfp.price'} && ($env{'rfp.price'} ne $rfp{'price'}));
	$columns{'price'}='NULL' if $columns{'price'} eq "''";
	# price_currency
	$columns{'price_currency'}="'".TOM::Security::form::sql_escape($env{'rfp.price_currency'})."'"
		if ($env{'rfp.price_currency'} && ($env{'rfp.price_currency'} ne $rfp{'price_currency'}));
	# datetime_publish_start
	$columns{'datetime_publish_start'}="'".TOM::Security::form::sql_escape($env{'rfp.datetime_publish_start'})."'"
		if ($env{'rfp.datetime_publish_start'} && ($env{'rfp.datetime_publish_start'} ne $rfp{'datetime_publish_start'}));
	# datetime_publish_stop
	if ($env{'rfp.datetime_publish_stop'})
	{
		$columns{'datetime_publish_stop'}="'".TOM::Security::form::sql_escape($env{'rfp.datetime_publish_stop'})."'"
			if ($env{'rfp.datetime_publish_stop'} && ($env{'rfp.datetime_publish_stop'} ne $rfp{'datetime_publish_stop'}));
	}
	elsif (exists $env{'rfp.datetime_publish_stop'})
	{
		$columns{'datetime_publish_stop'} = "NULL"
			if ($env{'rfp.datetime_publish_stop'} ne $rfp{'datetime_publish_stop'});
	}

	# ID_org
	$columns{'ID_org'}="'".TOM::Security::form::sql_escape($env{'rfp.ID_org'})."'"
		if (exists $env{'rfp.ID_org'} && ($env{'rfp.ID_org'} ne $rfp{'ID_org'}));
	$columns{'ID_org'}='NULL' if $columns{'ID_org'} eq "''";

	# ID_user
	$columns{'ID_user'}="'".TOM::Security::form::sql_escape($env{'rfp.ID_user'})."'"
		if (exists $env{'rfp.ID_user'} && ($env{'rfp.ID_user'} ne $rfp{'ID_user'}));
	
	# metadata
	my %metadata=App::020::functions::metadata::parse($rfp{'metadata'});
	
	foreach my $section(split(';',$env{'rfp.metadata.override_sections'}))
	{
		delete $metadata{$section};
	}
	
	if ($env{'rfp.metadata.replace'})
	{
		if (!ref($env{'rfp.metadata'}) && $env{'rfp.metadata'})
		{
			%metadata=App::020::functions::metadata::parse($env{'rfp.metadata'});
		}
		if (ref($env{'rfp.metadata'}) eq "HASH")
		{
			%metadata=%{$env{'rfp.metadata'}};
		}
	}
	else
	{
		if (!ref($env{'rfp.metadata'}) && $env{'rfp.metadata'})
		{
			# when metadata send as <metatree></metatree> then always replace
			%metadata=App::020::functions::metadata::parse($env{'rfp.metadata'});
#			my %metadata_=App::020::functions::metadata::parse($env{'product.metadata'});
#			delete $env{'product.metadata'};
#			%{$env{'product.metadata'}}=%metadata_;
		}
		if (ref($env{'rfp.metadata'}) eq "HASH")
		{
			# metadata overrride
			foreach my $section(keys %{$env{'rfp.metadata'}})
			{
				foreach my $variable(keys %{$env{'rfp.metadata'}{$section}})
				{
					$metadata{$section}{$variable}=$env{'rfp.metadata'}{$section}{$variable};
				}
			}
		}
	}
	
	$env{'rfp.metadata'}=App::020::functions::metadata::serialize(%metadata);
	
	$data{'metadata'}=$env{'rfp.metadata'}
		if (exists $env{'rfp.metadata'} && ($env{'rfp.metadata'} ne $rfp{'metadata'}));
	
	if (($main::RPC->{'rfp_cat.ID'} || $main::RPC->{'rfp_cat.ID_entity'}) && ($rfp{'status'} eq "T"))
	{
		$env{'rfp.status'}=$env{'rfp.status'}||'N';
	}
	
	# status
	$data{'status'}=$env{'rfp.status'}
		if ($env{'rfp.status'} && ($env{'rfp.status'} ne $rfp{'status'}));
	
	if (keys %columns || keys %data)
	{
		App::020::SQL::functions::update(
			'ID' => $env{'rfp.ID'},
			'db_h' => "main",
			'db_name' => $App::930::db_name,
			'tb_name' => "a930_rfp",
			'columns' => {%columns},
			'data' => {%data},
			'-posix' => 1,
			'-journalize' => 1
		);
	}
	
	
	# LNG DETECTION
	if ($env{'rfp_cat.ID'})
	{
		my $sql=qq{
			SELECT
				*
			FROM
				$App::930::db_name.a930_rfp_cat
			WHERE
				ID=$env{'rfp_cat.ID'}
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %rfp_cat=$sth0{'sth'}->fetchhash();
		$env{'rfp_cat.ID_entity'}=$rfp_cat{'ID_entity'};
	}
	$env{'rfp_cat.ID_entity'} = $env{'rfp_cat.ID_entity'} || $env{'rfp_rel_cat.ID_category'};
	
	my %rfp_rel_cat;
	my %rfp_cat;
	
	# check lng_param
	$env{'rfp_lng.lng'}=$tom::lng unless $env{'rfp_lng.lng'};
	main::_log("lng='$env{'rfp_lng.lng'}'");
	
	# PRODUCT_LNG
	
	my %rfp_lng;
	if (!$env{'rfp_lng.ID'})
	{
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::930::db_name`.`a930_rfp_lng`
			WHERE
				ID_entity=$env{'rfp.ID'} AND
				lng='$env{'rfp_lng.lng'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%rfp_lng=$sth0{'sth'}->fetchhash();
		$env{'rfp_lng.ID'}=$rfp_lng{'ID'} if $rfp_lng{'ID'};
	}
	
	if (!$env{'rfp_lng.ID'}) # if product_lng not defined, create a new
	{
		main::_log("!rfp_lng.ID, create rfp_lng.ID (rfp_lng.lng='$env{'rfp_lng.lng'}')");
		my %data;
		$data{'ID_entity'}=$env{'rfp.ID'};
		$data{'lng'}=$env{'rfp_lng.lng'};
		$env{'rfp_lng.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::930::db_name,
			'tb_name' => "a930_rfp_lng",
			'data' => {%data},
			'-journalize' => 1,
		);
		%rfp_lng=App::020::SQL::functions::get_ID(
			'ID' => $env{'rfp_lng.ID'},
			'db_h' => "main",
			'db_name' => $App::930::db_name,
			'tb_name' => "a930_rfp_lng",
			'columns' => {'*'=>1}
		);
		$env{'rfp_lng.ID'}=$rfp_lng{'ID'};
		$env{'rfp_lng.ID_entity'}=$rfp_lng{'ID_entity'};
	}
	
	main::_log("rfp_lng.ID='$rfp_lng{'ID'}' rfp_lng.ID_entity='$rfp_lng{'ID_entity'}'");
	
	# update only if necessary
	my %columns;
	my %data;
	# name
	$data{'name'}=$env{'rfp_lng.name'}
		if ($env{'rfp_lng.name'} && ($env{'rfp_lng.name'} ne $rfp_lng{'name'}));
	$data{'name_url'}=TOM::Net::URI::rewrite::convert($env{'rfp_lng.name'},'notlower'=>1)
		if ($env{'rfp_lng.name'} && ($env{'rfp_lng.name'} ne $rfp_lng{'name'}));
	# name_long
	$data{'name_long'}=$env{'rfp_lng.name_long'}
		if ($env{'rfp_lng.name_long'} && ($env{'rfp_lng.name_long'} ne $rfp_lng{'name_long'}));
	# abstract
	$data{'abstract'}=$env{'rfp_lng.abstract'}
		if ($env{'rfp_lng.abstract'} && ($env{'rfp_lng.abstract'} ne $rfp_lng{'abstract'}));
	# body
	$data{'body'}=$env{'rfp_lng.body'}
		if ($env{'rfp_lng.body'} && ($env{'rfp_lng.body'} ne $rfp_lng{'body'}));
	
	if (keys %columns || keys %data)
	{
		App::020::SQL::functions::update(
			'ID' => $env{'rfp_lng.ID'},
			'db_h' => "main",
			'db_name' => $App::930::db_name,
			'tb_name' => "a930_rfp_lng",
			'columns' => {%columns},
			'data' => {%data},
			'-journalize' => 1,
			'-posix' => 1,
		);
	}
	
	main::_log("rfp_cat.ID_entity='$env{'rfp_cat.ID_entity'}'");
	
	if ($env{'rfp_cat.ID_entity'})
	{
		TOM::Database::SQL::execute(qq{
			REPLACE INTO `$App::930::db_name`.a930_rfp_rel_cat
			(
				ID_rfp,
				ID_category
			)
			VALUES
			(
				?,?
			)
		},'bind'=>[$env{'rfp.ID'},$env{'rfp_cat.ID_entity'}],'quiet'=>1);
	}
	
	$t->close();
	return %rfp;
}



=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
