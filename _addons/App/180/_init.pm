#!/bin/perl
package App::180;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;


=head1 NAME

Application 180 - Crawler

=head1 DESCRIPTION

Application crawls web pages and harvests data

=cut

BEGIN {main::_log("<={LIB} ".__PACKAGE__);}

our $VERSION='1';


=head1 SYNOPSIS

 use App::180::_init;

=cut

=head1 DEPENDS

=over

=item *

L<App::020::_init|app/"020/_init.pm">

=back

=cut

use App::020::_init; # data standard 0


our $db_name=$App::180::db_name || $TOM::DB{'main'}{'name'};
main::_log("db_name=$db_name");


# this should be defined in the local conf of a domain (later)


=head1 AUTHOR

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
