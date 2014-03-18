#!/bin/perl
package App::430;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;


=head1 NAME

Application 430 - List

=head1 DESCRIPTION

Application which manages lists of other content

=cut

BEGIN {main::_log("<={LIB} ".__PACKAGE__);}

our $VERSION='1';


=head1 SYNOPSIS

 use App::430::_init;

=cut

=head1 DEPENDS

=over

=item *

L<App::020::_init|app/"020/_init.pm">

=item *

L<App::301::_init|app/"301/_init.pm">

=item *

L<App::430::functions|app/"430/functions.pm">

=item *

L<App::430::a160|app/"430/a160.pm">

=item *

L<App::430::a301|app/"430/a301.pm">

=back

=cut

use TOM::Template;
use App::020::_init; # data standard 0
use App::301::_init;
use App::430::functions;
use App::430::a160;
use App::430::a301;


=head1 CONFIGURATION

 $db_name

=cut

our $db_name=$App::430::db_name || $TOM::DB{'main'}{'name'};
our %priority;
our $metadata_default=$App::430::metadata_default || qq{
<metatree>
</metatree>
};

=head1 AUTHOR

Comsultia, Ltd. (open@comsultia.com)

=cut

1;
