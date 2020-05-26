#!/bin/perl
package App::210;

=head1 NAME

App::210

=cut

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our $VERSION='1';

use App::020::_init; # data standard 0
use App::210::SQL;
use App::210::a160;
use App::210::a301;

our $db_name=$App::210::db_name || $TOM::DB{'main'}{'name'};
main::_log("db_name='$db_name'");
our $metadata_default=$App::210::metadata_default || qq{
<metatree>
	<section name="Others"></section>
</metatree>
};

1;
