#!/bin/perl
package App::740;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;


=head1 NAME

Application  - Job offer

=head1 DESCRIPTION

Application to manage job offers

=cut

BEGIN {main::_log("<={LIB} ".__PACKAGE__);}

our $VERSION='1';


=head1 SYNOPSIS

 use App::740::_init;

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

=head1 CONFIGURATION

 $db_name

=cut

our $db_name=$App::740::db_name || $TOM::DB{'main'}{'name'};
our %priority;
our $metadata_default=$App::740::metadata_default || qq{
<metatree>
</metatree>
};

=head1 AUTHOR

Comsultia, Ltd. (open@comsultia.com)

=cut

1;
