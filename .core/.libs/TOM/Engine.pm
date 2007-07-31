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

3rd party knižnice

 DateTime
 Time::Local
 Time::HiRes
 Digest::MD5
 SVG
 Term::ANSIColor

=cut

use Fcntl; # 300KB

use CVML;

use TOM::Debug;
use TOM::rev;
use TOM::Error;
use TOM::Warning;
use TOM::Temp::file;

# default aplikácie
use App::100::_init; # Ticket system

use DateTime; # mem:1.5MB
use Time::Local; # pre opacnu konverziu casu
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );
use Digest::MD5  qw( md5 md5_hex md5_base64 );
use SVG;
use Term::ANSIColor;

1;