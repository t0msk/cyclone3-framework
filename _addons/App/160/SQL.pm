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

our $DEBUG=0;

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
	$env{'db_name'}=$TOM::DB{$env{'db_h'}}{'name'} unless $env{'db_name'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
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
				'status' => "'Y'",
			},
		);
		
		$t->close();
		return $relation->{'ID_entity'}, $relation->{'ID'};
	}
	
	# find if this relation has ID_entity
	my $relation=(get_relations(
		%env,
		'rel_type' => undef,
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
				'status' => "'Y'",
			},
		);
		
		main::_log("clone with ID='$ID'");
		
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
			'status' => "'Y'",
		},
	);
	
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
	$env{'db_name'}=$TOM::DB{$env{'db_h'}}{'name'} unless $env{'db_name'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	# check if this relation already exists
	my $relation=(get_relations(
		'ID'=>$env{'ID'},
		'status' => 'YNT',
		'limit' => '0,1'
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
			);
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



=head2 get_relations()

Returns list of references to relations

 my @list=get_relations(
   #'ID' => 1,
   #'ID_entity' => 1,
   #'db_h' => 'main',
   #'db_name' => $TOM::DB{$env{'db_h'}}{'name'},
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
	my $t=track TOM::Debug(__PACKAGE__."::get_relation()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	$env{'db_name'}=$TOM::DB{$env{'db_h'}}{'name'} unless $env{'db_name'};
	$env{'limit'}="0,100" unless $env{'limit'};
	
	# list of input
	foreach (sort keys %env) {main::_log("input '$_'='$env{$_}'") if defined $env{$_}};
	
	my $where;
	
	# status
	if ($env{'status'}){$where.= "status IN ('".(join "','" , split('',$env{'status'}))."') ";}
	else {$where.="status='Y' ";}
	
	# fill 'where' with valid input variables ( prefix l_, r_, ID )
	foreach (keys %env)
	{
		next unless defined $env{$_};
		if ($_=~/^(l|r)_/ || $_=~/^ID/){ $where.="AND $_='$env{$_}' ";}
	}
	if (exists $env{'rel_type'}){$where.="AND rel_tyle='$env{rel_tyle}' ";}
	
	my @relations;
	
	my $sql=qq{
		SELECT
			*
		FROM
			$env{'db_name'}.a160_relation
		WHERE
			$where
		ORDER BY
			r_db_name, r_prefix, r_table, r_ID_entity
		LIMIT
			$env{'limit'};
	};
	my $i=0;
	my %sth0=TOM::Database::SQL::execute($sql,'log'=>$DEBUG);
	while (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		main::_log("relation[$i] rel_tyle='$db0_line{'rel_type'}' r_db_name='$db0_line{'r_db_name'}' r_prefix='$db0_line{'r_prefix'}' r_table='$db0_line{'r_table'}' r_ID_entity='$db0_line{'r_ID_entity'}'");
		push @relations, {%db0_line};
		$i++;
	}
	
	$t->close();
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
	$env{'r_db_name'}=$TOM::DB{$env{'db_h'}}{'name'} unless $env{'r_db_name'};
	
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

Roman Fordinal (roman.fordinal@comsultia.com)

=cut

1;
