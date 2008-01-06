#!/bin/perl
package App::541::mimetypes;

=head1 NAME

App::541::mimetypes

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

=head2 %ext

List of file extensions related to mimetypes

=cut

our %ext=(
	'avi' => 'video/x-msvideo',
	'docbook' => 'application/docbook+xml',
	'fli' => 'video/x-fli',
	'flv' => 'video/x-flv',
	'mov' => 'video/quicktime',
	'mpe' => 'video/mpeg',
	'mpeg' => 'video/mpeg',
	'mpg' => 'video/mpeg',
	'qt' => 'video/quicktime',
	'wmv' => 'video/x-ms-wmv',
	'xml' => 'text/xml',
);

our %mime=(
	'image/jpeg' => 'jpg',
	'image/x-png' => 'png',
	'image/gif' => 'gif',
);


our @filetype_ext=
(
	['Macromedia Flash Video' => 'flv'],
	['setgid sticky Microsoft ASF' => 'wmv'],
	['ISO Media, MPEG v4 system, version 1' => 'mp4'],
	['Microsoft ASF' => 'asf']
);


=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut

1;
