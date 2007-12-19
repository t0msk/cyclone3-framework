#!/bin/perl
package App::401::mimetypes::html;

=head1 NAME

App::401::mimetypes

=head1 DESCRIPTION

Handle different mimetypes in article

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 DEPENDS

=over

=item *

L<App::401::_init|app/"401/_init.pm">

=item *

L<App::401::mimetypes::html|app/"401/mimetypes/html.pm">

=back

=cut

use App::401::_init;
use App::401::mimetypes::html;



=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
