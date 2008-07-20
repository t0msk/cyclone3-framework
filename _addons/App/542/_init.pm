#!/bin/perl
package App::542;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;


=head1 NAME

Application 542 - File Storage

=head1 DESCRIPTION

Application which manages files and directories.

=cut

BEGIN {main::_log("<={LIB} ".__PACKAGE__)}

our $VERSION='$Rev$';



=head1 SYNOPSIS

 use App::542::_init;

=cut

=head1 DEPENDS

=over

=item *

L<App::020::_init|app/"020/_init.pm">

=item *

L<App::301::_init|app/"301/_init.pm">

=item *

L<App::542::mimetypes|app/"542/mimetypes.pm">

=item *

L<App::542::functions|app/"542/functions.pm">

=item *

L<App::542::a160|app/"542/a160.pm">

=item *

L<App::542::a301|app/"542/a301.pm">

=item *

File::Copy

=item *

File::Path

=back

=cut

use App::020::_init; # data standard 0
use App::301::_init;
use App::542::mimetypes;
use App::542::functions;
use App::542::a160;
use App::542::a301;
use File::Copy;
use File::Path;


BEGIN
{
	eval
	{
		alarm 1; # when media directory is a freezed network filesystem
		my $htaccess_j=qq{
		# safe data
			RewriteEngine Off
			Deny from All
		};
		
		# check media directory
		my $check=1;
		if ($tom::P && $check)
		{
			main::_log("checking a542 file directory");
			if (!-e $tom::P.'/!media/a542/file/item')
			{
				File::Path::mkpath $tom::P.'/!media/a542/file/item';
			}
			
			if (!-e $tom::P.'/!media/a542/file/item_j')
			{
				main::_log("creating path $tom::P/!media/a542/file/item_j");
				File::Path::mkpath $tom::P.'/!media/a542/file/item_j';
			}
			
			if (!-e $tom::P.'/!media/a542/file/item_j/.htaccess')
			{
				open (HND,'>'.$tom::P.'/!media/a542/file/item_j/.htaccess');
				print HND $htaccess_j;
				close HND;
			}
			
		}
	};
	alarm 0;
}



our $db_name=$App::542::db_name || $TOM::DB{'main'}{'name'};
$tom::H_a542=$tom::H_media."/a542" if (!$tom::H_a542 && $tom::H_media);


1;
