#!/bin/perl
package App::440;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;


=head1 NAME

Application 440 - Promo

=head1 DESCRIPTION

Application which manages promo_item content

=cut

BEGIN {main::_log("<={LIB} ".__PACKAGE__);}

our $VERSION='1';


=head1 SYNOPSIS

 use App::440::_init;

=cut

=head1 DEPENDS

=over

=item *

L<App::020::_init|app/"020/_init.pm">

=item *

L<App::301::_init|app/"301/_init.pm">

=item *

L<App::401::functions|app/"401/functions.pm">

=item *

L<App::440::functions|app/"440/functions.pm">

=item *

L<App::440::a160|app/"440/a160.pm">

=item *

L<App::440::a301|app/"440/a301.pm">

=back

=cut

use TOM::Template;
use App::020::_init; # data standard 0
use App::301::_init;
use App::401::mimetypes;
use App::440::functions;
use App::440::a160;
use App::440::a301;


=head1 CONFIGURATION

 $db_name

=cut

our $db_name=$App::440::db_name || $TOM::DB{'main'}{'name'};
our %priority;
our $metadata_default=$App::440::metadata_default || qq{
<metatree>
</metatree>
};

=head1 AUTHOR

Comsultia, Ltd. (open@comsultia.com)

=cut

1;
