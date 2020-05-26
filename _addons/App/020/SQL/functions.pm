#!/bin/perl
package App::020::SQL::functions;

=head1 NAME

App::020::SQL::functions

=cut

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DESCRIPTIONS

This is low level SQL API to database tables defined by L<DATA standard|standard/"DATA">.

Allow you to automatically journalize entities, make clones, copies, etc...

=cut


=head1 DEPENDS

=over

=item *

L<TOM::Database::SQL|source-doc/".core/.libs/TOM/Database/SQL.pm">

=item *

L<Ext::CacheMemcache::_init|ext/"CacheMemcache/_init.pm">

=item *

L<App::020::SQL::functions::tree|app/"020/SQL/functions/tree.pm">

=item *

L<App::020::SQL|app/"020/SQL.pm">

=item *

L<App::020|app/"020/_init.pm">

=back

=cut

use TOM::Database::SQL;
use Ext::CacheMemcache::_init;
use Ext::Redis::_init;
use Ext::RabbitMQ::_init;
use App::020::SQL::functions::tree;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );

our $debug=0;
our $quiet;$quiet=1 unless $debug;

=head1 FUNCTIONS

=head2 new()

Function creates new row into main table and initializes it ( creates ID and ID_entity ).

This function makes automatically journalization copy of every created new row, when -journalize is enabled (table with suffix '_j' must exists).

 my $ID=App::020::SQL::functions::new
 (
  'db_h' => 'main', # name of database handler
  'db_name' => 'domain_tld', # name of database
  'tb_name' => 'a020_object', # name of main table
  'columns'=>
  {
   'column1' => "'value'",
   'column2' => "NOW()",
   'column3' => "NULL"
  },
  '-journalize' => 1,
  '-posix' => 1, # posix enhanced table (set posix_modified to $main::USRM{'ID_user'})
  '-replace' => 0 # use REPLACE INTO instead of INSERT INTO
 )

Please don't forget that this funcion is low-level, also is not escaping column values, that's your work!

Function returns ID, which is in new() same as ID_entity!

=cut

sub new
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::new()") if $debug;
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'") if $debug;
	}
	
	my $sel_columns;
	my $sel_values;
	my @columns;
	my @values;
	my @bind;
	$env{'columns'}{'posix_modified'}="'".$main::USRM{'ID_user'}."'" if $env{'-posix'};
	$env{'columns'}{'uuid'}="UUID()" if $env{'-uuid'};
	foreach (sort keys %{$env{'columns'}})
	{
		push @columns, $_;
		push @values, $env{'columns'}{$_};
	}
	foreach (sort keys %{$env{'data'}})
	{
		next if exists $env{'columns'}{$_}; # 'columns' has higher priority
		push @columns, $_;
		push @values, '?';
		push @bind, $env{'data'}{$_};
	}
	$sel_columns="`" . (join "`,`" , @columns) . "`" if @columns;
	$sel_values= join (",",@values) if @values;
	
	my $type="INSERT";
	$type="REPLACE" if $env{'-replace'};
	$type.=" DELAYED" if $env{'-delayed'};
	my $SQL=qq{
		$type INTO
			`$env{'db_name'}`.`$env{'tb_name'}`
		($sel_columns)
		VALUES
		($sel_values)
	};
	
	my %sth0=TOM::Database::SQL::execute($SQL,'db_h'=>$env{'db_h'},'log'=>$debug,'bind'=>[@bind],'quiet'=>$quiet);
	
	if ($sth0{'rows'})
	{
		# new entry inserted
		my $ID=$sth0{'sth'}->insertid();
		main::_log("new ID='$ID'") if $debug;
		main::_log("<={SQL:$env{'db_h'}} '$env{'db_name'}'.'$env{'tb_name'}' ID='$ID' $type") unless $debug;
		# activating by setting ID_entity
		new_initialize(
			'db_h' => $env{'db_h'},
			'db_name' => $env{'db_name'},
			'tb_name' => $env{'tb_name'},
			'ID' => $ID,
			'ID_entity' => ($env{'data'}{'ID_entity'} || $env{'columns'}{'ID_entity'}),
			'datetime_create' => $env{'columns'}{'datetime_create'},
			'-low_priority' => $env{'-delayed'}
		);
		
		if ($env{'-journalize'})
		{
			# zajournalujem sucasnu verziu
			journalize(
				'db_h' => $env{'db_h'},
				'db_name' => $env{'db_name'},
				'tb_name' => $env{'tb_name'},
				'ID' => $ID
			);
		}
		
		$env{'ID_entity'} = $env{'ID_entity'} || $env{'columns'}{'ID_entity'} || $env{'data'}{'ID_entity'} || $ID;
		_save_changetime(\%env);
		
		$t->close() if $debug;
		return $ID;
	}
	else
	{
		main::_log("can't $type into $env{'db_h'}:'$env{'db_name'}'.'$env{'tb_name'}'",1);
		main::_log("err: $sth0{'err'}",1);
		main::_log("SQL: $SQL",1);
	}
	
	$t->close() if $debug;
	return undef;
}



=head2 new_initialize()

This function is called from new() function. Finds all rows where ID_entity IS NULL and initializes this rows with setting ID_entity=ID, datetime_create=NOW()

Function can be called with one param - ID;

 App::020::SQL::functions::new_initialize(
  ID => $ID, # or undef
  'db_h' => 'main', # name of database handler
  'db_name' => 'domain_tld', # name of database
  'tb_name' => 'a020_object', # name of main table
 );

=cut

sub new_initialize
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::new_initialize($env{'ID'})") if $debug;
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'") if $debug;
	}
	
	my $low_priority;
#		$low_priority=" LOW_PRIORITY" if $env{'-low_priority'};
	$env{'datetime_create'}="NOW()" unless $env{'datetime_create'};
	
	# this is not very safe, but...
	# Error 1093 (ER_UPDATE_TABLE_USED)
	# SQLSTATE = HY000
	# Message = "You can't specify target table 'x'
	# for update in FROM clause"
	my $ID_entity='ID';
	my $locked;
	if (!$env{'ID_entity'} && $env{'ID'})
	{
		$locked=1;
#		main::_log("LOCK tables");
		TOM::Database::SQL::execute(qq{LOCK TABLES `$env{'db_name'}`.`$env{'tb_name'}` WRITE},'db_h'=>$env{'db_h'},'log'=>$debug,'quiet'=>$quiet);
		my $sql=qq{SELECT MAX(ID_entity)+1 AS ID_entity FROM `$env{'db_name'}`.`$env{'tb_name'}`};
		my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>$env{'db_h'},'log'=>$debug,'quiet'=>$quiet);
		my %db0_line=$sth0{'sth'}->fetchhash();
#		$ID_entity=$env{'ID'};
		if ($db0_line{'ID_entity'} < $env{'ID'}){$ID_entity=$env{'ID'};}
		elsif ($db0_line{'ID_entity'} > 1){$ID_entity=$db0_line{'ID_entity'};}
	}
	
	my $SQL="UPDATE$low_priority `$env{'db_name'}`.`$env{'tb_name'}` SET datetime_create=$env{'datetime_create'}, ";
	
	if ($env{'ID_entity'} && $env{'ID'})
	{
		$SQL="UPDATE$low_priority `$env{'db_name'}`.`$env{'tb_name'}` SET datetime_create=$env{'datetime_create'} WHERE ID=$env{'ID'}";
	}
	elsif ($env{'ID'})
	{
		$SQL.="ID_entity=$ID_entity WHERE ID=$env{'ID'} AND ID_entity IS NULL";
	}
	else
	{
		$SQL.="ID_entity=$ID_entity WHERE ID_entity IS NULL";
	}
	
	my %sth0=TOM::Database::SQL::execute($SQL,'db_h'=>$env{'db_h'},'log'=>$debug,'quiet'=>$quiet);
	TOM::Database::SQL::execute(qq{UNLOCK TABLES},'db_h'=>$env{'db_h'},'log'=>$debug,'quiet'=>$quiet)
		if $locked;
	
	$t->close() if $debug;
	return 1;
}


=head2 get_ID()

Function returns one row in %hash from main table ( also actual row, not journalized ).

 my %hash=App::020::SQL::functions::get_ID
 (
  ID => $ID, # must be defined
  'db_h' => 'main', # name of database handler
  'db_name' => 'domain_tld', # name of database
  'tb_name' => 'a020_object', # name of main table
  'columns' =>
  {
   'column1' => 1, # return value of this column
   'column2' => 1, # same
  }
  '-slave' => 1, # select data from slave servers
 )

Into 'columns' is automatically added ID, ID_entity, datetime_create and status.

Into 'columns' you are able set '*' => 1

=cut

sub get_ID(%env)
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::get_ID($env{'ID'})") if $debug;
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'") if $debug;
	}
	
	if (!$env{'ID'})
	{
		$t->close() if $debug;
		return undef;
	}
	
	my %data;
	my @columns=
	(
		'ID',
		'ID_entity',
		'datetime_create',
		'status'
	);
	
	push @columns, grep {defined $env{'columns'}{$_}} keys %{$env{'columns'}} if $env{'columns'};
	@columns=('*') if $env{'columns'}{'*'};
	
	my $sel_columns=join ",",@columns;
	
	my $SQL="
		SELECT
			$sel_columns
		FROM
			`$env{'db_name'}`.`$env{'tb_name'}`
		WHERE
			ID='".TOM::Security::form::sql_escape($env{'ID'})."'
		LIMIT 1
	";
	
	my %cache;
	$cache{'-cache_changetime'} = App::020::SQL::functions::_get_changetime(\%env) if ($env{'-cache'} && !$cache{'-cache_changetime'});
	my %sth0=TOM::Database::SQL::execute(
		$SQL,
		'db_h' => $env{'db_h'},
		'log' => $debug,
		'quiet' => $quiet,
		'-cache' => $env{'-cache'},
		'-slave' => $env{'-slave'},
		%cache
	);
	
	if ($sth0{'rows'})
	{
		main::_log("returned row") if $debug;
		$t->close() if $debug;
		return $sth0{'sth'}->fetchhash();
	}
	else
	{
		main::_log("none row returned",1) if $debug;
	}
	
	$t->close() if $debug;
}



=head2 get_ID_entity()

Function returns list of get_ID()'s used by one ID_entity

 my @IDs=App::020::SQL::functions::get_ID_entity
 (
  ID_entity => $ID_entity, # must be defined
  'db_h' => 'main', # name of database handler
  'db_name' => 'domain_tld', # name of database
  'tb_name' => 'a020_object', # name of main table
  'columns' =>
  {
   'column1' => 1, # return value of this column
   'column2' => 1, # same
  }
 )

Into 'columns' is automatically added ID, ID_entity, datetime_create and status.

Into 'columns' you are able set '*' => 1

Get unique ID when you know only ID_entity

 my %hash=(
   App::020::SQL::functions::get_ID_entity
   (
    ID_entity => $ID_entity, # must be defined
    'db_h' => 'main', # name of database handler
    'db_name' => 'domain_tld', # name of database
    'tb_name' => 'a020_object', # name of main table
    'columns' =>
    {
     'column1' => 1, # return value of this column
     'column2' => 1, # same
    }
   )
 )[0];

=cut

sub get_ID_entity(%env)
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::get_ID_entity($env{'ID_entity'})") if $debug;
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'") if $debug;
	}
	
	if (!$env{'ID_entity'})
	{
		$t->close() if $debug;
		return undef;
	}
	
	my $SQL=qq{
		SELECT
			ID
		FROM
			`$env{'db_name'}`.`$env{'tb_name'}`
		WHERE
			ID_entity=$env{'ID_entity'}
		ORDER BY
			ID
	};
	
	my @data;
	
	my %sth0=TOM::Database::SQL::execute(
		$SQL,
		'db_h'=>$env{'db_h'},
		'log'=>$debug,
		'quiet'=>$quiet,
		'-cache'=>$env{'-cache'},
		'-slave'=>$env{'-slave'},
	);
	
	while (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		main::_log("adding ID='$db0_line{'ID'}'") if $debug;
		
		push @data, {get_ID(
			%env,
			'ID' => $db0_line{'ID'},
			'-cache' => $env{'-cache'}
		)};
		
	}
	
	$t->close() if $debug;
	return @data;
}



=head2 update()

Updates one row ( also one ID ) in main table.

 my $retcode=App::020::SQL::functions::update(
  'ID' => $ID, # must be defined
  'db_h' => 'main', # name of database handler
  'db_name' => 'domain_tld', # name of database
  'tb_name' => 'a020_object', # name of main table
  'columns' =>
  {
   'column1' => "'string'", # set value of this column
   'column2' => "number", # same
  },
  '-journalize' => 1, # create journal copy of this update
  '-historical' => 'datetime', # update historical version of data (not yet implemented)
  '-posix' => 1, # posix enhanced table (set posix_modified to $main::USRM{'ID_user'})
 )

Please do not set column datetime_create. datetime_create is updated automatically.

=cut

sub update
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::update()") if $debug;
	my $transaction;
	$transaction=1 if $env{'-journalize'};
	$transaction=1 if $env{'-historical'};
	
	my @bind;
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'") if $debug;
	}
	
	$env{'columns'}{'datetime_create'} = "NOW()" unless $env{'datetime_create'};
	$env{'columns'}{'posix_modified'}="'".$main::USRM{'ID_user'}."'" if $env{'-posix'};
	
	my $sel_set;
	foreach (sort keys %{$env{'columns'}})
	{
		$sel_set.="\t\t`$_` = $env{'columns'}{$_},\n";
	}
	foreach (sort keys %{$env{'data'}})
	{
		next if exists $env{'columns'}{$_}; # 'columns' has higher priority
		$sel_set.="\t\t`$_` = ?,\n";
		push @bind, $env{'data'}{$_};
	}
	$sel_set=~s|,\n$||;
	
	my $tr=new TOM::Database::SQL::transaction('db_h'=>$env{'db_h'},'log'=>$debug,'quiet'=>$quiet) if $transaction;
	
	my $SQL=qq{
		UPDATE `$env{'db_name'}`.`$env{'tb_name'}`
		SET
$sel_set
		WHERE ID=$env{'ID'}
		LIMIT 1
	};
	if ($env{'-historical'})
	{
		main::_log("requiring historical '$env{'-historical'}'") if $debug;
		# check if this history label not already exists
		# if not exists, find older label from this and update it.
		# 
		# 
#		my $SQL=qq{
#			UPDATE `$env{'db_name'}`.`$env{'tb_name'}_h`
#			SET
#$sel_set
#			WHERE ID=$env{'ID'} AND datetime_valid='$env{'-historical'}'
#			LIMIT 1
#		};
	}
	
	my $clmns=join "','", (keys %{$env{'columns'}},keys %{$env{'data'}});
	
	my %sth0=TOM::Database::SQL::execute($SQL,'db_h'=>$env{'db_h'},'log'=>$debug,'quiet'=>$quiet,'bind'=>[@bind]);
	
	if ($sth0{'rows'})
	{
		main::_log("<={SQL:$env{'db_h'}} '$env{'db_name'}'.'$env{'tb_name'}' ID='$env{'ID'}' UPDATE '$clmns'");
		if ($env{'-journalize'})
		{
			# zajournalujem sucasnu verziu
			my $out=journalize(
				'db_h' => $env{'db_h'},
				'db_name' => $env{'db_name'},
				'tb_name' => $env{'tb_name'},
				'ID' => $env{'ID'}
			);
			
			if (!$out)
			{
				main::_log("can't journalize, rollback",1) if $debug;
				$tr->rollback() if $transaction;
				$t->close() if $debug;
				return undef;
			}
			
		}
		
		# get ID_entity
		my %sth1=TOM::Database::SQL::execute(qq{SELECT ID_entity FROM `$env{'db_name'}`.`$env{'tb_name'}` WHERE ID=$env{'ID'} LIMIT 1},'db_h'=>$env{'db_h'},'quiet'=>1);
		my %db1_line=$sth1{'sth'}->fetchhash();
		$env{'ID_entity'}=$db1_line{'ID_entity'};
		
		_save_changetime(\%env);
		
	}
	else
	{
		main::_log("can't update, rollback",1) if $debug;
		$tr->rollback() if $transaction;
		$t->close() if $debug;
		return undef;
	}
	
	$tr->close() if $transaction;
	$t->close() if $debug;
	return 1;
}



=head2 journalize()

Copies actual row from main table into journal table.

 App::020::SQL::functions::journalize
 (
  'ID' => $ID, # must be defined
  'db_h' => 'main', # name of database handler
  'db_name' => 'domain_tld', # name of database
  'tb_name' => 'a020_object', # name of main table
 )

Please do not execute this function alone. After this function must be in main table updated column datetime_create with same ID.

=cut

sub journalize
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::journalize()") if $debug;
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'") if $debug;
	}
	
	my $SQL=qq{
		REPLACE INTO
			`$env{'db_name'}`.`$env{'tb_name'}_j`
		SELECT *
		FROM
			`$env{'db_name'}`.`$env{'tb_name'}`
		WHERE ID=$env{'ID'}
		LIMIT 1
	};
	
	my %sth0=TOM::Database::SQL::execute($SQL,'db_h'=>$env{'db_h'},'log'=>$debug,'quiet'=>$quiet);
	# error
	if ($sth0{'err'})
	{
		$t->close() if $debug;
		return undef;
	}
	
	main::_log("<={SQL:$env{'db_h'}} '$env{'db_name'}'.'$env{'tb_name'}' ID='$env{'ID'}' JOURNAL");
	
	$t->close() if $debug;
	return 1;
}



sub update_now
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::update_now()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	my $SQL="UPDATE `$env{'db_name'}`.`$env{'tb_name'}_j` SET datetime_create=NOW() WHERE ID=$env{'ID'} LIMIT 1";
	
	main::_log("SQL='$SQL'");
	
	my @eout=TOM::Database::SQL::execute($SQL,'db_h'=>$env{'db_h'});
	
	$t->close();
	return 1;
}


sub diff_versions
{
	# porovna dve verzie a povie ktore riadky su rozdielne v ktorych columnoch
	
}


=head2 clone()

Makes copy of given ID, into new ID, but with same ID_entity. Also makes new version/modification of ID_entity.

For example, when ID_entity is like 'article', and one ID is language version of this article, then making clones is as making new language version of this article.

 my $new_ID=App::020::SQL::functions::clone
 (
  'ID' => $ID, # must be defined
  'db_h' => 'main', # name of database handler
  'db_name' => 'domain_tld', # name of database
  'tb_name' => 'a020_object', # name of main table
  'columns' => # list of columns which are changed above old ID
  {
   'column1' => "'string'", # set value of this column
   'column2' => "number", # same
  },
  '-journalize' => 1, # create journal copy of this clone
 );

Clone can be created only from enabled, disabled or trashed rows, not from deleted.

=cut

sub clone
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::clone()");
	
	my $ID;
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	# najdem riadok ktory chcem naklonovat
	my %data=get_ID(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'ID' => $env{'ID'},
		'columns' => {'*'=>1}
	);
	if ($data{'ID'} && $data{'status'}=~/^[YNT]$/)
	{
		
		# pripravim si columny na new
		
		# nepovolim update tychto columnov (z povodneho riadku)
		delete $data{'datetime_create'};
		delete $data{'ID'};
		# nepovolim override tychto columnov
		delete $env{'columns'}{'ID'};
		delete $env{'columns'}{'ID_entity'};
		delete $env{'columns'}{'datetime_create'};
		
		my %columns;
		
		# override %data z $env{columns}
		foreach (keys %{$env{'columns'}})
		{
			$columns{$_}=$env{'columns'}{$_};
			delete $env{'data'}{$_}; # override data from input
			delete $data{$_}; # override original data
		}
		
		foreach (keys %{$env{'data'}})
		{
			$data{$_}=$env{'data'}{$_};
		}
		
		# pokusim sa o novy riadok modifikacie
		$ID=new(
			'db_h' => $env{'db_h'},
			'db_name' => $env{'db_name'},
			'tb_name' => $env{'tb_name'},
			'columns' => {%columns},
			'data' => {%data},
			'-journalize' => $env{'-journalize'},
		);
		if (!$ID)
		{
			# error handling
			${$env{'_errstr'}}=
				"Can't create clone of ID $env{'ID'}\n".
				(Mysql->errmsg())."\n".
				${$env{'_errstr'}} if exists $env{'_errstr'};
			main::_log("Mysql errmsg='".Mysql->errmsg()."'",1);
			$t->close();
			return undef;
		}
		
	}
	else
	{
		main::_log("Can't clone ID='$env{'ID'}. This ID not exists, or is Deleted'",1);
		$t->close();
		return undef;
	}
	
	$t->close();
	return $ID;
}


=head2 copy()

Makes copy of given ID, into new ID and new ID_entity. Also makes new entity

 my $new_ID=App::020::SQL::functions::copy
 (
  'ID' => $ID, # must be defined
  'db_h' => 'main', # name of database handler
  'db_name' => 'domain_tld', # name of database
  'tb_name' => 'a020_object', # name of main table
  'columns' => # list of columns which are changed above old ID
  {
   'column1' => "'string'", # set value of this column
   'column2' => "number", # same
  },
  '-journalize' => 1, # create journal copy of this copy
 );

Clone can be created only from enabled or disabled rows, not from deleted or trashed.

=cut

sub copy
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::copy()");
	
	my $ID;
	my $ID_entity;
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	# najdem riadok ktory chcem naklonovat
	my %data=get_ID(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'ID' => $env{'ID'},
		'columns' => {'*'=>1}
	);
	if ($data{'ID'} && $data{'status'}=~/^[YN]$/)
	{
		$ID_entity=$data{'ID_entity'};
		# pripravim si columny na new
		
		# nepovolim update tychto columnov (z povodneho riadku)
		delete $data{'datetime_create'};
		delete $data{'ID'};
		delete $data{'ID_entity'};
		# nepovolim override tychto columnov
		delete $env{'columns'}{'ID'};
		delete $env{'columns'}{'ID_entity'};
		delete $env{'columns'}{'datetime_create'};
		
		# osetrenie data
		foreach (keys %data)
		{
			$data{$_}="'".TOM::Security::form::sql_escape($data{$_})."'";
		}
		
		# override %data z $env{columns}
		foreach (keys %{$env{'columns'}})
		{
			$data{$_}=$env{'columns'}{$_};
		}
		
		# pokusim sa o novy riadok
		$ID=new(
			'db_h' => $env{'db_h'},
			'db_name' => $env{'db_name'},
			'tb_name' => $env{'tb_name'},
			'columns' => {%data},
			'-journalize' => $env{'-journalize'},
		);
		if (!$ID)
		{
			# error handling
			${$env{'_errstr'}}=
				"Can't create copy of ID $env{'ID'}\n".
				(Mysql->errmsg())."\n".
				${$env{'_errstr'}} if exists $env{'_errstr'};
			main::_log("Mysql errmsg='".Mysql->errmsg()."'",1);
			$t->close();
			return undef;
		}
		else
		{
			if ($env{'a160'})
			{
				require App::160::_init;
#				main::_log("copy a160 of ID_entity=$ID_entity");
				
				my $l_prefix=$env{'tb_name'};
					$l_prefix=~s|^(.*?)_(.*)$|$1|;
				my $l_table=$2;
				foreach my $relation (App::160::SQL::get_relations(
					'db_name' => $env{'db_name'},
					'l_prefix' => $1,
					'l_table' => $2,
					'l_ID_entity' => $ID_entity
				))
				{
#					use Data::Dumper;
#					print "relation:".Dumper($relation)."\n";
					# create relation
					App::160::SQL::new_relation(
						'l_prefix' => $relation->{'l_prefix'},
						'l_table' => $relation->{'l_table'}, # this value can be send as undefined
						'l_ID_entity' => $ID,
						'rel_type' => $relation->{'rel_type'},
						'r_db_name' => $relation->{'r_db_name'}, # this value can be send as undefined
						'r_prefix' => $relation->{'r_prefix'},
						'r_table' => $relation->{'r_table'}, # this value can be send as undefined
						'r_ID_entity' => $relation->{'r_ID_entity'},
						'status' => $relation->{'status'},
					);
				}
				
			}
		}
	}
	else
	{
		main::_log("Can't copy ID='$env{'ID'}. This ID not exists, or is in Trash/Deleted'",1);
		$t->close();
		return undef;
	}
	
	$t->close();
	return $ID;
}


sub copy_entity
{
	# kopia celej entity
}


=head2 to_trash()

Moves one row ( also ID ) into trash. Physically only changes status of this row to 'T'.

 my $retcode=App::020::SQL::functions::to_trash
 (
  'ID' => $ID, # must be defined
  'db_h' => 'main', # name of database handler
  'db_name' => 'domain_tld', # name of database
  'tb_name' => 'a020_object', # name of main table
  '-journalize' => 1, # create journal copy of this action
 );

Only rows with status Y or N can be moved into trash.

=cut

sub to_trash
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::to_trash()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	my %columns=get_ID(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'ID' => $env{'ID'}
	);
	
	if (!$columns{'ID'})
	{
		main::_log("this ID not exists!",1);
		$t->close();
		return undef;
	}
	
	if ($columns{'status'} eq "T")
	{
		main::_log("this ID has been previously added to Trash");
		$t->close();
		return 1;
	}
	
	update(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'ID' => $env{'ID'},
		'-journalize' => $env{'-journalize'},
		'columns' => {
			'status' => "'T'"
		}
	);
	
	$t->close();
	return 1;
}


=head2 trash_restore()

Restores one row ( also ID ) from trash. Physically only changes status of this row to 'N'.

 my $retcode=App::020::SQL::functions::trash_restore
 (
  'ID' => $ID, # must be defined
  'db_h' => 'main', # name of database handler
  'db_name' => 'domain_tld', # name of database
  'tb_name' => 'a020_object', # name of main table
  '-journalize' => 1, # create journal copy of this action
 );

Only rows with status T can be restored

=cut

sub trash_restore
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::trash_restore()") if $debug;
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'") if $debug;
	}
	
	my %columns=get_ID(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'ID' => $env{'ID'}
	);
	
	if (!$columns{'ID'})
	{
		main::_log("this ID not exists!",1) if $debug;
		$t->close() if $debug;
		return undef;
	}
	
	if ($columns{'status'} ne "T")
	{
		main::_log("this ID is previously restored") if $debug;
		$t->close() if $debug;
		return 1;
	}
	
	update(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'ID' => $env{'ID'},
		'-journalize' => $env{'-journalize'},
		'columns' => {
			'status' => "'N'"
		}
	);
	
	$t->close() if $debug;
	return 1;
}


=head2 trash_delete()

Delete one row ( also ID ) from trash. Physically only changes status of this row to 'D' and moves it from main table into journal table ( when journalize is enabled ).

 my $retcode=App::020::SQL::functions::trash_delete
 (
  'ID' => $ID, # must be defined
  'db_h' => 'main', # name of database handler
  'db_name' => 'domain_tld', # name of database
  'tb_name' => 'a020_object', # name of main table
  '-journalize' => 1, # create journal copy of this action
 );

Only rows with status T can be deleted

=cut

sub trash_delete
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::trash_delete()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	my %columns=get_ID(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'ID' => $env{'ID'}
	);
	
	if (!$columns{'ID'})
	{
		main::_log("this ID not exists!",1);
		$t->close();
		return undef;
	}
	
	if ($columns{'status'} ne "T")
	{
		main::_log("this ID is not in Trash");
		$t->close();
		return 1;
	}
	
	# zmenim status sucasneho zaznamu za zmazany
	update(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'ID' => $env{'ID'},
		'columns' => {
			'status' => "'D'",
		},
		'-journalize' => $env{'-journalize'}
	);
	
	# zmazem z hlavnej tabulky zmazany zaznam
	_remove(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'ID' => $env{'ID'}
	);
	
	$t->close();
	return 1;
}


=head2 trash_empty()

Empty trash with all trashed ID's. Use carefully. When journalize is not enabled, all this rows is gone and can't be returned.

 my $retcode=App::020::SQL::functions::trash_empty
 (
  'db_h' => 'main', # name of database handler
  'db_name' => 'domain_tld', # name of database
  'tb_name' => 'a020_object', # name of main table
  '-journalize' => 1, # create journal copy of this action
 );

Only rows with status T will be deleted

=cut

sub trash_empty
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::trash_empty()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	my $tr=new TOM::Database::SQL::transaction('db_h'=>$env{'db_h'});
	
	my $sql=qq{
		SELECT
			ID
		FROM
			`$env{'db_name'}`.`$env{'tb_name'}`
		WHERE
			status='T'
		ORDER BY ID
	};
	
	my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>$env{'db_h'},'quiet'=>1);
	if (!$sth0{'sth'})
	{
		$tr->rollback();
		$t->close();
		return undef;
	}
	
	while (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		main::_log("ID='$db0_line{'ID'}'");
		my $out=trash_delete(
			'ID' => $db0_line{'ID'},
			'db_h' => $env{'db_h'},
			'db_name' => $env{'db_name'},
			'tb_name' =>$env{'tb_name'}
		);
		if (!$out)
		{
			$tr->rollback();
			$t->close();
			return undef;
		}
	}
	
	
	$tr->close();
	$t->close();
	return 1;
}


=head2 delete()

Deletes one row ( also ID ) from main table. Physically only changes status of this row to 'D' and moves it into journal table ( if enabled ).

 my $retcode=App::020::SQL::functions::delete
 (
  'ID' => $ID, # must be defined
  'db_h' => 'main', # name of database handler
  'db_name' => 'domain_tld', # name of database
  'tb_name' => 'a020_object', # name of main table
  '-journalize' => 1, # create journal copy of this action
 );

=cut

sub delete
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::delete()") if $debug;
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'") if $debug;
	}
	
	my %columns=get_ID(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'ID' => $env{'ID'}
	);
	
	if (!$columns{'ID'})
	{
		main::_log("this ID not exists!",1) if $debug;
		$t->close() if $debug;
		return undef;
	}
	
	# zmenim status sucasneho zaznamu za zmazany
	update(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'ID' => $env{'ID'},
		'columns' => {
			'status' => "'D'",
		},
		'-journalize' => $env{'-journalize'}
	);
	
	# zmazem z hlavnej tabulky zmazany zaznam
	_remove(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'ID' => $env{'ID'}
	);
	
	$t->close() if $debug;
	return 1;
}



sub undele
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::undele()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	
	
	$t->close();
	return 1;
}



sub _remove
{
	# fyzicke zmazanie verziovaneho zaznamu z hlavnej tabulky
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::_remove()") if $debug;
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'") if $debug;
	}
	
	my $SQL="DELETE FROM `$env{'db_name'}`.`$env{'tb_name'}` WHERE ID=$env{'ID'} LIMIT 1";
	
	my %sth0=TOM::Database::SQL::execute($SQL,'db_h'=>$env{'db_h'},'log'=>$debug,'quiet'=>$quiet);
	
	if ($sth0{'rows'})
	{
		main::_log("<={SQL:$env{'db_h'}} '$env{'db_name'}'.'$env{'tb_name'}' ID='$env{'ID'}' DELETE");
	}
	
	$t->close() if $debug;
	return 1;
}


=head2 disable()

Sets one row ( also ID ) as disabled ( not active ). Physically only changes status of this row to 'N'.

 my $retcode=App::020::SQL::functions::disable
 (
  'ID' => $ID, # must be defined
  'db_h' => 'main', # name of database handler
  'db_name' => 'domain_tld', # name of database
  'tb_name' => 'a020_object', # name of main table
  '-journalize' => 1, # create journal copy of this action
 );

Only rows with status Y can be disabled

=cut

sub disable
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::disable()") if $debug;
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'") if $debug;
	}
	
	my %columns=get_ID(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'ID' => $env{'ID'}
	);
	
	if (!$columns{'ID'})
	{
		main::_log("this ID not exists!",1) if $debug;
		main::_log("<={SQL:$env{'db_h'}} can't update ID='$columns{'ID'}' in '$env{'db_name'}'.'$env{'tb_name'}' because ID not exists",1) unless $debug;
		$t->close() if $debug;
		return undef;
	}
	
	if ($columns{'status'} eq "N")
	{
		main::_log("this ID is already disabled") if $debug;
		main::_log("<={SQL:$env{'db_h'}} '$env{'db_name'}'.'$env{'tb_name'}' ID='$columns{'ID'}' already disabled") unless $debug;
		$t->close() if $debug;
		return 1;
	}
	
	if ($columns{'status'} ne "Y")
	{
		main::_log("only ID with status 'N' can be disabled, not status='$columns{'status'}'") if $debug;
		$t->close() if $debug;
		return undef;
	}
	
	my $out=update(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'ID' => $env{'ID'},
		'-journalize' => $env{'-journalize'},
		'columns' => {
			'status' => "'N'"
		}
	);
	
	$t->close() if $debug;
	return $out;
}


=head2 enable()

Sets one row ( also ID ) as enabled ( active ). Physically only changes status of this row to 'Y'.

 my $retcode=App::020::SQL::functions::enable
 (
  'ID' => $ID, # must be defined
  'db_h' => 'main', # name of database handler
  'db_name' => 'domain_tld', # name of database
  'tb_name' => 'a020_object', # name of main table
  '-journalize' => 1, # create journal copy of this action
 );

Only rows with status N can be enabled

=cut

sub enable
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::enable()") if $debug;
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'") if $debug;
	}
	
	my %columns=get_ID(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'ID' => $env{'ID'}
	);
	
	if (!$columns{'ID'})
	{
		main::_log("this ID not exists!",1) if $debug;
		main::_log("<={SQL:$env{'db_h'}} can't update ID='$columns{'ID'}' in '$env{'db_name'}'.'$env{'tb_name'}' because ID not exists",1) unless $debug;
		$t->close() if $debug;
		return undef;
	}
	
	if ($columns{'status'} eq "Y")
	{
		main::_log("this ID is already enabled") if $debug;
		main::_log("<={SQL:$env{'db_h'}} '$env{'db_name'}'.'$env{'tb_name'}' ID='$columns{'ID'}' already enabled") unless $debug;
		$t->close() if $debug;
		return 1;
	}
	
	if ($columns{'status'} ne "N")
	{
		main::_log("only ID with status 'N' can be enabled, not status='$columns{'status'}'") if $debug;
		$t->close() if $debug;
		return undef;
	}
	
	my $out=update(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'ID' => $env{'ID'},
		'-journalize' => $env{'-journalize'},
		'columns' => {
			'status' => "'Y'"
		}
	);
	
	$t->close() if $debug;
	return $out;
}





sub _get_changetime
{
	my %env=%{shift @_};
	
	$env{'db_h'}='main' unless $env{'db_h'};
	$env{'db_name'}=$TOM::DB{$env{'db_h'}}{'name'} unless $env{'db_name'};
	
	if (!$TOM::CACHE_memcached && !$Redis)
	{
		# when memcached is not enabled, return 1 = database is always changed
		return Time::HiRes::time();
	}
	
	my $key=$env{'db_h'}.'::'.$env{'db_name'}.'::'.$env{'tb_name'};
		$key.='::'.$env{'ID_entity'} if $env{'ID_entity'};
	
	if ($main::env{'cache'}{'db_changed'}{$key})
	{
		# don't check twice on this request
		return $main::env{'cache'}{'db_changed'}{$key};
	}
	
	my $changetime;
	if ($Redis)
	{
		$changetime=$Redis->hget('C3|db_entity|'.$key,'modified');
	}
	else # or old memcached way
	{
		$changetime=$Ext::CacheMemcache::cache->get
		(
			'namespace' => "db_changed",
			'key' => $key
		);
	}
	
	$main::env{'cache'}{'db_changed'}{$key}=$changetime;
	
	if (!$changetime)
	{
		_save_changetime(\%env,'-autosave'=>1);
	}
#	main::_log("ent '$key' $changetime");
	return $changetime || Time::HiRes::time();
}


sub _save_changetime
{
	my %env=%{shift @_};
	my %conf=@_;
	
	$env{'db_h'}='main' unless $env{'db_h'};
	$env{'db_name'}=$TOM::DB{$env{'db_h'}}{'name'} unless $env{'db_name'};
	
	if (!$TOM::CACHE_memcached && !$Redis)
	{
		# when memcached or Redis is not enabled, return 1
		return 1;
	}
	
	my $key=$env{'db_h'}.'::'.$env{'db_name'}.'::'.$env{'tb_name'};
	my $key_entity=$env{'db_h'}.'::'.$env{'db_name'}.'::'.$env{'tb_name'}.'::'.$env{'ID_entity'};
	
	my $tt=Time::HiRes::time();
	$main::env{'cache'}{'db_changed'}{$key}=$tt;
	$main::env{'cache'}{'db_changed'}{$key_entity}=$tt;
	
	main::_log("_save_changetime ".$key_entity." to ".$tt,3,"debug");
	
	if ($RabbitMQ && !$conf{'-autosave'}) # publish event
	{
		use JSON;
		if ($env{'ID_entity'})
		{
			$RabbitMQ->publish(
				'exchange' => 'cyclone3.notify',
				'routing_key' => 'notify',
				'header' => {
					'app_id' => $tom::H_orig
				},
				'body' => to_json({
					'event' => 'db_changed',
					'db_name' => $env{'db_name'},
					'tb_name' => $env{'tb_name'},
					'ID_entity' => $env{'ID_entity'},
					'key' => $key_entity,
					'mtime' => $tt,
					'user' => $main::USRM{'ID_user'},
					'hostname' => $TOM::hostname,
					'domain' => $tom::H_orig
				})
			);
		}
#		else
#		{
#			$RabbitMQ->publish(
#				'exchange' => 'entity.change',
#				'routing_key' => '',
#				'header' => {
#					'app_id' => $tom::H
#				},
#				'body' => to_json({
#					'key' => $key,
#					'mtime' => $tt,
#					'user' => $main::USRM{'ID_user'},
#					'hostname'  => $TOM::hostname,
#					'domain' => $tom::H
#				})
#			);
#		}
	}
	
	if ($Redis)
	{
		use JSON;
		if (!$env{'ID_entity'}||($env{'ID_entity'} && !$conf{'-autosave'}))
		{
			$Redis->hset('C3|db_entity|'.$key,'modified',$tt,sub{});
			$Redis->expire('C3|db_entity|'.$key,(86400*30),sub{});
#			if (!$RabbitMQ) # publish only when pub/sub of RabbitMQ not available
#			{
				$Redis->publish('C3|db_entity|modified|'.$key,to_json({
					'mtime'=>$tt,
					'user'=>$main::USRM{'ID_user'},
					'hostname' => $TOM::hostname,
					'domain' => $tom::H
				})) unless $conf{'-autosave'}; # publish event
#			}
		}
		
		if ($env{'ID_entity'})
		{
			$Redis->hset('C3|db_entity|'.$key_entity,'modified',$tt,sub{});
			$Redis->expire('C3|db_entity|'.$key_entity,(86400*30),sub{});
#			if (!$RabbitMQ) # publish only when pub/sub of RabbitMQ not available
#			{
				$Redis->publish('C3|db_entity|modified|'.$key_entity,to_json({
					'mtime'=>$tt,
					'user'=>$main::USRM{'ID_user'},
					'hostname' => $TOM::hostname,
					'domain' => $tom::H
				})) unless $conf{'-autosave'};
#			}
		}
		return 1;
	}
	
	$Ext::CacheMemcache::cache->set
	(
		'namespace' => "db_changed",
		'key' => $key,
		'value' => $tt,
		'expiration' => "30D",
	);
	
	if ($env{'ID_entity'})
	{
		$Ext::CacheMemcache::cache->set
		(
			'namespace' => "db_changed",
			'key' => $key_entity,
			'value' => $tt,
			'expiration' => "30D",
		);
	}
	
	return 1;
}

our %db_names;
sub _detect_db_name
{
	my $prefix=shift;
	
	return $TOM::DB{'main'}{'name'} unless $prefix=~/^[a-zA-Z0-9_\-:]+$/;
	
	main::_log("detect db_name with '$prefix' addon") if $debug;
	# at first check if this addon is available
	$prefix=~s|^a|App::|;
	$prefix=~s|^e|Ext::|;
	# load this addon if not available
	if (not defined $prefix->VERSION)
	{
		eval "use $prefix".'::_init;';
		if ($@)
		{
			main::_log("err:$@",1);
			return undef;
		}
	}
	# read db_name from this library
	if ($db_names{$prefix})
	{
		main::_log("get cached db_name=$db_names{$prefix}") if $debug;
		return $db_names{$prefix};
	}
	my $db_name;eval '$db_name=$'.$prefix.'::db_name;';
	main::_log("detected db_name=$db_name") if $debug;
	# setup when found
	$db_names{$prefix}=$db_name;
	return $db_name if $db_name;
	return undef;
}


=head1 SEE ALSO

=over

=item *

L<DATA standard|standard/"DATA">

=item *

L<API standard|standard/"API">

=item *

L<a020 database structure|app/"020/a020_struct.sql">

=back

=cut

=head1 AUTHORS

Roman Fordinal (roman.fordinal@comsultia.com)

=cut

1;
