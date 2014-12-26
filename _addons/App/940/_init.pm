#!/bin/perl
package App::940;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;


=head1 NAME

Application 940 - Coupons

=head1 DESCRIPTION

Coupons

=cut

BEGIN {main::_log("<={LIB} ".__PACKAGE__);}

our $VERSION='1';


=head1 SYNOPSIS

 use App::940::_init;

=cut

=head1 DEPENDS

=over

=item *

L<App::020::_init|app/"020/_init.pm">

=item *

L<App::301::_init|app/"301/_init.pm">

=item *

L<App::940::a160|app/"940/a160.pm">

=item *

L<App::940::a301|app/"940/a301.pm">

=item *

L<App::940::functions|app/"940/functions.pm">

=back

=cut

use TOM::Template;
use TOM::Utils::currency;
use App::020::_init; # data standard 0
use App::301::_init;
use App::940::a020;
use App::940::a160;
use App::940::a301;
use App::940::functions;

our $db_name=$App::940::db_name || $TOM::DB{'main'}{'name'};

=head1 AUTHOR

Comsultia, Ltd. (open@comsultia.com)

=cut

1;
