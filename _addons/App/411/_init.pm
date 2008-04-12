#!/bin/perl
package App::411;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;


=head1 NAME

Application 411 - Polls

=head1 DESCRIPTION

Application which manages content in polls

=cut

BEGIN {main::_log("<={LIB} ".__PACKAGE__);}

our $VERSION='$Rev$';


=head1 SYNOPSIS

 use App::411::_init;

=cut

=head1 DEPENDS

=over

=item *

L<App::020::_init|app/"020/_init.pm">

=item *

L<App::301::_init|app/"301/_init.pm">

=item *

L<App::411::functions|app/"411/functions.pm">

=item *

L<App::411::a160|app/"411/a160.pm">

=back

=cut

use App::020::_init; # data standard 0
use App::301::_init;
use App::411::functions;
use App::411::a160;


=head1 CONFIGURATION

 $db_name

=cut

our $db_name=$App::411::db_name || $TOM::DB{'main'}{'name'};



=head1 AUTHOR

Comsultia, Ltd. (open@comsultia.com)

=cut

1;
