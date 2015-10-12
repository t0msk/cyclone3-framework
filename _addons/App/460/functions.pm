#!/bin/perl
package App::460::functions;


use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
use charnames ':full';
our $soft_hyphen="\N{SOFT HYPHEN}";
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


use App::460::_init;

our $debug=0;
our $quiet;$quiet=1 unless $debug;


sub tag_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::tag_add()");
	
	my %tag;
	
	if ($env{'tag.ID'})
	{
		$env{'tag.ID'}=$env{'tag.ID'}+0;
		undef $env{'tag.ID_entity'}; # ID_entity has lower priority as ID
		# when real ID_entity used, then read it from ID
		# when ID not found, undef ID_entity, because is invalid
		main::_log("finding tag.ID_entity by tag.ID='$env{'tag.ID'}'");
		%tag=App::020::SQL::functions::get_ID(
			'ID' => $env{'tag.ID'},
			'db_h' => "main",
			'db_name' => $App::460::db_name,
			'tb_name' => "a460_tag",
			'columns' => {'*'=>1}
		);
		if ($tag{'ID'})
		{
			$env{'tag.ID_entity'}=$tag{'ID_entity'};
			main::_log("found tag.ID_entity='$env{'tag.ID_entity'}'");
		}
		else
		{
			main::_log("not found tag.ID, undef",1);
			App::020::SQL::functions::new(
				'db_h' => "main",
				'db_name' => $App::460::db_name,
				'tb_name' => "a460_tag",
				'columns' => {
					'ID' => $env{'tag.ID'},
					'datetime_publish_start' => 'NOW()'
				},
				'-journalize' => 1,
			);
			%tag=App::020::SQL::functions::get_ID(
				'ID' => $env{'tag.ID'},
				'db_h' => "main",
				'db_name' => $App::460::db_name,
				'tb_name' => "a460_tag",
				'columns' => {'*'=>1}
			);
			$env{'tag.ID_entity'}=$tag{'ID_entity'};
		}
	}
	
	if (!$env{'tag.ID'} && $env{'tag.name'})
	{
		main::_log("finding tag.ID_entity by tag.name='$env{'tag.name'}'");
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				`$App::460::db_name`.a460_tag
			WHERE
				name LIKE ?
		},'bind'=>[$env{'tag.name'}]);
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$env{'tag.ID'} = $db0_line{'ID'};
			$env{'tag.ID_entity'} = $db0_line{'ID_entity'};
			main::_log("found tag.ID_entity='$env{'tag.ID_entity'}'");
			%tag=App::020::SQL::functions::get_ID(
				'ID' => $env{'tag.ID'},
				'db_h' => "main",
				'db_name' => $App::460::db_name,
				'tb_name' => "a460_tag",
				'columns' => {'*'=>1}
			);
		}
	}
	
	if (!$env{'tag.ID'})
	{
		main::_log("!tag.ID, create tag.ID (tag.ID_entity='$env{'tag.ID_entity'}')");
		my %columns;
		$columns{'ID_entity'}=$env{'tag.ID_entity'} if $env{'tag.ID_entity'};
		$env{'tag.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::460::db_name,
			'tb_name' => "a460_tag",
			'columns' => {%columns,'datetime_publish_start' => 'NOW()'},
			'-journalize' => 1,
		);
		%tag=App::020::SQL::functions::get_ID(
			'ID' => $env{'tag.ID'},
			'db_h' => "main",
			'db_name' => $App::460::db_name,
			'tb_name' => "a460_tag",
			'columns' => {'*'=>1}
		);
		$env{'tag.ID'}=$tag{'ID'};
		$env{'tag.ID_entity'}=$tag{'ID_entity'};
	}
	
	main::_log("tag.ID='$tag{'ID'}' tag.ID_entity='$tag{'ID_entity'}'");
	
	# update only if necessary
	my %columns;
	my %data;
	
	# datetime_publish_start
	$columns{'datetime_publish_start'}="'".TOM::Security::form::sql_escape($env{'tag.datetime_publish_start'})."'"
		if ($env{'tag.datetime_publish_start'} && ($env{'tag.datetime_publish_start'} ne $tag{'datetime_publish_start'}));
	# datetime_publish_stop
	if ($env{'tag.datetime_publish_stop'})
	{
		$columns{'datetime_publish_stop'}="'".TOM::Security::form::sql_escape($env{'tag.datetime_publish_stop'})."'"
			if ($env{'tag.datetime_publish_stop'} && ($env{'tag.datetime_publish_stop'} ne $tag{'datetime_publish_stop'}));
	}
	elsif (exists $env{'tag.datetime_publish_stop'})
	{
		$columns{'datetime_publish_stop'} = "NULL"
			if ($env{'tag.datetime_publish_stop'} ne $tag{'datetime_publish_stop'});
	}
	
	# name
	$data{'name'}=$env{'tag.name'}
		if ($env{'tag.name'} && ($env{'tag.name'} ne $tag{'name'}));
	$data{'name_url'}=TOM::Net::URI::rewrite::convert($env{'tag.name'},'notlower'=>1)
		if ($env{'tag.name'} && ($env{'tag.name'} ne $tag{'name'}));
	
	
	# metadata
	my %metadata=App::020::functions::metadata::parse($tag{'metadata'});
	
	foreach my $section(split(';',$env{'tag.metadata.override_sections'}))
	{
		delete $metadata{$section};
	}
	
	if ($env{'tag.metadata.replace'})
	{
		if (!ref($env{'tag.metadata'}) && $env{'tag.metadata'})
		{
			%metadata=App::020::functions::metadata::parse($env{'tag.metadata'});
		}
		if (ref($env{'tag.metadata'}) eq "HASH")
		{
			%metadata=%{$env{'tag.metadata'}};
		}
	}
	else
	{
		if (!ref($env{'tag.metadata'}) && $env{'tag.metadata'})
		{
			# when metadata send as <metatree></metatree> then always replace
			%metadata=App::020::functions::metadata::parse($env{'tag.metadata'});
		}
		if (ref($env{'tag.metadata'}) eq "HASH")
		{
			# metadata overrride
			foreach my $section(keys %{$env{'tag.metadata'}})
			{
				foreach my $variable(keys %{$env{'tag.metadata'}{$section}})
				{
					$metadata{$section}{$variable}=$env{'tag.metadata'}{$section}{$variable};
				}
			}
		}
	}
	
	$env{'tag.metadata'}=App::020::functions::metadata::serialize(%metadata);
	
	$data{'metadata'}=$env{'tag.metadata'}
		if (exists $env{'tag.metadata'} && ($env{'tag.metadata'} ne $tag{'metadata'}));
	
	if (($main::RPC->{'tag_cat.ID'} || $main::RPC->{'tag_cat.ID_entity'}) && ($tag{'status'} eq "T"))
	{
		$env{'tag.status'}=$env{'tag.status'} || 'N';
	}
	
	foreach my $field ('status')
	{
		$data{$field}=$env{'tag.'.$field}
			if ($env{'tag.'.$field} && ($env{'tag.'.$field} ne $tag{$field}));
	}
	
#	foreach my $field (
#		'rules_validation', 'rules_apply'
#	)
#	{
#		$data{$field}=$env{'tag.'.$field}
#			if (exists $env{'tag.'.$field} && ($env{'tag.'.$field} ne $tag{$field}));
#		if (exists $data{$field} && !$data{$field})
#		{
#			delete $data{$field};
#			$columns{$field}="''";
#		}
#	}
	
#	foreach my $field (
#		'target_url'
#	)
#	{
#		$data{$field}=$env{'tag.'.$field}
#			if (exists $env{'tag.'.$field} && ($env{'tag.'.$field} ne $tag{$field}));
#		if (exists $data{$field} && !$data{$field})
#		{
#			delete $data{$field};
#			$columns{$field}='NULL';
#		}
#	}
	
	if (keys %columns || keys %data)
	{
		App::020::SQL::functions::update(
			'ID' => $env{'tag.ID'},
			'db_h' => "main",
			'db_name' => $App::460::db_name,
			'tb_name' => "a460_tag",
			'columns' => {%columns},
			'data' => {%data},
			'-posix' => 1,
			'-journalize' => 1
		);
	}
	
	
	if ($env{'tag_cat.ID'})
	{
		my $sql=qq{
			SELECT
				*
			FROM
				$App::460::db_name.a460_tag_cat
			WHERE
				ID=$env{'tag_cat.ID'}
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %tag_cat=$sth0{'sth'}->fetchhash();
		$env{'tag_cat.ID_entity'}=$tag_cat{'ID_entity'};
	}
	$env{'tag_cat.ID_entity'} = $env{'tag_cat.ID_entity'} || $env{'tag_rel_cat.ID_category'};
	
	my %tag_rel_cat;
	my %tag_cat;
	
	main::_log("tag_cat.ID_entity='$env{'tag_cat.ID_entity'}'");
	
	if ($env{'tag_cat.ID_entity'})
	{
		TOM::Database::SQL::execute(qq{
			REPLACE INTO `$App::460::db_name`.a460_tag_rel_cat
			(
				ID_tag,
				ID_category
			)
			VALUES
			(
				?,?
			)
		},'bind'=>[$env{'tag.ID_entity'},$env{'tag_cat.ID_entity'}],'quiet'=>1);
	}
	
	$t->close();
	return %tag;
}


1;
