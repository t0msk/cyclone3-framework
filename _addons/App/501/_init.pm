#!/bin/perl
package App::501;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;


=head1 NAME

Application 501 - Images

=head1 DESCRIPTION

Application which manages images and its formats

=cut

BEGIN {main::_log("<={LIB} ".__PACKAGE__)}

our $VERSION='$Rev$';



=head1 SYNOPSIS

 use App::501::_init;

=cut

=head1 DEPENDS

=over

=item *

L<App::020::_init|app/"020/_init.pm">

=item *

L<App::301::_init|app/"301/_init.pm">

=item *

L<App::501::functions|app/"501/functions.pm">

=item *

L<App::501::a160|app/"501/a160.pm">

=item *

File::Copy

=item *

File::Path

=back

=cut

use App::020::_init; # data standard 0
use App::301::_init;
use App::501::functions;
use App::501::a160;
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
		if ($tom::P)
		{
			
			if (!-e $tom::P.'/!media/a501/image/file')
			{
				File::Path::mkpath $tom::P.'/!media/a501/image/file';
			}
			
			if (!-e $tom::P.'/!media/a501/image/file_j')
			{
				main::_log("creating path $tom::P/!media/a501/image/file_j");
				File::Path::mkpath $tom::P.'/!media/a501/image/file_j';
			}
			
			if (!-e $tom::P.'/!media/a501/image/file_j/.htaccess')
			{
				open (HND,'>'.$tom::P.'/!media/a501/image/file_j/.htaccess');
				print HND $htaccess_j;
				close HND;
			}
			
		}
	};
	alarm 0;
}



our $db_name=$App::501::db_name || $TOM::DB{'main'}{'name'};
our $image_format_ext_default=$App::501::image_format_ext_default || 'jpg';


our $image_format_original_ID;
our $image_format_fullsize_ID;
our $image_format_thumbnail_ID;


my $sql=qq{
	SELECT ID
	FROM `$db_name`.a501_image_format
	WHERE name='original'
	LIMIT 1;
};
my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
my %db0_line=$sth0{'sth'}->fetchhash();
if (!$db0_line{'ID'})
{
	$image_format_original_ID=App::020::SQL::functions::tree::new(
		'db_h' => 'main',
		'db_name' => $db_name,
		'tb_name' => 'a501_image_format',
		'columns' =>
		{
			'name' => "'original'",
			'status' => "'L'"
		}
	);
}
else
{
	$image_format_original_ID=$db0_line{'ID'};
}


if ($image_format_original_ID)
{
	
	my $sql=qq{
		SELECT ID
		FROM `$db_name`.a501_image_format
		WHERE name='fullsize'
		LIMIT 1;
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	my %db0_line=$sth0{'sth'}->fetchhash();
	if (!$db0_line{'ID'})
	{
		$image_format_fullsize_ID=App::020::SQL::functions::tree::new(
			'parent_ID' => $image_format_original_ID,
			'db_h' => 'main',
			'db_name' => $db_name,
			'tb_name' => 'a501_image_format',
			'columns' =>
			{
				'name' => "'fullsize'",
				'process' => "'scale(640,480)'",
				'status' => "'L'"
			}
		);
	}
	else
	{
		$image_format_fullsize_ID=$db0_line{'ID'};
	}
	
	
	my $sql=qq{
		SELECT ID
		FROM `$db_name`.a501_image_format
		WHERE name='thumbnail'
		LIMIT 1;
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	my %db0_line=$sth0{'sth'}->fetchhash();
	if (!$db0_line{'ID'})
	{
		$image_format_thumbnail_ID=App::020::SQL::functions::tree::new(
			'parent_ID' => $image_format_fullsize_ID,
			'db_h' => 'main',
			'db_name' => $db_name,
			'tb_name' => 'a501_image_format',
			'columns' =>
			{
				'name' => "'thumbnail'",
				'process' => "'scale(80,80)'",
				'status' => "'L'"
			}
		);
	}
	else
	{
		$image_format_thumbnail_ID=$db0_line{'ID'};
	}
}


1;
