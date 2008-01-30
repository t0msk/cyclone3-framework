#!/bin/perl
package App::510;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;


=head1 NAME

Application 510 - Videos

=head1 DESCRIPTION

Application which manages videos and its formats. The only one support encoder is mencoder from mplayer package

Notice, L<a501|app/"501"> is used for storing thumbnail pictures.

=cut

BEGIN {main::_log("<={LIB} ".__PACKAGE__)}

our $VERSION='$Rev$';



=head1 SYNOPSIS

 use App::510::_init;

=cut

=head1 DEPENDS

=over

=item *

L<App::020::_init|app/"020/_init.pm">

=item *

L<App::301::_init|app/"301/_init.pm">

=item *

L<App::501::_init|app/"501/_init.pm">

=item *

L<App::510::functions|app/"510/functions.pm">

=item *

File::Copy

=item *

File::Path

=back

=cut

use App::020::_init; # data standard 0
use App::301::_init;
use App::501::_init;
use App::510::functions;
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
			main::_log("checking a510 media directory");
			if (!-e $tom::P.'/!media/a510/video/part/file')
			{
				File::Path::mkpath $tom::P.'/!media/a510/video/part/file';
			}
			
			if (!-e $tom::P.'/!media/a510/video/part/file_j')
			{
				main::_log("creating path $tom::P/!media/a510/video/part/file_j");
				File::Path::mkpath $tom::P.'/!media/a510/video/part/file_j';
			}
			
			if (!-e $tom::P.'/!media/a510/video/part/file_j/.htaccess')
			{
				open (HND,'>'.$tom::P.'/!media/a510/video/part/file_j/.htaccess');
				print HND $htaccess_j;
				close HND;
			}
			
		}
	};
	alarm 0;
}



our $db_name=$App::510::db_name || $TOM::DB{'main'}{'name'};
our $video_format_ext_default=$App::510::video_format_ext_default || 'avi';


our $video_format_original_ID;
our $video_format_full_ID;
our $video_format_preview_ID;


my $sql=qq{
	SELECT ID
	FROM `$db_name`.a510_video_format
	WHERE name='original'
	LIMIT 1;
};
my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
my %db0_line=$sth0{'sth'}->fetchhash();
if (!$db0_line{'ID'})
{
	$video_format_original_ID=App::020::SQL::functions::tree::new(
		'db_h' => 'main',
		'db_name' => $db_name,
		'tb_name' => 'a510_video_format',
		'columns' =>
		{
			'name' => "'original'",
			'status' => "'L'"
		},
		'-journalize' => 1
	);
}
else
{
	$video_format_original_ID=$db0_line{'ID'};
}

if ($video_format_original_ID)
{
	my $sql=qq{
		SELECT ID
		FROM `$db_name`.a510_video_format
		WHERE name='full'
		LIMIT 1;
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	my %db0_line=$sth0{'sth'}->fetchhash();
	if (!$db0_line{'ID'})
	{
		$video_format_full_ID=App::020::SQL::functions::tree::new(
			'parent_ID' => $video_format_original_ID,
			'db_h' => 'main',
			'db_name' => $db_name,
			'tb_name' => 'a510_video_format',
			'columns' =>
			{
				'name' => "'full'",
				'process' => "'scale(320,240)'",
				'status' => "'L'"
			},
			'-journalize' => 1
		);
	}
	else
	{
		$video_format_full_ID=$db0_line{'ID'};
	}
	
	my $sql=qq{
		SELECT ID
		FROM `$db_name`.a510_video_format
		WHERE name='preview'
		LIMIT 1;
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	my %db0_line=$sth0{'sth'}->fetchhash();
	if (!$db0_line{'ID'})
	{
		$video_format_preview_ID=App::020::SQL::functions::tree::new(
			'parent_ID' => $video_format_full_ID,
			'db_h' => 'main',
			'db_name' => $db_name,
			'tb_name' => 'a510_video_format',
			'columns' =>
			{
				'name' => "'preview'",
				'process' => "'crop(00:00:00,00:00:20)'",
				'status' => "'L'"
			},
			'-journalize' => 1
		);
	}
	else
	{
		$video_format_preview_ID=$db0_line{'ID'};
	}
}




# check relation to a501
our $thumbnail_cat_ID_entity;
our %thumbnail_cat;

# find any category;
my $sql="
	SELECT
		ID, ID_entity
	FROM
		`$App::501::db_name`.`a501_image_cat`
	WHERE
		name='video thumbnails' AND
		lng IN ('".(join "','",@TOM::LNG_accept)."')
	LIMIT 1
";
my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
if (my %db0_line=$sth0{'sth'}->fetchhash())
{
	$thumbnail_cat_ID_entity=$db0_line{'ID_entity'} unless $thumbnail_cat_ID_entity;
}
else
{
	$thumbnail_cat_ID_entity=App::020::SQL::functions::tree::new(
		'db_h' => "main",
		'db_name' => $App::501::db_name,
		'tb_name' => "a501_image_cat",
		'columns' => {
			'name' => "'video thumbnails'",
			'lng' => "'$tom::LNG'",
			'status' => "'L'"
		},
		'-journalize' => 1
	);
}

foreach my $lng(@TOM::LNG_accept)
{
	#main::_log("check related category $lng");
	my $sql=qq{
		SELECT
			ID, ID_entity
		FROM
			`$App::501::db_name`.`a501_image_cat`
		WHERE
			ID_entity=$thumbnail_cat_ID_entity AND
			lng='$lng'
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		$thumbnail_cat{$lng}=$db0_line{'ID'};
	}
	else
	{
		#main::_log("creating related category");
		$thumbnail_cat{$lng}=App::020::SQL::functions::tree::new(
			'db_h' => "main",
			'db_name' => $App::501::db_name,
			'tb_name' => "a501_image_cat",
			'columns' => {
				'ID_entity' => $thumbnail_cat_ID_entity,
				'name' => "'video thumbnails'",
				'lng' => "'$lng'",
				'status' => "'L'"
			},
			'-journalize' => 1
		);
	}
}


1;
