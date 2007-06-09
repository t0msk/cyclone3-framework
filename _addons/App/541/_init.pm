#!/bin/perl
package App::541;

=head1 NAME

App::541

=cut

use open ':utf8', ':std';
use encoding 'utf8';
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
		
		if (!-e $tom::P.'/!media/a541/files')
		{
			File::Path::mkpath $tom::P.'/!media/a541/files';
		}
		
		if (!-e $tom::P.'/!media/a541/.htaccess')
		{
			open (HND,'>'.$tom::P.'/!media/a541/.htaccess');
			print HND $htaccess;
			close HND;
		}
		
	}
	
}

use App::020::_init; # data standard 0
use App::541::functions;

1;
