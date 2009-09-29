#!/bin/perl
package App::730::functions;

=head1 NAME

App::730::functions

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

L<App::730::_init|app/"730/_init.pm">

=item *

L<TOM::Security::form|lib/"TOM/Security/form.pm">

=back

=cut

use App::730::_init;
use TOM::Security::form;
use Time::HiRes qw(usleep);

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
		
		$columns{'datetime_start'}='NOW()';
		$columns{'datetime_finish'}='NOW()';
		$columns{'datetime_publish_start'}='NOW()';
		
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
		$columns{'datetime_start'}="'".$env{'event.datetime_start'}."'"
			if ($env{'event.datetime_start'} && ($env{'event.datetime_start'} ne $event{'datetime_start'}));
		# datetime_finish
		$columns{'datetime_finish'}="'".$env{'event.datetime_finish'}."'"
			if ($env{'event.datetime_finish'} && ($env{'event.datetime_finish'} ne $event{'datetime_finish'}));
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
		# link
		$columns{'link'}="'".TOM::Security::form::sql_escape($env{'event.link'})."'"
			if (exists $env{'event.link'} && ($env{'event.link'} ne $event{'link'}));
		# location
		$columns{'location'}="'".TOM::Security::form::sql_escape($env{'event.location'})."'"
			if (exists $env{'event.location'} && ($env{'event.location'} ne $event{'location'}));
		# metadata
		$columns{'metadata'}="'".TOM::Security::form::sql_escape($env{'event.metadata'})."'"
			if (exists $env{'event.metadata'} && ($env{'event.metadata'} ne $event{'metadata'}));
		if ($columns{'metadata'})
		{
			App::020::functions::metadata::metaindex_set(
				'db_h' => 'main',
				'db_name' => $App::730::db_name,
				'tb_name' => 'a730_event',
				'ID' => $env{'event.ID'},
				'metadata' => {App::020::functions::metadata::parse($env{'event.metadata'})}
			);
		}
		# status
		$columns{'status'}="'".TOM::Security::form::sql_escape($env{'event.status'})."'"
			if ($env{'event.status'} && ($env{'event.status'} ne $event{'status'}));

		# priority_A
		$columns{'priority_A'}="'".TOM::Security::form::sql_escape($env{'event.priority_A'})."'"
			if ($env{'event.priority_A'} && ($env{'event.priority_A'} ne $event{'priority_A'}));
		
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
	}
	
	$t->close();
	return %env;
}


=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
