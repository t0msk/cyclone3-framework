#!/bin/perl
package App::821;
use open ':utf8', ':std';
use Encode;
use encoding 'utf8';
use utf8;
use strict;



=head1 NAME

Application 821 - Discussions

=head1 DESCRIPTION

Application which manages discussions

=cut

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 SYNOPSIS

 use App::821::_init;

=cut

=head1 DEPENDS

=over

=item *

L<App::301::_init|app/"301/_init.pm">

=item *

L<App::821::a160|app/"821/a160.pm">

=back

=cut

use App::821::a160;
use App::301::_init;



our $db_name=$App::821::db_name || $TOM::DB{'main'}{'name'};



=head1 AUTHOR

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
