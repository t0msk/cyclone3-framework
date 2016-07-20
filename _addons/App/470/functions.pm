#!/bin/perl
package App::470::functions;


use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
use charnames ':full';
our $soft_hyphen="\N{SOFT HYPHEN}";
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


use App::470::_init;

use Data::Dumper;

our $debug=1;
our $quiet;$quiet=1 unless $debug;

sub event_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::event_add()");
	
	my %event;
	
	if ($env{'event.ID'})
	{
		$env{'event.ID'}=$env{'event.ID'}+0;
		undef $env{'event.ID_entity'}; # ID_entity has lower priority as ID
		# when real ID_entity used, then read it from ID
		# when ID not found, undef ID_entity, because is invalid
		main::_log("finding event.ID_entity by event.ID='$env{'event.ID'}'");
		%event=App::020::SQL::functions::get_ID(
			'ID' => $env{'event.ID'},
			'db_h' => "main",
			'db_name' => $App::470::db_name,
			'tb_name' => "a470_event",
			'columns' => {'*'=>1}
		);
		if ($event{'ID'})
		{
			$env{'event.ID_entity'}=$event{'ID_entity'};
			main::_log("found event.ID_entity='$env{'event.ID_entity'}'");
		}
		else
		{
			main::_log("not found event.ID, undef",1);
			App::020::SQL::functions::new(
				'db_h' => "main",
				'db_name' => $App::470::db_name,
				'tb_name' => "a470_event",
				'columns' => {
					'ID' => $env{'event.ID'},
				},
				'-journalize' => 1,
			);
			%event=App::020::SQL::functions::get_ID(
				'ID' => $env{'event.ID'},
				'db_h' => "main",
				'db_name' => $App::470::db_name,
				'tb_name' => "a470_event",
				'columns' => {'*'=>1}
			);
			$env{'event.ID_entity'}=$event{'ID_entity'};
		}
	}
	
	if (!$env{'event.ID'})
	{
		main::_log("!event.ID, create event.ID (event.ID_entity='$env{'event.ID_entity'}')");
		my %columns;
		$columns{'ID_entity'}=$env{'event.ID_entity'} if $env{'event.ID_entity'};


		$env{'event.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::470::db_name,
			'tb_name' => "a470_event",
			'columns' => {%columns},
			'-journalize' => 1,
		);
		%event=App::020::SQL::functions::get_ID(
			'ID' => $env{'event.ID'},
			'db_h' => "main",
			'db_name' => $App::470::db_name,
			'tb_name' => "a470_event",
			'columns' => {'*'=>1}
		);
		$env{'event.ID'}=$event{'ID'};
		$env{'event.ID_entity'}=$event{'ID_entity'};
	}
	
	main::_log("event.ID='$event{'ID'}' event.ID_entity='$event{'ID_entity'}'");
	
	# update only if necessary
	my %columns;
	my %data;

	# # status
	# $data{'status'}=$env{'event.status'}
	# 	if ($env{'event.status'} && ($env{'event.status'} ne $event{'status'}));

	# # name
	# $data{'name'}=$env{'event.name'}
	# 	if ($env{'event.name'} && ($env{'event.name'} ne $event{'name'}));
	# $data{'name_url'}=TOM::Net::URI::rewrite::convert($env{'event.name'},'notlower'=>1)
	# 	if ($env{'event.name'} && ($env{'event.name'} ne $event{'name'}));
	
	# # datetime_start
	# $data{'datetime_start'}=$env{'event.datetime_start'}
	# 	if ($env{'event.datetime_start'} && ($env{'event.datetime_start'} ne $event{'datetime_start'}));

	# # datetime_finish
	# $data{'datetime_finish'}=$env{'event.datetime_finish'}
	# 	if ($env{'event.datetime_finish'} && ($env{'event.datetime_finish'} ne $event{'datetime_finish'}));

	# metadata
	my %metadata=App::020::functions::metadata::parse($event{'metadata'});
	
	foreach my $section(split(';',$env{'event.metadata.override_sections'}))
	{
		delete $metadata{$section};
	}
	
	if ($env{'event.metadata.replace'})
	{
		if (!ref($env{'event.metadata'}) && $env{'event.metadata'})
		{
			%metadata=App::020::functions::metadata::parse($env{'event.metadata'});
		}
		if (ref($env{'event.metadata'}) eq "HASH")
		{
			%metadata=%{$env{'event.metadata'}};
		}
	}
	else
	{
		if (!ref($env{'event.metadata'}) && $env{'event.metadata'})
		{
			# when metadata send as <metatree></metatree> then always replace
			%metadata=App::020::functions::metadata::parse($env{'event.metadata'});
		}
		if (ref($env{'event.metadata'}) eq "HASH")
		{
			# metadata overrride
			foreach my $section(keys %{$env{'event.metadata'}})
			{
				foreach my $variable(keys %{$env{'event.metadata'}{$section}})
				{
					$metadata{$section}{$variable}=$env{'event.metadata'}{$section}{$variable};
				}
			}
		}
	}
	
	$env{'event.metadata'}=App::020::functions::metadata::serialize(%metadata);
	
	$data{'metadata'}=$env{'event.metadata'}
		if (exists $env{'event.metadata'} && ($env{'event.metadata'} ne $event{'metadata'}));
	
	if ($env{'event.ID_category'}) {
		$columns{'ID_category'} = $env{'event.ID_category'};
	}
	
	foreach my $field ('status','name','datetime_start','datetime_finish','result')
	{
		$data{$field}=$env{'event.'.$field}
			if ($env{'event.'.$field} && ($env{'event.'.$field} ne $event{$field}));
	}

	# participants
	foreach my $field ('participantA', 'participantB')
	{
		if ($field) {
			# remove existing relation first
			if (my $relation=(App::160::SQL::get_relations(
				'db_name' => $App::470::db_name,
				'l_prefix' => 'a470',
				'l_table' => 'event',
				'l_ID_entity' => $env{'event.ID'},
				'rel_type' => $field,
				'r_prefix' => "a470",
				'r_table' => "team",
				'status' => "Y",
				'limit' => 1
			))[0])
			{
				if ($relation->{'ID'})
				{
					my $success=App::160::SQL::remove_relation(
						'l_prefix' => 'a470',
						'ID' => $relation->{'ID'}
					);
				}
			}
			# create a new relation
			my ($ID_entity,$ID)=App::160::SQL::new_relation(
				'l_prefix' => 'a470',
				'l_table' => 'event',
				'l_ID_entity' => $env{'event.ID'},
				'rel_type' => $field,
				'r_db_name' => $App::470::db_name,
				'r_prefix' => 'a470',
				'r_table' => 'team',
				'r_ID_entity' => $env{"event.$field"},
				'status' => 'Y',
			);		
		}
	}

	if (keys %columns || keys %data)
	{
		App::020::SQL::functions::update(
			'ID' => $env{'event.ID'},
			'db_h' => "main",
			'db_name' => $App::470::db_name,
			'tb_name' => "a470_event",
			'columns' => {%columns},
			'data' => {%data},
			'-posix' => 1,
			'-journalize' => 1
		);
	}
	
	$t->close();
	return %event;
}

sub athlete_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::athlete_add()");
	
	my %athlete;
	if ($env{'athlete.ID'})
	{
		$env{'athlete.ID'}=$env{'athlete.ID'}+0;
		undef $env{'athlete.ID_entity'}; # ID_entity has lower priority as ID
		# when real ID_entity used, then read it from ID
		# when ID not found, undef ID_entity, because is invalid
		main::_log("finding athlete.ID_entity by athlete.ID='$env{'athlete.ID'}'");
		%athlete=App::020::SQL::functions::get_ID(
			'ID' => $env{'athlete.ID'},
			'db_h' => "main",
			'db_name' => $App::470::db_name,
			'tb_name' => "a470_athlete",
			'columns' => {'*'=>1}
		);
		if ($athlete{'ID'})
		{
			$env{'athlete.ID_entity'}=$athlete{'ID_entity'};
			main::_log("found athlete.ID_entity='$env{'athlete.ID_entity'}'");
		}
		else
		{
			main::_log("not found athlete.ID, undef",1);
			App::020::SQL::functions::new(
				'db_h' => "main",
				'db_name' => $App::470::db_name,
				'tb_name' => "a470_athlete",
				'columns' => {
					'ID' => $env{'athlete.ID'},
				},
				'-journalize' => 1,
			);
			%athlete=App::020::SQL::functions::get_ID(
				'ID' => $env{'athlete.ID'},
				'db_h' => "main",
				'db_name' => $App::470::db_name,
				'tb_name' => "a470_athlete",
				'columns' => {'*'=>1}
			);
			$env{'athlete.ID_entity'}=$athlete{'ID_entity'};
		}
	}
	
	if (!$env{'athlete.ID'})
	{
		main::_log("!athlete.ID, create athlete.ID (athlete.ID_entity='$env{'athlete.ID_entity'}')");
		my %columns;
		$columns{'ID_entity'}=$env{'athlete.ID_entity'} if $env{'athlete.ID_entity'};


		$env{'athlete.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::470::db_name,
			'tb_name' => "a470_athlete",
			'columns' => {%columns},
			'-journalize' => 1,
		);
		%athlete=App::020::SQL::functions::get_ID(
			'ID' => $env{'athlete.ID'},
			'db_h' => "main",
			'db_name' => $App::470::db_name,
			'tb_name' => "a470_athlete",
			'columns' => {'*'=>1}
		);
		$env{'athlete.ID'}=$athlete{'ID'};
		$env{'athlete.ID_entity'}=$athlete{'ID_entity'};

		# add lng
		App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::470::db_name,
			'tb_name' => "a470_athlete_lng",
			'columns' => {%columns},
			'data' => {
				'ID_entity' => $env{'athlete.ID'},
				'lng' => $env{'lng'},
			},
			'-journalize' => 1,
			'-posix' => 1,
		);
	}
	
	main::_log("athlete.ID='$athlete{'ID'}' athlete.ID_entity='$athlete{'ID_entity'}'");
	
	# update only if necessary
	my %columns;
	my %data;

	# status
	$data{'status'}=$env{'athlete.status'}
		if ($env{'athlete.status'} && ($env{'athlete.status'} ne $athlete{'status'}));

	# name
	$data{'name'}=$env{'athlete.name'}
		if ($env{'athlete.name'} && ($env{'athlete.name'} ne $athlete{'name'}));
	$data{'name_url'}=TOM::Net::URI::rewrite::convert($env{'athlete.name'},'notlower'=>1)
		if ($env{'athlete.name'} && ($env{'athlete.name'} ne $athlete{'name'}));
	
	# country_code
	$data{'country_code'}=$env{'athlete.country_code'}
		if ($env{'athlete.country_code'} && ($env{'athlete.country_code'} ne $athlete{'country_code'}));
	
	# metadata
	my %metadata=App::020::functions::metadata::parse($athlete{'metadata'});
	
	foreach my $section(split(';',$env{'athlete.metadata.override_sections'}))
	{
		delete $metadata{$section};
	}
	
	if ($env{'athlete.metadata.replace'})
	{
		if (!ref($env{'athlete.metadata'}) && $env{'athlete.metadata'})
		{
			%metadata=App::020::functions::metadata::parse($env{'athlete.metadata'});
		}
		if (ref($env{'athlete.metadata'}) eq "HASH")
		{
			%metadata=%{$env{'athlete.metadata'}};
		}
	}
	else
	{
		if (!ref($env{'athlete.metadata'}) && $env{'athlete.metadata'})
		{
			# when metadata send as <metatree></metatree> then always replace
			%metadata=App::020::functions::metadata::parse($env{'athlete.metadata'});
		}
		if (ref($env{'athlete.metadata'}) eq "HASH")
		{
			# metadata overrride
			foreach my $section(keys %{$env{'athlete.metadata'}})
			{
				foreach my $variable(keys %{$env{'athlete.metadata'}{$section}})
				{
					$metadata{$section}{$variable}=$env{'athlete.metadata'}{$section}{$variable};
				}
			}
		}
	}
	
	$env{'athlete.metadata'}=App::020::functions::metadata::serialize(%metadata);
	
	$data{'metadata'}=$env{'athlete.metadata'}
		if (exists $env{'athlete.metadata'} && ($env{'athlete.metadata'} ne $athlete{'metadata'}));

	foreach my $field ('status')
	{
		$data{$field}=$env{'athlete.'.$field}
			if ($env{'athlete.'.$field} && ($env{'athlete.'.$field} ne $athlete{$field}));
	}
	
	if (keys %columns || keys %data)
	{
		App::020::SQL::functions::update(
			'ID' => $env{'athlete.ID'},
			'db_h' => "main",
			'db_name' => $App::470::db_name,
			'tb_name' => "a470_athlete",
			'columns' => {%columns},
			'data' => {%data},
			'-posix' => 1,
			'-journalize' => 1
		);
	}

	# update lng
	my %athlete_lng;
	# get lng fields
    foreach my $key (keys %env)
    {
        if ($key =~ /athlete_lng\.([a-zA-Z\-]+)\.(.+)$/) 
		{
			my $lng = $1; my $varname = $2;
			$athlete_lng{$lng} = {} unless (exists $athlete_lng{$lng});
			$athlete_lng{$lng}{$varname} = $env{$key};
			# name_url
			# if ($varname eq 'name') {
			# 	$athlete_lng{$lng}{'name_url'}=TOM::Security::form::sql_escape(TOM::Net::URI::rewrite::convert($env->{$key}));
			# }
		}
    }

    my @lng_IDs = App::020::SQL::functions::get_ID_entity(
    	'ID_entity' => $env{'athlete.ID'},
    	'db_h' => 'main',
    	'db_name' => $App::470::db_name,
    	'tb_name' => 'a470_athlete_lng'
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
    		$App::470::db_name.a470_athlete_lng
    	WHERE
    		ID IN (?)
    };
    
    my %sth_lng=TOM::Database::SQL::execute($sql,'quiet'=>1,'bind'=>[$where_lng_IDs]);
    
    while (my %lng_line=$sth_lng{'sth'}->fetchhash())
    {
    	my $local = $lng_line{'lng'};
    	if (%athlete_lng && $athlete_lng{$local}) {
			
			App::020::SQL::functions::update(
				'db_h' => 'main',
				'db_name' => $App::470::db_name,
				'tb_name' => 'a470_athlete_lng',
				'ID' => $lng_line{'ID'},
				'lng' => $local,
				'data' => { %{$athlete_lng{$local}} },
				'quiet' => 1,
				'-journalize' => 1,
				'-posix' => 1,
			);
		}
	}

	if ($env{'athlete_cat.ID'}) {
		$env{'athlete.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::470::db_name,
			'tb_name' => "a470_athlete_sym",
			'columns' => {
				'ID' => $env{'athlete_cat.ID'},
				'ID_entity' => $env{'athlete.ID'}
			},
			'-journalize' => 1,
		);
	}
	
	$t->close();
	return %athlete;
}

sub team_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::team_add()");
	
	my %team;
	
	if ($env{'team.ID'})
	{
		$env{'team.ID'}=$env{'team.ID'}+0;
		undef $env{'team.ID_entity'}; # ID_entity has lower priority as ID
		# when real ID_entity used, then read it from ID
		# when ID not found, undef ID_entity, because is invalid
		main::_log("finding team.ID_entity by team.ID='$env{'team.ID'}'");
		%team=App::020::SQL::functions::get_ID(
			'ID' => $env{'team.ID'},
			'db_h' => "main",
			'db_name' => $App::470::db_name,
			'tb_name' => "a470_team",
			'columns' => {'*'=>1}
		);
		if ($team{'ID'})
		{
			$env{'team.ID_entity'}=$team{'ID_entity'};
			main::_log("found team.ID_entity='$env{'team.ID_entity'}'");
		}
		else
		{
			main::_log("not found team.ID, undef",1);
			App::020::SQL::functions::new(
				'db_h' => "main",
				'db_name' => $App::470::db_name,
				'tb_name' => "a470_team",
				'columns' => {
					'ID' => $env{'team.ID'},
				},
				'-journalize' => 1,
			);
			%team=App::020::SQL::functions::get_ID(
				'ID' => $env{'team.ID'},
				'db_h' => "main",
				'db_name' => $App::470::db_name,
				'tb_name' => "a470_team",
				'columns' => {'*'=>1}
			);
			$env{'team.ID_entity'}=$team{'ID_entity'};
		}
	}
	
	if (!$env{'team.ID'})
	{
		main::_log("!team.ID, create team.ID (team.ID_entity='$env{'team.ID_entity'}')");
		my %columns;
		$columns{'ID_entity'}=$env{'team.ID_entity'} if $env{'team.ID_entity'};


		$env{'team.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::470::db_name,
			'tb_name' => "a470_team",
			'columns' => {%columns},
			'-journalize' => 1,
		);
		%team=App::020::SQL::functions::get_ID(
			'ID' => $env{'team.ID'},
			'db_h' => "main",
			'db_name' => $App::470::db_name,
			'tb_name' => "a470_team",
			'columns' => {'*'=>1}
		);
		$env{'team.ID'}=$team{'ID'};
		$env{'team.ID_entity'}=$team{'ID_entity'};
	}
	
	main::_log("team.ID='$team{'ID'}' team.ID_entity='$team{'ID_entity'}'");
	
	# update only if necessary
	my %columns;
	my %data;

	# status
	$data{'status'}=$env{'team.status'}
		if ($env{'team.status'} && ($env{'team.status'} ne $team{'status'}));

	# name
	$data{'name'}=$env{'team.name'}
		if ($env{'team.name'} && ($env{'team.name'} ne $team{'name'}));
	$data{'name_url'}=TOM::Net::URI::rewrite::convert($env{'team.name'},'notlower'=>1)
		if ($env{'team.name'} && ($env{'team.name'} ne $team{'name'}));

	#country_code
	$data{'country_code'}=$env{'team.country_code'}
		if ($env{'team.country_code'} && ($env{'team.country_code'} ne $team{'country_code'}));
	
	# metadata
	my %metadata=App::020::functions::metadata::parse($team{'metadata'});
	
	foreach my $section(split(';',$env{'team.metadata.override_sections'}))
	{
		delete $metadata{$section};
	}
	
	if ($env{'team.metadata.replace'})
	{
		if (!ref($env{'team.metadata'}) && $env{'team.metadata'})
		{
			%metadata=App::020::functions::metadata::parse($env{'team.metadata'});
		}
		if (ref($env{'team.metadata'}) eq "HASH")
		{
			%metadata=%{$env{'team.metadata'}};
		}
	}
	else
	{
		if (!ref($env{'team.metadata'}) && $env{'team.metadata'})
		{
			# when metadata send as <metatree></metatree> then always replace
			%metadata=App::020::functions::metadata::parse($env{'team.metadata'});
		}
		if (ref($env{'team.metadata'}) eq "HASH")
		{
			# metadata overrride
			foreach my $section(keys %{$env{'team.metadata'}})
			{
				foreach my $variable(keys %{$env{'team.metadata'}{$section}})
				{
					$metadata{$section}{$variable}=$env{'team.metadata'}{$section}{$variable};
				}
			}
		}
	}
	
	$env{'team.metadata'}=App::020::functions::metadata::serialize(%metadata);
	
	$data{'metadata'}=$env{'team.metadata'}
		if (exists $env{'team.metadata'} && ($env{'team.metadata'} ne $team{'metadata'}));
	
	if (($env{'team_cat.ID'} || $env{'team_cat.ID_entity'}) && ($team{'status'} eq "T"))
	{
		$env{'team.status'}=$env{'team.status'} || 'N';
	}

	if ($env{'team.ID_category'}) {
		$columns{'ID_category'} = $env{'team.ID_category'};
	}
	
	foreach my $field ('status')
	{
		$data{$field}=$env{'team.'.$field}
			if ($env{'team.'.$field} && ($env{'team.'.$field} ne $team{$field}));
	}
	
	if (keys %columns || keys %data)
	{
		App::020::SQL::functions::update(
			'ID' => $env{'team.ID'},
			'db_h' => "main",
			'db_name' => $App::470::db_name,
			'tb_name' => "a470_team",
			'columns' => {%columns},
			'data' => {%data},
			'-posix' => 1,
			'-journalize' => 1
		);
	}
	
	$t->close();
	return %team;
}

1;
