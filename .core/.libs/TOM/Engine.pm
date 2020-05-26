package TOM::Engine;

=head1 NAME

TOM::Engine

=head1 DESCRIPTION

Universal Cyclone3 engine loader.

=cut

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
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

L<TOM::Template|source-doc/".core/.libs/TOM/Template.pm">

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
use Number::Bytes::Human;
use Proc::ProcessTable;

use TOM::Debug;
use TOM::rev;
use TOM::Error;
use TOM::Warning;
use TOM::Temp::file;
use TOM::Template;
use CVML;

sub jobify{main::_log("dummy jobify");return undef}

BEGIN
{
	# load if enabled in TOM.conf (to all engines)
	require Ext::Solr::_init if $Ext::Solr::url;
	require Ext::RabbitMQ::_init if $Ext::RabbitMQ::host;
	require Ext::Redis::_init if ($Ext::Redis::host || @Ext::Redis::hosts);
	require Ext::CacheMemcache::_init if $TOM::CACHE_memcached && !$Ext::CacheMemcache::cache;
	use TOM::Engine::job::module; # for every engine load support of jobs
	use TOM::request;
	# import document library for every engine
	eval "use TOM::Document::".$pub::DOC if $pub::DOC;
}

# default aplikácie
use App::020::_init; # standard 0
use App::100::_init; # Ticket system

1;
