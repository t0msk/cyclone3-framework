#!/bin/perl
package App::430::functions;

=head1 NAME

App::430::functions

=head1 DESCRIPTION



=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
use charnames ':full';
our $soft_hyphen="\N{SOFT HYPHEN}";
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 DEPENDS

=over

=item *

L<App::430::_init|app/"430/_init.pm">

=item *

L<TOM::Security::form|lib/"TOM/Security/form.pm">

=back

=cut

use App::430::_init;
use TOM::Security::form;
use Time::HiRes qw(usleep);
use Ext::TextHyphen::_init;

our $debug=0;
our $quiet;$quiet=1 unless $debug;

=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
