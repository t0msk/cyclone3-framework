#!/bin/perl
package App::8021;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;


=head1 NAME

Application 8021 - Internal messages

=head1 DESCRIPTION

Application which allow to registered users send messages

=cut

BEGIN {main::_log("<={LIB} ".__PACKAGE__);}

our $VERSION='1';


=head1 SYNOPSIS

 use App::8021::_init;

=cut

=head1 DEPENDS

=over

=item *

L<App::020::_init|app/"020/_init.pm">

=item *

L<App::300::_init|app/"300/_init.pm">

=back

=cut

use App::020::_init; # data standard 0
use App::300::_init;


=head1 CONFIGURATION

 $db_name

=cut

our $db_name=$App::8021::db_name || $TOM::DB{'main'}{'name'};



=head1 AUTHOR

Comsultia, Ltd. (open@comsultia.com)

=cut

1;
