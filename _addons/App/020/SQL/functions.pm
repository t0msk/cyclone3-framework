#!/bin/perl
package App::020::SQL::functions;

=head1 NAME

App::020::SQL::functions

=cut

use open ':utf8', ':std';
use encoding 'utf8';
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

L<App::020::SQL::functions::tree|app/"020/SQL/functions/tree.pm">

=back

=cut

use TOM::Database::SQL;
use App::020::SQL::functions::tree;


=head1 FUNCTIONS

=head2 new()

Function creates new row into main table and initializes it ( creates ID and ID_entity ).

This function makes automatically journalization copy of every created new row, when -journalize is enabled (table with suffix '_j' must exists).

 my $ID=new
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
  '-journalize' => 1
 )

Please never try over this function setting columns named ID, ID_entity and datetime_create.

Function returns ID, which is in new() same as ID_entity!

=cut

sub new
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::new()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	my $sel_columns;
	my $sel_values;
	my @columns;
	my @values;
	foreach (sort keys %{$env{'columns'}})
	{
		push @columns, $_;
		push @values, $env{'columns'}{$_};
	}
	$sel_columns="`" . (join "`,`" , @columns) . "`" if @columns;
	$sel_values= join (",",@values) if @values;
	
	my $SQL=qq{
		INSERT INTO
			`$env{'db_name'}`.`$env{'tb_name'}`
		($sel_columns)
		VALUES
		($sel_values)
	};
	
	my %sth0=TOM::Database::SQL::execute($SQL,'db_h'=>$env{'db_h'});
	
	if ($sth0{'rows'})
	{
		# podarilo sa vlozit zaznam
		my $ID=$sth0{'sth'}->insertid();
		main::_log("new ID='$ID'");
		# aktivujem ho tym ze mu priradim cislo a cislo verzie
		new_initialize(
			'db_h' => $env{'db_h'},
			'db_name' => $env{'db_name'},
			'tb_name' => $env{'tb_name'},
			'ID' => $ID
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
		
		$t->close();
		return $ID;
	}
	
	$t->close();
	return undef;
}



=head2 new_initialize()

This function is called from new() function. Finds all rows where ID_entity IS NULL and initializes this rows with setting ID_entity=ID, datetime_create=NOW()

Function can be called with one param - ID;

 new_initialize(
  ID => $ID, # or undef
  'db_h' => 'main', # name of database handler
  'db_name' => 'domain_tld', # name of database
  'tb_name' => 'a020_object', # name of main table
 );

=cut

sub new_initialize
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::new_initialize($env{'ID'})");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	my $SQL="UPDATE `$env{'db_name'}`.`$env{'tb_name'}` SET datetime_create=NOW(), ID_entity=ID WHERE ";
	
	if ($env{'ID'})
	{
		$SQL.="ID=$env{'ID'} AND ID_entity IS NULL";
	}
	else
	{
		$SQL.="ID_entity IS NULL";
	}
	
	main::_log("SQL='$SQL'");
	
	my %sth0=TOM::Database::SQL::execute($SQL,'db_h'=>$env{'db_h'});
	
	$t->close();
	return 1;
}


=head2 get_ID()

Function returns one row in %hash from main table ( also actual row, not journalized ).

 my %hash=get_ID
 (
  ID => $ID, # must be defined
  'db_h' => 'main', # name of database handler
  'db_name' => 'domain_tld', # name of database
  'tb_name' => 'a020_object', # name of main table
  'colums' =>
  {
  	'column1' => 1, # return value of this column
  	'column2' => 1, # same
  }
 )

Into 'columns' is automatically added ID, ID_entity, datetime_create and status.

Into 'columns' you are able set '*' => 1

=cut

sub get_ID(%env)
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::get_ID($env{'ID'})");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	my %data;
	my @columns=
	(
		'ID',
		'ID_entity',
		'datetime_create',
		'status'
	);
	
	push @columns, keys %{$env{'columns'}} if $env{'columns'};
	@columns=('*') if $env{'columns'}{'*'};
	
	my $sel_columns=join ",",@columns;
	
	my $SQL=qq{
		SELECT
			$sel_columns
		FROM
			`$env{'db_name'}`.`$env{'tb_name'}`
		WHERE
			ID=$env{'ID'}
		LIMIT 1
	};
	
	my %sth0=TOM::Database::SQL::execute($SQL,'db_h'=>$env{'db_h'},'quiet'=>1);
	if ($sth0{'rows'})
	{
		main::_log("returned row");
		$t->close();
		return $sth0{'sth'}->fetchhash();
	}
	else
	{
		main::_log("none row returned",1);
	}
	
	$t->close();
}


=head2 update()

Updates one row ( also one ID ) in main table.

 my $retcode=update(
  'ID' => $ID, # must be defined
  'db_h' => 'main', # name of database handler
  'db_name' => 'domain_tld', # name of database
  'tb_name' => 'a020_object', # name of main table
  'colums' =>
  {
   'column1' => "'string'", # set value of this column
   'column2' => "number", # same
  },
  '-journalize' => 1, # create journal copy of this update
 )

Please do not set column datetime_create. datetime_create is updatet automatically.

=cut

sub update
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::update()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	$env{'columns'}{'datetime_create'} = "NOW()";
	
	my $sel_set;
	foreach (sort keys %{$env{'columns'}})
	{
		$sel_set.="\t\t`$_` = $env{'columns'}{$_},\n";
	}
	$sel_set=~s|,\n$||;
	
	my $tr=new TOM::Database::SQL::transaction('db_h'=>$env{'db_h'});
	
	my $SQL=qq{
		UPDATE `$env{'db_name'}`.`$env{'tb_name'}`
		SET
$sel_set
		WHERE ID=$env{'ID'}
		LIMIT 1
	};
	
	my %sth0=TOM::Database::SQL::execute($SQL,'db_h'=>$env{'db_h'});
	
	if ($sth0{'rows'})
	{
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
				main::_log("can't journalize, rollback",1);
				$tr->rollback();
				$t->close();
				return undef;
			}
			
		}
	}
	else
	{
		main::_log("can't update, rollback",1);
		$tr->rollback();
		$t->close();
		return undef;
	}
	
	$tr->close();
	$t->close();
	return 1;
}



=head2 journalize()

Copies actual row from main table into journal table.

 journalize
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
	my $t=track TOM::Debug(__PACKAGE__."::journalize()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
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
		
	my %sth0=TOM::Database::SQL::execute($SQL,'db_h'=>$env{'db_h'});
	# error
	if ($sth0{'err'})
	{
		$t->close();
		return undef;
	}
	
	$t->close();
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

 my $new_ID=clone
 (
  'ID' => $ID, # must be defined
  'db_h' => 'main', # name of database handler
  'db_name' => 'domain_tld', # name of database
  'tb_name' => 'a020_object', # name of main table
  'colums' => # list of columns which are changed above old ID
  {
   'column1' => "'string'", # set value of this column
   'column2' => "number", # same
  },
  '-journalize' => 1, # create journal copy of this clone
 );

Clone can be created only from enabled or disabled rows, not from deleted or trashed.

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
	if ($data{'ID'} && $data{'status'}=~/^[YN]$/)
	{
		
		# pripravim si columny na new
		
		# nepovolim update tychto columnov (z povodneho riadku)
		delete $data{'datetime_create'};
		delete $data{'ID'};
		# nepovolim override tychto columnov
		delete $env{'columns'}{'ID'};
		delete $env{'columns'}{'ID_entity'};
		delete $env{'columns'}{'datetime_create'};
		
		# osetrenie data
		foreach (keys %data)
		{
			$data{$_}="'".$data{$_}."'";
		}
		
		# override %data z $env{columns}
		foreach (keys %{$env{'columns'}})
		{
			$data{$_}=$env{'columns'}{$_};
		}
		
		# pokusim sa o novy riadok modifikacie
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
		main::_log("Can't clone ID='$env{'ID'}. This ID not exists, or is in Trash/Deleted'",1);
		$t->close();
		return undef;
	}
	
	$t->close();
	return $ID;
}


=head2 copy()

Makes copy of given ID, into new ID and new ID_entity. Also makes new entity

 my $new_ID=copy
 (
  'ID' => $ID, # must be defined
  'db_h' => 'main', # name of database handler
  'db_name' => 'domain_tld', # name of database
  'tb_name' => 'a020_object', # name of main table
  'colums' => # list of columns which are changed above old ID
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
			$data{$_}="'".$data{$_}."'";
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

 my $retcode=to_trash
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

 my $retcode=to_restore
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
	my $t=track TOM::Debug(__PACKAGE__."::trash_restore()");
	
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
		main::_log("this ID is previously restored");
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
			'status' => "'N'"
		}
	);
	
	$t->close();
	return 1;
}


=head2 trash_delete()

Delete one row ( also ID ) from trash. Physically only changes status of this row to 'D' and moves it from main table into journal table ( when journalize is enabled ).

 my $retcode=trash_delete
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

 my $retcode=trash_empty
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

 my $retcode=delete
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
	my $t=track TOM::Debug(__PACKAGE__."::delete()");
	
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
	my $t=track TOM::Debug(__PACKAGE__."::_delete()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	my $SQL="DELETE FROM `$env{'db_name'}`.`$env{'tb_name'}` WHERE ID=$env{'ID'} LIMIT 1";
	main::_log("SQL='$SQL'");
	
	my @eout=TOM::Database::SQL::execute($SQL,'db_h'=>$env{'db_h'});
	
	if ($eout[1])
	{
		main::_log("ID='$env{'ID'}' successfully deleted from `$env{db_name}`.`$env{tb_name}`");
	}
	
	$t->close();
	return 1;
}


=head2 disable()

Sets one row ( also ID ) as disabled ( not active ). Physically only changes status of this row to 'N'.

 my $retcode=disable
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
	my $t=track TOM::Debug(__PACKAGE__."::disable()");
	
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
	
	if ($columns{'status'} eq "N")
	{
		main::_log("this ID is previously disabled");
		$t->close();
		return 1;
	}
	
	if ($columns{'status'} ne "Y")
	{
		main::_log("only ID with status 'Y' can be disabled, not status='$columns{'status'}'",1);
		$t->close();
		return undef;
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
	
	$t->close();
	return 1;
}


=head2 enable()

Sets one row ( also ID ) as enabled ( active ). Physically only changes status of this row to 'Y'.

 my $retcode=enable
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
	my $t=track TOM::Debug(__PACKAGE__."::enable()");
	
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
	
	if ($columns{'status'} eq "Y")
	{
		main::_log("this ID is previously enabled");
		$t->close();
		return 1;
	}
	
	if ($columns{'status'} ne "N")
	{
		main::_log("only ID with status 'N' can be enabled, not status='$columns{'status'}'");
		$t->close();
		return undef;
	}
	
	update(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'ID' => $env{'ID'},
		'-journalize' => $env{'-journalize'},
		'columns' => {
			'status' => "'Y'"
		}
	);
	
	$t->close();
	return 1;
}

1;
