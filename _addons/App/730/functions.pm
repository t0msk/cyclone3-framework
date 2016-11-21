#!/bin/perl
package App::730::functions;

=head1 NAME

App::730::functions

=head1 DESCRIPTION



=cut

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 DEPENDS

=over

=item *

L<App::730::_init|app/"730/_init.pm">

=item *

L<TOM::Security::form|lib/"TOM/Security/form.pm">

=back

=cut

use App::730::_init;
use TOM::Security::form;
use Time::HiRes qw(usleep);
use Ext::TextHyphen::_init;
use Ext::Redis::_init;
use Ext::Elastic::_init;

our $debug=0;
our $quiet;$quiet=1 unless $debug;

=head2 event_add()

Adds new event, or updates the old one

Add new event

 event_add
 (
   #'event.ID' => '', || 'event.ID_entity' => '',
   'event.name' => 'My Event',
   'event.datetime_start' => 'CURDAY()',
   'event.datetime_finish' => 'CURDAY()+1',
   'event.datetime_publish_start' => 'NOW()',
   'event.datetime_publish_stop' => 'NULL',
   'event.link' => 'http://',
   'event.location' => 'Bratislava',
   'event.metadata' => '<...>',
   'event.status' => 'N',
   'event_lng.lng' => $tom::lng,
   'event_lng.name_long' => 'My Event form my beer friends',
   'event_lng.description_short' => '<p>...',
   'event_lng.description' => '<p>...'
 );

=cut

sub event_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::event_add()",'timer'=>1);
	
	my $content_updated=0; # boolean if important content attributes was updated
	
	$env{'event_lng.lng'} = $tom::lng unless $env{'event_lng.lng'};
	
	# EVENT
	
	my %event;
	
	if ($env{'event.ID_entity'})
	{
		# convert ID_entity to ID
		my $sql=qq{
			SELECT
				ID
			FROM
				`$App::730::db_name`.`a730_event`
			WHERE
				ID_entity='$env{'event.ID_entity'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%event=$sth0{'sth'}->fetchhash();
		$env{'event.ID'}=$event{'ID'};
	}
	
	if ($env{'event.ID'})
	{
		%event=App::020::SQL::functions::get_ID(
			'ID' => $env{'event.ID'},
			'db_h' => "main",
			'db_name' => $App::730::db_name,
			'tb_name' => "a730_event",
			'columns' => {'*'=>1}
		);
		$env{'event.ID_entity'}=$event{'ID_entity'};
	}
	
	if (!$env{'event.ID'})
	{
		# generating new event!
		main::_log("adding new regular event");
		
		my %columns;
		$columns{'ID_entity'}=$env{'event.ID_entity'} if $env{'event.ID_entity'};
		$columns{'mode'}="'".TOM::Security::form::sql_escape($env{'event.mode'})."'" if $env{'event.mode'};
		
		# default datetimes
		
		# start today
		$columns{'datetime_start'}='NOW()';
		
		# finish last second of today by default
		$columns{'datetime_finish'}='DATE_ADD(DATE_ADD(CURDATE(), INTERVAL 1 DAY), INTERVAL  -1 SECOND)';
		#$columns{'datetime_finish'}='NOW()';
		
		$columns{'datetime_publish_start'}='NOW()';
		
#		my $user = $env{'ID_user'} if exists $env{'ID_user'};
#		$user = $main::USRM{'ID_user'} unless ($user);
		
		$columns{'posix_owner'} = "'".($env{'ID_user'} || $main::USRM{'ID_user'})."'";
		$columns{'posix_modified'} = "'".$main::USRM{'ID_user'}."'";
		
		$env{'event.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::730::db_name,
			'tb_name' => "a730_event",
			'columns' =>
			{
				%columns,
			},
			'-journalize' => 1,
		);
		
		main::_log("generated event ID='$env{'event.ID'}'");
		undef $env{'event.ID_entity'}; # to reload event info
		$content_updated=1;
	}
	
	if (!$env{'event.ID_entity'})
	{
		# convert ID to ID_entity
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::730::db_name`.`a730_event`
			WHERE
				ID='$env{'event.ID'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%event=$sth0{'sth'}->fetchhash();
		$env{'event.ID_entity'}=$event{'ID_entity'};
	}
	
	
	# update if necessary
	if ($env{'event.ID'})
	{
		my %columns;
		# name
		$columns{'name'}="'".TOM::Security::form::sql_escape($env{'event.name'})."'"
			if ($env{'event.name'} && ($env{'event.name'} ne $event{'name'}));
		# name_url
		$columns{'name_url'}="'".TOM::Security::form::sql_escape(TOM::Net::URI::rewrite::convert($env{'event.name'}))."'"
			if ($env{'event.name'} && ($env{'event.name'} ne $event{'name'}));
		
		# datetime_start
		if (exists $env{'event.datetime_start'} && ($env{'event.datetime_start'} ne $event{'datetime_start'}))
		{
			if (!$env{'event.datetime_start'})
			{
				$columns{'datetime_start'}="NULL";
			}
			else
			{
				$columns{'datetime_start'}="'".$env{'event.datetime_start'}."'";
			}
		}

		# datetime_finish
		if (exists $env{'event.datetime_finish'} && ($env{'event.datetime_finish'} ne $event{'datetime_finish'}))
		{
			if (!$env{'event.datetime_finish'})
			{
				$columns{'datetime_finish'}="NULL";
			}
			else
			{
				$columns{'datetime_finish'}="'".$env{'event.datetime_finish'}."'";
			}
		}

		# datetime_publish_start
		$columns{'datetime_publish_start'}="'".$env{'event.datetime_publish_start'}."'"
			if ($env{'event.datetime_publish_start'} && ($env{'event.datetime_publish_start'} ne $event{'datetime_publish_start'}));

		# datetime_publish_stop
		if (exists $env{'event.datetime_publish_stop'} && ($env{'event.datetime_publish_stop'} ne $event{'datetime_publish_stop'}))
		{
			if (!$env{'event.datetime_publish_stop'})
			{
				$columns{'datetime_publish_stop'}="NULL";
			}
			else
			{
				$columns{'datetime_publish_stop'}="'".$env{'event.datetime_publish_stop'}."'";
			}
		}

		# max_attendees
		if (exists $env{'event.max_attendees'} && ($env{'event.max_attendees'} ne $event{'max_attendees'}))
		{
			if (!$env{'event.max_attendees'})
			{
				if ($env{'event.max_attendees'} eq '0') { $columns{'max_attendees'}="'".$env{'event.max_attendees'}."'"; } else
				{
					$columns{'max_attendees'}="NULL";
				}
			}
			else
			{
				$columns{'max_attendees'}="'".$env{'event.max_attendees'}."'";
			}
		}

		# ref_ID
		$columns{'ref_ID'}="'".TOM::Security::form::sql_escape($env{'event.ref_ID'})."'"
			if (exists $env{'event.ref_ID'} && ($env{'event.ref_ID'} ne $event{'ref_ID'}));
		# link
		$columns{'link'}="'".TOM::Security::form::sql_escape($env{'event.link'})."'"
			if (exists $env{'event.link'} && ($env{'event.link'} ne $event{'link'}));
		# location
		$columns{'location'}="'".TOM::Security::form::sql_escape($env{'event.location'})."'"
			if (exists $env{'event.location'} && ($env{'event.location'} ne $event{'location'}));

		# latitude_decimal
		$columns{'latitude_decimal'}="'".TOM::Security::form::sql_escape($env{'event.latitude_decimal'})."'"
			if (exists $env{'event.latitude_decimal'} && ($env{'event.latitude_decimal'} ne $event{'latitude_decimal'}));
		# longitude_decimal
		$columns{'longitude_decimal'}="'".TOM::Security::form::sql_escape($env{'event.longitude_decimal'})."'"
			if (exists $env{'event.longitude_decimal'} && ($env{'event.longitude_decimal'} ne $event{'longitude_decimal'}));
		
		# country_code
		$columns{'country_code'}="'".TOM::Security::form::sql_escape($env{'event.country_code'})."'"
			if (exists $env{'event.country_code'} && ($env{'event.country_code'} ne $event{'country_code'}));
		# state
		$columns{'state'}="'".TOM::Security::form::sql_escape($env{'event.state'})."'"
			if (exists $env{'event.state'} && ($env{'event.state'} ne $event{'state'}));
		# county
		$columns{'county'}="'".TOM::Security::form::sql_escape($env{'event.county'})."'"
			if (exists $env{'event.county'} && ($env{'event.county'} ne $event{'county'}));
		# district
		$columns{'district'}="'".TOM::Security::form::sql_escape($env{'event.district'})."'"
			if (exists $env{'event.district'} && ($env{'event.district'} ne $event{'district'}));
		# city
		$columns{'city'}="'".TOM::Security::form::sql_escape($env{'event.city'})."'"
			if (exists $env{'event.city'} && ($env{'event.city'} ne $event{'city'}));
		# ZIP
		$columns{'ZIP'}="'".TOM::Security::form::sql_escape($env{'event.ZIP'})."'"
			if (exists $env{'event.ZIP'} && ($env{'event.ZIP'} ne $event{'ZIP'}));
		# street
		$columns{'street'}="'".TOM::Security::form::sql_escape($env{'event.street'})."'"
			if (exists $env{'event.street'} && ($env{'event.street'} ne $event{'street'}));
		# street_num
		$columns{'street_num'}="'".TOM::Security::form::sql_escape($env{'event.street_num'})."'"
			if (exists $env{'event.street_num'} && ($env{'event.street_num'} ne $event{'street_num'}));
		
		# metadata
		my %metadata=App::020::functions::metadata::parse($event{'metadata'});
		
		if ($env{'event.metadata.replace'} && $env{'event.metadata'})
		{
			if (!ref($env{'event.metadata'}))
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
		
		$columns{'metadata'}="'".TOM::Security::form::sql_escape($env{'event.metadata'})."'"
			if (exists $env{'event.metadata'} && ($env{'event.metadata'} ne $event{'metadata'}));
		
		# status
		$columns{'status'}="'".TOM::Security::form::sql_escape($env{'event.status'})."'"
			if ($env{'event.status'} && ($env{'event.status'} ne $event{'status'}));

		# mode
		$columns{'mode'}="'".TOM::Security::form::sql_escape($env{'event.mode'})."'"
			if ($env{'event.mode'} && ($env{'event.mode'} ne $event{'mode'}));


		# priority_A
		$columns{'priority_A'}="'".TOM::Security::form::sql_escape($env{'event.priority_A'})."'"
			if ($env{'event.priority_A'} && ($env{'event.priority_A'} ne $event{'priority_A'}));


		# prices

		# price
		$env{'event.price'}='' if $env{'event.price'} eq "0.000";
		$columns{'price'}="'".TOM::Security::form::sql_escape($env{'event.price'})."'"
			if (exists $env{'event.price'} && ($env{'event.price'} ne $event{'price'}));
		$columns{'price'}='NULL' if $columns{'price'} eq "''";
		# price_max
		$env{'event.price_max'}='' if $env{'event.price_max'} eq "0.000";
		$columns{'price_max'}="'".TOM::Security::form::sql_escape($env{'event.price_max'})."'"
			if (exists $env{'event.price_max'} && ($env{'event.price_max'} ne $event{'price_max'}));
		$columns{'price_max'}='NULL' if $columns{'price_max'} eq "''";
		# price_currency
		$columns{'price_currency'}="'".TOM::Security::form::sql_escape($env{'event.price_currency'})."'"
		if ($env{'event.price_currency'} && ($env{'event.price_currency'} ne $event{'price_currency'}));
		
		$columns{'VAT'}="'".TOM::Security::form::sql_escape($env{'event.VAT'})."'"
		if (exists $env{'event.VAT'} && ($env{'event.VAT'} ne $event{'VAT'}));

		if (keys %columns)
		{
			App::020::SQL::functions::update(
				'ID' => $env{'event.ID'},
				'db_h' => "main",
				'db_name' => $App::730::db_name,
				'tb_name' => "a730_event",
				'columns' => {%columns},
				'-journalize' => 1
			);
			$content_updated=1;
		}
	}
	
	# EVENT_CAT

	if ($env{'category'})
	{
		
		main::_log("add to cat '$env{'category'}'");
		
		my $sql=qq{
			SELECT
				ID, ID_entity
			FROM
				`$App::730::db_name`.a730_event_cat
			WHERE
				name = '$env{'category'}' OR ID=$env{'category'}
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			if ($db0_line{'ID_entity'})
			{
				main::_log("adding event to category...ID_entity: ".$db0_line{'ID_entity'});
				my $sql=qq{
					REPLACE INTO `$App::730::db_name`.a730_event_rel_cat
					(
						ID_event,
						ID_category
					)
					VALUES
					(
						$env{'event.ID_entity'},
						$db0_line{'ID_entity'}
					)
				};
				TOM::Database::SQL::execute($sql,'quiet'=>1);
				
			}
			else
			{
				main::_log("cannot add to nonexistent category");
			}
		}
		
	}
	
	
	# EVENT_LNG
	
	my %event_lng;
	if (!$env{'event_lng.ID'})
	{
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::730::db_name`.`a730_event_lng`
			WHERE
				ID_entity='$event{'ID_entity'}' AND
				lng='$env{'event_lng.lng'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%event_lng=$sth0{'sth'}->fetchhash();
		$env{'event_lng.ID'}=$event_lng{'ID'};
	}
	
	if (!$env{'event_lng.ID'})
	{
		# create one language representation of event in content structure
		my %columns;
		
		$env{'event_lng.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::730::db_name,
			'tb_name' => "a730_event_lng",
			'columns' =>
			{
				%columns,
				'ID_entity' => $env{'event.ID_entity'},
				'lng' => "'$env{'event_lng.lng'}'",
			},
			'-journalize' => 1,
		);
		$content_updated=1;
	}
	
	# update if necessary
	if ($env{'event_lng.ID'})
	{
		my %columns;
		
		# name_long
		$columns{'name_long'}="'".TOM::Security::form::sql_escape($env{'event_lng.name_long'})."'"
			if (exists $env{'event_lng.name_long'} && ($env{'event_lng.name_long'} ne $event{'name_long'}));
		# description_short
		$columns{'description_short'}="'".TOM::Security::form::sql_escape($env{'event_lng.description_short'})."'"
			if (exists $env{'event_lng.description_short'} && ($env{'event_lng.description_short'} ne $event{'description_short'}));
		# description
		$columns{'description'}="'".TOM::Security::form::sql_escape($env{'event_lng.description'})."'"
			if (exists $env{'event_lng.description'} && ($env{'event_lng.description'} ne $event{'description'}));
		
		if (keys %columns)
		{
			App::020::SQL::functions::update(
				'ID' => $env{'event_lng.ID'},
				'db_h' => "main",
				'db_name' => $App::730::db_name,
				'tb_name' => "a730_event_lng",
				'columns' => {%columns},
				'-journalize' => 1
			);
			$content_updated=1;
		}
	}
	
	if ($content_updated)
	{
		App::020::SQL::functions::_save_changetime({'db_h'=>'main','db_name'=>$App::730::db_name,'tb_name'=>'a730_event','ID_entity'=>$env{'event.ID_entity'}});
		_event_index('ID'=>$env{'event.ID'}, 'commit' => $env{'commit'});
	}
	
	$t->close();
	return %env;
}


sub _event_index_all
{
	return 1 if TOM::Engine::jobify(\@_,{'routing_key' => 'db:'.$App::730::db_name}); # do it in background
	
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			`ID_entity`
		FROM
			`$App::730::db_name`.`a730_event`
	},'quiet'=>1);
	my $i;
	while (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		_event_index('ID_entity' => $db0_line{'ID_entity'});
	}
	main::_log("created pool");
}


sub _event_index
{
	return 1 if TOM::Engine::jobify(\@_,{'routing_key' => 'db:'.$App::730::db_name,'class'=>'indexer'}); # do it in background
	
	my %env=@_;
	$env{'ID_entity'} = $env{'ID'} unless $env{'ID_entity'}; # doesn't matter in events
	return undef unless $env{'ID_entity'}; # event.ID
	
	if ($Elastic) # the new way in Cyclone3 :)
	{
		my $t=track TOM::Debug(__PACKAGE__."::_article_index::elastic(".$env{'ID_entity'}.")",'timer'=>1);
		
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				`ID`
			FROM
				`$App::730::db_name`.`a730_event`
			WHERE
						`ID_entity` = ?
				AND	`status` IN ('Y','N','L')
			LIMIT 1
		},'quiet'=>1,'bind'=>[$env{'ID_entity'}]);
		if (!$sth0{'rows'})
		{
			main::_log("event.ID_entity=$env{'ID_entity'} not found",1);
			if ($Elastic->exists(
				'index' => 'cyclone3.'.$App::730::db_name,
				'type' => 'a730_event',
				'id' => $env{'ID_entity'}
			))
			{
				main::_log("removing from Elastic",1);
				$Elastic->delete(
					'index' => 'cyclone3.'.$App::730::db_name,
					'type' => 'a730_event',
					'id' => $env{'ID_entity'}
				);
			}
			$t->close();
			return 1;
		}
		
		my %event;
		
		# event_lng
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				`$App::730::db_name`.`a730_event_lng`
			WHERE
						`status` = 'Y'
				AND	`ID_entity` = ?
		},'quiet'=>1,'bind'=>[$env{'ID_entity'}]);
		while (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$event{'locale'}{$db0_line{'lng'}}{'description'}=$db0_line{'description'}
				if $db0_line{'description'};
			$event{'locale'}{$db0_line{'lng'}}{'description_short'}=$db0_line{'description_short'}
				if $db0_line{'description_short'};
			$event{'locale'}{$db0_line{'lng'}}{'name_long'}=$db0_line{'name_long'}
				if $db0_line{'name_long'};
		}
		
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				`event`.`ID`,
				`event`.`name`,
				`event`.`datetime_start`,
				`event`.`datetime_finish`,
				`event`.`datetime_publish_start`,
				`event`.`datetime_publish_stop`,
				`event`.`status`,
				`event_cat`.`name` AS `cat_name`,
				`event_cat`.`ID` AS `cat_ID`,
				`event_cat`.`ID_entity` AS `cat_ID_entity`,
				`event_cat`.`ID_charindex`
			FROM
				`$App::730::db_name`.`a730_event` AS `event`
			LEFT JOIN `$App::730::db_name`.`a730_event_rel_cat` AS `event_rel_cat` ON
				(
					`event_rel_cat`.`ID_event` = `event`.`ID_entity`
				)
			LEFT JOIN `$App::730::db_name`.`a730_event_cat` AS `event_cat` ON
				(
							`event_cat`.`ID_entity` = `event_rel_cat`.`ID_category`
					AND	`event_cat`.`lng` = '$env{'lng'}'
				)
			WHERE
						`event`.`ID_entity` = ?
				AND	`event`.`status` = 'Y'
			ORDER BY
				`event`.`datetime_start` DESC
		},'quiet'=>1,'bind'=>[$env{'ID_entity'}]);
		$event{'status'}="N";
		while (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			push @{$event{'name'}},$db0_line{'name'};

			push @{$event{'cat'}},$db0_line{'cat_ID_entity'}
				if $db0_line{'cat_ID_entity'};
			push @{$event{'cat_charindex'}},$db0_line{'ID_charindex'}
				if $db0_line{'ID_charindex'};
			
			push @{$event{'cat_charindex'}},$db0_line{'ID_charindex'}
				if $db0_line{'ID_charindex'};
			
			push @{$event{'event_attrs'}},{
				'name' => $db0_line{'name'},
				'cat' => $db0_line{'cat_ID_entity'},
				'cat_charindex' => $db0_line{'ID_charindex'},
				'datetime_start' => $db0_line{'datetime_start'}
			};
			
			$event{'status'}="Y"
				if $db0_line{'status'} eq "Y";
		}
		
		my %log_date=main::ctogmdatetime(time(),format=>1);
		$Elastic->index(
			'index' => 'cyclone3.'.$App::730::db_name,
			'type' => 'a730_event',
			'id' => $env{'ID_entity'},
			'body' => {
				%event,
				'_datetime_index' => 
					$log_date{'year'}.'-'.$log_date{'mom'}.'-'.$log_date{'mday'}
					.'T'.$log_date{'hour'}.":".$log_date{'min'}.":".$log_date{'sec'}.'Z'
			}
		);
		
#		use Data::Dumper;
#		print Dumper(\%event);
		
		$t->close();
	}
	
	return undef unless $Ext::Solr;
	
	my $t=track TOM::Debug(__PACKAGE__."::_event_index($env{'ID'})",'timer'=>1);
	
	my @content;
	my %content_lng;
	
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			*
		FROM
			$App::730::db_name.a730_event
		WHERE
			status IN ('Y','N','L') AND
			ID=?
		LIMIT 1
	},'quiet'=>1,'bind'=>[$env{'ID'}]);
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		$env{'ID_entity'} = $db0_line{'ID_entity'};
		
		push @content,WebService::Solr::Field->new( 'name' => $db0_line{'name'} )
			if $db0_line{'name'};
		push @content,WebService::Solr::Field->new( 'title' => $db0_line{'name'} )
			if $db0_line{'name'};
		push @content,WebService::Solr::Field->new( 'name_url_s' => $db0_line{'name_url'} )
			if $db0_line{'name_url'};
		
		push @content,WebService::Solr::Field->new( 'link_s' => $db0_line{'link'} )
			if $db0_line{'link'};
		push @content,WebService::Solr::Field->new( 'location_s' => $db0_line{'location'} )
			if $db0_line{'location'};
		push @content,WebService::Solr::Field->new( 'country_code_s' => $db0_line{'country_code'} )
			if $db0_line{'country_code'};
		push @content,WebService::Solr::Field->new( 'state_s' => $db0_line{'state'} )
			if $db0_line{'state'};
		push @content,WebService::Solr::Field->new( 'county_s' => $db0_line{'county'} )
			if $db0_line{'county'};
		push @content,WebService::Solr::Field->new( 'district_s' => $db0_line{'district'} )
			if $db0_line{'district'};
		push @content,WebService::Solr::Field->new( 'city_s' => $db0_line{'city'} )
			if $db0_line{'city'};
		push @content,WebService::Solr::Field->new( 'ZIP_s' => $db0_line{'ZIP'} )
			if $db0_line{'ZIP'};
		push @content,WebService::Solr::Field->new( 'street_s' => $db0_line{'street'} )
			if $db0_line{'street'};
		push @content,WebService::Solr::Field->new( 'street_num_s' => $db0_line{'street_num'} )
			if $db0_line{'street_num'};
		push @content,WebService::Solr::Field->new( 'latitude_decimal_f' => $db0_line{'latitude_decimal'} )
			if $db0_line{'latitude_decimal'};
		push @content,WebService::Solr::Field->new( 'longitude_decimal_f' => $db0_line{'longitude_decimal'} )
			if $db0_line{'longitude_decimal'};
		push @content,WebService::Solr::Field->new( 'priority_A_s' => $db0_line{'priority_A'} )
			if $db0_line{'priority_A'};
		push @content,WebService::Solr::Field->new( 'max_attendees_i' => $db0_line{'max_attendees'} )
			if $db0_line{'max_attendees'};
		
		push @content,WebService::Solr::Field->new( 'mode_s' => $db0_line{'mode'} )
			if $db0_line{'mode'};
		push @content,WebService::Solr::Field->new( 'status_s' => $db0_line{'status'} )
			if $db0_line{'status'};
		
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
					{push @content,WebService::Solr::Field->new( $sec.'.'.$_.'_sm' => $val)}
					push @content,WebService::Solr::Field->new( 'metadata_used_sm' => $sec.'.'.$_);
					next;
				}
				
				push @content,WebService::Solr::Field->new( $sec.'.'.$_.'_s' => "$metadata{$sec}{$_}" );
				if ($metadata{$sec}{$_}=~/^[0-9]{1,9}$/)
				{
					push @content,WebService::Solr::Field->new( $sec.'.'.$_.'_i' => "$metadata{$sec}{$_}" );
				}
				if ($metadata{$sec}{$_}=~/^[0-9\.]{1,9}$/)
				{
					push @content,WebService::Solr::Field->new( $sec.'.'.$_.'_f' => "$metadata{$sec}{$_}" );
				}
				
				# list of used metadata fields
				push @content,WebService::Solr::Field->new( 'metadata_used_sm' => $sec.'.'.$_ );
			}
		}
	}
	else
	{
		
	}
	
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			*
		FROM
			$App::730::db_name.a730_event_lng
		WHERE
			status='Y'
			AND ID_entity=?
	},'quiet'=>1,'bind'=>[$env{'ID'}]);
	while (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		my $lng=$db0_line{'lng'};
		
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT
				a730_event_rel_cat.ID_category,
				a730_event_cat.ID_charindex
			FROM
				$App::730::db_name.a730_event_rel_cat
			INNER JOIN $App::730::db_name.a730_event_cat ON
			(
				a730_event_rel_cat.ID_category = a730_event_cat.ID_entity
				AND a730_event_cat.lng = ?
				AND a730_event_cat.status = 'Y'
			)
			WHERE
				a730_event_rel_cat.ID_event = ?
		},'quiet'=>1,'bind'=>[$lng,$env{'ID_entity'}]);
		while (my %db1_line=$sth1{'sth'}->fetchhash())
		{
			push @{$content_lng{$lng}},WebService::Solr::Field->new( 'cat_charindex_sm' =>  $db1_line{'ID_charindex'}); # event_cat.ID_entity
		}
		
		# save original HTML values
		push @{$content_lng{$db0_line{'lng'}}},WebService::Solr::Field->new( 'description_short_orig_s' => $db0_line{'description_short'} )
			if $db0_line{'description_short'};
		push @{$content_lng{$db0_line{'lng'}}},WebService::Solr::Field->new( 'description_orig_s' => $db0_line{'description'} )
			if $db0_line{'description'};
		
		for my $part('description_short', 'description')
		{
			$db0_line{$part}=~s|<.*?>||gms;
			$db0_line{$part}=~s|&nbsp;| |gms;
			$db0_line{$part}=~s|  | |gms;
		}
		
		push @{$content_lng{$lng}},WebService::Solr::Field->new( 'lng_s' => $lng );
		
		push @{$content_lng{$lng}},WebService::Solr::Field->new( 'name' => $db0_line{'name'} )
			if $db0_line{'name'};
		push @{$content_lng{$lng}},WebService::Solr::Field->new( 'title' => $db0_line{'name'} )
			if $db0_line{'name'};
		push @{$content_lng{$lng}},WebService::Solr::Field->new( 'name_url_s' => $db0_line{'name_url'} )
			if $db0_line{'name_url'};
		push @{$content_lng{$lng}},WebService::Solr::Field->new( 'subject' => $db0_line{'name_long'} )
			if ($db0_line{'name_long'});
		
		push @{$content_lng{$db0_line{'lng'}}},WebService::Solr::Field->new( 'description' => $db0_line{'description_short'} )
			if $db0_line{'description_short'};
		
		if ($db0_line{'datetime_modified'})
		{
			$db0_line{'datetime_modified'}=~s| (\d\d)|T$1|;
			$db0_line{'datetime_modified'}.="Z";
			push @{$content_lng{$lng}},WebService::Solr::Field->new( 'last_modified' => $db0_line{'datetime_modified'} );
		}
		
	}
	
	my $solr = Ext::Solr::service();
	
	my $response = $solr->search( "+id:".$App::730::db_name.".a730_event.* +ID_i:$env{'ID'}" );
	for my $doc ( $response->docs )
	{
		my $lng=$doc->value_for( 'lng_s' );
		if (!$content_lng{$lng})
		{
			$solr->delete_by_id($doc->value_for('id'));
		}
	}
	
	my $last_indexed=$tom::Fyear."-".$tom::Fmom."-".$tom::Fmday."T".$tom::Fhour.":".$tom::Fmin.":".$tom::Fsec."Z";
	foreach my $lng (keys %content_lng)
	{
		my $id=$App::730::db_name.".a730_event.".$lng.".".$env{'ID'};
		main::_log("index id='$id'");
		
		my $doc = WebService::Solr::Document->new();
		
		$doc->add_fields((
			WebService::Solr::Field->new( 'id' => $id ),
			@content,
			@{$content_lng{$lng}},
			WebService::Solr::Field->new( 'db_s' => $App::730::db_name ),
			WebService::Solr::Field->new( 'addon_s' => 'a730_event' ),
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


sub _a210_by_cat
{
	my $cats=shift;
	my %env=@_;
	
	$env{'lng'}=$tom::lng unless $env{'lng'};
	my $cache_key=$env{'lng'}.'::'.join('::',@{$cats});
	
	# changetimes
	my $changetime_a730=App::020::SQL::functions::_get_changetime({
		'db_name' => $App::730::db_name,
		'tb_name' => 'a730_event_cat',
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
			'key' => 'App::730::functions::_a210_by_cat::'.$cache_key
		);
		if (($cache->{'time'} > $changetime_a210) && ($cache->{'time'} > $changetime_a730))
		{
#			print "value=$cache->{'value'} time=$cache->{'time'} key=$cache_key\n";
#			main::_log("found, return");
			return $cache->{'value'};
		}
	}
	
	# find path
	my @categories;
	my %sql_def=('db_h' => "main",'db_name' => $App::730::db_name,'tb_name' => "a730_event_cat");
	foreach my $cat(@{$cats})
	{
#		print "mam $cat";
		my %sth0=TOM::Database::SQL::execute(
			qq{SELECT ID FROM $App::730::db_name.a730_event_cat WHERE ID_entity=? AND lng=? LIMIT 1},
			'bind'=>[$cat,$env{'lng'}],'log'=>0,'quiet'=>1,
			'-cache' => 600,
			'-cache_changetime' => App::020::SQL::functions::_get_changetime({
				'db_name' => $App::730::db_name,
				'tb_name' => 'a730_event_cat',
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
#			push @{$event->{'log'}},"find $i ".$cat;
#			print "aha $i $cat\n";
			my %db0_line;
			foreach my $relation(App::160::SQL::get_relations(
				'db_name' => $App::210::db_name,
				'l_prefix' => 'a210',
				'l_table' => 'page',
				#'l_ID_entity' = > ???
				'r_prefix' => "a730",
				'r_table' => "event_cat",
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
					'-cache' => 86400*7,
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
			'key' => 'App::730::functions::_a210_by_cat::'.$cache_key,
			'value' => {
				'time' => time(),
				'value' => $category
			},
			'expiration' => '3600S'
		);
	}
	
	return $category;
}


=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
