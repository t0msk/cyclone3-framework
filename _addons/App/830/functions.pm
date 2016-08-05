#!/bin/perl
package App::830::functions;


use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



use App::830::_init;
use TOM::Security::form;
use App::160::SQL;
use POSIX qw(ceil);

our $debug=1;
our $quiet;$quiet=1 unless $debug;


sub form_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::form_add()");
	
	my %form;
	
	if ($env{'form.ID'})
	{
		$env{'form.ID'}=$env{'form.ID'}+0;
		undef $env{'form.ID_entity'}; # ID_entity has lower priority as ID
		# when real ID_entity used, then read it from ID
		# when ID not found, undef ID_entity, because is invalid
		main::_log("finding form.ID_entity by form.ID='$env{'form.ID'}'");
		%form=App::020::SQL::functions::get_ID(
			'ID' => $env{'form.ID'},
			'db_h' => "main",
			'db_name' => $App::830::db_name,
			'tb_name' => "a830_form",
			'columns' => {'*'=>1}
		);
		if ($form{'ID'})
		{
			$env{'form.ID_entity'}=$form{'ID_entity'};
			main::_log("found form.ID_entity='$env{'form.ID_entity'}'");
		}
		else
		{
			main::_log("not found form.ID, undef",1);
			App::020::SQL::functions::new(
				'db_h' => "main",
				'db_name' => $App::830::db_name,
				'tb_name' => "a830_form",
				'columns' => {
					'ID' => $env{'form.ID'},
					'name' => $env{'form.name'},
					'datetime_publish_start' => 'NOW()'
				},
				'-journalize' => 1,
			);
			%form=App::020::SQL::functions::get_ID(
				'ID' => $env{'form.ID'},
				'db_h' => "main",
				'db_name' => $App::830::db_name,
				'tb_name' => "a830_form",
				'columns' => {'*'=>1}
			);
			$env{'form.ID_entity'}=$form{'ID_entity'};
		}
	}
	
	if (!$env{'form.ID'})
	{
		main::_log("!form.ID, create form.ID (form.ID_entity='$env{'form.ID_entity'}')");
		my %columns;
		$columns{'ID_entity'}=$env{'form.ID_entity'} if $env{'form.ID_entity'};
		$env{'form.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::830::db_name,
			'tb_name' => "a830_form",
			'columns' => {%columns,'datetime_publish_start' => 'NOW()'},
			'-journalize' => 1,
		);
		%form=App::020::SQL::functions::get_ID(
			'ID' => $env{'form.ID'},
			'db_h' => "main",
			'db_name' => $App::830::db_name,
			'tb_name' => "a830_form",
			'columns' => {'*'=>1}
		);
		$env{'form.ID'}=$form{'ID'};
		$env{'form.ID_entity'}=$form{'ID_entity'};
	}
	
	main::_log("form.ID='$form{'ID'}' form.ID_entity='$form{'ID_entity'}'");
	
	# update only if necessary
	my %columns;
	my %data;
	# datetime_publish_start
	$columns{'datetime_publish_start'}="'".TOM::Security::form::sql_escape($env{'form.datetime_publish_start'})."'"
		if ($env{'form.datetime_publish_start'} && ($env{'form.datetime_publish_start'} ne $form{'datetime_publish_start'}));
	# datetime_publish_stop
	if ($env{'form.datetime_publish_stop'})
	{
		$columns{'datetime_publish_stop'}="'".TOM::Security::form::sql_escape($env{'form.datetime_publish_stop'})."'"
			if ($env{'form.datetime_publish_stop'} && ($env{'form.datetime_publish_stop'} ne $form{'datetime_publish_stop'}));
	}
	elsif (exists $env{'form.datetime_publish_stop'})
	{
		$columns{'datetime_publish_stop'} = "NULL"
			if ($env{'form.datetime_publish_stop'} ne $form{'datetime_publish_stop'});
	}
	
	$columns{'name'}="'".TOM::Security::form::sql_escape($env{'form.name'})."'"
		if (exists $env{'form.name'} && ($env{'form.name'} ne $form{'name'}));
	$data{'name_url'}=TOM::Net::URI::rewrite::convert($env{'form.name'})
		if ($env{'form.name'} && ($env{'form.name'} ne $form{'name'}));
	
	# metadata
	my %metadata=App::020::functions::metadata::parse($form{'metadata'});
	
	foreach my $section(split(';',$env{'form.metadata.override_sections'}))
	{
		delete $metadata{$section};
	}
	
	if ($env{'form.metadata.replace'})
	{
		if (!ref($env{'form.metadata'}) && $env{'form.metadata'})
		{
			%metadata=App::020::functions::metadata::parse($env{'form.metadata'});
		}
		if (ref($env{'form.metadata'}) eq "HASH")
		{
			%metadata=%{$env{'form.metadata'}};
		}
	}
	else
	{
		if (!ref($env{'form.metadata'}) && $env{'form.metadata'})
		{
			# when metadata send as <metatree></metatree> then always replace
			%metadata=App::020::functions::metadata::parse($env{'form.metadata'});
#			my %metadata_=App::020::functions::metadata::parse($env{'product.metadata'});
#			delete $env{'product.metadata'};
#			%{$env{'product.metadata'}}=%metadata_;
		}
		if (ref($env{'form.metadata'}) eq "HASH")
		{
			# metadata overrride
			foreach my $section(keys %{$env{'form.metadata'}})
			{
				foreach my $variable(keys %{$env{'form.metadata'}{$section}})
				{
					$metadata{$section}{$variable}=$env{'form.metadata'}{$section}{$variable};
				}
			}
		}
	}
	
	$env{'form.metadata'}=App::020::functions::metadata::serialize(%metadata);
	
	$columns{'metadata'}="'".TOM::Security::form::sql_escape($env{'form.metadata'})."'"
		if (exists $env{'form.metadata'} && ($env{'form.metadata'} ne $form{'metadata'}));
	
	if (($main::RPC->{'form_cat.ID'} || $main::RPC->{'form_cat.ID_entity'}) && ($form{'status'} eq "T"))
	{
		$env{'form.status'}=$env{'form.status'}||'N';
	}
	
	# status
	$data{'status'}=$env{'form.status'}
		if ($env{'form.status'} && ($env{'form.status'} ne $form{'status'}));
	
	if (keys %columns || keys %data)
	{
		App::020::SQL::functions::update(
			'ID' => $env{'form.ID'},
			'db_h' => "main",
			'db_name' => $App::830::db_name,
			'tb_name' => "a830_form",
			'columns' => {%columns},
			'data' => {%data},
			'-posix' => 1,
			'-journalize' => 1
		);
	}
	
	
	# LNG DETECTION
	if ($env{'form_cat.ID'})
	{
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::830::db_name`.`a830_form_cat`
			WHERE
				`ID` = $env{'form_cat.ID'}
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %form_cat=$sth0{'sth'}->fetchhash();
		$env{'form_cat.ID_entity'}=$form_cat{'ID_entity'};
	}
	$env{'form_cat.ID_entity'} = $env{'form_cat.ID_entity'} || $env{'form_rel_cat.ID_category'};
	
	my %form_rel_cat;
	my %form_cat;
	
	main::_log("form_cat.ID_entity='$env{'form_cat.ID_entity'}'");
	
	if ($env{'form_cat.ID_entity'})
	{
		TOM::Database::SQL::execute(qq{
			REPLACE INTO `$App::830::db_name`.a830_form_rel_cat
			(
				`ID_form`,
				`ID_category`
			)
			VALUES
			(
				?,?
			)
		},'bind'=>[$env{'form.ID'},$env{'form_cat.ID_entity'}],'quiet'=>1);
	}
	
	$t->close();
	return %form;
}


1;
