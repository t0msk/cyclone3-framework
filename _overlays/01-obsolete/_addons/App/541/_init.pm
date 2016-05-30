#!/bin/perl
package App::541;

=head1 NAME

App::541

=cut

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our $VERSION='$Rev$';

use File::Path;

BEGIN
{
	
	my $htaccess=qq{
	# safe data
		RewriteEngine Off
		Deny from All
	};
	
	# check media directory
	if ($tom::P)
	{
		
		if (!-e $tom::P_media.'/a541/files')
		{
			File::Path::mkpath $tom::P_media.'/a541/files';
		}
		
		if (!-e $tom::P_media.'/a541/.htaccess')
		{
			open (HND,'>'.$tom::P_media.'/a541/.htaccess');
			print HND $htaccess;
			close HND;
		}
		
	}
	
}

our $db_name=$App::541::db_name || $TOM::DB{'main'}{'name'};


=head1 DEPENDS

=over

=item *

L<App::020::_init|app/"020/_init.pm">

=item *

L<App::541::functions|app/"541/functions.pm">

=item *

L<App::541::preview|app/"541/preview.pm">

=item *

L<App::541::mimetypes|app/"541/mimetypes.pm">

=item *

File::Path

=back

=cut

use App::020::_init; # data standard 0
use App::541::functions;
use App::541::preview;
use App::541::mimetypes;


=head1 AUTHORS

Roman Fordinal (roman.fordinal@comsultia.com)

=cut


1;
