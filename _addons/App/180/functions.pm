#!/bin/perl
package App::180::functions;

=head1 NAME

App::180::functions

=head1 DESCRIPTION


=cut

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


=head1 DEPENDS

=over

=item *

L<App::180::_init|app/"180/_init.pm">

=item *

L<TOM::Security::form|lib/"TOM/Security/form.pm">

=back

=cut

use App::180::_init;

use TOM::Security::form;
use Time::HiRes qw(usleep);
use WWW::Mechanize;
use HTTP::Cookies;

our $debug=0;
our $quiet; $quiet=1 unless $debug;

=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
