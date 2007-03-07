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

Initial library of generic application L<020|app/"020/">.

=cut

=head1 SYNOPSIS

 use App::020::_init;
 
 my $ID=App::020::SQL::functions::new
 (
  'db_name' => $TOM::DB{'main'}{'name'},
  'tb_name' => 'a020_object',
  'columns'=>
  {
   'column1' => "'value'",
   'column2' => "NOW()",
   'column3' => "NULL"
  },
  '-journalize' => 1
 );
 
 my $scalar=App::020::SQL::functions::to_trash
 (
  'ID' => $ID,
  'db_name' => $TOM::DB{'main'}{'name'},
  'tb_name' => 'a020_object',
  '-journalize' => 1
 );
 
 my %columns=App::020::SQL::functions::get_ID
 (
  'ID' => $ID,
  'db_name' => $TOM::DB{'main'}{'name'},
  'tb_name' => 'a020_object',
  'columns'=> { '*' => 1 }
 );
 
=cut

=head1 DEPENDS

=over

=item *

L<App::020::SQL|app/"020/SQL.pm">

=item *

L<App::020::SQL::functions|app/"020/SQL/functions.pm">

=item *

L<App::020::a160|app/"020/a160.pm">

=back

=cut

use App::020::SQL;
use App::020::SQL::functions;
use App::020::a160;

our $VERSION='$Rev$';

=head1 SEE ALSO

=over

=item *

L<DATA standard|standard/"DATA">

=item *

L<API standard|standard/"API">

=item *

L<a020 database structure|app/"020/a020_struct.sql">

=back

=cut

=head1 AUTHORS

Roman Fordinal (roman.fordinal@comsultia.com)

=cut

1;
