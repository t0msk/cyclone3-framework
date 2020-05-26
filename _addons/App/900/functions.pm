#!/bin/perl
package App::900::functions;


use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


use App::900::_init;
use TOM::Security::form;
use App::160::SQL;
use POSIX qw(ceil);

our $debug=1;
our $quiet;$quiet=1 unless $debug;


sub banner_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::banner_add()");
	
	my %banner;
	
	if ($env{'banner.ID'})
	{
		$env{'banner.ID'}=$env{'banner.ID'}+0;
		undef $env{'banner.ID_entity'}; # ID_entity has lower priority as ID
		# when real ID_entity used, then read it from ID
		# when ID not found, undef ID_entity, because is invalid
		main::_log("finding banner.ID_entity by banner.ID='$env{'banner.ID'}'");
		%banner=App::020::SQL::functions::get_ID(
			'ID' => $env{'banner.ID'},
			'db_h' => "main",
			'db_name' => $App::900::db_name,
			'tb_name' => "a900_banner",
			'columns' => {'*'=>1}
		);
		if ($banner{'ID'})
		{
			$env{'banner.ID_entity'}=$banner{'ID_entity'};
			main::_log("found banner.ID_entity='$env{'banner.ID_entity'}'");
		}
		else
		{
			main::_log("not found banner.ID, undef",1);
			App::020::SQL::functions::new(
				'db_h' => "main",
				'db_name' => $App::900::db_name,
				'tb_name' => "a900_banner",
				'columns' => {
					'ID' => $env{'banner.ID'},
					'datetime_publish_start' => 'NOW()'
				},
				'-journalize' => 1,
			);
			%banner=App::020::SQL::functions::get_ID(
				'ID' => $env{'banner.ID'},
				'db_h' => "main",
				'db_name' => $App::900::db_name,
				'tb_name' => "a900_banner",
				'columns' => {'*'=>1}
			);
			$env{'banner.ID_entity'}=$banner{'ID_entity'};
		}
	}
	
	if (!$env{'banner.ID'})
	{
		main::_log("!banner.ID, create banner.ID (banner.ID_entity='$env{'banner.ID_entity'}')");
		my %columns;
		$columns{'ID_entity'}=$env{'banner.ID_entity'} if $env{'banner.ID_entity'};
		$env{'banner.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::900::db_name,
			'tb_name' => "a900_banner",
			'columns' => {%columns,'datetime_publish_start' => 'NOW()'},
			'-journalize' => 1,
		);
		%banner=App::020::SQL::functions::get_ID(
			'ID' => $env{'banner.ID'},
			'db_h' => "main",
			'db_name' => $App::900::db_name,
			'tb_name' => "a900_banner",
			'columns' => {'*'=>1}
		);
		$env{'banner.ID'}=$banner{'ID'};
		$env{'banner.ID_entity'}=$banner{'ID_entity'};
	}
	
	main::_log("banner.ID='$banner{'ID'}' banner.ID_entity='$banner{'ID_entity'}'");
	
	# update only if necessary
	my %columns;
	my %data;
	
	# datetime_publish_start
	$columns{'datetime_publish_start'}="'".TOM::Security::form::sql_escape($env{'banner.datetime_publish_start'})."'"
		if ($env{'banner.datetime_publish_start'} && ($env{'banner.datetime_publish_start'} ne $banner{'datetime_publish_start'}));
	# datetime_publish_stop
	if ($env{'banner.datetime_publish_stop'})
	{
		$columns{'datetime_publish_stop'}="'".TOM::Security::form::sql_escape($env{'banner.datetime_publish_stop'})."'"
			if ($env{'banner.datetime_publish_stop'} && ($env{'banner.datetime_publish_stop'} ne $banner{'datetime_publish_stop'}));
	}
	elsif (exists $env{'banner.datetime_publish_stop'})
	{
		$columns{'datetime_publish_stop'} = "NULL"
			if ($env{'banner.datetime_publish_stop'} ne $banner{'datetime_publish_stop'});
	}
	
	# name
	$data{'name'}=$env{'banner.name'}
		if ($env{'banner.name'} && ($env{'banner.name'} ne $banner{'name'}));
	$data{'name_url'}=TOM::Net::URI::rewrite::convert($env{'banner.name'},'notlower'=>1)
		if ($env{'banner.name'} && ($env{'banner.name'} ne $banner{'name'}));
	
	
	# metadata
	my %metadata=App::020::functions::metadata::parse($banner{'metadata'});
	
	foreach my $section(split(';',$env{'banner.metadata.override_sections'}))
	{
		delete $metadata{$section};
	}
	
	if ($env{'banner.metadata.replace'})
	{
		if (!ref($env{'banner.metadata'}) && $env{'banner.metadata'})
		{
			%metadata=App::020::functions::metadata::parse($env{'banner.metadata'});
		}
		if (ref($env{'banner.metadata'}) eq "HASH")
		{
			%metadata=%{$env{'banner.metadata'}};
		}
	}
	else
	{
		if (!ref($env{'banner.metadata'}) && $env{'banner.metadata'})
		{
			# when metadata send as <metatree></metatree> then always replace
			%metadata=App::020::functions::metadata::parse($env{'banner.metadata'});
		}
		if (ref($env{'banner.metadata'}) eq "HASH")
		{
			# metadata overrride
			foreach my $section(keys %{$env{'banner.metadata'}})
			{
				foreach my $variable(keys %{$env{'banner.metadata'}{$section}})
				{
					$metadata{$section}{$variable}=$env{'banner.metadata'}{$section}{$variable};
				}
			}
		}
	}
	
	$env{'banner.metadata'}=App::020::functions::metadata::serialize(%metadata);
	
	$data{'metadata'}=$env{'banner.metadata'}
		if (exists $env{'banner.metadata'} && ($env{'banner.metadata'} ne $banner{'metadata'}));
	
	if (($main::RPC->{'banner_cat.ID'} || $main::RPC->{'banner_cat.ID_entity'}) && ($banner{'status'} eq "T"))
	{
		$env{'banner.status'}=$env{'banner.status'} || 'N';
	}
	
	foreach my $field ('ID_zonetarget', 'status', 'rules_weight', 'target_nofollow', 'rules_views_period')
	{
		$data{$field}=$env{'banner.'.$field}
			if ($env{'banner.'.$field} && ($env{'banner.'.$field} ne $banner{$field}));
	}
	
	foreach my $field ('rules_validation', 'rules_apply')
	{
		$data{$field}=$env{'banner.'.$field}
			if (exists $env{'banner.'.$field} && ($env{'banner.'.$field} ne $banner{$field}));
		if (exists $data{$field} && !$data{$field})
		{
			delete $data{$field};
			$columns{$field}="''";
		}
	}
	
	foreach my $field ('target_url', 'target_addon', 'stats_view', 'rules_views_max', 'rules_views_session_max', 'rules_pageviews_session_min', 'rules_clicks_max',
		'rules_views_browser_session_max', 'rules_clicks_browser_max',
		'utm_source', 'utm_medium', 'utm_term', 'utm_content', 'utm_campaign',
		'time_publish_start', 'time_publish_stop', 'skip', 'rules_views_browser_max'
	)
	{
		$data{$field}=$env{'banner.'.$field}
			if (exists $env{'banner.'.$field} && ($env{'banner.'.$field} ne $banner{$field}));
		if (exists $data{$field} && !$data{$field})
		{
			delete $data{$field};
			$columns{$field}='NULL';
		}
	}
	
	if (keys %columns || keys %data)
	{
		App::020::SQL::functions::update(
			'ID' => $env{'banner.ID'},
			'db_h' => "main",
			'db_name' => $App::900::db_name,
			'tb_name' => "a900_banner",
			'columns' => {%columns},
			'data' => {%data},
			'-posix' => 1,
			'-journalize' => 1
		);
	}
	
	
	if ($env{'banner_cat.ID'})
	{
		my $sql=qq{
			SELECT
				*
			FROM
				$App::900::db_name.a900_banner_cat
			WHERE
				ID=$env{'banner_cat.ID'}
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %banner_cat=$sth0{'sth'}->fetchhash();
		$env{'banner_cat.ID_entity'}=$banner_cat{'ID_entity'};
	}
	$env{'banner_cat.ID_entity'} = $env{'banner_cat.ID_entity'} || $env{'banner_rel_cat.ID_category'};
	
	my %banner_rel_cat;
	my %banner_cat;
	
	# check lng_param
	$env{'banner_lng.lng'}=$tom::lng unless $env{'banner_lng.lng'};
	main::_log("lng='$env{'banner_lng.lng'}'");
	
	# BANNER_LNG
	my %banner_lng;
	if (!$env{'banner_lng.ID'})
	{
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::900::db_name`.`a900_banner_lng`
			WHERE
				ID_entity=? AND
				lng=?
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1,'bind'=>[
			$env{'banner.ID_entity'},
			$env{'banner_lng.lng'}
		]);
		%banner_lng=$sth0{'sth'}->fetchhash();
		$env{'banner_lng.ID'}=$banner_lng{'ID'} if $banner_lng{'ID'};
	}
	
	if (!$env{'banner_lng.ID'}) # if banner_lng not defined, create a new
	{
		main::_log("!banner_lng.ID, create banner_lng.ID (banner_lng.lng='$env{'banner_lng.lng'}')");
		my %data;
		$data{'ID_entity'}=$env{'banner.ID_entity'};
		$data{'lng'}=$env{'banner_lng.lng'};
		$env{'banner_lng.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::900::db_name,
			'tb_name' => "a900_banner_lng",
			'data' => {%data},
			'-journalize' => 1,
		);
		%banner_lng=App::020::SQL::functions::get_ID(
			'ID' => $env{'banner_lng.ID'},
			'db_h' => "main",
			'db_name' => $App::900::db_name,
			'tb_name' => "a900_banner_lng",
			'columns' => {'*'=>1}
		);
		$env{'banner_lng.ID'}=$banner_lng{'ID'};
		$env{'banner_lng.ID_entity'}=$banner_lng{'ID_entity'};
	}
	
	$banner{'banner_lng.ID'} = $banner_lng{'ID'};
	main::_log("banner_lng.ID='$banner_lng{'ID'}' banner_lng.ID_entity='$banner_lng{'ID_entity'}'");
	
	# update only if necessary
	my %columns;
	my %data;
	
	foreach my $field ('title', 'def_target', 'status')
	{
		$data{$field}=$env{'banner_lng.'.$field}
			if ($env{'banner_lng.'.$field} && ($env{'banner_lng.'.$field} ne $banner_lng{$field}));
	}
	
	foreach my $field ('def_type', 'def_img_src', 'def_script', 'def_text_1', 'def_text_2', 'def_text_3', 'def_text_4', 'def_body')
	{
		$data{$field}=$env{'banner_lng.'.$field}
			if (exists $env{'banner_lng.'.$field} && ($env{'banner_lng.'.$field} ne $banner_lng{$field}));
		if (exists $data{$field} && !$data{$field})
		{
			delete $data{$field};
			$columns{$field}='NULL';
		}
	}
	
	if (keys %columns || keys %data)
	{
		App::020::SQL::functions::update(
			'ID' => $env{'banner_lng.ID'},
			'db_h' => "main",
			'db_name' => $App::900::db_name,
			'tb_name' => "a900_banner_lng",
			'columns' => {%columns},
			'data' => {%data},
			'-journalize' => 1,
			'-posix' => 1,
		);
	}
	
	main::_log("banner_cat.ID_entity='$env{'banner_cat.ID_entity'}'");
	
	if ($env{'banner_cat.ID_entity'})
	{
		TOM::Database::SQL::execute(qq{
			REPLACE INTO `$App::900::db_name`.a900_banner_rel_cat
			(
				ID_banner,
				ID_category
			)
			VALUES
			(
				?,?
			)
		},'bind'=>[$env{'banner.ID_entity'},$env{'banner_cat.ID_entity'}],'quiet'=>1);
	}
	
	$t->close();
	return %banner;
}


1;
