package main;

=head1 NAME

Cyclone3 dependencies

=head1 DESCRIPTION

This perl library can check if all dependencies are available on system

This file is used by L<100-check_update.0.cron|app/"100/_mdl/100-check_update.0.cron"> script to send information about incomming upgrade and new required dependencies.

=head1 Perl libs

Described in source-code of this library

=cut



use POSIX; # perl
use Inline; # libinline-perl (debian)
use SVN::Core; # libsvn-perl (debian)
use SVG; # installation from sources
use MIME::Entity; # libmime-perl (debian) + libmime-types-perl (debian)
use DateTime; # libdatetime-perl (debian)
use XML::Generator; # libxml-generator-perl (debian)
use SOAP::Lite; # libsoap-lite-perl (debian)
use Net::SMTP; # libnet-smtpauth-perl (debian)
use Net::SSLeay; # libnet-ssleay-perl (debian)
use String::CRC32; # libstring-crc32-perl (debian)
use CGI::Fast; # libfcgi-perl + libcgi-fast-perl (debian)
use Parallel::ForkManager; # libparallel-forkmanager-perl
use Compress::Zlib; # libcompress-zlib-perl (debian) || libzlib-perl (ubuntu)
use File::Type; # libfile-type-perl (debian)


=head1 Other dependencies

 >=MySQL-5.0
 =Apache1.3 || >=Apache2.0
 ?inkscape  # convert SVG images to PNG and send stats emails
 ?memcached  # cache more effectively

=cut

# remove all used <a href="?|?<$main::ENV{'QUERY_STRING_FULL'}>... and use this new form <a href="?|?|...

1;