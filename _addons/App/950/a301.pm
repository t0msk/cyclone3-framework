#!/bin/perl
package App::950::a301;

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


use App::950::_init;
use App::301::perm;
use App::020::_init;


our $VERSION='1';


# addon functions
our %functions=(
	'addon' => 1,
	'data.offer.details' => 1,
	'data.offer.thumbnail' => 1,
	'data.offer_cat.details' => 1,
	'action.offer.trash' => 1,
	'action.offer.new' => 1,
	'action.offer_cat.new' => 1,
	'action.offer_cat.trash' => 1,
	'publish.offer' => 1,
	'publish.offer_cat' => 1
);


# addon roles
our %roles=(
	'addon' => [
		'addon'
	],
	'offer.data' => [
		'data.offer.details',
		'data.offer.thumbnail'
	],
	'offer.action' => [
		'action.offer.trash',
		'action.offer.new'
	],
	'offer_cat.data' =>
	[
		'action.offer_cat.details'
	],
	'offer_cat.action' =>
	[
		'action.offer_cat.new',
		'action.offer_cat.trash'
	],
	'offer_cat.publish' =>
	[
		'offer_cat.publish'
	],
	'offer.publish' =>
	[
		'offer.publish'
	]
);


# default groups related to addon roles with defined permissions
our %groups=(
	'world' => {
#		'poll' => 'r  '
	},
	'editor' => {
		'addon' => 'rwx',
		'offer.data' => 'rwx',
		'offer.action' => 'rwx',
		'offer.publish' => 'rwx',
		'offer_cat.data' => 'rwx',
		'offer_cat.action' => 'rwx',
		'offer_cat.publish' => 'rwx'
	},
);


# ACL role override
our %ACL_roles=(
	'owner' => {
#		'poll' => 'rwx',
	},
);


# register this definition

App::301::perm::register(
	'addon' => 'a950',
	'functions' => \%functions,
	'roles' => \%roles,
	'ACL_roles' => \%ACL_roles,
	'groups' => \%groups
);



sub get_owner
{
	shift;
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::get_owner()");
	
	foreach (sort keys %env) {main::_log("input '$_'='$env{$_}'") if defined $env{$_}};
	
	if ($env{'r_table'} eq "offer")
	{
		my $sql=qq{
			SELECT
				posix_owner
			FROM
				`$App::950::db_name`.a950_offer
			WHERE
				ID_entity='$env{'r_ID_entity'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>'main','quiet'=>1,'-slave'=>0);
		my %db0_line=$sth0{'sth'}->fetchhash();
		$t->close();
		return $db0_line{'posix_owner'};
	}
	elsif ($env{'r_table'} eq "offer_cat")
	{
		my $sql=qq{
			SELECT
				posix_owner
			FROM
				`$App::910::db_name`.a950_offer_cat
			WHERE
				ID='$env{'r_ID_entity'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>'main','quiet'=>1,'-slave'=>0);
		my %db0_line=$sth0{'sth'}->fetchhash();
		$t->close();
		return $db0_line{'posix_owner'};
	}
	
	$t->close();
	return undef;
}


sub set_owner
{
	shift;
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::set_owner()");
	
	foreach (sort keys %env) {main::_log("input '$_'='$env{$_}'") if defined $env{$_}};
	
	if ($env{'r_table'} eq "offer_cat")
	{
		App::020::SQL::functions::update(
			'ID' => $env{'r_ID_entity'},
			'db_h' => 'main',
			'db_name' => $App::950::db_name,
			'tb_name' => 'a950_offer_cat',
			'columns' =>
			{
				'posix_owner' => "'".$env{'posix_owner'}."'"
			},
			'-journalize' => 1,
			'-posix' => 1
		);
		$t->close();
		return 1;
	}
	elsif ($env{'r_table'} eq "offer")
	{
		my @IDs=App::020::SQL::functions::get_ID_entity
		(
			'ID_entity' => $env{'r_ID_entity'},
			'db_h' => 'main',
			'db_name' => $App::950::db_name,
			'tb_name' => 'a950_offer',
		);
		if ($IDs[0]->{'ID'})
		{
			App::020::SQL::functions::update(
				'ID' => $IDs[0]->{'ID'},
				'db_h' => 'main',
				'db_name' => $App::950::db_name,
				'tb_name' => 'a950_offer',
				'columns' =>
				{
					'posix_owner' => "'".$env{'posix_owner'}."'"
				},
				'-journalize' => 1,
				'-posix' => 1
			);
			$t->close();
			return 1;
		}
	}
	
	$t->close();
	return undef;
}



1;
