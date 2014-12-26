#!/bin/perl
package App::210::a160;

=head1 NAME

App::210::a160

=cut
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DESCRIPTION

a160 enhancement to a210

=cut

=head1 DEPENDS

=over

=item *

L<App::210::_init|app/"210/_init.pm">

=item *

L<App::020::_init|app/"020/_init.pm">

=item *

L<App::020::a160|app/"020/a160.pm">

=back

=cut

use App::210::_init;
use App::020::_init;
use App::020::a160;

our $VERSION='1';
our $DEBUG;
our %def=(
	'db_h' => 'main',
	'table' =>
	{
		'page' =>
		{
			'name_column' => 'name',
			'type_name' => 'Sitemap page',
			'db_h' => 'main'
		}
	}
);
sub def {return %def};
our @ISA=("App::020::a160");


1;