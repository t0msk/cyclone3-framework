#!/bin/perl
package App::830;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

=head1 NAME

Application 830 - Forms

=head1 DESCRIPTION

Application which creates formulars

=cut

BEGIN {main::_log("<={LIB} ".__PACKAGE__);}

our $VERSION='1';



use TOM::Template;
use TOM::Utils::currency;
use App::020::_init; # data standard 0
use App::830::a160;
use App::301::_init;
use App::830::functions;


our $db_name=$App::830::db_name || $TOM::DB{'main'}{'name'};


1;

=head1 AUTHOR

Comsultia, Ltd. (open@comsultia.com)

=cut
