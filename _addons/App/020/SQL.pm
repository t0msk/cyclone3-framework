#!/bin/perl
package App::020::SQL;

=head1 NAME

App::020::SQL

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DESCRIPTION

This library only loads all needed SQL libs into L<a020|app/"020/">

=cut

=head1 DEPENDS

=over

=item *

L<App::020::_init|app/"020/_init.pm">

=item *

L<App::020::SQL::functions|app/"020/SQL/functions.pm">

=back

=cut

use App::020::_init;
use App::020::SQL::functions;

1;
