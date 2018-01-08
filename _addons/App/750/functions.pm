#!/bin/perl
package App::750::functions;


use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
use charnames ':full';
our $soft_hyphen="\N{SOFT HYPHEN}";
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


use App::750::_init;

our $debug=0;
our $quiet;$quiet=1 unless $debug;


sub complex_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::complex_add()");
	
	my %complex;
	if ($env{'complex.ID'})
	{
		$env{'complex.ID'}=$env{'complex.ID'}+0;
		undef $env{'complex.ID_entity'}; # ID_entity has lower priority as ID
		# when real ID_entity used, then read it from ID
		# when ID not found, undef ID_entity, because is invalid
		main::_log("finding complex.ID_entity by complex.ID='$env{'complex.ID'}'");
		%complex=App::020::SQL::functions::get_ID(
			'ID' => $env{'complex.ID'},
			'db_h' => "main",
			'db_name' => $App::750::db_name,
			'tb_name' => "a750_complex",
			'columns' => {'*'=>1}
		);
		if ($complex{'ID'})
		{
			$env{'complex.ID_entity'}=$complex{'ID_entity'};
			main::_log("found complex.ID_entity='$env{'complex.ID_entity'}'");
		}
		else
		{
			main::_log("not found complex.ID, undef",1);
			App::020::SQL::functions::new(
				'db_h' => "main",
				'db_name' => $App::750::db_name,
				'tb_name' => "a750_complex",
				'columns' => {
					'posix_owner' => "'".$main::USRM{'ID_user'}."'",
					'ID' => $env{'complex.ID'},
				},
				'-journalize' => 1,
				'-posix' => 1,
			);
			%complex=App::020::SQL::functions::get_ID(
				'ID' => $env{'complex.ID'},
				'db_h' => "main",
				'db_name' => $App::750::db_name,
				'tb_name' => "a750_complex",
				'columns' => {'*'=>1}
			);
			$env{'complex.ID_entity'}=$complex{'ID_entity'};
		}
	}
	
	if (!$env{'complex.ID'})
	{
		main::_log("!complex.ID, create complex.ID (complex.ID_entity='$env{'complex.ID_entity'}')");
		my %columns;
		$columns{'ID_entity'}=$env{'complex.ID_entity'} if $env{'complex.ID_entity'};
		$columns{'posix_owner'}="'".$main::USRM{'ID_user'}."'" unless $columns{'posix_owner'};
		
		$env{'complex.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::750::db_name,
			'tb_name' => "a750_complex",
			'columns' => {%columns},
			'-journalize' => 1,
			'-posix' => 1,
		);
		%complex=App::020::SQL::functions::get_ID(
			'ID' => $env{'complex.ID'},
			'db_h' => "main",
			'db_name' => $App::750::db_name,
			'tb_name' => "a750_complex",
			'columns' => {'*'=>1}
		);
		$env{'complex.ID'}=$complex{'ID'};
		$env{'complex.ID_entity'}=$complex{'ID_entity'};

		# add lng
		foreach my $lng (@TOM::LNG_accept) {
			App::020::SQL::functions::new(
				'db_h' => "main",
				'db_name' => $App::750::db_name,
				'tb_name' => "a750_complex_lng",
				'columns' => {%columns},
				'data' => {
					'ID_entity' => $env{'complex.ID'},
					'lng' => $lng,
				},
				'-journalize' => 1,
				'-posix' => 1,
			);
		}
	}
	
	main::_log("complex.ID='$complex{'ID'}' complex.ID_entity='$complex{'ID_entity'}'");
	
	# update only if necessary
	my %columns;
	my %data;

	# status
	$data{'status'}=$env{'complex.status'}
		if ($env{'complex.status'} && ($env{'complex.status'} ne $complex{'status'}));

	# name
	$data{'name'}=$env{'complex.name'}
		if (exists $env{'complex.name'} && ($env{'complex.name'} ne $complex{'name'}));
	$data{'name_url'}=TOM::Net::URI::rewrite::convert($env{'complex.name'},'notlower'=>1)
		if (exists $env{'complex.name'} && ($env{'complex.name'} ne $complex{'name'}));
	
	# country_code
	$data{'country_code'}=$env{'complex.country_code'}
		if (exists $env{'complex.country_code'} && ($env{'complex.country_code'} ne $complex{'country_code'}));
	
	# metadata
	my %metadata=App::020::functions::metadata::parse($complex{'metadata'});
	
	foreach my $section(split(';',$env{'complex.metadata.override_sections'}))
	{
		delete $metadata{$section};
	}
	
	if ($env{'complex.metadata.replace'})
	{
		if (!ref($env{'complex.metadata'}) && $env{'complex.metadata'})
		{
			%metadata=App::020::functions::metadata::parse($env{'complex.metadata'});
		}
		if (ref($env{'complex.metadata'}) eq "HASH")
		{
			%metadata=%{$env{'complex.metadata'}};
		}
	}
	else
	{
		if (!ref($env{'complex.metadata'}) && $env{'complex.metadata'})
		{
			# when metadata send as <metatree></metatree> then always replace
			%metadata=App::020::functions::metadata::parse($env{'complex.metadata'});
		}
		if (ref($env{'complex.metadata'}) eq "HASH")
		{
			# metadata overrride
			foreach my $section(keys %{$env{'complex.metadata'}})
			{
				foreach my $variable(keys %{$env{'complex.metadata'}{$section}})
				{
					$metadata{$section}{$variable}=$env{'complex.metadata'}{$section}{$variable};
				}
			}
		}
	}
	
	$env{'complex.metadata'}=App::020::functions::metadata::serialize(%metadata);
	
	$data{'metadata'}=$env{'complex.metadata'}
		if (exists $env{'complex.metadata'} && ($env{'complex.metadata'} ne $complex{'metadata'}));

	foreach my $field ('status','code','owner_occupied','rental_park','land','park','industry','complex_type','year','url_web','url_google_maps','floor_loading_capacity','floor_loading_capacity_to','clear_height','clear_height_to','truck_yard_depth','truck_yard_depth_to','column_grid_x','column_grid_y','cross_dock','dock_note','dock_doors_amount','drive_in','street','street_num','city','ZIP','district','county','state','country_code','geo_lat','geo_lon','note') {
		$data{$field}=$env{'complex.'.$field}
			if (exists $env{'complex.'.$field} && ($env{'complex.'.$field} ne $complex{$field}));
	}
	# replace dropdown values which are erased when some checkboxes are not checked
	$data{'complex_type'}=$env{'complex.complex_type'} if exists $env{'complex.complex_type'};
	$data{'industry'}=$env{'complex.industry'} if exists $env{'complex.industry'};
	if (exists $data{'geo_lat'} && $data{'geo_lat'} eq "")
	{
		delete $data{'geo_lat'};
		$columns{'geo_lat'}='NULL';
	}
	if (exists $data{'geo_lon'} && $data{'geo_lon'} eq "")
	{
		delete $data{'geo_lon'};
		$columns{'geo_lon'}='NULL';
	}
	
	if (keys %columns || keys %data)
	{
		App::020::SQL::functions::update(
			'ID' => $env{'complex.ID'},
			'db_h' => "main",
			'db_name' => $App::750::db_name,
			'tb_name' => "a750_complex",
			'columns' => {%columns},
			'data' => {%data},
			'-posix' => 1,
			'-journalize' => 1
		);
	}

	# update lng
	my %complex_lng;
	# get lng fields
    foreach my $key (keys %env)
    {
    	# main::_log("traversing key='$key', value='$env{$key}'");
        if ($key =~ /complex_lng\.([a-zA-Z\-]+)\.(.+)$/) 
		{

			my $lng = $1; my $varname = $2;
			# main::_log("traversing lng='$lng', varname='$varname'");
			$complex_lng{$lng} = {} unless (exists $complex_lng{$lng});
			$complex_lng{$lng}{$varname} = $env{$key};
			# name_url
			# if ($varname eq 'name') {
			# 	$complex_lng{$lng}{'name_url'}=TOM::Security::form::sql_escape(TOM::Net::URI::rewrite::convert($env->{$key}));
			# }
		}
    }

    my @lng_IDs = App::020::SQL::functions::get_ID_entity(
    	'ID_entity' => $env{'complex.ID'},
    	'db_h' => 'main',
    	'db_name' => $App::750::db_name,
    	'tb_name' => 'a750_complex_lng'
    );
    my $where_lng_IDs;
    foreach (@lng_IDs) {
    	$where_lng_IDs .= $_->{'ID'} . ",";
    };
    $where_lng_IDs =~ s/,$//;

    my $sql=qq{
    	SELECT
    		ID, lng
    	FROM
    		$App::750::db_name.a750_complex_lng
    	WHERE
    		ID IN ($where_lng_IDs)
    };
    
    my %sth_lng=TOM::Database::SQL::execute($sql,'quiet'=>1);
    
    while (my %lng_line=$sth_lng{'sth'}->fetchhash())
    {
    	my $local = $lng_line{'lng'};
    	if (%complex_lng && $complex_lng{$local}) {
			
			App::020::SQL::functions::update(
				'db_h' => 'main',
				'db_name' => $App::750::db_name,
				'tb_name' => 'a750_complex_lng',
				'ID' => $lng_line{'ID'},
				'lng' => $local,
				'data' => { %{$complex_lng{$local}} },
				'quiet' => 1,
				'-journalize' => 1,
				'-posix' => 1,
			);
		}
	}

	if ($env{'complex_cat.ID_entity'}) {
			TOM::Database::SQL::execute(qq{
				REPLACE INTO `$App::750::db_name`.a750_complex_rel_cat
				(
					ID_complex,
					ID_category
				)
				VALUES
				(
					?,?
				)
			},'bind'=>[$env{'complex.ID_entity'},$env{'complex_cat.ID_entity'}],'quiet'=>1);
	}
	
	$t->close();
	return %complex;
}


1;
