package TOM::Engine;

=head1 NAME

TOM::Engine

=head1 DESCRIPTION

Universal Cyclone3 engine loader.

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DEPENDS

=over

=item *

Fcntl

=item *

Time::Local

=item *

Time::HiRes

=item *

Digest::MD5

=item *

Datetime

=item *

Term::ANSIColor

=item *

L<TOM::Debug|source-doc/".core/.libs/TOM/Debug.pm">

=item *

L<TOM::rev|source-doc/".core/.libs/TOM/rev.pm">

=item *

L<TOM::Error|source-doc/".core/.libs/TOM/Error.pm">

=item *

L<TOM::Temp::file|source-doc/".core/.libs/TOM/Temp/file.pm">

=item *

L<CVML|source-doc/".core/.libs/CVML.pm">

=item *

L<App::100::_init|app/"100/_init.pm">

=back

=cut

use Fcntl; # 300KB

use Time::Local; # pre opacnu konverziu casu
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );
use Digest::MD5  qw( md5 md5_hex md5_base64 );
use DateTime; # mem:1.5MB
use Term::ANSIColor;

use TOM::Debug;
use TOM::rev;
use TOM::Error;
use TOM::Warning;
use TOM::Temp::file;
use CVML;

# default aplikácie
use App::100::_init; # Ticket system

1;