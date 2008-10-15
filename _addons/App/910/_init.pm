#!/bin/perl
package App::910;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;


=head1 NAME

Application 910 - Products catalog

=head1 DESCRIPTION

Application which manages products catalag

=cut

BEGIN {main::_log("<={LIB} ".__PACKAGE__);}

our $VERSION='$Rev$';


=head1 SYNOPSIS

 use App::910::_init;

=cut

=head1 DEPENDS

=over

=item *

L<App::020::_init|app/"020/_init.pm">

=item *

L<App::301::_init|app/"301/_init.pm">

=item *

L<App::401::mimetypes|app/"401/mimetypes.pm">

=item *

L<App::910::a160|app/"910/a160.pm">

=item *

L<App::910::a301|app/"910/a301.pm">

=item *

L<App::910::functions|app/"910/functions.pm">

=back

=cut

use TOM::Template;
use TOM::Utils::currency;
use App::020::_init; # data standard 0
use App::301::_init;
use App::401::mimetypes;
use App::910::a160;
use App::910::a301;
use App::910::functions;



=head1 CONFIGURATION

 $db_name
 $currency='EUR'

=cut

our $currency=$App::910::currency || 'EUR';
our $db_name=$App::401::db_name || $TOM::DB{'main'}{'name'};

=head1 AUTHOR

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
