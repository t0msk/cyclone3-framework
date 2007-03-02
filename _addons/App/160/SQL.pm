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
   'l_ID_entity' => '2'
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



=head2 get_relations()

Returns list of references to relations

 my @list=get_relations(
   #'ID' => 1,
   #'ID_entity' => 1,
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
  main::_log("reference with ID='$reverence->{'ID'}'");
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
		main::_log("relation[$i] r_db_name='$db0_line{'r_db_name'}' r_prefix='$db0_line{'r_prefix'}' r_table='$db0_line{'r_table'}' r_ID_entity='$db0_line{'r_ID_entity'}'");
		push @relations, {%db0_line};
		$i++;
	}
	
	$t->close();
	return @relations;
}

=head1 AUTHORS

Roman Fordinal (roman.fordinal@comsultia.com)

=cut

1;
