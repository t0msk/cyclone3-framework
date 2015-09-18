#!/bin/perl
package App::900::a301;

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use App::900::_init;
use App::301::perm;
use App::020::_init;


our $VERSION='1';


# addon functions
our %functions=(
	'addon' => 1,
	'data.banner.details' => 1,
	'data.banner_cat.details' => 1,
	'action.banner.trash' => 1,
	'action.banner.new' => 1,
	'action.banner_cat.new' => 1,
	'action.banner_cat.trash' => 1,
	'publish.banner' => 1,
	'publish.banner_cat' => 1
);


# addon roles
our %roles=(
	'addon' => [
		'addon'
	],
	'banner.data' => [
		'data.banner.details'
	],
	'banner.action' => [
		'action.banner.trash',
		'action.banner.new'
	],
	'banner_cat.data' =>
	[
		'action.banner_cat.details'
	],
	'banner_cat.action' =>
	[
		'action.banner_cat.new',
		'action.banner_cat.trash'
	],
	'banner_cat.publish' =>
	[
		'banner_cat.publish'
	],
	'banner.publish' =>
	[
		'banner.publish'
	]
);


# default groups related to addon roles with defined permissions
our %groups=(
	'world' => {
#		'poll' => 'r  '
	},
	'editor' => {
		'addon' => 'rwx',
		'banner.data' => 'rwx',
		'banner.action' => 'rwx',
		'banner.publish' => 'rwx',
		'banner_cat.data' => 'rwx',
		'banner_cat.action' => 'rwx',
		'banner_cat.publish' => 'rwx'
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
	'addon' => 'a900',
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
	
	if ($env{'r_table'} eq "banner")
	{
		my $sql=qq{
			SELECT
				posix_owner
			FROM
				`$App::900::db_name`.a900_banner
			WHERE
				ID_entity='$env{'r_ID_entity'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>'main','quiet'=>1,'-slave'=>0);
		my %db0_line=$sth0{'sth'}->fetchhash();
		$t->close();
		return $db0_line{'posix_owner'};
	}
	elsif ($env{'r_table'} eq "banner_cat")
	{
		my $sql=qq{
			SELECT
				posix_owner
			FROM
				`$App::910::db_name`.a900_banner_cat
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
	
	if ($env{'r_table'} eq "banner")
	{
		App::020::SQL::functions::update(
			'ID' => $env{'r_ID_entity'},
			'db_h' => 'main',
			'db_name' => $App::900::db_name,
			'tb_name' => 'a900_banner',
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
	elsif ($env{'r_table'} eq "banner_cat")
	{
		my @IDs=App::020::SQL::functions::get_ID_entity
		(
			'ID_entity' => $env{'r_ID_entity'},
			'db_h' => 'main',
			'db_name' => $App::900::db_name,
			'tb_name' => 'a900_banner_cat',
		);
		if ($IDs[0]->{'ID'})
		{
			App::020::SQL::functions::update(
				'ID' => $IDs[0]->{'ID'},
				'db_h' => 'main',
				'db_name' => $App::900::db_name,
				'tb_name' => 'a900_banner_cat',
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
