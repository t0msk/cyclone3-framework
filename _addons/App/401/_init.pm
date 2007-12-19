#!/bin/perl
package App::401;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;


=head1 NAME

Application 401 - Articles

=head1 DESCRIPTION

Application which manages content in articles

=cut

BEGIN {main::_log("<={LIB} ".__PACKAGE__);}

our $VERSION='$Rev$';


=head1 SYNOPSIS

 use App::401::_init;

=cut

=head1 DEPENDS

=over

=item *

L<App::020::_init|app/"020/_init.pm">

=item *

L<App::300::_init|app/"300/_init.pm">

=item *

L<App::401::mimetypes|app/"401/mimetypes.pm">

=back

=cut

use App::020::_init; # data standard 0
use App::300::_init;
use App::401::mimetypes;


=head1 CONFIGURATION

 $db_name
 $priority_A_level=1
 $priority_B_level=undef
 $priority_C_level=undef

=cut

our $db_name=$App::401::db_name || $TOM::DB{'main'}{'name'};
our $priority_A_level=$App::401::priority_A_level || 1;
our $priority_B_level=$App::401::priority_B_level || undef;
our $priority_C_level=$App::401::priority_C_level || undef;



=head1 AUTHOR

Comsultia, Ltd. (open@comsultia.com)

=cut

1;
