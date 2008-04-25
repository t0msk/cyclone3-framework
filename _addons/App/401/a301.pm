#!/bin/perl
package App::401::a301;

=head1 NAME

App::401::a301

=cut
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DESCRIPTION

a301 enhancement to a401

=cut

=head1 DEPENDS

=over

=item *

L<App::401::_init|app/"401/_init.pm">

=item *

L<App::301::perm|app/"301/perm.pm">

=item *

L<App::020::_init|app/"020/_init.pm">

=back

=cut

use App::401::_init;
use App::301::perm;
use App::020::_init;


our $VERSION='$Rev$';


# addon functions
our %functions=(
	# article data
	'data.article.visits' => 1,
	'data.article.title' => 1,
	'data.article.datetime_start' => 1,
	'data.article.datetime_stop' => 1,
	'data.article.priority_A' => 1,
	'data.article.priority_B' => 1,
	'data.article.priority_C' => 1,
	'data.article.editor' => 1,
	'data.article.subtitle' => 1,
	'data.article.content' => 1,
	
	# actions
	'action.article.enable' => 1,
);


# addon roles
our %roles=(
	'article.content' => [
		'data.article.title',
		'data.article.subtitle',
		'data.article.content',
	],
	'article.planning' => [
		'data.article.datetime_start',
		'data.article.datetime_stop',
		'data.article.priority_A',
		'data.article.priority_B',
		'data.article.priority_C'
	],
	'article.publishing' => [
		'action.article.enable'
	],
);


# default groups related to addon roles with defined permissions
our %groups=(
	'world' => {
		'article.content' => 'r--'
	},
	'editor' => {
		'article.content' => 'rwx',
		'article.planning' => 'rwx',
		'article.publishing' => 'rwx'
	}
);



# register this definition

App::301::perm::register(
	'addon' => 'a401',
	'functions' => \%functions,
	'roles' => \%roles,
	'groups' => \%groups
);



1;