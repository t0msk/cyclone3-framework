#!/bin/perl
package App::541::preview;

=head1 NAME

App::541::preview

=head1 DESCRIPTION



=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 DEPENDS

=over

=item *

L<App::541::_init|app/"541/_init.pm">

=back

=cut

use App::541::_init;



=head1 VARIABLES

=head2 %mimetypes_selfpreview

List of mimetypes which can be previewed directly or with online transformation

=cut

our %mimetypes_selfpreview=(
	'video/x-flv' => 1,
	'application/docbook+xml' => 1
);



=head1 AUTHORS

Roman Fordinal (roman.fordinal@comsultia.com)

=cut

1;
