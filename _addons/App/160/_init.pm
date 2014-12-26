#!/bin/perl
package App::160;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

=head1 NAME

Application 160 - XRelated

=head1 DESCRIPTION

Application which creates relations between other applications

=cut

BEGIN {main::_log("<={LIB} ".__PACKAGE__);}

=head1 SYNOPSIS

 use App::160::_init;

=cut

=head1 DEPENDS

=over

=item *

L<App::160::SQL|app/"160/SQL.pm">

=back

=cut


our $db_name=$App::160::db_name || $TOM::DB{'main'}{'name'};

our $partners = $App::160::partners || [ 'partner'];

 


use App::160::SQL;


1;

=head1 AUTHOR

Comsultia, Ltd. (open@comsultia.com)

=cut
