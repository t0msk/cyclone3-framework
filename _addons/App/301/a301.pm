#!/bin/perl
package App::301::a301;

=head1 NAME

App::301::a301

=cut
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DESCRIPTION

a301 enhancement to a301 :-)

=cut

=head1 DEPENDS

=over

=item *

L<App::301::_init|app/"301/_init.pm">

=item *

L<App::301::perm|app/"301/perm.pm">

=item *

L<App::020::_init|app/"020/_init.pm">

=back

=cut

use App::301::_init;
use App::301::perm;
use App::020::_init;


our $VERSION='1';


# addon functions
our %functions=(
	
	'addon' => 1,
	'contact.addon' => 1,
#	'data.user_group' => 1,
	
	# user data
#	'data.user_group.tree' => 1,
	
#	'data.user.tree' => 1,
	
	# actions
#	'action.user_group.create' => 1,
#	'action.user_group.enable' => 1,
#	'action.user_group.trash' => 1,
	
#	'action.user.enable' => 1,
	
#	'action.user.create' => 1,
);


# addon roles
our %roles=(
	
	'addon' => [
		'addon',
#		'action.user_group.enable',
#		'action.user_group.trash',
	],
	
	'contact.addon' => [
		'contact.addon',
	],
	
#	'user_group' => [
#		'data.user_group',
#		'action.user_group.enable',
#		'action.user_group.trash',
#	],
	
#	'user_group.create' => [
#		'data.user_group.tree',
#		'action.user_group.create',
#	],
	
#	'user.create' => [
#		'data.user_group.tree',
#		'action.user.create'
#	],
	
#	'user.public_data' => [
#		'data.user_group.tree',
#		'action.user.create'
#	],
	
#	'user.private_data' => [
#		'data.user_group.tree',
#		'action.user.create'
#	],
	
#	'user.other_contacts' => [
#		'data.user_group.tree',
#		'action.user.create'
#	],
	
);


# default groups related to addon roles with defined permissions
our %groups=(
	'world' => {
#		'user' => 'r  '
#		'user_group' => 'r  '
	},
	'editor' => {
		'addon' => 'r  ',
		'contact.addon' => 'rwx',
#		'user' => 'r  ',
#		'user.public_data' => 'rwx',
#		'user.private_data' => 'rwx',
#		'user.other_contacts' => 'rwx',
	}
);


# ACL role override
our %ACL_roles=(
#	'owner' => {
#		'user.public_data' => 'rwx',
#		'user.private_data' => 'rwx',
#		'user_group' => 'rwx',
#	},
#	'guest' => {
#		'user.public_data' => 'r  ',
#	},
#	'manager' => {
#		'user.private_data' => 'rwx',
#	},
);


# register this definition

App::301::perm::register(
	'addon' => 'a301',
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
	
	if ($env{'r_table'} eq "user_group")
	{
		my $sql=qq{
			SELECT
				posix_owner
			FROM
				`$App::301::db_name`.a301_user_group
			WHERE
				ID_entity='$env{'r_ID_entity'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>'main','quiet'=>1);
		my %db0_line=$sth0{'sth'}->fetchhash();
		main::_log("owner='$db0_line{'posix_owner'}'");
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
	
	if ($env{'r_table'} eq "user_group")
	{
		App::020::SQL::functions::update(
			'ID' => $env{'r_ID_entity'},
			'db_h' => 'main',
			'db_name' => $App::301::db_name,
			'tb_name' => 'a301_user_group',
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
	
	$t->close();
	return undef;
}



1;
