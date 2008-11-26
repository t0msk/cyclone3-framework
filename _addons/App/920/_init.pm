#!/bin/perl
package App::920;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;


=head1 NAME

Application 920 - Orders

=head1 DESCRIPTION

Application which manages orders

=cut

BEGIN {main::_log("<={LIB} ".__PACKAGE__);}

our $VERSION='$Rev$';


=head1 SYNOPSIS

 use App::920::_init;

=cut

=head1 DEPENDS

=over

=item *

L<App::020::_init|app/"020/_init.pm">

=item *

L<App::301::_init|app/"301/_init.pm">

=item *

L<App::920::a160|app/"920/a160.pm">

=item *

L<App::920::a301|app/"920/a301.pm">

=back

=cut

use TOM::Template;
use TOM::Utils::currency;
use App::020::_init; # data standard 0
use App::301::_init;
use App::920::a160;
use App::920::a301;
#use App::710::functions;


our $db_name=$App::920::db_name || $TOM::DB{'main'}{'name'};





=head1 AUTHOR

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
