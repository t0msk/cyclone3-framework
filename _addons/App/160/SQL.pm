#!/bin/perl
package App::160::SQL;

=head1 NAME

App::160::SQL

=cut

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DESCRIPTION

Functions above SQL database to manipulate with relations

=cut

=head1 DEPENDS

=over

=item *

L<App::020::_init|app/"020/_init.pm">

=item *

L<App::160::_init|app/"160/_init.pm">

=back

=cut

use App::020::_init;
use App::160::_init;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );

our $debug=0;
our $quiet;$quiet=1 unless $debug;
our $CACHE=1;
our $cache_expire = 86400; # 5 minutes - better is less time, when anything is cached wrong

=head1 FUNCTIONS

=head2 new_relation()

Creates a new relation and return ID_entity, ID

 my ($ID_entity,$ID)=new_relation(
   'l_prefix' => 'a400',
   'l_table' => '',
   'l_ID_entity' => '2',
   #'rel_type' => '', # relation type
   #'r_db_name' => 'example_tld',
   #'r_prefix' => 'a210',
   #'r_table' => 'page',
   #'r_ID_entity' => '2'
 );

=cut

sub new_relation
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::new_relation()");
	
	delete $env{'ID'} if exists $env{'ID'};
	delete $env{'ID_entity'} if exists $env{'ID_entity'};
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	# detect db_name - where a160 is stored
	if ($env{'l_prefix'} && !$env{'db_name'})
	{$env{'db_name'}=App::020::SQL::functions::_detect_db_name($env{'l_prefix'})}
	
	if ($env{'r_prefix'} && !$env{'r_db_name'})
	{$env{'r_db_name'}=App::020::SQL::functions::_detect_db_name($env{'r_prefix'})}

	$env{'db_name'}=$App::160::db_name unless $env{'db_name'};
	$env{'status'}='Y' unless $env{'status'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'") if $debug;
	}
	
	my $cache_change_key='a160_relation_change::'.$env{'db_h'}.'::'.$env{'db_name'}.'::'.$env{'l_prefix'}.'::'.$env{'l_table'}.'::'.$env{'l_ID_entity'};
	my $cache_change_rkey='a160_relation_change::'.$env{'db_h'}.'::'.$env{'db_name'}.'::'.$env{'r_prefix'}.'::'.$env{'r_table'}.'::'.$env{'r_ID_entity'};
	
	# check if this relation already exists
	my $relation=(get_relations(
		%env,
		'status' => 'YNT',
		'limit' => '0,1'
	))[0];
	if ($relation)
	{
		main::_log("this relation exists with ID='$relation->{'ID'}' status='$relation->{'status'}'");
		# when it exists, check if is enabled ( when not, enable it )
		if ($relation->{'status'} eq "Y")
		{
			main::_log("also returning as okay") if $debug;
			$t->close();
			return $relation->{'ID_entity'}, $relation->{'ID'};
		}
		
		# re-enable this relation
		main::_log("re-enabling");
		App::020::SQL::functions::update(
			'ID' => $relation->{'ID'},
			'db_h' => $env{'db_h'},
			'db_name' => $env{'db_name'},
			'tb_name' => 'a160_relation',
			'data' =>
			{
				'note' => $env{'note'},
				'rel_type' => $env{'rel_type'},
				'rel_name' => $env{'rel_name'},
				'priority' => $env{'priority'},
				'quantifier' => $env{'quantifier'},
			},
			'columns' =>
			{
				'status' => "'$env{'status'}'",
			}
		);
		
		if ($TOM::CACHE_memcached && $TOM::CACHE && $CACHE)
		{
			# save info about changed set of relations
			my $tt=Time::HiRes::time();
			main::_log("[cache_change_key] set '$cache_change_key'=$tt") if $debug;
			$Ext::CacheMemcache::cache->set('namespace'=>"db_cache", 'key'=>$cache_change_key, 'value'=>$tt, 'expiration'=>$cache_expire.'S');
			# the source application has been changed
			App::020::SQL::functions::_save_changetime(
				{'db_h'=>$env{'db_h'},'db_name'=>$env{'db_name'},'tb_name'=>$env{'l_prefix'}.'_'.$env{'l_table'},'ID_entity'=>$env{'l_ID_entity'}}
			);
			# destination entity
			$Ext::CacheMemcache::cache->set('namespace'=>"db_cache", 'key'=>$cache_change_rkey, 'value'=>$tt, 'expiration'=>$cache_expire.'S');
		}
		
		$t->close();
		return $relation->{'ID_entity'}, $relation->{'ID'};
	}
	
	# prepare quantifier

	my $quantifier = 1;
		$quantifier = $env{'quantifier'} if ($env{'quantizer'} =~ /^\d+$/);
	my $priority = 'NULL';
		$priority = $env{'priority'} if ($env{'priority'} =~ /^\d+$/);
	
	my %data_col;
		$data_col{'note'} = '';
		$data_col{'note'} = $env{'note'} if defined $env{'note'};
		$data_col{'rel_name'} = $env{'rel_name'} if defined $env{'rel_name'};
	
	# find if this relation has ID_entity
	my $relation=(get_relations(
		%env,
		'rel_type' => -1,
		'r_db_name' => undef,
		'r_prefix' => undef,
		'r_table' => undef,
		'r_ID_entity' => undef,
		'status' => 'YNT',
		'limit' => '0,1'
	))[0];
	if ($relation)
	{
		main::_log("this relation has ID_entity='$relation->{'ID_entity'}', also creating clone");
		
		my %columns=(
			'rel_type' => "'".TOM::Security::form::sql_escape($env{'rel_type'})."'",
			'r_db_name' => "'".TOM::Security::form::sql_escape($env{'r_db_name'})."'",
			'r_prefix' => "'".TOM::Security::form::sql_escape($env{'r_prefix'})."'",
			'r_table' => "'".TOM::Security::form::sql_escape($env{'r_table'})."'",
			'r_ID_entity' => "'".TOM::Security::form::sql_escape($env{'r_ID_entity'})."'",
			'rel_type' => "'".TOM::Security::form::sql_escape($env{'rel_type'})."'",
			'rel_name' => "NULL",
			'quantifier' => $quantifier,
			'priority' => $priority,
			'status' => "'".TOM::Security::form::sql_escape($env{'status'})."'",
		);
		delete $columns{'rel_name'} if $data_col{'rel_name'};
		delete $columns{'note'} if $data_col{'note'};
		
		my $ID=App::020::SQL::functions::clone(
			'ID' => $relation->{'ID'},
			'db_h' => $env{'db_h'},
			'db_name' => $env{'db_name'},
			'tb_name' => 'a160_relation',
			'data' => {%data_col},
			'columns' => {%columns},
		);
		
		main::_log("clone with ID='$ID'");
		
		if ($TOM::CACHE_memcached && $TOM::CACHE && $CACHE)
		{
			# save info about changed set of relations
			my $tt=Time::HiRes::time();
			main::_log("[cache_change_key] set '$cache_change_key'=$tt") if $debug;
			$Ext::CacheMemcache::cache->set('namespace'=>"db_cache", 'key'=>$cache_change_key, 'value'=>$tt, 'expiration'=>$cache_expire.'S');
			# the source application has been changed
			App::020::SQL::functions::_save_changetime(
				{'db_h'=>$env{'db_h'},'db_name'=>$env{'db_name'},'tb_name'=>$env{'l_prefix'}.'_'.$env{'l_table'},'ID_entity'=>$env{'l_ID_entity'}}
			);
			# destination entity
			$Ext::CacheMemcache::cache->set('namespace'=>"db_cache", 'key'=>$cache_change_rkey, 'value'=>$tt, 'expiration'=>$cache_expire.'S');
		}
		
		$t->close();
		return $relation->{'ID_entity'}, $ID;
	}
	
	main::_log("creating new relation");
	
	my $ID=App::020::SQL::functions::new(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => 'a160_relation',
		'data' => {%data_col},
		'columns' =>
		{
			'l_prefix' => "'".TOM::Security::form::sql_escape($env{'l_prefix'})."'",
			'l_table' => "'".TOM::Security::form::sql_escape($env{'l_table'})."'",
			'l_ID_entity' => "'".TOM::Security::form::sql_escape($env{'l_ID_entity'})."'",
			'rel_type' => "'".TOM::Security::form::sql_escape($env{'rel_type'})."'",
			'quantifier' => $quantifier,
			'priority' => $priority,
			'r_db_name' => "'".TOM::Security::form::sql_escape($env{'r_db_name'})."'",
			'r_prefix' => "'".TOM::Security::form::sql_escape($env{'r_prefix'})."'",
			'r_table' => "'".TOM::Security::form::sql_escape($env{'r_table'})."'",
			'r_ID_entity' => "'".TOM::Security::form::sql_escape($env{'r_ID_entity'})."'",
			'status' => "'".TOM::Security::form::sql_escape($env{'status'})."'",
		},
		
	);
	
	if ($TOM::CACHE_memcached && $TOM::CACHE && $CACHE)
	{
		# save info about changed set of relations
		my $tt=Time::HiRes::time();
		main::_log("[cache_change_key] set '$cache_change_key'=$tt") if $debug;
		$Ext::CacheMemcache::cache->set('namespace'=>"db_cache", 'key'=>$cache_change_key, 'value'=>$tt, 'expiration'=>$cache_expire.'S');
		# the source application has been changed
		App::020::SQL::functions::_save_changetime(
			{'db_h'=>$env{'db_h'},'db_name'=>$env{'db_name'},'tb_name'=>$env{'l_prefix'}.'_'.$env{'l_table'},'ID_entity'=>$env{'l_ID_entity'}}
		);
		# destination entity
		$Ext::CacheMemcache::cache->set('namespace'=>"db_cache", 'key'=>$cache_change_rkey, 'value'=>$tt, 'expiration'=>$cache_expire.'S');
	}
	
	$t->close();
	return $ID, $ID;
}



=head2 remove_relation()

Removes relation and return true/false

 my $output=remove_relation(
   'ID' => $ID
 );

=cut

sub remove_relation
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::remove_relation()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	# detect db_name - where a160 is stored
	if ($env{'l_prefix'} && !$env{'db_name'})
	{$env{'db_name'}=App::020::SQL::functions::_detect_db_name($env{'l_prefix'})}
	
	$env{'db_name'}=$App::160::db_name unless $env{'db_name'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	# check if this relation already exists
	my $relation=(get_relations(
		'ID'=>$env{'ID'},
		'l_prefix' => $env{'l_prefix'},
		'db_name' => $env{'db_name'},
		'status' => 'YNT',
		'limit' => '1'
	))[0];
	if ($relation)
	{
		main::_log("this relation exists with status='$relation->{'status'}'");
		# when it exists, check if is enabled or disabled
		if ($relation->{'status'}=~/[YN]/)
		{
			main::_log("also giving it into trash");
			App::020::SQL::functions::to_trash(
				'ID' => $relation->{'ID'},
				'db_h' => $env{'db_h'},
				'db_name' => $env{'db_name'},
				'tb_name' => 'a160_relation',
				'-journalize' => 1,
			);
			my $cache_change_key='a160_relation_change::'.$env{'db_h'}.'::'.$env{'db_name'}.'::'.$relation->{'l_prefix'}.'::'.$relation->{'l_table'}.'::'.$relation->{'l_ID_entity'};
			my $cache_change_rkey='a160_relation_change::'.$env{'db_h'}.'::'.$env{'db_name'}.'::'.$relation->{'r_prefix'}.'::'.$relation->{'r_table'}.'::'.$relation->{'r_ID_entity'};
			if ($TOM::CACHE_memcached && $TOM::CACHE && $CACHE)
			{
				# save info about changed set of relations
				my $tt=Time::HiRes::time();
				main::_log("[cache_change_key] set '$cache_change_key'=$tt") if $debug;
				$Ext::CacheMemcache::cache->set('namespace'=>"db_cache", 'key'=>$cache_change_key, 'value'=>$tt, 'expiration'=>$cache_expire.'S');
				# the source application has been changed
				App::020::SQL::functions::_save_changetime(
					{'db_h'=>$env{'db_h'},'db_name'=>$env{'db_name'},'tb_name'=>$relation->{'l_prefix'}.'_'.$relation->{'l_table'},'ID_entity'=>$relation->{'l_ID_entity'}}
				);
				# destination entity
				$Ext::CacheMemcache::cache->set('namespace'=>"db_cache", 'key'=>$cache_change_rkey, 'value'=>$tt, 'expiration'=>$cache_expire.'S');
			}
			$t->close();
			return 1;
		}
		else
		{
			# this relation is already in trash
		}
		
	}
	
	# this relation not exists
	
	$t->close();
	return 1;
}



=head2 relation_change_status()

Changes relation status

 my $output=relation_change_status(
   'ID' => $ID,
   'status' => 'Y'
 );

=cut

sub relation_change_status
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::relation_change_status()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	# detect db_name - where a160 is stored
	if ($env{'l_prefix'} && !$env{'db_name'})
	{$env{'db_name'}=App::020::SQL::functions::_detect_db_name($env{'l_prefix'})}
	
	$env{'db_name'}=$App::160::db_name unless $env{'db_name'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	# check if this relation already exists
	my $relation=(get_relations(
		'ID' => $env{'ID'},
		'l_prefix' => $env{'l_prefix'},
		'db_name' => $env{'db_name'},
		'status' => 'YN',
		'limit' => '1'
	))[0];
	if ($relation->{'ID'})
	{
		main::_log("this relation exists with status='$relation->{'status'}'");
		# when it exists, check if is enabled or disabled
#		if ($relation->{'status'} ne $env{'status'})
#		{
			main::_log("also updating status");
			App::020::SQL::functions::update(
				'ID' => $relation->{'ID'},
				'db_h' => $env{'db_h'},
				'db_name' => $env{'db_name'},
				'tb_name' => 'a160_relation',
				'columns' => {
					'status' => "'".$env{'status'}."'"
				},
				'-journalize' => 1,
			);
			my $cache_change_key='a160_relation_change::'.$env{'db_h'}.'::'.$env{'db_name'}.'::'.$relation->{'l_prefix'}.'::'.$relation->{'l_table'}.'::'.$relation->{'l_ID_entity'};
			my $cache_change_rkey='a160_relation_change::'.$env{'db_h'}.'::'.$env{'db_name'}.'::'.$relation->{'r_prefix'}.'::'.$relation->{'r_table'}.'::'.$relation->{'r_ID_entity'};
			if ($TOM::CACHE_memcached && $TOM::CACHE && $CACHE)
			{
				# save info about changed set of relations
				my $tt=Time::HiRes::time();
				main::_log("[cache_change_key] set '$cache_change_key'=$tt") if $debug;
				$Ext::CacheMemcache::cache->set('namespace'=>"db_cache", 'key'=>$cache_change_key, 'value'=>$tt, 'expiration'=>$cache_expire.'S');
				# the source application has been changed
				App::020::SQL::functions::_save_changetime(
					{'db_h'=>$env{'db_h'},'db_name'=>$env{'db_name'},'tb_name'=>$relation->{'l_prefix'}.'_'.$relation->{'l_table'},'ID_entity'=>$relation->{'l_ID_entity'}}
				);
				# destination entity
				$Ext::CacheMemcache::cache->set('namespace'=>"db_cache", 'key'=>$cache_change_rkey, 'value'=>$tt, 'expiration'=>$cache_expire.'S');
			}
			$t->close();
			return 1;
#		}
#		else
#		{
			# this relation has already this status
#		}
		
	}
	
	# this relation not exists
	
	$t->close();
	return 1;
}


sub relation_change_rel_type
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::relation_change_rel_type()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	# detect db_name - where a160 is stored
	if ($env{'l_prefix'} && !$env{'db_name'})
	{$env{'db_name'}=App::020::SQL::functions::_detect_db_name($env{'l_prefix'})}
	
	$env{'db_name'}=$App::160::db_name unless $env{'db_name'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'") if $debug;
	}
	
	# check if this relation already exists
	my $relation=(get_relations(
		'ID' => $env{'ID'},
		'l_prefix' => $env{'l_prefix'},
		'db_name' => $env{'db_name'},
		'status' => 'YN',
		'limit' => '1'
	))[0];
	if ($relation->{'ID'})
	{
		main::_log("this relation exists with rel_type='$relation->{'rel_type'}'");
		# when it exists, check if is not already set to same value

		my %columns;

		if (exists $env{'rel_type'})
		{
			main::_log('Trying to update rel_type: '.$env{'rel_type'});
			$columns{'rel_type'} = "'".TOM::Security::form::sql_escape($env{'rel_type'})."'" if ($relation->{'rel_type'} ne $env{'rel_type'});
		}

		if (exists $env{'quantifier'})
		{
			if ($relation->{'quantifier'} ne $env{'quantifier'})
			{
				if ($env{'quantifier'} =~ /^\d+$/)
				{
					$columns{'quantifier'} = $env{'quantifier'};
				}
			}
		} 
		
		if (exists $columns{'quantifier'} || exists $columns{'rel_type'})
		{
			main::_log("also updating rel_type");

			App::020::SQL::functions::update(
				'ID' => $relation->{'ID'},
				'db_h' => $env{'db_h'},
				'db_name' => $env{'db_name'},
				'tb_name' => 'a160_relation',
				'columns' => {
					%columns
				},
				'-journalize' => 1,
			);
			
			my $cache_change_key='a160_relation_change::'.$env{'db_h'}.'::'.$env{'db_name'}.'::'.$relation->{'l_prefix'}.'::'.$relation->{'l_table'}.'::'.$relation->{'l_ID_entity'};
			my $cache_change_rkey='a160_relation_change::'.$env{'db_h'}.'::'.$env{'db_name'}.'::'.$relation->{'r_prefix'}.'::'.$relation->{'r_table'}.'::'.$relation->{'r_ID_entity'};
			if ($TOM::CACHE_memcached && $TOM::CACHE && $CACHE)
			{
				# save info about changed set of relations
				my $tt=Time::HiRes::time();
				main::_log("[cache_change_key] set '$cache_change_key'=$tt") if $debug;
				$Ext::CacheMemcache::cache->set('namespace'=>"db_cache", 'key'=>$cache_change_key, 'value'=>$tt, 'expiration'=>$cache_expire.'S');
				# the source application has been changed
				App::020::SQL::functions::_save_changetime(
					{'db_h'=>$env{'db_h'},'db_name'=>$env{'db_name'},'tb_name'=>$relation->{'l_prefix'}.'_'.$relation->{'l_table'},'ID_entity'=>$relation->{'l_ID_entity'}}
				);
				# destination entity
				$Ext::CacheMemcache::cache->set('namespace'=>"db_cache", 'key'=>$cache_change_rkey, 'value'=>$tt, 'expiration'=>$cache_expire.'S');
			}
			$t->close();
			return 1;
		}
		else
		{
			main::_log('No columns, not updating');
			# this relation has already this rel_type
		}
	}
	# this relation does not exist
	
	$t->close();
	return 1;
}


sub relation_change_priority
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::relation_change_priority()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	# detect db_name - where a160 is stored
	if ($env{'l_prefix'} && !$env{'db_name'})
	{$env{'db_name'}=App::020::SQL::functions::_detect_db_name($env{'l_prefix'})}
	
	$env{'db_name'}=$App::160::db_name unless $env{'db_name'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'") if $debug;
	}
	
	# check if this relation already exists
	my $relation=(get_relations(
		'ID' => $env{'ID'},
		'l_prefix' => $env{'l_prefix'},
		'db_name' => $env{'db_name'},
		'status' => 'YN',
		'limit' => '1'
	))[0];
	if ($relation->{'ID'})
	{
		main::_log("this relation exists with priority='$relation->{'priority'}'");
		# when it exists, check if is not already set to same value
		
		my %columns;
		
		if (exists $env{'priority'})
		{
			main::_log('trying to update priority: '.$env{'priority'});
			$columns{'priority'} = $env{'priority'} if ($relation->{'priority'} ne $env{'priority'});
		}
		
		if (exists $columns{'priority'})
		{
			main::_log("also updating priority");
			
			App::020::SQL::functions::update(
				'ID' => $relation->{'ID'},
				'db_h' => $env{'db_h'},
				'db_name' => $env{'db_name'},
				'tb_name' => 'a160_relation',
				'columns' => {
					%columns
				},
				'-journalize' => 1,
			);
			
			my $cache_change_key='a160_relation_change::'.$env{'db_h'}.'::'.$env{'db_name'}.'::'.$relation->{'l_prefix'}.'::'.$relation->{'l_table'}.'::'.$relation->{'l_ID_entity'};
			if ($TOM::CACHE_memcached && $TOM::CACHE && $CACHE)
			{
				# save info about changed set of relations
				my $tt=Time::HiRes::time();
				main::_log("[cache_change_key] set '$cache_change_key'=$tt") if $debug;
				$Ext::CacheMemcache::cache->set('namespace'=>"db_cache", 'key'=>$cache_change_key, 'value'=>$tt, 'expiration'=>$cache_expire.'S');
				# the source application has been changed
				App::020::SQL::functions::_save_changetime(
					{'db_h'=>$env{'db_h'},'db_name'=>$env{'db_name'},'tb_name'=>$relation->{'l_prefix'}.'_'.$relation->{'l_table'},'ID_entity'=>$relation->{'l_ID_entity'}}
				);
			}
			$t->close();
			return 1;
		}
		else
		{
			main::_log('no columns, not updating');
			# this relation has already this rel_type
		}
	}
	# this relation does not exist
	
	$t->close();
	return 1;
}


sub relation_change_name
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::relation_change_name()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	# detect db_name - where a160 is stored
	if ($env{'l_prefix'} && !$env{'db_name'})
	{$env{'db_name'}=App::020::SQL::functions::_detect_db_name($env{'l_prefix'})}
	
	$env{'db_name'}=$App::160::db_name unless $env{'db_name'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'") if $debug;
	}
	
	# check if this relation already exists
	my $relation=(get_relations(
		'ID' => $env{'ID'},
		'l_prefix' => $env{'l_prefix'},
		'db_name' => $env{'db_name'},
		'status' => 'YN',
		'limit' => '1'
	))[0];
	if ($relation->{'ID'})
	{
		main::_log("this relation exists with rel_name='$relation->{'rel_name'}'");
		# when it exists, check if is not already set to same value
		
		my %data;
		my %columns;
		
		if (exists $env{'rel_name'})
		{
			main::_log('trying to update rel_name: '.$env{'rel_name'});
			$data{'rel_name'} = $env{'rel_name'} if ($relation->{'rel_name'} ne $env{'rel_name'});
			$columns{'rel_name'} = 'NULL' unless $data{'rel_name'};
		}
		
		if (exists $data{'rel_name'} || exists $columns{'rel_name'})
		{
			main::_log("also updating rel_name");
			
			App::020::SQL::functions::update(
				'ID' => $relation->{'ID'},
				'db_h' => $env{'db_h'},
				'db_name' => $env{'db_name'},
				'tb_name' => 'a160_relation',
				'columns' => {
					%columns
				},
				'data' => {
					%data
				},
				'-journalize' => 1,
			);
			
			my $cache_change_key='a160_relation_change::'.$env{'db_h'}.'::'.$env{'db_name'}.'::'.$relation->{'l_prefix'}.'::'.$relation->{'l_table'}.'::'.$relation->{'l_ID_entity'};
			if ($TOM::CACHE_memcached && $TOM::CACHE && $CACHE)
			{
				# save info about changed set of relations
				my $tt=Time::HiRes::time();
				main::_log("[cache_change_key] set '$cache_change_key'=$tt") if $debug;
				$Ext::CacheMemcache::cache->set('namespace'=>"db_cache", 'key'=>$cache_change_key, 'value'=>$tt, 'expiration'=>$cache_expire.'S');
				# the source application has been changed
				App::020::SQL::functions::_save_changetime(
					{'db_h'=>$env{'db_h'},'db_name'=>$env{'db_name'},'tb_name'=>$relation->{'l_prefix'}.'_'.$relation->{'l_table'},'ID_entity'=>$relation->{'l_ID_entity'}}
				);
			}
			$t->close();
			return 1;
		}
		else
		{
			main::_log('no datas, not updating');
			# this relation has already this rel_type
		}
	}
	# this relation does not exist
	
	$t->close();
	return 1;
}



sub relation_change_note
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::relation_change_note()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	# detect db_name - where a160 is stored
	if ($env{'l_prefix'} && !$env{'db_name'})
	{$env{'db_name'}=App::020::SQL::functions::_detect_db_name($env{'l_prefix'})}
	
	$env{'db_name'}=$App::160::db_name unless $env{'db_name'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'") if $debug;
	}
	
	# check if this relation already exists
	my $relation=(get_relations(
		'ID' => $env{'ID'},
		'l_prefix' => $env{'l_prefix'},
		'db_name' => $env{'db_name'},
		'status' => 'YN',
		'limit' => '1'
	))[0];
	if ($relation->{'ID'})
	{
		main::_log("this relation exists with note='$relation->{'note'}'");
		# when it exists, check if is not already set to same value
		
		my %data;
		my %columns;
		
		if (exists $env{'note'})
		{
			main::_log('trying to update note: '.$env{'note'});
			$data{'note'} = $env{'note'} if ($relation->{'note'} ne $env{'note'});
			$columns{'note'} = 'NULL' unless $data{'note'};
		}
		
		if (exists $data{'note'} || exists $columns{'note'})
		{
			main::_log("also updating note");
			
			App::020::SQL::functions::update(
				'ID' => $relation->{'ID'},
				'db_h' => $env{'db_h'},
				'db_name' => $env{'db_name'},
				'tb_name' => 'a160_relation',
				'columns' => {
					%columns
				},
				'data' => {
					%data
				},
				'-journalize' => 1,
			);
			
			my $cache_change_key='a160_relation_change::'.$env{'db_h'}.'::'.$env{'db_name'}.'::'.$relation->{'l_prefix'}.'::'.$relation->{'l_table'}.'::'.$relation->{'l_ID_entity'};
			if ($TOM::CACHE_memcached && $TOM::CACHE && $CACHE)
			{
				# save info about changed set of relations
				my $tt=Time::HiRes::time();
				main::_log("[cache_change_key] set '$cache_change_key'=$tt") if $debug;
				$Ext::CacheMemcache::cache->set('namespace'=>"db_cache", 'key'=>$cache_change_key, 'value'=>$tt, 'expiration'=>$cache_expire.'S');
				# the source application has been changed
				App::020::SQL::functions::_save_changetime(
					{'db_h'=>$env{'db_h'},'db_name'=>$env{'db_name'},'tb_name'=>$relation->{'l_prefix'}.'_'.$relation->{'l_table'},'ID_entity'=>$relation->{'l_ID_entity'}}
				);
			}
			$t->close();
			return 1;
		}
		else
		{
			main::_log('no datas, not updating');
			# this relation has already this rel_type
		}
	}
	# this relation does not exist
	
	$t->close();
	return 1;
}


=head2 get_relations()

Returns list of references to relations

 my @list=get_relations(
   #'ID' => 1,
   #'ID_entity' => 1,
   #'db_h' => 'main',
   #'db_name' => $App::160::db_name,
   'l_prefix' => 'a400',
   'l_table' => '',
   'l_ID_entity' => '2'
   #'r_db_name' => 'example_tld',
   #'r_prefix' => 'a210',
   #'r_table' => 'page',
   #'r_ID_entity' => '2'
 );
 foreach $reference (@list)
 {
  main::_log("reference with ID='$reference->{'ID'}'");
 }

=cut

sub get_relations
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::get_relation()") if $debug;
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	# detect db_name - where a160 is stored
	if ($env{'l_prefix'} && !$env{'db_name'})
	{$env{'db_name'}=App::020::SQL::functions::_detect_db_name($env{'l_prefix'})}
	
	$env{'db_name'}=$App::160::db_name unless $env{'db_name'};
	$env{'limit'}="100" unless $env{'limit'};
	return undef unless $env{'limit'}=~/^[0-9,]+$/;
	
	# list of input
	foreach (sort keys %env) {main::_log("input '$_'='$env{$_}'") if defined $env{$_} && $debug};
	
	# Memcached key
	my $use_cache=1;
	my $cache_change_key='a160_relation_change::'.$env{'db_h'}.'::'.$env{'db_name'}.'::'.$env{'l_prefix'}.'::'.$env{'l_table'}.'::'.$env{'l_ID_entity'};
	if ($env{'r_ID_entity'})
	{
		$cache_change_key='a160_relation_change::'.$env{'db_h'}.'::'.$env{'db_name'}.'::'.$env{'r_prefix'}.'::'.$env{'r_table'}.'::'.$env{'r_ID_entity'};
	}
	if (!$env{'l_prefix'} || !$env{'l_table'})
	{
		# don't use cache, when cached info is not related to atomized cache (ID_entity)
		$use_cache=0;
	}
	my $cache_key='a160_relation::'.$env{'db_h'}.'::'.$env{'db_name'}.'::'.$env{'status'}.'::'.$env{'rel_type'}.'::'.
		$env{'ID'}.'/'.
		$env{'ID_entity'}.'/'.
		$env{'l_prefix'}.'/'.
		$env{'l_table'}.'/'.
		$env{'l_ID_entity'}.'/'.
		$env{'r_db_name'}.'/'.
		$env{'r_prefix'}.'/'.
		$env{'r_table'}.'/'.
		$env{'r_ID_entity'}.'::'.
		$env{'limit'};
	my $cache_change;
	
	my $where;
	
	# status
	if ($env{'status'}){$where.= "status IN ('".(join "','" , split('',$env{'status'}))."') ";}
	else {$where.="status='Y' ";}
	
	# fill 'where' with valid input variables ( prefix l_, r_, ID )
	foreach (keys %env)
	{
		next unless defined $env{$_};
		if ($_=~/^(l|r)_/ || $_=~/^ID/)
		{
			if ($_ eq "r_db_name"){$where.="AND r_db_name IN ('".TOM::Security::form::sql_escape($env{$_})."','') ";}
			else {$where.="AND $_='".TOM::Security::form::sql_escape($env{$_})."' ";}
		}
	}
	if ($env{'rel_type'} == -1){}
	elsif (exists $env{'rel_type'}){$where.="AND rel_type='".TOM::Security::form::sql_escape($env{'rel_type'})."' ";}
	
	my @relations;
	
	if ($TOM::CACHE_memcached && $TOM::CACHE && $CACHE && $use_cache && $main::cache)
	{
		$cache_change=$Ext::CacheMemcache::cache->get('namespace' => "db_cache",'key' => $cache_change_key);
		my $cache=$Ext::CacheMemcache::cache->get('namespace' => "db_cache",'key' => $cache_key);
		
#		main::_log("cache-time='".$cache->{'time'}."' cache_change='".$cache_change."' ($cache_change_key)") if $debug;
		main::_log("[cache_change_key] get '$cache_change_key'=$cache_change") if $debug;
		
		if ($cache->{'time'} && (($cache->{'time'} > $cache_change) && $cache_change))
		{
			main::_log("found in cache") if $debug;
			$t->close() if $debug;
			return @{$cache->{'data'}};
		}
	}
	
	my $sql=qq{
		SELECT
			*,
			LEFT(datetime_create,16) AS datetime_create_short
		FROM
			`$env{'db_name'}`.`a160_relation`
		WHERE
			$where
		ORDER BY
			priority DESC, rel_type, r_db_name, r_prefix, r_table, r_ID_entity
		LIMIT
			$env{'limit'};
	};
	my $i=0;
	my %sth0=TOM::Database::SQL::execute($sql,'log'=>$debug,'quiet'=>$quiet,'slave'=>1);
	while (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		main::_log("relation[$i] rel_type='$db0_line{'rel_type'}' r_db_name='$db0_line{'r_db_name'}' r_prefix='$db0_line{'r_prefix'}' r_table='$db0_line{'r_table'}' r_ID_entity='$db0_line{'r_ID_entity'}'") if $debug;
		push @relations, {%db0_line};
		$i++;
	}
	
	if ($TOM::CACHE_memcached && $TOM::CACHE && $CACHE && $use_cache)
	{
		if (!$cache_change)
		{
			my $tt=Time::HiRes::time();
			main::_log("[cache_change_key] set '$cache_change_key'=$tt") if $debug;
			$Ext::CacheMemcache::cache->set('namespace'=>"db_cache", 'key'=>$cache_change_key, 'value'=>$tt, 'expiration'=>$cache_expire.'S');
		}
		$Ext::CacheMemcache::cache->set
		(
			'namespace' => "db_cache",
			'key' => $cache_key,
			'value' =>
			{
				'time' => Time::HiRes::time(),
				'data' => [@relations]
			},
			'expiration'=>$cache_expire.'S'
		);
	}
	
	$t->close() if $debug;
	return @relations;
}



=head2 get_relation_iteminfo

Return information hash of relation right table, also about concrete entity

 my %info=get_relation_iteminfo(
    lng => 'en' # get this language if support
   'r_db_name' => 'example_tld',
   'r_prefix' => 'a210',
   'r_table' => 'page',
   'r_ID_entity' => '2',
 );
 
 main::_log("name of relation = '$info{name}'");

=cut

sub get_relation_iteminfo
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::get_relation_iteminfo()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	# detect db_name - where a160 is stored
	if ($env{'l_prefix'} && !$env{'db_name'})
	{$env{'db_name'}=App::020::SQL::functions::_detect_db_name($env{'l_prefix'})}
	
#	$env{'r_db_name'}=$App::160::db_name unless $env{'r_db_name'};
	
	# detect r_db_name - where dest App is stored
	if ($env{'r_prefix'} && !$env{'r_db_name'})
	{$env{'r_db_name'}=App::020::SQL::functions::_detect_db_name($env{'r_prefix'})}
	
	# list of input
	foreach (sort keys %env) {main::_log("input '$_'='$env{$_}'") if defined $env{$_}};
	
	if (!$env{'r_prefix'} || !$env{'r_ID_entity'})
	{
		main::_log("missing r_prefix or r_ID_entity");
		$t->close();
		return undef;
	}
	
	my %info;
	
	# at first check if this addon is available
	my $r_prefix=$env{'r_prefix'};
		$r_prefix=~s|^a|App::|;
		$r_prefix=~s|^e|Ext::|;
	if (not defined $r_prefix->VERSION)
	{
		eval "use $r_prefix".'::a160;';
		main::_log("err:$@",1) if $@;
	}
	
	# check if a160 enhancement of this application is available
	my $pckg=$r_prefix."::a160";
	if (defined $pckg->VERSION)
	{
		main::_log("trying get_relation_iteminfo() from package '$pckg'");
		%info=$pckg->get_relation_iteminfo(
			'r_db_name' => $env{'r_db_name'},
			'r_table' => $env{'r_table'},
			'r_ID_entity' => $env{'r_ID_entity'},
			'lng' => $env{'lng'}
		);
		$info{'r_db_name'}=$env{'r_db_name'};
		$info{'r_prefix'}=$env{'r_prefix'};
		$info{'r_table'}=$env{'r_table'};
		$info{'r_ID_entity'}=$env{'r_ID_entity'};
		$info{'lng'}=$env{'lng'};
		main::_log("info name='$info{'name'}'");
		$t->close();
		return %info;
	}
	
	$t->close();
	return %info;
}

=head2 new_historization

=cut


sub new_historization
{
	my %env = @_;
	$env{'db_h'}='main' unless $env{'db_h'};

	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'") if $debug;
	}

	my %columns;

	$columns{'l_prefix'} = "'".$env{'l_prefix'}."'" if ($env{'l_prefix'});
	$columns{'l_table'} = "'".$env{'l_table'}."'" if ($env{'l_table'});
	$columns{'l_column'} = "'".$env{'l_column'}."'" if ($env{'l_column'});
	$columns{'l_ID_entity'} = "'".$env{'l_ID_entity'}."'" if ($env{'l_ID_entity'});
	$columns{'value'} = "'".$env{'value'}."'" if ($env{'value'});
	$columns{'datetime_valid'} = "'".$env{'datetime_valid'}."'" if ($env{'datetime_valid'});

	my $historization_ID;

	if ($env{'ID'})
	{
		App::020::SQL::functions::update(
			'ID' => $env{'ID'},
			'db_h' => $env{'db_h'},
			'db_name' => $env{'db_name'},
			'tb_name' => "a160_historization",
			'columns' => {%columns},
			'-journalize' => 1,
			'-posix' => 1
		);

		return $env{'ID'};

	} else
	{
		$historization_ID=App::020::SQL::functions::new(
			'db_h' => $env{'db_h'},
			'db_name' => $env{'db_name'},
				'tb_name' => "a160_historization",
				'columns' =>
				{
					%columns,
					'status' => "'Y'"
				},
				'-journalize' => 1,
				'-posix' => 1,
			);

		return $historization_ID;
	}
}

=head2 get_historization

=cut

sub get_historization
{
	my %env = @_;
	

	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'") if $debug;
	}

	return unless (	$env{'datetime_valid'} && 
			$env{'db_name'} && 
			$env{'l_prefix'} &&
			$env{'l_table'}  &&
			$env{'l_column'}  &&
			$env{'l_ID_entity'}
			);

	my $where;	

	$where = qq{
		datetime_valid > '$env{'datetime_valid'}' AND
		l_prefix = '$env{'l_prefix'}' AND
		l_table = '$env{'l_table'}' AND
		l_column = '$env{'l_column'}' AND
		l_ID_entity=  '$env{'l_ID_entity'}' AND
		status NOT IN ('T')
		};

	my $sql=qq{
		SELECT
			*
		FROM
			`$env{'db_name'}`.`a160_historization`
		WHERE
			$where
		ORDER BY
			datetime_valid ASC
		LIMIT
			1;
	};

	my %sth0=TOM::Database::SQL::execute($sql,'log'=>$debug,'quiet'=>$quiet,'slave'=>1);

	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		return { %db0_line };
	}
	
}

=head2 trash_historization

=cut

sub trash_historization
{
	my %env = @_;

	return 0 unless $env{'ID'};
	$env{'db_h'}='main' unless $env{'db_h'};

	App::020::SQL::functions::to_trash
	(
			'ID' => $env{'ID'},
			'db_h' => $env{'db_h'},
			'db_name' => $env{'db_name'},
			'tb_name' => 'a160_historization',
			'-journalize' => 1,
	);
}

=head1

Shifts relations priority to left or right


relation_shift (
	'direction' => 'left' | 'right',
	'ID' => ?,
	'regexp' => qr/^partner.*$/ # (optional)
);




=cut


sub relation_shift
{
	my %env = @_;

	return unless ($env{'direction'} && $env{'ID'});

	$env{'db_name'}=$App::160::db_name unless $env{'db_name'};
	$env{'db_h'}='main' unless $env{'db_h'};

	my $plus;

	if ($env{'direction'} eq 'up' || $env{'direction'} eq 'left')
	{
		$plus = -1;
	} 
	elsif($env{'direction'} eq 'down' || $env{'direction'} eq 'right')
	{
		$plus = 1;
	}


	# get relation details - l_ID_entity and rel_type

	my $sql = qq{

                SELECT
                        *
                FROM
                        `$App::160::db_name`.a160_relation
                WHERE
                        ID = ?
                LIMIT 1
        };
	my %sth0=TOM::Database::SQL::execute($sql,'log'=>1,'quiet'=>1, 'bind' => [ $env{'ID'} ]);
	if ($sth0{'sth'}){
	
		if ( my %db0_line=$sth0{'sth'}->fetchhash() )
		{
			# get all sister relations of the l_ID_entity of the type / like
			
			my $l_ID_entity = $db0_line{'l_ID_entity'};	
			my $l_prefix = $db0_line{'l_prefix'};	
			my $r_prefix = $db0_line{'r_prefix'};	
			my $r_table = $db0_line{'r_table'};	
			my $l_table = $db0_line{'l_table'};

			my $rel_type = $db0_line{'rel_type'};
			my $quantifier = $db0_line{'quantifier'};

			main::_log("Reordering relations for l_ID_entity=$l_ID_entity l_prefix=$l_prefix l_table=$l_table r_prefix=$r_prefix r_table=$r_table");
			
			if ($env{'regexp'})
			{
				main::_log("relation is of rel_type=$rel_type, but I will filter relations by specified regexp $env{'regexp'}");
			} else
			{
				main::_log("I will filter relations by fixed rel type=$rel_type");
			}

			my $sql2 = qq{

				SELECT
					ID, priority, rel_type
				FROM
					`$App::160::db_name`.a160_relation
				WHERE
					l_ID_entity = ? AND
					l_prefix = ? AND r_prefix = ? AND r_table = ? AND l_table = ?
				ORDER BY
					priority DESC, rel_type, r_db_name, r_prefix, r_table, r_ID_entity
			};
			my %sth1=TOM::Database::SQL::execute($sql2,'log'=>1,'quiet'=>1, 
				'bind' => [ $l_ID_entity, $l_prefix, $r_prefix, $r_table, $l_table ]);

			my @all_relations;
			my $counter = 0;
			my $position;

			if ($sth1{'sth'})
			{

				while ( my %db1_line=$sth1{'sth'}->fetchhash() )
				{
					# check if relation is valid. we got relations of all rel_type's. Now we manually filter it
					# either by the same rel_type or by regexp

					my $regexp = $env{'regexp'};
					my $rel_type_item = $db1_line{'rel_type'};
	
					# if regexp is in env, use regexp, otherwise compare to rel_type
					$position = $counter if ($db1_line{'ID'} == $db0_line{'ID'});

					if ($regexp)
					{
						$all_relations[$counter] = { %db1_line }  if ($rel_type_item =~ $regexp);
					} 
					elsif ($rel_type_item eq $rel_type)
					{
						$all_relations[$counter] = { %db1_line };
					}
					
					$counter++;
				}
			}

			# @all_relations now contains an ordered list of relations of the desired rel_type


		 	my $priority_max = @all_relations - 1;

			main::_log( "Max priority: $priority_max, I am at position: $position\n") if ($debug);

			# switch positions of the relation we want to move with its neighboring relation to the left or right

			if (my $switch_with = $all_relations[$position + $plus])
			{
				# main::_log( "Switching my primary ID=".$all_relations[$position]->{'ID'}." with ID=".$all_relations[$position + $plus]->{'ID'}."\n");
				
				$all_relations[$position + $plus] = $all_relations[$position];
				$all_relations[$position] = $switch_with;
				
			} 

			# Now update priorities for the whole set

			my $tr=new TOM::Database::SQL::transaction('db_h'=>"main");

			for (my $i = 0; $i <= $priority_max; $i++) 
			{
				my $sql_u = qq{

					UPDATE
						`$App::160::db_name`.a160_relation
					SET
						priority = ?
					WHERE
						ID = ?
					LIMIT 1
				};
				my %sth0=TOM::Database::SQL::execute($sql_u,'log'=>1,'quiet'=>1, 'bind' => [ int($priority_max - $i), $all_relations[$i]->{'ID'} ]);

				main::_log('Updating relation ID='.$all_relations[$i]->{'ID'}.' to priority='.int($priority_max - $i)) if ($debug);
			}
			$tr ->close();


			#update cache

			my $cache_change_key='a160_relation_change::'.$env{'db_h'}.'::'.$env{'db_name'}.'::'.$l_prefix.'::'.$l_table.'::'.$l_ID_entity;
			if ($TOM::CACHE_memcached && $TOM::CACHE && $CACHE)
			{
				# save info about changed set of relations
				my $tt=Time::HiRes::time();
				main::_log("[cache_change_key] set '$cache_change_key'=$tt") if $debug;
				$Ext::CacheMemcache::cache->set('namespace'=>"db_cache", 'key'=>$cache_change_key, 'value'=>$tt, 'expiration'=>$cache_expire.'S');
			}
		}
	}
}

=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut

1;
