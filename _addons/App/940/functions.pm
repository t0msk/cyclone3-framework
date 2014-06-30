#!/bin/perl
package App::940::functions;

=head1 NAME

App::940::functions

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

L<App::940::_init|app/"940/_init.pm">

=item *

L<TOM::Security::form|lib/"TOM/Security/form.pm">

=back

=cut

use App::940::_init;
use TOM::Security::form;
use App::160::SQL;
use POSIX qw(ceil);

our $debug=1;
our $quiet;$quiet=1 unless $debug;



=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
