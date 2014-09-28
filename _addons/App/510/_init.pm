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

our $VERSION='1';
our $smil=$App::510::smil || 0;
our $smil2file_path=$App::510::smil2file_path || '../file';

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

L<App::510::a160|app/"510/a160.pm">

=item *

L<App::510::a301|app/"510/a301.pm">

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
use App::510::a160;
use App::510::a301;
require App::821::_init if $tom::addons{'a821'};
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
		my $check=0;
		if ($tom::P && $check)
		{
			main::_log("checking a510 media directory");
			if (!-e $tom::P_media.'/a510/video/part/file')
			{
				File::Path::mkpath $tom::P_media.'/a510/video/part/file';
			}
			
			if (!-e $tom::P_media.'/a510/video/part/file_j')
			{
				main::_log("creating path $tom::P_media/a510/video/part/file_j");
				File::Path::mkpath $tom::P_media.'/a510/video/part/file_j';
			}
			
			if (!-e $tom::P_media.'/a510/video/part/file_j/.htaccess')
			{
				open (HND,'>'.$tom::P_media.'/a510/video/part/file_j/.htaccess');
				print HND $htaccess_j;
				close HND;
			}
			
#			if ($smil && !-e $tom::P_media.'/a510/video/part/smil')
#			{
#				File::Path::mkpath $tom::P_media.'/a510/video/part/smil';
#				chmod (0777,$tom::P_media.'/a510/video/part/smil')
#			}
			
		}
	};
	alarm 0;
}

# main is automatically added
our %dist=(
	'main' =>
	{
		'country' => ['*'],
		'weight' => 100,
	}
);



#$dist{'abc'}=
#{
#	'hostname' => 'http://www.example.tld/flv',
#	'remote_hostname' => 'server.example.tld',
#	'remote_path' => '/home/example/a510',
#	'remote_user' => 'example',
#	'remote_pass' => 'nbusr123',
#	'country' => ['CZ','GB'],
#	'weight' => 10000,
#	'limits' =>
#	{
#		'size_MB' => 50000, # 50GB
#		'traffic_GB_day' => 1000, # 1TB
#	}
#};


our $db_name=$App::510::db_name || $TOM::DB{'main'}{'name'};
$tom::H_a510=$tom::H_media."/a510" if (!$tom::H_a510 && $tom::H_media);
main::_log("db_name='$db_name' H_a510='$tom::H_a510'");
our $video_format_ext_default=$App::510::video_format_ext_default || 'avi';

our %priority;
$priority{'A'}=$App::401::priority{'A'} || 1;
$priority{'B'}=$App::401::priority{'B'} || undef;
$priority{'C'}=$App::401::priority{'C'} || undef;

our $original_playable;
our $video_format_original_ID;
our $video_format_full_ID;
#our $video_format_preview_ID;


my %sth0=TOM::Database::SQL::execute(qq{
	SELECT ID,process
	FROM `$db_name`.a510_video_format
	WHERE name='original'
	LIMIT 1;
},'quiet'=>1);
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
	if ($db0_line{'process'})
	{
		main::_log("original video format is playable (\$App::510::original_playable=1)");
		$original_playable=1;
	}
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
				'process' => "'set_env(\\'encoder\\',\\'ffmpeg\\')
set_env(\\'f\\',\\'flv\\')
set_env(\\'vcodec\\',\\'flv\\')
set_env(\\'b\\',\\'450k\\')
set_env(\\'acodec\\',\\'mp3\\')
set_env(\\'ar\\',\\'22050\\')
set_env(\\'ab\\',\\'48k\\')
set_env(\\'s_height\\',\\'240\\')
set_env(\\'r\\',\\'20\\')
set_env(\\'ac\\',\\'1\\')
set_env(\\'ar\\',\\'22050\\')
encode()'",
				'status' => "'L'"
			},
			'-journalize' => 1
		);
	}
	else
	{
		$video_format_full_ID=$db0_line{'ID'};
	}
=head1
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
=cut
}



# commercial
our $commercial_cat_ID_entity;
our %commercial_cat;

# find any category;
my $sql="
	SELECT
		ID, ID_entity
	FROM
		`$App::510::db_name`.`a510_video_cat`
	WHERE
		name='Commercials' AND
		lng IN ('".(join "','",@TOM::LNG_accept)."')
	LIMIT 1
";
my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
if (my %db0_line=$sth0{'sth'}->fetchhash())
{
	$commercial_cat_ID_entity=$db0_line{'ID_entity'} unless $commercial_cat_ID_entity;
}
else
{
	$commercial_cat_ID_entity=App::020::SQL::functions::tree::new(
		'db_h' => "main",
		'db_name' => $App::510::db_name,
		'tb_name' => "a510_video_cat",
		'parent_ID' => $App::510::system_cat{$tom::LNG},
		'columns' => {
			'name' => "'Commercials'",
			'lng' => "'$tom::LNG'",
			'status' => "'L'"
		},
		'-journalize' => 1
	);
}
foreach my $lng(@TOM::LNG_accept)
{
	my $sql=qq{
		SELECT
			ID, ID_entity
		FROM
			`$App::510::db_name`.`a510_video_cat`
		WHERE
			ID_entity=$commercial_cat_ID_entity AND
			lng='$lng'
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		$commercial_cat{$lng}=$db0_line{'ID'};
	}
	else
	{
		$commercial_cat{$lng}=App::020::SQL::functions::tree::new(
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_video_cat",
			'parent_ID' => $App::510::system_cat{$lng},
			'columns' => {
				'ID_entity' => $commercial_cat_ID_entity,
				'name' => "'Commercials'",
				'lng' => "'$lng'",
				'status' => "'L'"
			},
			'-journalize' => 1
		);
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
		'parent_ID' => $App::501::system_cat{$tom::LNG},
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
			'parent_ID' => $App::501::system_cat{$lng},
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


# video cat avatars

our $cat_avatar_cat_ID_entity;
our %cat_avatar_cat;

# find any category;
my $sql="
	SELECT
		ID, ID_entity
	FROM
		`$App::501::db_name`.`a501_image_cat`
	WHERE
		name='video category avatars' AND
		lng IN ('".(join "','",@TOM::LNG_accept)."')
	LIMIT 1
";
my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
if (my %db0_line=$sth0{'sth'}->fetchhash())
{
	$cat_avatar_cat_ID_entity=$db0_line{'ID_entity'} unless $cat_avatar_cat_ID_entity;
}
else
{
	$cat_avatar_cat_ID_entity=App::020::SQL::functions::tree::new(
		'db_h' => "main",
		'db_name' => $App::501::db_name,
		'tb_name' => "a501_image_cat",
		'parent_ID' => $App::501::system_cat{$tom::LNG},
		'columns' => {
			'name' => "'video category avatars'",
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
			ID_entity=$cat_avatar_cat_ID_entity AND
			lng='$lng'
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		$cat_avatar_cat{$lng}=$db0_line{'ID'};
	}
	else
	{
		#main::_log("creating related category");
		$cat_avatar_cat{$lng}=App::020::SQL::functions::tree::new(
			'db_h' => "main",
			'db_name' => $App::501::db_name,
			'tb_name' => "a501_image_cat",
			'parent_ID' => $App::501::system_cat{$lng},
			'columns' => {
				'ID_entity' => $cat_avatar_cat_ID_entity,
				'name' => "'video category avatars'",
				'lng' => "'$lng'",
				'status' => "'L'"
			},
			'-journalize' => 1
		);
	}
}


# check relation to a821
our $forum_ID_entity;
our %forum;

if ($App::821::db_name)
{
	# find any category;
	my $sql="
		SELECT
			ID, ID_entity
		FROM
			`$App::821::db_name`.`a821_discussion_forum`
		WHERE
			name='video discussions' AND
			lng IN ('".(join "','",@TOM::LNG_accept)."')
		LIMIT 1
	";
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		$forum_ID_entity=$db0_line{'ID_entity'} unless $forum_ID_entity;
	}
	else
	{
		$forum_ID_entity=App::020::SQL::functions::tree::new(
			'db_h' => "main",
			'db_name' => $App::821::db_name,
			'tb_name' => "a821_discussion_forum",
			'columns' => {
				'name' => "'video discussions'",
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
				`$App::821::db_name`.`a821_discussion_forum`
			WHERE
				ID_entity=$forum_ID_entity AND
				lng='$lng'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$forum{$lng}=$db0_line{'ID'};
		}
		else
		{
			#main::_log("creating related category");
			$forum{$lng}=App::020::SQL::functions::tree::new(
				'db_h' => "main",
				'db_name' => $App::821::db_name,
				'tb_name' => "a821_discussion_forum",
				'columns' => {
					'ID_entity' => $forum_ID_entity,
					'name' => "'video discussions'",
					'lng' => "'$lng'",
					'status' => "'L'"
				},
				'-journalize' => 1
			);
		}
	}
}

my %sth0=TOM::Database::SQL::execute(qq{
	SELECT name
	FROM `$db_name`.a510_video_brick
	WHERE status='Y'
	ORDER BY ID
},'quiet'=>1);
while (my %db0_line=$sth0{'sth'}->fetchhash())
{
	my $class_name="App::510::brick::".$db0_line{'name'};
#	main::_log("load brick '$db0_line{'name'}' '$class_name'");
#	require $class_name;
	eval "require $class_name; 1; ";
	main::_log("$@",1);
}

1;
