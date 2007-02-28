#!/bin/perl
package App::020;

=head1 NAME

App::020

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DESCRIPTION

Initial library of generic App 020.

=cut

=head1 SYNOPSIS

 use App::020::_init;

=cut

=head1 DEPENDS

=over

=item *

L<App::020::SQL|app/"020/SQL.pm">

=back

=cut

use App::020::SQL;


=head1 SEE ALSO

L<DATA standard|standard/"DATA">, L<API standard|standard/"API">

=cut

=head1 AUTHORS

Roman Fordinal (roman.fordinal@comsultia.com)

=cut

1;
