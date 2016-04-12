#!/bin/perl
package App::520;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;


BEGIN {main::_log("<={LIB} ".__PACKAGE__)}

our $VERSION='1';

use App::020::_init; # data standard 0
use App::301::_init;
#use App::501::_init;
use App::520::functions;
use App::520::a160;
use App::520::a301;
use File::Copy;
use File::Path;



BEGIN
{
	eval
	{
		alarm 1; # when media directory is a freezed network filesystem
		my $htaccess_j=qq{# safe data
RewriteEngine Off
Deny from All};
		
		# check media directory
		my $check=1;
		if ($tom::P && $check)
		{
			main::_log("checking a520 media directory");
			if (!-e $tom::P_media.'/a520/audio/')
			{
				File::Path::mkpath $tom::P_media.'/a520/audio/';
			}
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


our $db_name=$App::520::db_name || $TOM::DB{'main'}{'name'};
$tom::H_a520=$tom::H_media."/a520" if (!$tom::H_a520 && $tom::H_media);
main::_log("db_name='$db_name' H_a520='$tom::H_a520'");
our $audio_format_ext_default=$App::520::audio_format_ext_default || 'mp3';

our %priority;
$priority{'A'}=$App::401::priority{'A'} || 1;
$priority{'B'}=$App::401::priority{'B'} || undef;
$priority{'C'}=$App::401::priority{'C'} || undef;

our $original_playable;
our $audio_format_original_ID;
our $audio_format_full_ID;
#our $video_format_preview_ID;


my %sth0=TOM::Database::SQL::execute(qq{
	SELECT ID,process
	FROM `$db_name`.a520_audio_format
	WHERE name='original'
	LIMIT 1;
},'quiet'=>1);
my %db0_line=$sth0{'sth'}->fetchhash();
if (!$db0_line{'ID'})
{
	$audio_format_original_ID=App::020::SQL::functions::tree::new(
		'db_h' => 'main',
		'db_name' => $db_name,
		'tb_name' => 'a520_audio_format',
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
		main::_log("original audio format is playable (\$App::520::original_playable=1)");
		$original_playable=1;
	}
	$audio_format_original_ID=$db0_line{'ID'};
}

if ($audio_format_original_ID)
{
	my $sql=qq{
		SELECT ID
		FROM `$db_name`.a520_audio_format
		WHERE name='full'
		LIMIT 1;
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	my %db0_line=$sth0{'sth'}->fetchhash();
	if (!$db0_line{'ID'})
	{
		$audio_format_full_ID=App::020::SQL::functions::tree::new(
			'parent_ID' => $audio_format_original_ID,
			'db_h' => 'main',
			'db_name' => $db_name,
			'tb_name' => 'a520_audio_format',
			'columns' =>
			{
				'name' => "'full'",
				'process' => "'set_env(\\'codec\\',\\'mp3\\')
encode()'",
				'status' => "'L'"
			},
			'-journalize' => 1
		);
	}
	else
	{
		$audio_format_full_ID=$db0_line{'ID'};
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
		name='audio thumbnails' AND
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
			'name' => "'audio thumbnails'",
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
				'name' => "'audio thumbnails'",
				'lng' => "'$lng'",
				'status' => "'L'"
			},
			'-journalize' => 1
		);
	}
}


# audio cat avatars

our $cat_avatar_cat_ID_entity;
our %cat_avatar_cat;

# find any category;
my $sql="
	SELECT
		ID, ID_entity
	FROM
		`$App::501::db_name`.`a501_image_cat`
	WHERE
		name='audio category avatars' AND
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
			'name' => "'audio category avatars'",
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
				'name' => "'audio category avatars'",
				'lng' => "'$lng'",
				'status' => "'L'"
			},
			'-journalize' => 1
		);
	}
}

my %sth0=TOM::Database::SQL::execute(qq{
	SELECT name
	FROM `$db_name`.a520_audio_brick
	WHERE status='Y'
	ORDER BY ID
},'quiet'=>1);
while (my %db0_line=$sth0{'sth'}->fetchhash())
{
	my $class_name="App::520::brick::".$db0_line{'name'};
#	main::_log("load brick '$db0_line{'name'}' '$class_name'");
#	require $class_name;
	eval "require $class_name; 1; ";
	main::_log("$@",1);
}

1;
