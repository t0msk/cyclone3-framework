#!/bin/perl
package App::930::a301;

=head1 NAME

App::930::a301

=cut
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DESCRIPTION

a301 enhancement to a930

=cut

=head1 DEPENDS

=over

=item *

L<App::930::_init|app/"930/_init.pm">

=item *

L<App::301::perm|app/"301/perm.pm">

=item *

L<App::020::_init|app/"020/_init.pm">

=back

=cut

use App::910::_init;
use App::301::perm;
use App::020::_init;


our $VERSION='1';


# addon functions
our %functions=(
	'addon' => 1,
	'data.rfp.details' => 1,
	'data.rfp.thumbnail' => 1,
	'data.rfp_cat.details' => 1,
	'action.rfp.trash' => 1,
	'action.rfp.new' => 1,
	'action.rfp_cat.new' => 1,
	'action.rfp_cat.trash' => 1,
	'publish.rfp' => 1,
	'publish.rfp_cat' => 1
);


# addon roles
our %roles=(
	'addon' => [
		'addon'
	],
	'rfp.data' => [
		'data.rfp.details',
		'data.rfp.thumbnail'
	],
	'rfp.action' => [
		'action.rfp.trash',
		'action.rfp.new'
	],
	'rfp_cat.data' =>
	[
		'action.rfp_cat.details'
	],
	'rfp_cat.action' =>
	[
		'action.rfp_cat.new',
		'action.rfp_cat.trash'
	],
	'rfp_cat.publish' =>
	[
		'rfp_cat.publish'
	],
	'rfp.publish' =>
	[
		'rfp.publish'
	]
);


# default groups related to addon roles with defined permissions
our %groups=(
	'world' => {
#		'poll' => 'r  '
	},
	'editor' => {
		'addon' => 'rwx',
		'rfp.data' => 'rwx',
		'rfp.action' => 'rwx',
		'rfp.publish' => 'rwx',
		'rfp_cat.data' => 'rwx',
		'rfp_cat.action' => 'rwx',
		'rfp_cat.publish' => 'rwx'
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
	'addon' => 'a930',
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
	
	if ($env{'r_table'} eq "rfp")
	{
		my $sql=qq{
			SELECT
				posix_owner
			FROM
				`$App::930::db_name`.a930_rfp
			WHERE
				ID_entity='$env{'r_ID_entity'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>'main','quiet'=>1,'-slave'=>0);
		my %db0_line=$sth0{'sth'}->fetchhash();
		$t->close();
		return $db0_line{'posix_owner'};
	}
	elsif ($env{'r_table'} eq "rfp_cat")
	{
		my $sql=qq{
			SELECT
				posix_owner
			FROM
				`$App::910::db_name`.a930_rfp_cat
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
	
	if ($env{'r_table'} eq "rfp_cat")
	{
		App::020::SQL::functions::update(
			'ID' => $env{'r_ID_entity'},
			'db_h' => 'main',
			'db_name' => $App::930::db_name,
			'tb_name' => 'a930_rfp_cat',
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
	elsif ($env{'r_table'} eq "rfp")
	{
		my @IDs=App::020::SQL::functions::get_ID_entity
		(
			'ID_entity' => $env{'r_ID_entity'},
			'db_h' => 'main',
			'db_name' => $App::930::db_name,
			'tb_name' => 'a930_rfp',
		);
		if ($IDs[0]->{'ID'})
		{
			App::020::SQL::functions::update(
				'ID' => $IDs[0]->{'ID'},
				'db_h' => 'main',
				'db_name' => $App::930::db_name,
				'tb_name' => 'a930_rfp',
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
