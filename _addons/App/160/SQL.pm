#!/bin/perl
package App::160::SQL;

=head1 NAME

App::160::SQL

=cut

use open ':utf8', ':std';
use encoding 'utf8';
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

our $debug=0;
our $quiet;$quiet=1 unless $debug;
our $CACHE=1; # sorry not well tested caching
our $cache_expire=600; # 5 minutes - better is less time, when anything is cached wrong

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

sub _detect_db_name
{
	my $prefix=shift;
	
	main::_log("detect db_name with '$prefix' addon") if $debug;
	# at first check if this addon is available
	$prefix=~s|^a|App::|;
	$prefix=~s|^e|Ext::|;
	# load this addon if not available
	eval "use $prefix".'::_init;' unless $prefix->VERSION;
	# read db_name from this library
	my $db_name;eval '$db_name=$'.$prefix.'::db_name;';
	main::_log("detected db_name=$db_name") if $debug;
	# setup when found
	return $db_name if $db_name;
	return undef;
}

sub new_relation
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::new_relation()");
	
	delete $env{'ID'} if exists $env{'ID'};
	delete $env{'ID_entity'} if exists $env{'ID_entity'};
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	# detect db_name - where a160 is stored
	if ($env{'l_prefix'} && !$env{'db_name'})
	{$env{'db_name'}=_detect_db_name($env{'l_prefix'})}
	
	$env{'db_name'}=$App::160::db_name unless $env{'db_name'};
	$env{'status'}='Y' unless $env{'status'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	my $cache_change_key='a160_relation_change::'.$env{'db_h'}.'::'.$env{'db_name'}.'::'.$env{'l_prefix'}.'/'.$env{'l_table'};
	
	# check if this relation already exists
	my $relation=(get_relations(
		%env,
		'status' => 'YNT',
		'limit' => '0,1'
	))[0];
	if ($relation)
	{
		main::_log("this relation exists with status='$relation->{'status'}'");
		# when it exists, check if is enabled ( when not, enable it )
		if ($relation->{'status'} eq "Y")
		{
			main::_log("also returning as okay");
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
			'columns' =>
			{
				'status' => "'$env{'status'}'",
			},
		);
		
		if ($TOM::CACHE_memcached && $TOM::CACHE && $CACHE)
		{
			# save info about changed set of relations
			$Ext::CacheMemcache::cache->set('namespace'=>"db_cache", 'key'=>$cache_change_key, 'value'=>time(), 'expiration'=>$cache_expire.'S');
		}
		
		$t->close();
		return $relation->{'ID_entity'}, $relation->{'ID'};
	}
	
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
		
		my $ID=App::020::SQL::functions::clone(
			'ID' => $relation->{'ID'},
			'db_h' => $env{'db_h'},
			'db_name' => $env{'db_name'},
			'tb_name' => 'a160_relation',
			'columns' =>
			{
				'rel_type' => "'$env{'rel_type'}'",
				'r_db_name' => "'$env{'r_db_name'}'",
				'r_prefix' => "'$env{'r_prefix'}'",
				'r_table' => "'$env{'r_table'}'",
				'r_ID_entity' => "'$env{'r_ID_entity'}'",
				'rel_type' => "'$env{'rel_type'}'",
				'status' => "'$env{'status'}'",
			},
		);
		
		main::_log("clone with ID='$ID'");
		
		if ($TOM::CACHE_memcached && $TOM::CACHE && $CACHE)
		{
			# save info about changed set of relations
			$Ext::CacheMemcache::cache->set('namespace'=>"db_cache", 'key'=>$cache_change_key, 'value'=>time(), 'expiration'=>$cache_expire.'S');
		}
		
		$t->close();
		return $relation->{'ID_entity'}, $ID;
	}
	
	main::_log("creating new relation");
	
	my $ID=App::020::SQL::functions::new(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => 'a160_relation',
		'columns' =>
		{
			'l_prefix' => "'$env{'l_prefix'}'",
			'l_table' => "'$env{'l_table'}'",
			'l_ID_entity' => "'$env{'l_ID_entity'}'",
			'rel_type' => "'$env{'rel_type'}'",
			'r_db_name' => "'$env{'r_db_name'}'",
			'r_prefix' => "'$env{'r_prefix'}'",
			'r_table' => "'$env{'r_table'}'",
			'r_ID_entity' => "'$env{'r_ID_entity'}'",
			'status' => "'$env{'status'}'",
		},
	);
	
	if ($TOM::CACHE_memcached && $TOM::CACHE && $CACHE)
	{
		# save info about changed set of relations
		$Ext::CacheMemcache::cache->set('namespace'=>"db_cache", 'key'=>$cache_change_key, 'value'=>time(), 'expiration'=>$cache_expire.'S');
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
	{$env{'db_name'}=_detect_db_name($env{'l_prefix'})}
	
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
			my $cache_change_key='a160_relation_change::'.$env{'db_h'}.'::'.$env{'db_name'}.'::'
				.$relation->{'l_prefix'}.'/'.$relation->{'l_table'};
			if ($TOM::CACHE_memcached && $TOM::CACHE && $CACHE)
			{
				# save info about changed set of relations
				$Ext::CacheMemcache::cache->set('namespace'=>"db_cache", 'key'=>$cache_change_key, 'value'=>time(), 'expiration'=>$cache_expire.'S');
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
	{$env{'db_name'}=_detect_db_name($env{'l_prefix'})}
	
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
	if ($relation)
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
			my $cache_change_key='a160_relation_change::'.$env{'db_h'}.'::'.$env{'db_name'}.'::'
				.$relation->{'l_prefix'}.'/'.$relation->{'l_table'};
			if ($TOM::CACHE_memcached && $TOM::CACHE && $CACHE)
			{
				main::_log("save ($cache_change_key)=".(time())."") if $debug;
				# save info about changed set of relations
				$Ext::CacheMemcache::cache->set('namespace'=>"db_cache", 'key'=>$cache_change_key, 'value'=>time(), 'expiration'=>$cache_expire.'S');
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
	{$env{'db_name'}=_detect_db_name($env{'l_prefix'})}
	
	$env{'db_name'}=$App::160::db_name unless $env{'db_name'};
	$env{'limit'}="100" unless $env{'limit'};
	
	# list of input
	foreach (sort keys %env) {main::_log("input '$_'='$env{$_}'") if defined $env{$_} && $debug};
	
	# Memcached key
	my $cache_change_key='a160_relation_change::'.$env{'db_h'}.'::'.$env{'db_name'}.'::'.
		$env{'l_prefix'}.'/'.$env{'l_table'};
	my $cache_key='a160_relation::'.$env{'db_h'}.'::'.$env{'db_name'}.'::'.$env{'status'}.'::'.
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
			if ($_ eq "r_db_name"){$where.="AND r_db_name IN ('$env{$_}','') ";}
			else {$where.="AND $_='$env{$_}' ";}
		}
	}
	if ($env{'rel_type'} == -1){}
	elsif (exists $env{'rel_type'}){$where.="AND rel_type='$env{rel_type}' ";}
	
	my @relations;
	
	if ($TOM::CACHE_memcached && $TOM::CACHE && $CACHE)
	{
		my $cache_change=$Ext::CacheMemcache::cache->get('namespace' => "db_cache",'key' => $cache_change_key);
		my $cache=$Ext::CacheMemcache::cache->get('namespace' => "db_cache",'key' => $cache_key);
		
		main::_log("cache-time='".$cache->{'time'}."' cache_change='".$cache_change."' ($cache_change_key)") if $debug;
		
		if ($cache->{'time'} && ($cache->{'time'} > $cache_change))
		{
			main::_log("found in cache") if $debug;
			$t->close() if $debug;
			return @{$cache->{'data'}};
		}
	}
	
	my $sql=qq{
		SELECT
			*
		FROM
			`$env{'db_name'}`.`a160_relation`
		WHERE
			$where
		ORDER BY
			rel_type, r_db_name, r_prefix, r_table, r_ID_entity
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
	
	if ($TOM::CACHE_memcached && $TOM::CACHE && $CACHE)
	{
		$Ext::CacheMemcache::cache->set
		(
			'namespace' => "db_cache",
			'key' => $cache_key,
			'value' =>
			{
				'time' => time(),
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
	{$env{'db_name'}=_detect_db_name($env{'l_prefix'})}
	
#	$env{'r_db_name'}=$App::160::db_name unless $env{'r_db_name'};
	
	# detect r_db_name - where dest App is stored
	if ($env{'r_prefix'} && !$env{'r_db_name'})
	{$env{'r_db_name'}=_detect_db_name($env{'r_prefix'})}
	
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
	eval "use $r_prefix".'::a160;' unless $r_prefix->VERSION;
	
	# check if a160 enhancement of this application is available
	my $pckg=$r_prefix."::a160";
	if ($pckg->VERSION)
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


=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut

1;
