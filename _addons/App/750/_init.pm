#!/bin/perl
package App::750;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;


=head1 NAME

Application  - Real estate

=head1 DESCRIPTION

Application to manage real estate assets (complex, object, area)

=cut

BEGIN {main::_log("<={LIB} ".__PACKAGE__);}

our $VERSION='1';


=head1 SYNOPSIS

 use App::750::_init;

=cut

=head1 DEPENDS

=over

=item *

L<App::020::_init|app/"020/_init.pm">

=item *

L<App::301::_init|app/"301/_init.pm">

=item *

L<App::710::_init|app/"710/_init.pm"

=back

=cut

use TOM::Template;
use App::020::_init; # data standard 0
use App::301::_init;
use App::710::_init;
use App::750::functions;

=head1 CONFIGURATION

 $db_name

=cut

our $db_name=$App::750::db_name || $TOM::DB{'main'}{'name'};
our %priority;
our $metadata_default=$App::750::metadata_default || qq{
<metatree>
</metatree>
};

=head1 AUTHOR

Comsultia, Ltd. (open@comsultia.com)

=cut

1;
