package TOM::Engine;

=head1 NAME

TOM::Engine

=head1 DESCRIPTION

Univerzálny zavádzač všetkých engines.

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DEPENDS

knižnice:

 Fcntl
 TOM::Debug
 TOM::rev
 TOM::Error
 TOM::Temp::file

=cut

use Fcntl;

use TOM::Debug;
use TOM::rev;
use TOM::Error;
use TOM::Temp::file;

1;