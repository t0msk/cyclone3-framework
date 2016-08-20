#!/bin/perl
package App::480::functions;


use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
use charnames ':full';
our $soft_hyphen="\N{SOFT HYPHEN}";
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


use App::480::_init;

use Data::Dumper;

sub table_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::table_add()");
	
	my %table;
	
	if ($env{'table.ID'})
	{
		$env{'table.ID'}=$env{'table.ID'}+0;
		undef $env{'table.ID_entity'}; # ID_entity has lower priority as ID
		# when real ID_entity used, then read it from ID
		# when ID not found, undef ID_entity, because is invalid
		main::_log("finding table.ID_entity by table.ID='$env{'table.ID'}'");
		%table=App::020::SQL::functions::get_ID(
			'ID' => $env{'table.ID'},
			'db_h' => "main",
			'db_name' => $App::480::db_name,
			'tb_name' => "a480_table",
			'columns' => {'*'=>1}
		);
		if ($table{'ID'})
		{
			$env{'table.ID_entity'}=$table{'ID_entity'};
			main::_log("found table.ID_entity='$env{'table.ID_entity'}'");
		}
		else
		{
			main::_log("not found table.ID, undef",1);
			App::020::SQL::functions::new(
				'db_h' => "main",
				'db_name' => $App::480::db_name,
				'tb_name' => "a480_table",
				'columns' => {
					'ID' => $env{'table.ID'},
				},
				'-journalize' => 1,
			);
			%table=App::020::SQL::functions::get_ID(
				'ID' => $env{'table.ID'},
				'db_h' => "main",
				'db_name' => $App::480::db_name,
				'tb_name' => "a480_table",
				'columns' => {'*'=>1}
			);
			$env{'table.ID_entity'}=$table{'ID_entity'};
		}
	}
	
	if (!$env{'table.ID'})
	{
		main::_log("!table.ID, create table.ID (table.ID_entity='$env{'table.ID_entity'}')");
		my %columns;
		$columns{'ID_entity'}=$env{'table.ID_entity'} if $env{'table.ID_entity'};


		$env{'table.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::480::db_name,
			'tb_name' => "a480_table",
			'columns' => {%columns},
			'-journalize' => 1,
		);
		%table=App::020::SQL::functions::get_ID(
			'ID' => $env{'table.ID'},
			'db_h' => "main",
			'db_name' => $App::480::db_name,
			'tb_name' => "a480_table",
			'columns' => {'*'=>1}
		);
		$env{'table.ID'}=$table{'ID'};
		$env{'table.ID_entity'}=$table{'ID_entity'};
	}
	
	main::_log("table.ID='$table{'ID'}' table.ID_entity='$table{'ID_entity'}'");
	
	# update only if necessary
	my %columns;
	my %data;

	# # status
	# $data{'status'}=$env{'table.status'}
	# 	if ($env{'table.status'} && ($env{'table.status'} ne $table{'status'}));

	# # name
	# $data{'name'}=$env{'table.name'}
	# 	if ($env{'table.name'} && ($env{'table.name'} ne $table{'name'}));
	# $data{'name_url'}=TOM::Net::URI::rewrite::convert($env{'table.name'},'notlower'=>1)
	# 	if ($env{'table.name'} && ($env{'table.name'} ne $table{'name'}));
	
	# # datetime_start
	# $data{'datetime_start'}=$env{'table.datetime_start'}
	# 	if ($env{'table.datetime_start'} && ($env{'table.datetime_start'} ne $table{'datetime_start'}));

	# # datetime_finish
	# $data{'datetime_finish'}=$env{'table.datetime_finish'}
	# 	if ($env{'table.datetime_finish'} && ($env{'table.datetime_finish'} ne $table{'datetime_finish'}));

	# metadata
	my %metadata=App::020::functions::metadata::parse($table{'metadata'});
	
	foreach my $section(split(';',$env{'table.metadata.override_sections'}))
	{
		delete $metadata{$section};
	}
	
	if ($env{'table.metadata.replace'})
	{
		if (!ref($env{'table.metadata'}) && $env{'table.metadata'})
		{
			%metadata=App::020::functions::metadata::parse($env{'table.metadata'});
		}
		if (ref($env{'table.metadata'}) eq "HASH")
		{
			%metadata=%{$env{'table.metadata'}};
		}
	}
	else
	{
		if (!ref($env{'table.metadata'}) && $env{'table.metadata'})
		{
			# when metadata send as <metatree></metatree> then always replace
			%metadata=App::020::functions::metadata::parse($env{'table.metadata'});
		}
		if (ref($env{'table.metadata'}) eq "HASH")
		{
			# metadata overrride
			foreach my $section(keys %{$env{'table.metadata'}})
			{
				foreach my $variable(keys %{$env{'table.metadata'}{$section}})
				{
					$metadata{$section}{$variable}=$env{'table.metadata'}{$section}{$variable};
				}
			}
		}
	}
	
	$env{'table.metadata'}=App::020::functions::metadata::serialize(%metadata);
	
	$data{'metadata'}=TOM::Security::form::sql_escape($env{'table.metadata'})
		if (exists $env{'table.metadata'} && ($env{'table.metadata'} ne $table{'metadata'}));
	
	if ($env{'table.ID_category'}) {
		$columns{'ID_category'} = $env{'table.ID_category'};
	}

	$data{'posix_owner'}=$main::USRM{'ID_user'};

	foreach my $field ('status','name','result')
	{
		$data{$field}=TOM::Security::form::sql_escape($env{'table.'.$field})
			if ($env{'table.'.$field} && ($env{'table.'.$field} ne $table{$field}));
	}
	$data{'name_url'}=TOM::Net::URI::rewrite::convert($env{'table.name'},'notlower'=>1)
		if ($env{'table.name'} && ($env{'table.name'} ne $table{'name'}));
	

	if (keys %columns || keys %data)
	{
		App::020::SQL::functions::update(
			'ID' => $env{'table.ID'},
			'db_h' => "main",
			'db_name' => $App::480::db_name,
			'tb_name' => "a480_table",
			'columns' => {%columns},
			'data' => {%data},
			'-posix' => 1,
			'-journalize' => 1
		);
	}
	
	$t->close();
	return %table;
}

sub row_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::row_add()");
	
	my %row;
}


1;
