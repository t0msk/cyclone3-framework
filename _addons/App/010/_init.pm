#!/bin/perl
package App::010;

=head1 NAME

App::010

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DESCRIPTION

Initial library of generic local application L<010|app/"010/">.

=cut

our $db_name=$App::010::db_name || $TOM::DB{'main'}{'name'};
main::_log("db_name=$db_name");

1;
