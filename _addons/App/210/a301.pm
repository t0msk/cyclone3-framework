#!/bin/perl
package App::501::a301;

=head1 NAME

App::501::a301

=cut
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DESCRIPTION

a301 enhancement to a501

=cut

=head1 DEPENDS

=over

=item *

L<App::501::_init|app/"501/_init.pm">

=item *

L<App::301::perm|app/"301/perm.pm">

=item *

L<App::020::_init|app/"020/_init.pm">

=back

=cut

use App::210::_init;
use App::301::perm;
use App::020::_init;


our $VERSION='1';


# addon functions
our %functions=(
	'addon' => 1,
);


# addon roles
our %roles=(
	'addon' => [
		'addon'
	],
);


# default groups related to addon roles with defined permissions
our %groups=(
	'world' => {
#		'poll' => 'r  '
	},
	'editor' => {
		'addon' => 'rwx',
	}
);


# ACL role override
our %ACL_roles=(
	'owner' => {
#		'poll' => 'rwx',
	},
);


# register this definition

App::301::perm::register(
	'addon' => 'a210',
	'functions' => \%functions,
	'roles' => \%roles,
	'ACL_roles' => \%ACL_roles,
	'groups' => \%groups
);

1;