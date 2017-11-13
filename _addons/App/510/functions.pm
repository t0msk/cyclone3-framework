#!/bin/perl
package App::510::functions;

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


use App::510::_init;
use App::510::brick;
use App::160::_init;
use App::542::mimetypes;
use File::Path;
use Digest::MD5  qw(md5 md5_hex md5_base64);
use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);
use File::Type;
use Movie::Info;
use File::Which qw(where);
use Time::HiRes qw(usleep);
use Ext::Redis::_init;
use Ext::Elastic::_init;
use Number::Bytes::Human qw(format_bytes);

our $avconv_exec = (where('avconv'))[0];main::_log("avconv in '$avconv_exec'");
our $avprobe_exec = (where('avprobe'))[0];main::_log("avprobe in '$avprobe_exec'");
our $ffmpeg_exec = (where('ffmpeg'))[0];main::_log("ffmpeg in '$ffmpeg_exec'");
our $mencoder_exec = (where('mencoder'))[0];main::_log("mencoder in '$mencoder_exec'");
our $mplayer_exec = (where('mplayer'))[0];main::_log("mplayer in '$mplayer_exec'");
our $flvtool2_exec = (where('flvtool2'))[0];main::_log("flvtool2 in '$flvtool2_exec'");
our $MP4Box_exec = (where('MP4Box'))[0];main::_log("MP4Box in '$MP4Box_exec'");


=head1 FUNCTIONS

=head2 video_part_file_generate()

 video_part_file_generate
 (
   'video.ID_entity' => '' # related video.ID_entity
   'video_format.ID' => '' # related video_format.ID
   #'video_format.name' => '' # realted video_format.name
 )

=cut

sub video_part_file_generate
{
	my %env=@_;
	if ($env{'-jobify'})
	{
		return 1 if TOM::Engine::jobify(\@_,{
			'routing_key' => 'db:'.$App::510::db_name,
			'class' => 'encoder'.do{if (defined $env{'-encoder_slot'}){''.$env{'-encoder_slot'};}else{'';}},
			'deduplication' => 1}); # do it in background
	}
	
	my $t=track TOM::Debug(__PACKAGE__."::video_part_file_generate($env{'video_part.ID'},".
		($env{'video_format.ID'}||$env{'video_format.name'}).")");
	
	# get info about video_part
	my %video_part=App::020::SQL::functions::get_ID(
		'ID' => $env{'video_part.ID'},
		'db_h' => 'main',
		'db_name' => $App::510::db_name,
		'tb_name' => 'a510_video_part',
		'columns' =>
		{
			'*' => 1,
#			'ID_brick' => 1,
		}
	);
	
	my %brick;
	%brick=App::020::SQL::functions::get_ID(
		'ID' => $video_part{'ID_brick'},
		'db_h' => "main",
		'db_name' => $App::510::db_name,
		'tb_name' => "a510_video_brick",
		'columns' => {'*'=>1}
	) if $video_part{'ID_brick'};
	
	main::_log("video_part.ID='$video_part{'ID'}' part_id='$video_part{'part_id'}' status='$video_part{'status'}'");
	
	if ($video_part{'status'} ne "Y" && $video_part{'status'} ne "N")
	{
		main::_log("video_part is not available",1);
		$t->close();
		return undef;
	}
	
	my %format;
	
	if ($env{'video_format.ID'})
	{
		%format=App::020::SQL::functions::get_ID(
			'ID' => $env{'video_format.ID'},
			'db_h' => 'main',
			'db_name' => $App::510::db_name,
			'tb_name' => 'a510_video_format',
			'columns' =>
			{
				'name' => 1,
				'process' => 1,
				'definition' => 1,
			}
		);
		$env{'video_format.name'}=$format{'name'};
	}
	
	# lock time to this current
	$main::time_current=$tom::time_current=time();
	
	main::_log("video_format ID='$format{'ID'}' name='$format{'name'}' status='$format{'status'}'");
	
	if ($format{'status'} ne "Y" &&  $format{'status'} ne "L")
	{
		main::_log("video_format is disabled or not available",1);
		$t->close();
		return undef;
	}
	
	
	# find parent
	my %format_parent=App::020::SQL::functions::tree::get_parent_ID(
		'ID' => $format{'ID'},
		'db_h' => 'main',
		'db_name' => $App::510::db_name,
		'tb_name' => 'a510_video_format'
	);
	
	if ($format{'ID'} eq $App::510::video_format_original_ID && $format{'process'})
	{
		main::_log("regenerate video_part_file");
		%format_parent=%format;
	}
	elsif ($format_parent{'status'} ne "Y" &&  $format_parent{'status'} ne "L")
	{
		main::_log("parent video_format is disabled or not available",1);
		$t->close();
		return undef;
	}
	
	# find video_part_file defined by parent video_format (to convert from)
	
	# video.ID_entity is related to video_part_file.ID_entity
	
	my $sql=qq{
		SELECT
			*
		FROM
			`$App::510::db_name`.`a510_video_part_file`
		WHERE
			ID_entity=$video_part{'ID'} AND
			ID_format=$format_parent{'ID'}
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	my %file_parent=$sth0{'sth'}->fetchhash();
	
	if ($file_parent{'status'} ne "Y" && ($format_parent{'ID'} ne 1))
	{
		main::_log("parent video_part_file.ID='$file_parent{'ID'}' ID_format=$format_parent{'ID'} is disabled or not available",1);
		$t->close();
		return undef;
	}
	
	my $brick_class='App::510::brick';
		$brick_class.="::".$brick{'name'}
			if $brick{'name'};
	
	my %sth0=TOM::Database::SQL::execute(qq{
		INSERT INTO `$App::510::db_name`.`a510_video_part_file_process`
		(
			`ID_part`,
			`ID_format`,
			`request_code`,
			`encoder_slot`,
			`hostname`,
			`hostname_PID`,
			`process`,
			`datetime_start`
		)
		VALUES
		(
			'$video_part{'ID'}',
			'$format{'ID'}',
			?,
			?,
			'$TOM::hostname',
			'$$',
			'',
			NOW()
		)
	},'quiet'=>1,'bind'=>[
		$main::request_code,
		$env{'-encoder_slot'}
	]);
	my $process_ID=$sth0{'sth'}->insertid();
	main::_log("creating entry to _video_part_file_process with id '$process_ID' to lock video_part.ID='$video_part{'ID'}' format.ID='$format{'ID'}'");
	
	my $video_=$brick_class->video_part_file_path({
		'video_part.ID' => $video_part{'ID'},
		'video_part.datetime_air' => $video_part{'datetime_air'},
#		'video.ID' => $video{'ID_video'},
		'video_part_file.ID' => $file_parent{'ID'},
		'video_format.ID' => $format_parent{'ID'},
		'video_part_file.name' => $file_parent{'name'},
		'video_part_file.file_ext' => $file_parent{'file_ext'},
	});
	
	my $video1_path=$file_parent{'file_alt_src'} || $video_->{'dir'}.'/'.$video_->{'file_path'};
	
#	main::_log("path=$path",1);
#	my $video1_path=$file_parent{'file_alt_src'} || $tom::P_media.'/a510/video/part/file/'._video_part_file_genpath
#	(
#		$format_parent{'ID'},
#		$file_parent{'ID'},
#		$file_parent{'name'},
#		$file_parent{'file_ext'}
#	);
	
	main::_log("path to parent video_part_file='$video1_path'");
	
	my $video1={};
	no strict;
	if ($brick_class->can('download'))
	{
		$video1=new TOM::Temp::file('dir'=>$main::ENV{'TMP'},'nocreate'=>1);
		main::_log("download parent video to '$video1->{'filename'}'");
		$brick_class->download($video1_path, $video1->{'filename'});
		$video1_path=$video1->{'filename'};
	}
	elsif (${$brick_class.'::copybeforeencode'})
#	if ($brick_class->{'copybeforeencode'})
	{
		$video1=new TOM::Temp::file('dir'=>$main::ENV{'TMP'},'nocreate'=>1);
		main::_log("copy parent video to '$video1->{'filename'}'");
		File::Copy::copy($video1_path, $video1->{'filename'});
		$video1_path=$video1->{'filename'};
	}
	
	my $video2=new TOM::Temp::file('dir'=>$main::ENV{'TMP'},'nocreate'=>1);
	
	my %out=video_part_file_process(
		'video1' => $video1_path,
		'video2' => $video2->{'filename'},
		'process' => $env{'process'} || $format{'process'},
		'process_force' => $env{'process_force'},
		'definition' => $format{'definition'}
	);
	
	main::_log("return=$out{'return'}");
	
	if ($out{'return'})
	{
		main::_log("parent video_part_file can't be processed",1);
#		exit;
#		if ($file_parent{'ID_format'} == $App::510::video_format_original_ID && ($out <=> 512))
#		{
#			main::_log("lock processing of video_part.ID='$env{'video_part.ID'}'",1);
#			App::020::SQL::functions::update(
#				'ID' => $env{'video_part.ID'},
#				'db_h' => "main",
#				'db_name' => $App::510::db_name,
#				'tb_name' => "a510_video_part",
#				'columns' =>
#				{
#					'process_lock' => "'E'"
#				},
#				'-journalize' => 1
#			);
			
			# create empty video_part_file
			# Check if video_part_file for this format exists
			my $sql=qq{
				SELECT
					*
				FROM
					`$App::510::db_name`.`a510_video_part_file`
				WHERE
					ID_entity=$env{'video_part.ID'} AND
					ID_format=$format{'ID'}
				LIMIT 1
			};
			my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
			if (my %db0_line=$sth0{'sth'}->fetchhash)
			{
				if ($db0_line{'ID_format'} eq "1")
				{
					main::_log("can't set source format as invalid",1);
					App::020::SQL::functions::update(
						'ID' => $db0_line{'ID'},
						'db_h' => 'main',
						'db_name' => $App::510::db_name,
						'tb_name' => 'a510_video_part_file',
						'columns' =>
						{
							'from_parent' => "'Y'",
							'regen' => "'N'",
							'status' => "'E'",
						},
						'-journalize' => 1,
					);
				}
				else
				{
					App::020::SQL::functions::update(
						'ID' => $db0_line{'ID'},
						'db_h' => 'main',
						'db_name' => $App::510::db_name,
						'tb_name' => 'a510_video_part_file',
						'columns' =>
						{
							'name' => "''",
							'video_width' => "''",
							'video_height' => "''",
							'video_codec' => "''",
							'video_fps' => "''",
							'video_bitrate' => "''",
							'audio_codec' => "''",
							'audio_bitrate' => "''",
							'length' => "''",
							'file_alt_src' => "''",
							'file_size' => "''",
							'file_checksum' => "''",
							'file_ext' => "''",
							'from_parent' => "'Y'",
							'regen' => "'N'",
							'status' => "'E'",
						},
						'-journalize' => 1,
					);
				}
			}
			else
			{
				my $ID=App::020::SQL::functions::new(
					'db_h' => "main",
					'db_name' => $App::510::db_name,
					'tb_name' => "a510_video_part_file",
					'columns' =>
					{
						'ID_entity' => $env{'video_part.ID'},
						'ID_format' => $format{'ID'},
						'name' => "''",
						'video_width' => "''",
						'video_height' => "''",
						'video_codec' => "''",
						'video_fps' => "''",
						'video_bitrate' => "''",
						'audio_codec' => "''",
						'audio_bitrate' => "''",
						'length' => "''",
						'file_alt_src' => "''",
						'file_size' => "''",
						'file_checksum' => "''",
						'file_ext' => "''",
						'from_parent' => "'Y'",
						'regen' => "'N'",
						'status' => "'E'",
					},
					'-journalize' => 1
				);
			}
#		}
		
		my $sql=qq{
			UPDATE `$App::510::db_name`.`a510_video_part_file_process`
			SET datetime_stop=NOW(), status='E'
			WHERE ID=$process_ID
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		main::_log("set entry to _video_part_file_process with id '$process_ID' to status='E' (not processed)");
		$t->close();
		return undef;
	}
	
	video_part_file_add
	(
		'file' => $video2->{'filename'},
		'ext' => $out{'ext'},
		'video_part.ID' => $video_part{'ID'},
		'video_format.ID' => $format{'ID'},
		'from_parent' => "Y",
		'thumbnail_lock_ignore' => $env{'thumbnail_lock_ignore'}
	) || do {
		main::_log("setting entry to _video_part_file_process with id '$process_ID' to status='E' (not coppied)");
		my $sql=qq{
			UPDATE `$App::510::db_name`.`a510_video_part_file_process`
			SET datetime_stop=NOW(), status='E'
			WHERE ID=$process_ID
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		$t->close();return undef
	};
	
	main::_log("setting entry to _video_part_file_process with id '$process_ID' to status='Y' (done)");
	my $sql=qq{
		UPDATE `$App::510::db_name`.`a510_video_part_file_process`
		SET datetime_stop=NOW(), status='Y'
		WHERE ID=$process_ID
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	
	$t->close();
	return 1;
}



sub video_part_smil_generate
{
	my %env=@_;
	return undef unless $env{'video_part.ID'};
	my $t=track TOM::Debug(__PACKAGE__."::video_part_smil_generate($env{'video_part.ID'})");
	
#	my $subdir=sprintf('%04d',int($env{'video_part.ID'}/10000));
#	my $directory=$tom::P_media.'/a510/video/part/smil/'.$subdir;
#	main::_log("subdir $subdir");
	
	my %part=App::020::SQL::functions::get_ID(
		'ID' => $env{'video_part.ID'},
		'db_h' => "main",
		'db_name' => $App::510::db_name,
		'tb_name' => "a510_video_part",
		'columns' => {'*'=>1}
	);
	
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			video.ID_entity,
			video.ID,
			
			video.ID_entity AS ID_entity_video,
			video.ID AS ID_video,
			video_attrs.ID AS ID_attrs,
			video_part.ID AS ID_part,
			video_part_attrs.ID AS ID_part_attrs,
			
			video_ent.keywords,
			
			LEFT(video.datetime_rec_start, 18) AS datetime_rec_start,
			LEFT(video_attrs.datetime_create, 18) AS datetime_create,
			LEFT(video.datetime_rec_start,10) AS date_recorded,
			LEFT(video_ent.datetime_rec_stop, 18) AS datetime_rec_stop,
			
			video_attrs.ID_category,
			video_cat.name AS ID_category_name,
			
			video_attrs.name,
			video_attrs.name_url,
			
			video_attrs.datetime_publish_start,
			video_attrs.datetime_publish_stop,
			
			video_part_attrs.name AS part_name,
			video_part_attrs.description AS part_description,
			video_part.keywords AS part_keywords,
			video_part.datetime_air AS part_datetime_air
			
		FROM
			`$App::510::db_name`.`a510_video` AS video
		INNER JOIN `$App::510::db_name`.`a510_video_ent` AS video_ent ON
		(
			video_ent.ID_entity = video.ID_entity
		)
		LEFT JOIN `$App::510::db_name`.`a510_video_attrs` AS video_attrs ON
		(
			video_attrs.ID_entity = video.ID
		)
		LEFT JOIN `$App::510::db_name`.`a510_video_part` AS video_part ON
		(
			video_part.ID_entity = video.ID_entity
		)
		LEFT JOIN `$App::510::db_name`.`a510_video_part_attrs` AS video_part_attrs ON
		(
			video_part_attrs.ID_entity = video_part.ID AND
			video_part_attrs.lng = video_attrs.lng
		)
		LEFT JOIN `$App::510::db_name`.`a510_video_cat` AS video_cat ON
		(
			video_cat.ID_entity = video_attrs.ID_category
		)
		WHERE
			video_part.ID=$env{'video_part.ID'}
		LIMIT 1
	},'quiet'=>1,'-slave'=>1);
	my %video=$sth0{'sth'}->fetchhash();
	
#	my %video=App::020::SQL::functions::get_ID(
#		'ID' => $part{'ID_entity'},
#		'db_h' => "main",
#		'db_name' => $App::510::db_name,
#		'tb_name' => "a510_video",
#		'columns' => {'*'=>1}
#	);
	
	my %brick;
	%brick=App::020::SQL::functions::get_ID(
		'ID' => $part{'ID_brick'},
		'db_h' => "main",
		'db_name' => $App::510::db_name,
		'tb_name' => "a510_video_brick",
		'columns' => {'*'=>1}
	) if $part{'ID_brick'};
	
	my $brick_class='App::510::brick';
		$brick_class.="::".$brick{'name'}
			if $brick{'name'};
	
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			*
		FROM
			`$App::510::db_name`.a510_video_part_smil
		WHERE
			ID_entity=?
		LIMIT 1
	},'bind'=>[$env{'video_part.ID'}],'quiet'=>1);
	my %db0_line=$sth0{'sth'}->fetchhash();
	
	my $smil_=$brick_class->video_part_smil_path({
		'video_part.ID' => $part{'ID'},
#		'video_format.ID' => $env{'video_format.ID'},
#		'video_part_file.file_name' => $name,
#		'video_part_file.file_ext' => $file_ext,
		'video_part_smil.name' => $db0_line{'name'}
	});
	
	my $file_name=$smil_->{'dir'}.'/'.$smil_->{'smil_path'};
	
	$file_name=~s|^(.*)/(.*?)\.smil$|$2|;
	my $dir_name=$1;
	
	main::_log("smil='$dir_name/$file_name.smil'");
	
	my %sth1=TOM::Database::SQL::execute(qq{
		SELECT
			*
		FROM
			`$App::510::db_name`.a510_video_part_file
		WHERE
			ID_entity=?
			AND status='Y'
			AND file_alt_src IS NULL
			AND
			(
				ID_format != $App::510::video_format_original_ID
				OR
				(
					ID_format = $App::510::video_format_original_ID
					AND from_parent = 'Y'
				)
			)
		ORDER BY
			CASE 
				WHEN ID_format=1 THEN 3
				WHEN ID_format=2 THEN 1
				WHEN ID_format=3 THEN 4
				WHEN ID_format=4 THEN 5
				WHEN ID_format=5 THEN 6
				WHEN ID_format=6 THEN 2
			END ASC
			
	},'bind'=>[$env{'video_part.ID'}],'quiet'=>1);
	
	main::_log("found $sth1{'rows'} playable items");
	use XML::Generator ':pretty';
	
	if (!$sth1{'rows'})
	{
		main::_log("nothing to generate",1);
		$t->close();
		return undef;
	}
	
	my $xml=XML::Generator->new(':pretty');
	my $xml_string=$xml->smil(
		{
			'title' => "Cyclone3 ".$tom::H." video_part ".$env{'video_part.ID'}
		},
		$xml->header(
			$xml->entity(['C3' => 'uri:C3'],
				$xml->part(['C3' => 'uri:C3'],{
					'ID'=>$env{'video_part.ID'},
					'order_id' => $part{'part_id'},
					'name' => $video{'part_name'},
					'datetime_air'=>$part{'datetime_air'}
				}),
				$xml->video(['C3' => 'uri:C3'],{
					'name' => $video{'name'},
					'ID_entity' => $part{'ID_entity'},
					'valid-from' => $video{'datetime_publish_start'},
					'valid-to' => $video{'datetime_publish_stop'},
				})
			)
		),
		$xml->body(
			$xml->switch(do{
				my @video;
				while (my %db1_line=$sth1{'sth'}->fetchhash())
				{
					
					my $video_=$brick_class->video_part_file_path({
							'-notest' => 1,
						'video_part.ID' => $part{'ID'},
						'video_part.datetime_air' => $part{'datetime_air'},
						'video_part_file.ID' => $db1_line{'ID'},
						'video_format.ID' => $db1_line{'ID_format'},
						'video_part_file.name' => $db1_line{'name'},
						'video_part_file.file_ext' => $db1_line{'file_ext'},
					});
					
					my $video_part_file=$video_->{'dir'}.'/'.$video_->{'file_path'};
					$video_part_file=~s|^$dir_name/||;
					
					main::_log("video_part_file='$video_part_file' $db1_line{'video_height'}/$db1_line{'video_bitrate'}");
					
					push @video, $xml->video({
						'src' => $video_part_file,
						'width' => $db1_line{'video_width'},
						'height' => $db1_line{'video_height'},
						'system-bitrate' => ($db1_line{'video_bitrate'} + $db1_line{'audio_bitrate'})
					},
						$xml->param({
							'name' => "videoBitrate",
							'value' => $db1_line{'video_bitrate'},
							'valuetype' => 'data'
						}),
						$xml->param({
							'name' => "audioBitrate",
							'value' => $db1_line{'audio_bitrate'},
							'valuetype' => 'data'
						})
					);
				}
				@video;
			})
		)
	);
	
	if (!$sth0{'rows'})
	{
		App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_video_part_smil",
			'columns' =>
			{
				'ID_entity' => $env{'video_part.ID'},
				'name' => "'".$file_name."'",
				'status' => "'Y'"
			},
		);
	}
	
#	if (-e $dir_name.'/'.$file_name.'.smil')
#	{
#		unlink $dir_name.'/'.$file_name.'.smil';
#	}
	
#	main::_log("writed smil file");
	
	my $file_temp=new TOM::Temp::file('ext'=>'smil');
	open(HNDSMIL,'>'.$file_temp->{'filename'}) || 
		main::_log("can't write $!",1);
	print HNDSMIL $xml_string;
	close(HNDSMIL);
	chmod (0666,$file_temp->{'filename'});
	
	if ($brick_class->can('upload'))
	{
		main::_log(" upload file size=".format_bytes((stat $file_temp->{'filename'})[7]));
		$brick_class->upload(
			$file_temp->{'filename'},
			$dir_name.'/'.$file_name.'.smil'
		) || do {
			main::_log("$!",1);
			$t->close();
			return undef;
		};
	}
	else
	{
		main::_log(" copy file size=".format_bytes((stat $file_temp->{'filename'})[7]));
		copy($file_temp->{'filename'},$dir_name.'/'.$file_name.'.smil') || do {
			main::_log("$!",1);
			$t->close();
			return undef;
		};
	}
	
	$t->close();
	return 1;
}



sub video_encryption_generate
{
	my %env=@_;
	return undef unless $env{'ID_entity'};
	my $t=track TOM::Debug(__PACKAGE__."::video_encryption_generate($env{'ID_entity'})");
	
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			*
		FROM
			`$App::510::db_name`.a510_video_ent
		WHERE
			ID_entity = ?
		LIMIT 1
	},'bind'=>[$env{'ID_entity'}],'quiet'=>1);
	my %video_ent=$sth0{'sth'}->fetchhash();
	
	main::_log("encryption=".$video_ent{'status_encryption'});
	
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			*
		FROM
			`$App::510::db_name`.a510_video_part
		WHERE
			ID_entity = ? AND
			status IN ('Y','N','L')
		ORDER BY
			part_id
	},'bind'=>[$env{'ID_entity'}],'quiet'=>1);
	while (my %part=$sth0{'sth'}->fetchhash())
	{
		main::_log("part $part{'part_id'} ID=$part{'ID'} ID_brick=$part{'ID_brick'}");
		
		my %brick;
		%brick=App::020::SQL::functions::get_ID(
			'ID' => $part{'ID_brick'},
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_video_brick",
			'columns' => {'*'=>1}
		) if $part{'ID_brick'};
		
		my $brick_class='App::510::brick';
			$brick_class.="::".$brick{'name'}
				if $brick{'name'};
		
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				`$App::510::db_name`.a510_video_part_file
			WHERE
				ID_entity = ? AND
				status IN ('Y','N','L')
			ORDER BY
				ID_format
		},'bind'=>[$part{'ID'}],'quiet'=>1);
		while (my %part_file=$sth1{'sth'}->fetchhash())
		{
			my $video_=$brick_class->video_part_file_path({
					'-notest' => 1,
				'video_part.ID' => $part{'ID'},
				'video_format.ID' => $part_file{'ID_format'},
				'video_part_file.ID' => $part_file{'ID'},
				'video_part_file.file_alt_src' => $part_file{'file_alt_src'},
				'video_part_file.name' => $part_file{'name'},
				'video_part_file.file_ext' => $part_file{'file_ext'},
				'video_part.datetime_air' => $part{'datetime_air'},
			});
			main::_log("file ID=$part_file{'ID'} encryption_key=$part_file{'encryption_key'} dir=$video_->{'dir'} file=$video_->{'file_path'}");
			
			my $key_dir=$video_->{'dir'};
			my $key_file=$video_->{'file_path'}.".key";
			if ($brick_class->can('key_file_path'))
			{
#				main::_log("asking for key file");
				my $video_=$brick_class->key_file_path({
					'video_part.ID' => $part{'ID'},
					'video_format.ID' => $part_file{'ID_format'},
					'video_part_file.ID' => $part_file{'ID'},
					'video_part_file.file_alt_src' => $part_file{'file_alt_src'},
					'video_part_file.name' => $part_file{'name'},
					'video_part_file.file_ext' => $part_file{'file_ext'},
					'video_part.datetime_air' => $part{'datetime_air'},
				});
				$key_dir=$video_->{'dir'};
				$key_file=$video_->{'file_path'};
			}
			
			
			$key_dir=$key_dir.'/'.$key_file;
			$key_dir=~s|^(.*)/(.*?)$|$1|;
			$key_file=$2;
			main::_log(" key file dir=$key_dir file=$key_file");
			
			if (($part_file{'encryption_key'} || $env{'force'}) && $video_ent{'status_encryption'} ne "Y")
			{
				main::_log(" removing encryption");
			}
			elsif ((!$part_file{'encryption_key'} || $env{'force'}) && $video_ent{'status_encryption'} eq "Y")
			{
				my $hash=uc(unpack('H*',TOM::Utils::vars::genhashNU(16)));
				main::_log(" adding encryption AES-128 key '$hash'");
				my $content;
				$content.="cupertinostreaming-aes128-key: ".$hash."\n";
				$content.="cupertinostreaming-aes128-url: ".$tom::Hm_www."/binary/videokey?id=".$part_file{'ID'};
				$content.="\n";
				
				if ($brick_class->can('testdir'))
				{
					if (!$brick_class->testdir($key_dir))
					{
						main::_log("src dir can't be found, exiting",1);
						$t->close();
						return undef;
					}
				}
				
				my $file_temp=new TOM::Temp::file('ext'=>'key');
				open(HNDKEY,'>'.$file_temp->{'filename'}) || 
					main::_log("can't write $!",1);
				print HNDKEY $content;
				close(HNDKEY);
				chmod (0666,$file_temp->{'filename'});
				
				if ($brick_class->can('upload'))
				{
					main::_log(" upload file size=".format_bytes((stat $file_temp->{'filename'})[7]));
					$brick_class->upload(
						$file_temp->{'filename'},
						$key_dir.'/'.$key_file
					) || do {
						main::_log("$!",1);
						$t->close();
						return undef;
					};
				}
				else
				{
					main::_log(" copy file size=".format_bytes((stat $file_temp->{'filename'})[7]));
					copy($file_temp->{'filename'},$key_dir.'/'.$key_file) || do {
						main::_log("$!",1);
						$t->close();
						return undef;
					};
				}
				
				TOM::Database::SQL::execute(qq{
					UPDATE
						`$App::510::db_name`.a510_video_part_file
					SET
						encryption_key=?
					WHERE
						ID=?
					LIMIT 1
				},'bind'=>[$hash,$part_file{'ID'}],'quiet'=>1);
				
				# override modifytime
				App::020::SQL::functions::_save_changetime({
					'db_h' => 'main',
					'db_name' => $App::510::db_name,
					'tb_name' => 'a510_video_part_file',
					'ID_entity' => $part_file{'ID'}
				});
				
			}
		}
		
	}
	
	$t->close();
	return 1;
}



sub video_part_brick_change
{
	my %env=@_;
	if ($env{'-jobify'})
	{
		return 1 if TOM::Engine::jobify(\@_,{'routing_key' => 'db:'.$App::510::db_name,'class'=>'fifo'}); # do it in background
	}
	return undef unless $env{'video_part.ID'};
	return undef unless defined $env{'video_part.ID_brick'};
	my $t=track TOM::Debug(__PACKAGE__."::video_part_brick_change($env{'video_part.ID'},$env{'video_part.ID_brick'})");
	
	my %part=App::020::SQL::functions::get_ID(
		'ID' => $env{'video_part.ID'},
		'db_h' => "main",
		'db_name' => $App::510::db_name,
		'tb_name' => "a510_video_part",
		'columns' => {'*'=>1}
	);
	
	if (!$part{'ID'})
	{
		main::_log("brick not found",1);
		$t->close();
		return undef;
	}
	
	if ($part{'ID_brick'} eq $env{'video_part.ID_brick'})
	{
		main::_log("already changed ID_brick to '$part{'ID_brick'}'");
		$t->close();
		return 1;
	}
	
	my $sql=qq{
		SELECT
			video.ID_entity AS ID_entity_video,
			video.ID AS ID_video,
			video_attrs.ID AS ID_attrs,
			video_part.ID AS ID_part,
			video_part_attrs.ID AS ID_part_attrs,
			
			LEFT(video.datetime_rec_start, 16) AS datetime_rec_start,
			LEFT(video_attrs.datetime_create, 18) AS datetime_create,
			LEFT(video.datetime_rec_start,10) AS date_recorded,
			LEFT(video.datetime_rec_stop, 16) AS datetime_rec_stop,
			
			video_attrs.ID_category,
			
			video_attrs.name,
			video_attrs.name_url,
			video_attrs.description,
			video_attrs.order_id,
			video_attrs.priority_A,
			video_attrs.priority_B,
			video_attrs.priority_C,
			video_attrs.lng,
			
			video_part_attrs.name AS part_name,
			video_part_attrs.description AS part_description,
			video_part.part_id AS part_id,
			video_part.keywords AS part_keywords,
			video_part.visits,
			video_part_attrs.lng AS part_lng,
			
			video_part.rating_score,
			video_part.rating_votes,
			(video_part.rating_score/video_part.rating_votes) AS rating,
			
			video_attrs.status,
			video_part.status AS status_part
			
		FROM
			`$App::510::db_name`.`a510_video` AS video
		INNER JOIN `$App::510::db_name`.`a510_video_ent` AS video_ent ON
		(
			video_ent.ID_entity = video.ID_entity
		)
		LEFT JOIN `$App::510::db_name`.`a510_video_attrs` AS video_attrs ON
		(
			video_attrs.ID_entity = video.ID
		)
		INNER JOIN `$App::510::db_name`.`a510_video_part` AS video_part ON
		(
			video_part.ID_entity = video.ID_entity
		)
		LEFT JOIN `$App::510::db_name`.`a510_video_part_attrs` AS video_part_attrs ON
		(
			video_part_attrs.ID_entity = video_part.ID AND
			video_part_attrs.lng = video_attrs.lng
		)
		
		WHERE
			video.ID AND
			video_attrs.ID AND
			video_part.ID=?
		
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'bind'=>[$part{'ID'}],'quiet'=>1);
	my %video_db=$sth0{'sth'}->fetchhash();
	
	my %brick_src;
	%brick_src=App::020::SQL::functions::get_ID(
		'ID' => $part{'ID_brick'},
		'db_h' => "main",
		'db_name' => $App::510::db_name,
		'tb_name' => "a510_video_brick",
		'columns' => {'*'=>1}
	) if $part{'ID_brick'};
	
	my $brick_src_class='App::510::brick';
		$brick_src_class.="::".$brick_src{'name'}
			if $brick_src{'name'};
	
	main::_log("source brick class = '$brick_src_class'");
	
	my %brick_dst=App::020::SQL::functions::get_ID(
		'ID' => $env{'video_part.ID_brick'},
		'db_h' => "main",
		'db_name' => $App::510::db_name,
		'tb_name' => "a510_video_brick",
		'columns' => {'*'=>1}
	);
	
	my $brick_dst_class='App::510::brick';
		$brick_dst_class.="::".$brick_dst{'name'}
			if $brick_dst{'name'};
	
	main::_log("destination brick class = '$brick_dst_class'");
	
	my %sth1=TOM::Database::SQL::execute(qq{
		SELECT
			*
		FROM
			`$App::510::db_name`.a510_video_part_file
		WHERE
			ID_entity=?
			AND status IN ('Y','N','L','W')
		ORDER BY
			ID_format
	},'bind'=>[$env{'video_part.ID'}],'quiet'=>1);
	my @files_move;
	while (my %db1_line=$sth1{'sth'}->fetchhash())
	{
		main::_log("video_part_file.ID=$db1_line{'ID'} format.ID=$db1_line{'ID_format'} name=$db1_line{'name'}");
		
		my $video_=$brick_src_class->video_part_file_path({
			'video_part.ID' => $part{'ID'},
			'video_format.ID' => $db1_line{'ID_format'},
			'video_part_file.ID' => $db1_line{'ID'},
			'video_part_file.file_alt_src' => $db1_line{'file_alt_src'},
			'video_part_file.name' => $db1_line{'name'},
			'video_part_file.file_ext' => $db1_line{'file_ext'},
			'video_part.datetime_air' => $part{'datetime_air'},
		});
		my $src_dir=$video_->{'dir'};
		my $src_file_path=$video_->{'file_path'};
		
		
		my $video_=$brick_dst_class->video_part_file_path({
			'video_part.ID' => $part{'ID'},
			'video_format.ID' => $db1_line{'ID_format'},
			'video_part_file.ID' => $db1_line{'ID'},
#			'video_part_file.name' => $db1_line{'name'},
			'video_part_file.file_ext' => $db1_line{'file_ext'},
			'video_part.datetime_air' => $part{'datetime_air'},
			
			'video.datetime_rec_start' => $video_db{'datetime_rec_start'},
			'video_attrs.name' => ($video_db{'name'} || $video_db{'ID_video'}),
			'video_part_attrs.name' => $video_db{'part_name'}
		});
		my $dst_dir=$video_->{'dir'};
		my $dst_file_path=$video_->{'file_path'};
		
		main::_log(" file src '$src_dir/$src_file_path'");
		main::_log(" file dst '$dst_dir/$dst_file_path'");
		
		if ($src_dir.'/'.$src_file_path eq $dst_dir.'/'.$dst_file_path)
		{
			main::_log("src file same as destination");
			next;
		}
		
		# test source file
		if ($brick_src_class->can('testdir'))
		{
			if (!$brick_src_class->testdir($src_dir))
			{
				main::_log("src dir can't be found, exiting",1);
				$t->close();
				return undef;
			}
			if ($brick_src_class->can('testfile'))
			{
				if (!$brick_src_class->testfile($src_dir.'/'.$src_file_path))
				{
					main::_log("src file can't be found, exiting",1);
					$t->close();
					return undef;
				}
			}
		}
		elsif (-e $src_dir && !-e $src_dir.'/'.$src_file_path)
		{
			main::_log("src file can't be found, dir exits",1);
			$t->close();
			return undef;
		}
		elsif (!-e $src_dir.'/'.$src_file_path)
		{
			main::_log("src file can't be found",1);
			$t->close();
			return undef;
		}
		
		push @files_move,[
			$src_dir.'/'.$src_file_path,
			$dst_dir.'/'.$dst_file_path,
			$db1_line{'ID'}, # ID
			$video_->{'video_part_file.name'}
		];
	}
	
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			*
		FROM
			`$App::510::db_name`.a510_video_part_smil
		WHERE
			ID_entity=?
		LIMIT 1
	},'bind'=>[$part{'ID'}],'quiet'=>1);
	my %db0_line=$sth0{'sth'}->fetchhash();
	my $smil_src_file;
	if ($db0_line{'name'})
	{
		my $smil_=$brick_src_class->video_part_smil_path({
			'video_part.ID' => $part{'ID'},
			'video_part_smil.name' => $db0_line{'name'}
		});
		$smil_src_file=$smil_->{'dir'}.'/'.$smil_->{'smil_path'};
		main::_log("smil src '$smil_src_file'");
	}
	
	# copy files
	use File::Copy;
	my $i=0;
	foreach (@files_move)
	{
		$i++;
		my $src_file=$_->[0];
		my $dst_file=$_->[1];
		
		# pridat este download ak ideme z brick na brick
		
		if ($brick_src_class->can('download'))
		{
			
			if ($brick_dst_class->can('upload'))
			{
				# download to upload over tempfile
				my $temp=new TOM::Temp::file();
				
				main::_log(" download file [$i]");
				$brick_src_class->download(
					$src_file,
					$temp->{'filename'}
				) || do {
					main::_log("error $!",1);
					$t->close();
					return undef;
				};
				
				main::_log(" upload file [$i]");
				$brick_dst_class->upload(
					$temp->{'filename'},
					$dst_file
				) || do {
					main::_log("error $!",1);
					$t->close();
					return undef;
				};
				
			}
			else
			{
				main::_log(" download file [$i]");
				
				$brick_src_class->download(
					$src_file,
					$dst_file
				) || do {
					main::_log("$!",1);
					$t->close();
					return undef;
				};
			}
			
		}
		elsif ($brick_dst_class->can('upload'))
		{
			main::_log(" upload file [$i] size=".format_bytes((stat $src_file)[7]));
			$brick_dst_class->upload(
				$src_file,
				$dst_file
			) || do {
				main::_log("$!",1);
				$t->close();
				return undef;
			};
		}
		else
		{
			main::_log(" copy file [$i] '$src_file' size=".format_bytes((stat $src_file)[7]));
			copy($src_file,$dst_file) || do {
				main::_log("$!",1);
				$t->close();
				return undef;
			};
		}
	}
	
	# rename files in db to new names
	my $i=0;
	foreach (@files_move)
	{
		$i++;
		my $id=$_->[2];
		my $name=$_->[3];
		main::_log(" rename file in db [$i] to '$name'");
		my %sth0=TOM::Database::SQL::execute(qq{
			UPDATE
				`$App::510::db_name`.a510_video_part_file
			SET
				name=?,
				file_alt_src=NULL
			WHERE
				ID=?
			LIMIT 1
		},'bind'=>[$name,$id],'quiet'=>1);
		# noooo, don't change datetime_create
#		App::020::SQL::functions::update(
#			'ID' => $id,
#			'db_h' => 'main',
#			'db_name' => $App::510::db_name,
#			'tb_name' => 'a510_video_part_file',
#			'data' =>
#			{
#				'name' => $name
#			},
#			'columns' => 
#			{
#				'file_alt_src' => 'NULL'
#			},
#			'-journalize' => 1,
#		);
	}
	
	# update video_part.ID_brick
	App::020::SQL::functions::update(
		'ID' => $part{'ID'},
		'db_h' => "main",
		'db_name' => $App::510::db_name,
		'tb_name' => "a510_video_part",
		'columns' =>
		{
			'ID_brick' => $env{'video_part.ID_brick'}
		},
		'-journalize' => 1
	);
	
	# remove old files
	# TODO: delay this for couple of hours
	my $i=0;
	foreach (@files_move)
	{
		$i++;
		my $src_file=$_->[0];
		my $dst_file=$_->[1];
		main::_log(" unlink file [$i]");
		
		if ($brick_src_class->can('unlink'))
		{
			$brick_src_class->unlink(
				$src_file
			) || do {
				main::_log("$!",1);
				$t->close();
				return undef;
			};
		}
		else
		{
			unlink($src_file) || do {
				main::_log("$!",1);
				# sorry, can't stop this process now
			}
		}
	}
	
	# remove smil from db - hard way
	my %sth0=TOM::Database::SQL::execute(qq{
		DELETE
		FROM
			`$App::510::db_name`.a510_video_part_smil
		WHERE
			ID_entity=?
		LIMIT 1
	},'bind'=>[$part{'ID'}],'quiet'=>1);
	
	# generate smil file
	video_part_smil_generate('video_part.ID' => $part{'ID'});
	
	# remove old smil file
	if ($smil_src_file)
	{
		main::_log("unlink $smil_src_file");
		
		if ($brick_src_class->can('unlink'))
		{
			$brick_src_class->unlink(
				$smil_src_file
			) || do {
				main::_log("$!",1);
				$t->close();
				return undef;
			};
		}
		else
		{
			unlink $smil_src_file || do {
				main::_log("$!",1);
			};
		}
	}
	
	$t->close();
	return 1;
}


sub _video_part_file_genpath
{
	my $format=shift;
	my $ID=shift;
	my $name=shift;
	my $ext=shift;
	$ID=~s|^(....).*$|\1|;
	
	my $pth=$tom::P_media.'/a510/video/part/file/'.$format.'/'.$ID;
	if (!-d $pth)
	{
		File::Path::mkpath($tom::P_media.'/a510/video/part/file/'.$format.'/'.$ID);
		chmod 0777, $tom::P_media.'/a510/video/part/file/'.$format.'/'.$ID;
	}
	return "$format/$ID/$name.$ext";
};



sub video_part_file_process
{
	my %env=@_;
	my %outret;
	my $t=track TOM::Debug(__PACKAGE__."::video_part_file_process()");
	main::_log("video1='$env{'video1'}'");
	main::_log("video2='$env{'video2'}'");
	
	my $temp_passlog=new TOM::Temp::file('unlink_ext'=>'*','ext'=>'log','dir'=>$main::ENV{'TMP'},'nocreate_'=>1);
	my $temp_statslog=new TOM::Temp::file('unlink_ext'=>'*','ext'=>'log','dir'=>$main::ENV{'TMP'},'nocreate_'=>1);
	
	my $procs; # how many changes have been made in video2 file
	
	if (!$env{'ext'})
	{
		$env{'ext'}=$App::510::video_format_ext_default;
		$procs++;
	}
	
	# read the first video
	main::_log("reading file '$env{'video1'}'");
	my $movie1 = Movie::Info->new || die "Couldn't find an mplayer to use\n";
	my %movie1_info = $movie1->info($env{'video1'});
	foreach (keys %movie1_info)
	{
		main::_log("key $_='$movie1_info{$_}'");
	}
	
	my $target_is_same=0;
	foreach my $line(split('\n',$env{'definition'}))
	{
		$line=~s|[\n\r]||g;
		next unless $line=~/=/;
#		my @ref=split('=',$line);
		my @ref=split('(<=|>=|>|<|=)',$line);
		main::_log("target definition key $ref[0]$ref[1]'$ref[2]'");
		
		my $ref1_same=0;
		foreach (split(';',$ref[2])){
			if ($ref[1] eq "<")
			{
				$ref1_same=1 if $movie1_info{$ref[0]} < $_
			}
			elsif ($ref[1] eq "<=")
			{
				$ref1_same=1 if $movie1_info{$ref[0]} <= $_
			}
			elsif ($ref[1] eq ">")
			{
				$ref1_same=1 if $movie1_info{$ref[0]} > $_
			}
			elsif ($ref[1] eq ">=")
			{
				$ref1_same=1 if $movie1_info{$ref[0]} >= $_
			}
			else
			{
				$ref1_same=1 if $movie1_info{$ref[0]} eq $_
			}
		};
		if (!$ref1_same){$target_is_same=0;last;}
		
		$target_is_same=1;
	}
	
	$target_is_same=0 if $env{'process_force'};
	
	if ($target_is_same)
	{
		main::_log("target video is the same as source");
		main::_log("copying the file...");
		File::Copy::copy($env{'video1'}, $env{'video2'});
		$t->close();
		$outret{'return'}=0;
		return %outret;
	}
	
	$env{'fps'}=$movie1_info{'fps'} if $movie1_info{'fps'};
	
	my @files;
	my %files_key;
	$env{'process'}=~s|\r\n|\n|g;
	$env{'process'}=~s|\s+$||m;
	$env{'process'}.="\nencode()" unless $env{'process'}=~/encode\(\)$/m;
	
	if (-e 'frameno.avi'){main::_log("removing frameno.avi");unlink 'frameno.avi'}
	
#	print "$env{'process'}";exit;
	
	foreach my $function(split('\n',$env{'process'}))
	{
		$function=~s|\s+$||g;
		$function=~s|^\s+||g;
		
		next if $function=~/^#/;
		next unless $function=~/^([\w_]+)\((.*)\)/;
		
		my $function_name=$1;
		my $function_params=$2;
		
		my @params;
		foreach my $param (split(',',$function_params,2))
		{
			if ($param=~/^'.*'$/){$param=~s|^'||;$param=~s|'$||;}
			if ($param=~/^".*"$/){$param=~s|^"||;$param=~s|"$||;}
			push @params, $param;
		}
		
		if ($function_name eq "set_env")
		{
			main::_log("exec $function_name($params[0],$params[1])");
			#push @env0, '-'.$params[0].' '.$params[1];
			$env{$params[0]}=$params[1];
			#$procs++;
			next;
		}
		
		if ($function_name eq "del_env")
		{
			main::_log("exec $function_name(@params)");
			foreach (@params){delete $env{$_};}
			next;
		}
		
		if ($function_name eq "stop")
		{
			main::_log("exec $function_name()");
			last;
		}
		
		if ($function_name eq "normalize_audio")
		{
			main::_log("exec $function_name()");
			$env{'video1'}=~/.*\.(.*?)$/;
			
			push @files,new TOM::Temp::file('ext'=>'avi','dir'=>$main::ENV{'TMP'},'nocreate'=>1);
			
			main::_log($env{'video1'}."->".$files[-1]->{'filename'});
			
			my $cmd=$mencoder_exec.' '.$env{'video1'}.' -ovc x264 -af volnorm=1 -oac mp3lame -lameopts cbr:br=128 -o '.$files[-1]->{'filename'};
			main::_log("cmd=$cmd");
			$outret{'return'}=system("$cmd");main::_log("out=$outret{'return'}");
			if ($outret{'return'}){$t->close();return %outret}
			
			$env{'video1'}=$files[-1]->{'filename'};
			
			next;
		}
		
		if ($function_name eq "encode")
		{
			main::_log("exec $function_name()");
			
			# add params in this order
			my @encoder_env;
			my $ext='avi';
			if (!$env{'encoder'} || $env{'encoder'} eq "mencoder")
			{
				if ($env{'oac'}){push @encoder_env, '-oac '.$env{'oac'};}
				if ($env{'af'}){push @encoder_env, '-af '.$env{'af'};}
				if ($env{'lameopts'}){push @encoder_env, '-lameopts '.$env{'lameopts'};}
				if ($env{'faacopts'}){push @encoder_env, '-faacopts '.$env{'faacopts'};}
				if ($env{'srate'}){push @encoder_env, '-srate '.$env{'srate'};}
				if ($env{'sws'}){push @encoder_env, '-sws '.$env{'sws'};}
				if ($env{'mc'}){push @encoder_env, '-mc '.$env{'mc'};}
				if ($env{'idx'}){push @encoder_env, '-idx '.$env{'idx'};}
				if ($env{'ovc'}){push @encoder_env, '-ovc '.$env{'ovc'};}
				if ($env{'vc'}){push @encoder_env, '-vc '.$env{'vc'};}
				if ($env{'x264encopts'})
					{push @encoder_env, '-x264encopts '.$env{'x264encopts'}.do{$env{'pass'} ? ':pass='.$env{'pass'} : '';};}
				if ($env{'lavcopts'}){push @encoder_env, '-lavcopts '.$env{'lavcopts'};}
				if ($env{'of'}){push @encoder_env, '-of '.$env{'of'};}
				if ($env{'lavfopts'}){push @encoder_env, '-lavfopts '.$env{'lavfopts'};}
				if ($env{'vf'}){push @encoder_env, '-vf '.$env{'vf'};}
				if ($env{'fps'}){push @encoder_env, '-fps '.$env{'fps'};}
				if ($env{'demuxer'}){push @encoder_env, '-demuxer '.$env{'demuxer'};}
				if ($env{'ofps_max'})
				{
					main::_log("checking -ofps for max value $env{'ofps_max'}");
					if ($movie1_info{'fps'} > $env{'ofps_max'})
					{
						main::_log("exec set_env('ofps','$env{'ofps_max'}')");
						$env{'ofps'}=$env{'ofps_max'};
					}
				}
				if ($env{'ofps'}){push @encoder_env, '-ofps '.$env{'ofps'};}
				if (exists $env{'nosound'}){push @encoder_env, '-nosound'}
				if (exists $env{'novideo'}){push @encoder_env, '-novideo'}
				if ($env{'endpos'}){push @encoder_env, '-endpos '.$env{'endpos'};}
				# suggest extension
				$ext='mp4' if $env{'x264encopts'};
				$ext='avi' if $env{'lavfopts'}=~/format=avi/;
				$ext='flv' if $env{'lavfopts'}=~/format=flv/;
				$ext='wmv' if $env{'lavfopts'}=~/format=wmv/;
				$ext='wmv' if $env{'lavcopts'}=~/vcodec=wmv2/;
				$ext='264' if ($env{'x264encopts'} && exists $env{'nosound'});
			}
			elsif ($env{'encoder'} eq "ffmpeg")
			{
				if ($env{'pass'})
				{
					push @encoder_env, '-pass '.$env{'pass'};
					push @encoder_env, '-passlogfile '.$temp_passlog->{'filename'};
#					push @encoder_env, '-stats '.$temp_statslog->{'filename'};
				}
				if ($env{'vframes'}){push @encoder_env, '-vframes '.$env{'vframes'};}
				if ($env{'f'}){push @encoder_env, '-f '.$env{'f'};}
				if ($env{'map'}){push @encoder_env, '-map '.$env{'map'};}
				if ($env{'map0'}){push @encoder_env, '-map '.$env{'map0'};}
				if ($env{'map1'}){push @encoder_env, '-map '.$env{'map1'};}
				if ($env{'map2'}){push @encoder_env, '-map '.$env{'map2'};}
				if (exists $env{'an'} && !$env{'acodec'}){push @encoder_env, '-an'}
				if (exists $env{'sameq'}){push @encoder_env, '-sameq '}
				if (exists $env{'deinterlace'}){push @encoder_env, '-deinterlace '}
				if ($env{'flags'}){push @encoder_env, '-flags '.$env{'flags'};}
				if ($env{'flags2'}){push @encoder_env, '-flags2 '.$env{'flags2'};}
				if ($env{'cmp'}){push @encoder_env, '-cmp '.$env{'cmp'};}
				if ($env{'subcmp'}){push @encoder_env, '-subcmp '.$env{'subcmp'};}
				if ($env{'mbcmp'}){push @encoder_env, '-mbcmp '.$env{'mbcmp'};}
				if ($env{'ildctcmp'}){push @encoder_env, '-ildctcmp '.$env{'ildctcmp'};}
				if ($env{'precmp'}){push @encoder_env, '-precmp '.$env{'precmp'};}
				if ($env{'skipcmp'}){push @encoder_env, '-skipcmp '.$env{'skipcmp'};}
				if (exists $env{'mv0'}){push @encoder_env, '-mv0 ';}
				if ($env{'mbd'}){push @encoder_env, '-mbd '.$env{'mbd'};}
				if ($env{'inter_matrix'}){push @encoder_env, '-inter_matrix '.$env{'inter_matrix'};}
				if ($env{'pred'}){push @encoder_env, '-pred '.$env{'pred'};}
				if ($env{'partitions'}){push @encoder_env, '-partitions '.$env{'partitions'};}
				if ($env{'me'}){push @encoder_env, '-me '.$env{'me'};}
				if ($env{'subq'}){push @encoder_env, '-subq '.$env{'subq'};}
				if ($env{'trellis'}){push @encoder_env, '-trellis '.$env{'trellis'};}
				if ($env{'refs'}){push @encoder_env, '-refs '.$env{'refs'};}
				if ($env{'bf'}){push @encoder_env, '-bf '.$env{'bf'};}
				if ($env{'b_strategy'}){push @encoder_env, '-b_strategy '.$env{'b_strategy'};}
				if ($env{'coder'}){push @encoder_env, '-coder '.$env{'coder'};}
				if ($env{'me_range'}){push @encoder_env, '-me_range '.$env{'me_range'};}
				if ($env{'q'}){push @encoder_env, '-q '.$env{'q'};}
				if ($env{'qp'}){push @encoder_env, '-qp '.$env{'qp'};}
				if ($env{'crf'}){push @encoder_env, '-crf '.$env{'crf'};}
				if ($env{'g'}){push @encoder_env, '-g '.$env{'g'};}
				if ($env{'strict'}){push @encoder_env, '-strict '.$env{'strict'};}
				if ($env{'keyint_min'}){push @encoder_env, '-keyint_min '.$env{'keyint_min'};}
				if ($env{'keyint'}){push @encoder_env, '-keyint '.$env{'keyint'};}
				if ($env{'force_key_frames'}){push @encoder_env, '-force_key_frames '.$env{'force_key_frames'};}
				if (exists $env{'sc_threshold'}){push @encoder_env, '-sc_threshold '.$env{'sc_threshold'};}
				if ($env{'x264opts'}){push @encoder_env, '-x264opts '.$env{'x264opts'};}
				if ($env{'i_qfactor'}){push @encoder_env, '-i_qfactor '.$env{'i_qfactor'};}
				if ($env{'bt'}){push @encoder_env, '-bt '.$env{'bt'};}
				if ($env{'rc_eq'}){push @encoder_env, "-rc_eq '".$env{'rc_eq'}."'";}
				if ($env{'qcomp'}){push @encoder_env, '-qcomp '.$env{'qcomp'};}
				if ($env{'qblur'}){push @encoder_env, '-qblur '.$env{'qblur'};}
				if ($env{'qmin'}){push @encoder_env, '-qmin '.$env{'qmin'};}
				if ($env{'qmax'}){push @encoder_env, '-qmax '.$env{'qmax'};}
				if ($env{'qdiff'}){push @encoder_env, '-qdiff '.$env{'qdiff'};}
				if ($env{'vcodec'}){push @encoder_env, '-vcodec '.$env{'vcodec'};}
				if ($env{'vpre'}){push @encoder_env, '-vpre '.$env{'vpre'};}
				if (exists $env{'threads'}){push @encoder_env, '-threads '.$env{'threads'};}
				if ($env{'b'}){
					if ($env{'upscale'} eq "false" && $movie1_info{'bitrate'})
					{ # check for upscale
						my $bitrate=$env{'b'};
							$bitrate=~s|k$|000|;
						if ($bitrate > $movie1_info{'bitrate'})
						{
							push @encoder_env, '-b '.$movie1_info{'bitrate'};
						}
						else
						{
							push @encoder_env, '-b '.$env{'b'};
						}
					}
					else
					{
						push @encoder_env, '-b '.$env{'b'};
					}
				}
				if ($env{'b:v'}){
					if ($env{'upscale'} eq "false" && $movie1_info{'bitrate'})
					{ # check for upscale
						my $bitrate=$env{'b:v'};
							$bitrate=~s|k$|000|;
						if ($bitrate > $movie1_info{'bitrate'})
						{
							push @encoder_env, '-b:v '.$movie1_info{'bitrate'};
						}
						else
						{
							push @encoder_env, '-b:v '.$env{'b:v'};
						}
					}
					else
					{
						push @encoder_env, '-b:v '.$env{'b:v'};
					}
				}
				if ($env{'s_width'})
					{$env{'s'}=$env{'s_width'}.'x'.(int($movie1_info{'height'}/($movie1_info{'width'}/$env{'s_width'})/2)*2);}
				if ($env{'s_height'} && $movie1_info{'height'})
					{
						if ($env{'upscale'} eq "false" && $env{'s_height'} >= $movie1_info{'height'})
						{
							# don't upscale
						}
						else
						{
							$env{'s'}=(int($movie1_info{'width'}/($movie1_info{'height'}/$env{'s_height'})/2)*2).'x'.$env{'s_height'};
						}
					}
				if ($env{'s'}){push @encoder_env, '-s '.$env{'s'};}
				if ($env{'r'}){push @encoder_env, '-r '.$env{'r'};}
				if ($env{'acodec'}){
					push @encoder_env, '-acodec '.$env{'acodec'};
					if ($env{'acodec'})
					{
						push @encoder_env, '-strict -2';
					}
				}
				if ($env{'ab'}){
					if ($env{'upscale'} eq "false" && $movie1_info{'audio_bitrate'})
					{ # check for upscale
						my $bitrate=$env{'ab'};
							$bitrate=~s|k$|000|;
						if ($bitrate > $movie1_info{'audio_bitrate'})
						{
							push @encoder_env, '-ab '.$movie1_info{'audio_bitrate'};
						}
						else
						{
							push @encoder_env, '-ab '.$env{'ab'};
						}
					}
					else
					{
						push @encoder_env, '-ab '.$env{'ab'};
					}
				}
				if ($env{'b:a'}){
					if ($env{'upscale'} eq "false" && $movie1_info{'audio_bitrate'})
					{ # check for upscale
						my $bitrate=$env{'b:a'};
							$bitrate=~s|k$|000|;
						if ($bitrate > $movie1_info{'audio_bitrate'})
						{
							push @encoder_env, '-b:a '.$movie1_info{'audio_bitrate'};
						}
						else
						{
							push @encoder_env, '-b:a '.$env{'b:a'};
						}
					}
					else
					{
						push @encoder_env, '-b:a '.$env{'b:a'};
					}
				}
				if ($env{'c:v'}){push @encoder_env, '-c:v '.$env{'c:v'};}
				if ($env{'c:a'}){
					push @encoder_env, '-c:a '.$env{'c:a'};
					push @encoder_env, '-strict -2';
				}
				if ($env{'preset'}){push @encoder_env, '-preset '.$env{'preset'};}
				if ($env{'tune'}){push @encoder_env, '-tune '.$env{'tune'};}
				if ($env{'profile'}){push @encoder_env, '-profile '.$env{'profile'};}
				if ($env{'profile:v'}){push @encoder_env, '-profile:v '.$env{'profile:v'};}
				if ($env{'level:v'}){push @encoder_env, '-level:v '.$env{'level:v'};}
				if ($env{'ar'}){push @encoder_env, '-ar '.$env{'ar'};}
				if ($env{'ac'}){push @encoder_env, '-ac '.$env{'ac'};}
				if ($env{'fs'}){push @encoder_env, '-fs '.$env{'fs'};}
				if ($env{'ss'}){push @encoder_env, '-ss '.$env{'ss'};}
				if ($env{'t'}){push @encoder_env, '-t '.$env{'t'};}
				if ($env{'async'}){push @encoder_env, '-async '.$env{'async'};}
				
				# suggest extension
				$ext='mp4' if $env{'f'} eq "mp4";
				$ext='flv' if $env{'f'} eq "flv";
			}
			elsif ($env{'encoder'} eq "avconv")
			{
				if ($env{'pass'})
				{
					push @encoder_env, '-pass '.$env{'pass'};
					push @encoder_env, '-passlogfile '.$temp_passlog->{'filename'};
#					push @encoder_env, '-stats '.$temp_statslog->{'filename'};
				}
				if ($env{'vframes'}){push @encoder_env, '-vframes '.$env{'vframes'};}
				if ($env{'f'}){push @encoder_env, '-f '.$env{'f'};}
				if ($env{'map'}){push @encoder_env, '-map '.$env{'map'};}
				if ($env{'map0'}){push @encoder_env, '-map '.$env{'map0'};}
				if ($env{'map1'}){push @encoder_env, '-map '.$env{'map1'};}
				if ($env{'map2'}){push @encoder_env, '-map '.$env{'map2'};}
				if (exists $env{'an'} && !$env{'acodec'}){push @encoder_env, '-an'}
				if (exists $env{'sameq'}){push @encoder_env, '-sameq '}
				if (exists $env{'deinterlace'}){push @encoder_env, '-deinterlace '}
				if ($env{'movflags'}){push @encoder_env, '-movflags '.$env{'movflags'};}
				if ($env{'flags'}){push @encoder_env, '-flags '.$env{'flags'};}
				if ($env{'flags2'}){push @encoder_env, '-flags2 '.$env{'flags2'};}
				if ($env{'cmp'}){push @encoder_env, '-cmp '.$env{'cmp'};}
				if ($env{'subcmp'}){push @encoder_env, '-subcmp '.$env{'subcmp'};}
				if ($env{'mbcmp'}){push @encoder_env, '-mbcmp '.$env{'mbcmp'};}
				if ($env{'ildctcmp'}){push @encoder_env, '-ildctcmp '.$env{'ildctcmp'};}
				if ($env{'precmp'}){push @encoder_env, '-precmp '.$env{'precmp'};}
				if ($env{'skipcmp'}){push @encoder_env, '-skipcmp '.$env{'skipcmp'};}
				if (exists $env{'mv0'}){push @encoder_env, '-mv0 ';}
				if ($env{'mbd'}){push @encoder_env, '-mbd '.$env{'mbd'};}
				if ($env{'inter_matrix'}){push @encoder_env, '-inter_matrix '.$env{'inter_matrix'};}
				if ($env{'pred'}){push @encoder_env, '-pred '.$env{'pred'};}
				if ($env{'partitions'}){push @encoder_env, '-partitions '.$env{'partitions'};}
				if ($env{'me'}){push @encoder_env, '-me '.$env{'me'};}
				if ($env{'subq'}){push @encoder_env, '-subq '.$env{'subq'};}
				if ($env{'trellis'}){push @encoder_env, '-trellis '.$env{'trellis'};}
				if ($env{'refs'}){push @encoder_env, '-refs '.$env{'refs'};}
				if ($env{'bf'}){push @encoder_env, '-bf '.$env{'bf'};}
				if ($env{'b_strategy'}){push @encoder_env, '-b_strategy '.$env{'b_strategy'};}
				if ($env{'coder'}){push @encoder_env, '-coder '.$env{'coder'};}
				if ($env{'me_range'}){push @encoder_env, '-me_range '.$env{'me_range'};}
				if ($env{'q'}){push @encoder_env, '-q '.$env{'q'};}
				if ($env{'g'}){push @encoder_env, '-g '.$env{'g'};}
				if ($env{'strict'}){push @encoder_env, '-strict '.$env{'strict'};}
				if ($env{'keyint_min'}){push @encoder_env, '-keyint_min '.$env{'keyint_min'};}
				if ($env{'keyint'}){push @encoder_env, '-keyint '.$env{'keyint'};}
				if (exists $env{'sc_threshold'}){push @encoder_env, '-sc_threshold '.$env{'sc_threshold'};}
				if ($env{'x264opts'}){push @encoder_env, '-x264opts '.$env{'x264opts'};}
				if ($env{'libx264opts'}){push @encoder_env, '-libx264opts '.$env{'libx264opts'};}
				if ($env{'i_qfactor'}){push @encoder_env, '-i_qfactor '.$env{'i_qfactor'};}
				if ($env{'bt'}){push @encoder_env, '-bt '.$env{'bt'};}
				if ($env{'rc_eq'}){push @encoder_env, "-rc_eq '".$env{'rc_eq'}."'";}
				if ($env{'qcomp'}){push @encoder_env, '-qcomp '.$env{'qcomp'};}
				if ($env{'qblur'}){push @encoder_env, '-qblur '.$env{'qblur'};}
				if ($env{'qmin'}){push @encoder_env, '-qmin '.$env{'qmin'};}
				if ($env{'qmax'}){push @encoder_env, '-qmax '.$env{'qmax'};}
				if ($env{'qdiff'}){push @encoder_env, '-qdiff '.$env{'qdiff'};}
				if ($env{'vcodec'}){push @encoder_env, '-vcodec '.$env{'vcodec'};}
				if ($env{'acodec'}){
					push @encoder_env, '-acodec '.$env{'acodec'};
					if ($env{'acodec'})
					{
						push @encoder_env, '-strict -2';
					}
				}
				if ($env{'c:v'}){push @encoder_env, '-c:v '.$env{'c:v'};}
				if ($env{'c:a'}){
					push @encoder_env, '-c:a '.$env{'c:a'};
					push @encoder_env, '-strict -2';
				}
#				if ($env{'vpre'}){push @encoder_env, '-vpre '.$env{'vpre'};}
				if ($env{'preset'}){push @encoder_env, '-preset '.$env{'preset'};}
				if ($env{'tune'}){push @encoder_env, '-tune '.$env{'tune'};}
				if ($env{'profile'}){push @encoder_env, '-profile '.$env{'profile'};}
				if ($env{'profile:v'}){push @encoder_env, '-profile:v '.$env{'profile:v'};}
				if ($env{'level:v'}){push @encoder_env, '-level:v '.$env{'level:v'};}
				if ($env{'pass'})
				{
					push @encoder_env, '-stats '.$temp_statslog->{'filename'};
				}
				if (exists $env{'threads'}){push @encoder_env, '-threads '.$env{'threads'};}
				if ($env{'b'}){
					if ($env{'upscale'} eq "false" && $movie1_info{'bitrate'})
					{ # check for upscale
						my $bitrate=$env{'b'};
							$bitrate=~s|k$|000|;
						if ($bitrate > $movie1_info{'bitrate'})
						{
							push @encoder_env, '-b '.$movie1_info{'bitrate'};
						}
						else
						{
							push @encoder_env, '-b '.$env{'b'};
						}
					}
					else
					{
						push @encoder_env, '-b '.$env{'b'};
					}
				}
				if ($env{'b:v'}){
					if ($env{'upscale'} eq "false" && $movie1_info{'bitrate'})
					{ # check for upscale
						my $bitrate=$env{'b:v'};
							$bitrate=~s|k$|000|;
						if ($bitrate > $movie1_info{'bitrate'})
						{
							push @encoder_env, '-b:v '.$movie1_info{'bitrate'};
						}
						else
						{
							push @encoder_env, '-b:v '.$env{'b:v'};
						}
					}
					else
					{
						push @encoder_env, '-b:v '.$env{'b:v'};
					}
				}
				if ($env{'s_width'})
					{$env{'s'}=$env{'s_width'}.'x'.(int($movie1_info{'height'}/($movie1_info{'width'}/$env{'s_width'})/2)*2);}
				if ($env{'s_height'} && $movie1_info{'height'})
					{
						if ($env{'upscale'} eq "false" && $env{'s_height'} >= $movie1_info{'height'})
						{
							# don't upscale
						}
						else
						{
							$env{'s'}=(int($movie1_info{'width'}/($movie1_info{'height'}/$env{'s_height'})/2)*2).'x'.$env{'s_height'};
						}
					}
				if ($env{'s'}){push @encoder_env, '-s '.$env{'s'};}
				if ($env{'r'}){
					if ($movie1_info{'fps'} && $env{'upscale'} eq "false")
					{
						my $fps=int($movie1_info{'fps'});
						if ($fps < $env{'r'})
						{
							$env{'r'} = $fps;
						}
					}
					push @encoder_env, '-r '.$env{'r'};
				}
				if ($env{'ab'}){
					if ($env{'upscale'} eq "false" && $movie1_info{'audio_bitrate'})
					{ # check for upscale
						my $bitrate=$env{'ab'};
							$bitrate=~s|k$|000|;
						if ($bitrate > $movie1_info{'audio_bitrate'})
						{
							push @encoder_env, '-ab '.$movie1_info{'audio_bitrate'};
						}
						else
						{
							push @encoder_env, '-ab '.$env{'ab'};
						}
					}
					else
					{
						push @encoder_env, '-ab '.$env{'ab'};
					}
				}
				if ($env{'b:a'}){
					if ($env{'upscale'} eq "false" && $movie1_info{'audio_bitrate'})
					{ # check for upscale
						my $bitrate=$env{'b:a'};
							$bitrate=~s|k$|000|;
						if ($bitrate > $movie1_info{'audio_bitrate'})
						{
							push @encoder_env, '-b:a '.$movie1_info{'audio_bitrate'};
						}
						else
						{
							push @encoder_env, '-b:a '.$env{'b:a'};
						}
					}
					else
					{
						push @encoder_env, '-b:a '.$env{'b:a'};
					}
				}
				if ($env{'ar'}){push @encoder_env, '-ar '.$env{'ar'};}
				if ($env{'ac'}){push @encoder_env, '-ac '.$env{'ac'};}
				if ($env{'fs'}){push @encoder_env, '-fs '.$env{'fs'};}
				if ($env{'ss'}){push @encoder_env, '-ss '.$env{'ss'};}
				if ($env{'t'}){push @encoder_env, '-t '.$env{'t'};}
				if ($env{'async'}){push @encoder_env, '-async '.$env{'async'};}
				
				# suggest extension
				$ext='mp4' if $env{'f'} eq "mp4";
				$ext='flv' if $env{'f'} eq "flv";
			}
			
			$outret{'ext'}=$ext;
			
			my $temp_video;
			if ($env{'pass'})
			{
				if ($files_key{'pass'})
				{
					main::_log("using same file for pass encoding ".$files_key{'pass'}->{'filename'});
					$temp_video=$files_key{'pass'};
				}
				else
				{
					$temp_video=new TOM::Temp::file('ext'=>$ext,'dir'=>$main::ENV{'TMP'},'nocreate_'=>1);
					$files_key{'pass'}=$temp_video;
				}
			}
			$temp_video=new TOM::Temp::file('ext'=>$ext,'dir'=>$main::ENV{'TMP'},'nocreate_'=>1) unless $temp_video;
			# don't erase files after partial encode()
			push @files, $temp_video;
			$files_key{$env{'o_key'}}=$temp_video if $env{'o_key'};
			
			
			#main::_log("encoding to file '$temp_video->{'filename'}'");
			my $ff=$env{'video1'};
			$ff=~s| |\\ |g;
			
			my $cmd="/usr/bin/mencoder ".$ff." -o ".($env{'o'} || $temp_video->{'filename'});
			$cmd="cd $main::ENV{'TMP'};$ffmpeg_exec -y -i ".$ff if $env{'encoder'} eq "ffmpeg";
			#$cmd="cd $main::ENV{'TMP'};$avconv_exec -y -i ".$ff if $env{'encoder'} eq "avconv";
			$cmd="$avconv_exec -y -i ".$ff if $env{'encoder'} eq "avconv";
			
			foreach (@encoder_env){$cmd.=" $_";}
			$cmd.=" ".($env{'o'} || $temp_video->{'filename'}) if $env{'encoder'} eq "ffmpeg";
			$cmd.=" ".($env{'o'} || $temp_video->{'filename'}) if $env{'encoder'} eq "avconv";
			main::_log("cmd=$cmd");
			
			if ($tom::test && $env{'encoder'} eq "avconv")
			{
				main::_log("use async avconv processing");
				my $cv = AnyEvent->condvar;
				require AnyEvent::Run;
				my $handle = AnyEvent::Run->new(
					cmd      => [ $cmd ],
					priority => 19,              # optional nice value 
					on_read  => sub {
						my $handle = shift;
						use Data::Dumper;
#						main::_log("handle ".Dumper($handle),1);
						my $line=$handle->{'rbuf'};
						$handle->{'rbuf'}='';
#						$line=~s|\r||gms;
#						print "!$line!\n";
						
#						open HND,'>'.$tom::P.'/_temp/dump.dump';
#						print HND $line;
#						close HND;
						if ($line)
						{
							if ($line=~/frame=\s*(\d*) fps=\s*?(\d*) q=\s*([\d\.]*) size=\s*?([\d\.]*\w+) time=\s*?([\d\.]*) bitrate=\s+?([\d\.]+\w+)/) #     
							{
								my $frame=$1;
								my $fps=$2;
								my $q=$3;
								my $size=$4;
								my $time=$5;
								my $bitrate=$6;
								
								my $perc=int(($time / $movie1_info{'length'})*100);
								
								main::_log("frame=$frame fps=$fps q=$q size=$size time=$time [$perc%] bitrate=$bitrate");
							}
							else
							{
#								main::_log("$line");
							}
						}
#						$line=~/([^\n\r]*)\r$/ && do
#						{
#							$line=$1;
#							$line=~s|[\n\r]||g;
#							main::_log("$line");
#						}
						
#						print Dumper($handle->{'rbuf'});
#						print $1."\n";
#						$cv->send;
					},
					on_error  => sub {
						my ($handle, $fatal, $msg) = @_;
						main::_log("error $fatal $msg",1);
						$cv->send;
					},
				);
				
				$cv->recv;
			}
			else
			{
				$outret{'return'}=system("$cmd");main::_log("out=$outret{'return'}");
			}
			
#			$outret{'return'}=undef if $outret{'return'}==256;
			if ($outret{'return'} && $outret{'return'} != 11){$t->close();return %outret}
			
			$procs++;
			next;
		}
		
		if ($function_name eq "MP4Box")
		{
			main::_log("exec $function_name()");
			my $cmd='cd '.$main::ENV{'TMP'}.';'.$MP4Box_exec.' '.$files[@files-1]->{'filename'};
			main::_log("cmd=$cmd");
			$outret{'return'}=system("$cmd");main::_log("out=$outret{'return'}");
			$procs++;
			next;
		}
		
		if ($function_name eq "MP4BoxImport")
		{
			main::_log("exec $function_name()");
			
			my $temp_video=new TOM::Temp::file('ext'=>'mp4','dir'=>$main::ENV{'TMP'},'nocreate'=>1);
			
			if ($files_key{'video'})
			{
				main::_log("adding m4v");
				my $cmd='cd '.$main::ENV{'TMP'}.';'.$MP4Box_exec.' -add '.$files_key{'video'}->{'filename'}.'#video '.$temp_video->{'filename'};
				main::_log("cmd=$cmd");
				$outret{'return'}=system("$cmd");main::_log("out=$outret{'return'}");
				if ($outret{'return'}){$t->close();return %outret}
				
				if ($files_key{'audio'})
				{
					main::_log("adding m4a");
					my $cmd='cd '.$main::ENV{'TMP'}.';'.$MP4Box_exec.' -add '.$files_key{'audio'}->{'filename'}.'#audio '.$temp_video->{'filename'};
					main::_log("cmd=$cmd");
					$outret{'return'}=system("$cmd");main::_log("out=$outret{'return'}");
					if ($outret{'return'}){$t->close();return %outret}
				}
				
			}
			elsif ($files_key{'audiovideo'})
			{
				
				my $temp_video_input=new TOM::Temp::file('ext'=>'mp4','dir'=>$main::ENV{'TMP'},'nocreate'=>1);
				
				main::_log("adding m4v");
				my $cmd='cd '.$main::ENV{'TMP'}.';'.$MP4Box_exec.' -add '.$files_key{'audiovideo'}->{'filename'}.'#video '.$temp_video->{'filename'};
				main::_log("cmd=$cmd");
				$outret{'return'}=system("$cmd");main::_log("out=$outret{'return'}");
				if ($outret{'return'}){$t->close();return %outret}
				
				main::_log("adding m4a");
				my $cmd='cd '.$main::ENV{'TMP'}.';'.$MP4Box_exec.' -add '.$files_key{'audiovideo'}->{'filename'}.'#audio '.$temp_video->{'filename'};
				main::_log("cmd=$cmd");
				$outret{'return'}=system("$cmd");main::_log("out=$outret{'return'}");
				if ($outret{'return'}){$t->close();return %outret}
			}
			elsif ($files_key{'all'})
			{
				main::_log("adding a+v");
				my $cmd='cd '.$main::ENV{'TMP'}.';'.$MP4Box_exec.' -add '.$files_key{'all'}->{'filename'}.' '.$temp_video->{'filename'};
				main::_log("cmd=$cmd");
				$outret{'return'}=system("$cmd");main::_log("out=$outret{'return'}");
				if ($outret{'return'}){$t->close();return %outret}
			}
			else
			{
				main::_log("adding a+v last");
				my $cmd='cd '.$main::ENV{'TMP'}.';'.$MP4Box_exec.' -add '.($files[@files-1]->{'filename'}).' '.$temp_video->{'filename'};
				main::_log("cmd=$cmd");
				$outret{'return'}=system("$cmd");main::_log("out=$outret{'return'}");
				if ($outret{'return'}){$t->close();return %outret}
			}
			
			push @files, $temp_video;
			$procs++;
			next;
		}
		
		
		if ($function_name eq "onMetaTag")
		{
			main::_log("exec $function_name()");
			
			my $cmd='cd '.$main::ENV{'TMP'}.';'.$flvtool2_exec.' -U '.($files[@files-1]->{'filename'});
			main::_log("cmd=$cmd");
			$outret{'return'}=system("$cmd");main::_log("out=$outret{'return'}");
			if ($outret{'return'}){$t->close();return %outret}
			
			$procs++;
			next;
		}
		
		
		main::_log("unknown '$function'",1);
		$t->close();
		return %outret;
		
	}
	
	if ($procs)
	{
		main::_log("copying last processed file '$files[-1]->{'filename'}' ext='$env{'ext'}'");
		File::Copy::copy($files[-1]->{'filename'}, $env{'video2'});
		$t->close();
		$outret{'return'}=0;return %outret;
	}
	else
	{
		main::_log("copying same file '$env{'video2'}' ext='$env{'ext'}'");
		File::Copy::copy($env{'video1'}, $env{'video2'});
		chmod 0666, $env{'video2'};
		$t->close();
		$outret{'return'}=0;return %outret;
	}
	
	$t->close();
	return %outret;
}



=head2 video_add()

Adds new video to gallery, or updates old video

Add new video (uploading new original sized video)

 %video=video_add
 (
   'file' => '/path/to/file',
 # 'video.ID' => '',
 # 'video.ID_entity' => '',
 # 'video_en.keywords' => '',
 # 'video_format.ID' => '',
 # 'video_attrs.ID_category' => '',
 # 'video_attrs.name' => '',
 # 'video_attrs.description' => '',
 # 'video_part.ID' => '',
 # 'video_part.keywords' => '',
 # 'video_part.part_id' => '',
 # 'video_part_attrs.ID_category' => '',
 # 'video_part_attrs.name' => '',
 # 'video_part_attrs.description' => '',
 );

Add new part of video

 video_add
 (
   'file' => '/path/to/file',
   'video.ID' => 2,
   #'video_part.ID' => 1,
   #'video_part.order_id' => 1,
 );

=cut

sub video_add
{
	my %env=@_;
	if ($env{'-jobify'})
	{
		return 1 if TOM::Engine::jobify(\@_,{'routing_key' => 'db:'.$App::510::db_name,'class'=>'fifo'}); # do it in background
	}
	my $t=track TOM::Debug(__PACKAGE__."::video_add()");
	my $tr=new TOM::Database::SQL::transaction('db_h'=>"main");
	
	$env{'video_format.ID'}=$App::510::video_format_original_ID unless $env{'video_format.ID'};
	$env{'video_part.part_id'}=1 unless $env{'video_part.part_id'};
	
	$env{'video.ID_entity'}=$env{'video_ent.ID_entity'} if $env{'video_ent.ID_entity'};
	
	my $content_updated=0;
	my $content_reindex=0;
	
	# check if thumbnail file is correct
	if ($env{'file_thumbnail'})
	{
		main::_log("checking file_thumbnail='$env{'file_thumbnail'}'");
		if (!-e $env{'file_thumbnail'})
		{
			main::_log("file_thumbnail file not exists",1);
			delete $env{'file_thumbnail'};
		}
		elsif (-s $env{'file_thumbnail'} == 0)
		{
			main::_log("file_thumbnail file is empty",1);
			delete $env{'file_thumbnail'};
		}
	}
	
	my %category;
	if ($env{'video_cat.ID'} && $env{'video_cat.ID'} ne 'NULL')
	{
		# detect language
		%category=App::020::SQL::functions::get_ID(
			'ID' => $env{'video_cat.ID'},
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_video_cat",
			'columns' => {'*'=>1}
		);
		$env{'video_attrs.lng'}=$category{'lng'};
		$env{'video_attrs.ID_category'}=$category{'ID_entity'};
		main::_log("setting lng='$env{'video_attrs.lng'}' from video_attrs.ID_category");
		main::_log("setting video_attrs.ID_category='$env{'video_attrs.ID_category'}' from video_cat.ID='$env{'video_cat.ID'}'");
#		print Dumper(\%category);
		if ($category{'ID_brick'} || ($category{'ID_brick'} eq '0'))
		{
			if (not exists $env{'video_part.ID_brick'})
			{
				main::_log("re-set ID_brick=".$category{'ID_brick'});
				$env{'video_part.ID_brick'} = "$category{'ID_brick'}";
			}
		}
	}
	$env{'video_attrs.ID_category'}='NULL' if $env{'video_cat.ID'} eq 'NULL';
	
	$env{'video_attrs.lng'}=$tom::lng unless $env{'video_attrs.lng'};
	main::_log("lng='$env{'video_attrs.lng'}'");
	
	
	# if only video_part.ID is defined, not video.ID or video.ID_entity
	my %video_part;
	if ($env{'video_part.ID'} && !$env{'video.ID'} && !$env{'video.ID_entity'})
	{
		main::_log("\$env{'video_part.ID'} && !\$env{'video.ID'} && !\$env{'video.ID_entity'} -> search");
		%video_part=App::020::SQL::functions::get_ID(
			'ID' => $env{'video_part.ID'},
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_video_part",
			'columns' => {'*'=>1}
		);
		if ($video_part{'ID_entity'})
		{
			$env{'video.ID_entity'}=$video_part{'ID_entity'};
			main::_log("found video.ID_entity=$env{'video.ID_entity'}");
		}
		else
		{
			return undef;
		}
	}
	
	
	
	# VIDEO
	
	my %video;
	my %video_attrs;
	if ($env{'video.ID'})
	{
		# detect language
		%video=App::020::SQL::functions::get_ID(
			'ID' => $env{'video.ID'},
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_video",
			'columns' => {'*'=>1}
		);
		$env{'video.ID_entity'}=$video{'ID_entity'} unless $env{'video.ID_entity'};
	}
	
	# check if this symlink with same ID_category not already exists
	# and video.ID is unknown
	if (!$env{'video.ID'} && $env{'video.ID_entity'} && !$env{'forcesymlink'})
	{
		$env{'video_attrs.ID_category'}=0 unless $env{'video_attrs.ID_category'};
		main::_log("search for video.ID by video_attrs.ID_category='$env{'video_attrs.ID_category'}' and video.ID_entity='$env{'video.ID_entity'}'");
		my $sql=qq{
			SELECT
				video.ID AS ID_video,
				video_attrs.ID AS ID_attrs
			FROM
				`$App::510::db_name`.a510_video AS video
			LEFT JOIN `$App::510::db_name`.a510_video_attrs AS video_attrs
				ON ( video.ID = video_attrs.ID_entity )
			WHERE
				video.ID_entity=$env{'video.ID_entity'} AND
				( video_attrs.ID_category = $env{'video_attrs.ID_category'} OR ID_category IS NULL ) AND
				video_attrs.status IN ('Y','N','L')
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %db0_line=$sth0{'sth'}->fetchhash();
		if ($db0_line{'ID_video'})
		{
			$env{'video.ID'}=$db0_line{'ID_video'};
			$env{'video_attrs.ID'}=$db0_line{'ID_attrs'};
			main::_log("setup video.ID='$db0_line{'ID_video'}' video_attrs.ID='$env{'video_attrs.ID'}'");
		}
	}
	
=head1
	if ($env{'video_attrs.ID_category'} && $env{'video.ID_entity'} && $env{'video_attrs.lng'} && !$env{'video_attrs.ID'} && !$env{'video.ID'} && $env{'forcesymlink'})
	{
		main::_log("finding compatible video_attrs.ID_entity (also video.ID)");
		
		my $sql=qq{
			SELECT
				video.ID AS ID_video,
				video_attrs.ID AS ID_attrs
			FROM
				`$App::510::db_name`.a510_video AS video
			LEFT JOIN `$App::510::db_name`.a510_video_attrs AS video_attrs
				ON ( video.ID = video_attrs.ID_entity )
			WHERE
				video.ID_entity=$env{'video.ID_entity'} AND
				video_attrs.ID_category = $env{'video_attrs.ID_category'} AND
				video_attrs.lng != '$env{'video_attrs.lng'}' AND
				video_attrs.status IN ('Y','N','L')
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %db0_line=$sth0{'sth'}->fetchhash();
		if ($db0_line{'ID_video'})
		{
			$env{'video.ID'}=$db0_line{'ID_video'};
			$env{'video_attrs.ID'}=$db0_line{'ID_attrs'};
			main::_log("setup video.ID='$db0_line{'ID_video'}' video_attrs.ID='$env{'video_attrs.ID'}'");
		}
		
	}
=cut
	
=head1
	# check if this lng mutation of video_attrs exists
	if ($env{'video_attrs.ID'} && $env{'video_attrs.lng'} && $env{'video.ID'})
	{
		main::_log("check if lng='$env{'video_attrs.lng'}' of video.ID='$env{'video.ID'}' exists");
		my $sql=qq{
			SELECT
				ID
			FROM
				`$App::510::db_name`.a510_video_attrs
			WHERE
				ID_entity=? AND
				lng=?
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'bind'=>[$env{'video.ID'},$env{'video_attrs.lng'}],'quiet'=>1);
		if (!$sth0{'rows'})
		{
			main::_log("not exists, also reset video_attrs.ID");
			undef $env{'video_attrs.ID'};
		}
		else
		{
			
		}
		# if not remove video_attrs.ID
	}
=cut
	
	
	if (!$env{'video.ID'})
	{
		# generating new video!
		main::_log("adding new video");
		
		my %columns;
		
		$columns{'datetime_rec_start'}="NOW()";
		$columns{'ID_entity'}=$env{'video.ID_entity'} if $env{'video.ID_entity'};
		
		$env{'video.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_video",
			'columns' =>
			{
				%columns,
			},
			'-journalize' => 1,
		);
		main::_log("generated video.ID='$env{'video.ID'}'");
		$content_updated=1;
		$content_reindex=1;
	}
	
	
	if (!$env{'video.ID_entity'})
	{
		if ($video{'ID_entity'})
		{
			$env{'video.ID_entity'}=$video{'ID_entity'};
		}
		elsif ($env{'video.ID'})
		{
			%video=App::020::SQL::functions::get_ID(
				'ID' => $env{'video.ID'},
				'db_h' => "main",
				'db_name' => $App::510::db_name,
				'tb_name' => "a510_video",
				'columns' => {'*'=>1}
			);
			$env{'video.ID_entity'}=$video{'ID_entity'};
		}
		else
		{
			die "ufff\n";
		}
	}
	
	# update if necessary
	if ($video{'ID'})
	{
		my %columns;
		
		# datetime_rec_start
		$columns{'datetime_rec_start'}="'".$env{'video.datetime_rec_start'}."'"
			if ($env{'video.datetime_rec_start'} && ($env{'video.datetime_rec_start'} ne $video{'datetime_rec_start'}));
		$columns{'datetime_rec_start'}=$env{'video.datetime_rec_start'}
			if ($env{'video.datetime_rec_start'}=~/^FROM/ && ($env{'video.datetime_rec_start'} ne $video{'datetime_rec_start'}));
		# datetime_rec_stop
		if (exists $env{'video.datetime_rec_stop'} && ($env{'video.datetime_rec_stop'} ne $video{'datetime_rec_stop'}))
		{
			if (!$env{'video.datetime_rec_stop'})
			{$columns{'datetime_rec_stop'}="NULL";}
			else
			{$columns{'datetime_rec_stop'}="'".$env{'video.datetime_rec_stop'}."'";}
		}
		
		if (keys %columns)
		{
			App::020::SQL::functions::update(
				'ID' => $video{'ID'},
				'db_h' => "main",
				'db_name' => $App::510::db_name,
				'tb_name' => "a510_video",
				'columns' => {%columns},
				'-journalize' => 1
			);
			$content_updated=1;
			$content_reindex=1;
		}
	}
	
	
	if (!$env{'video_attrs.ID'})
	{
		main::_log("finding video_attrs.ID by video.ID=$env{'video.ID'} and video_attrs.lng='$env{'video_attrs.lng'}'");
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::510::db_name`.`a510_video_attrs`
			WHERE
				ID_entity='$env{'video.ID'}' AND
				lng='$env{'video_attrs.lng'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%video_attrs=$sth0{'sth'}->fetchhash();
		$env{'video_attrs.ID'}=$video_attrs{'ID'};
		main::_log("video_attrs.ID='$env{'video_attrs.ID'}'");
	}
	
	if (!$env{'video_attrs.ID'} && !$env{'video_attrs.ID_category'} && $env{'video.ID'})
	{ # find target ID_category if not defined
		main::_log("finding video_attrs.ID_category by video.ID=$env{'video.ID'}");
		my $sql=qq{
			SELECT
				ID_category
			FROM
				`$App::510::db_name`.`a510_video_attrs`
			WHERE
				ID_entity='$env{'video.ID'}' AND
				status IN ('Y','N','L')
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %db0_line=$sth0{'sth'}->fetchhash();
		$env{'video_attrs.ID_category'}=$db0_line{'ID_category'};# if $sth0{'rows'};
		main::_log("video_attrs.ID_category='$env{'video_attrs.ID_category'}'");
	}
	
	if (!$env{'video_attrs.ID'})
	{
		# create one language representation of video
		my %columns;
		$columns{'ID_category'}=$env{'video_attrs.ID_category'} if $env{'video_attrs.ID_category'};
		#$columns{'status'}="'$env{'video_attrs.status'}'" if $env{'video_attrs.status'};
		$columns{'datetime_publish_start'}="'".$env{'video_attrs.datetime_publish_start'}."'" if $env{'video_attrs.datetime_publish_start'};
		$columns{'datetime_publish_start'}=$env{'video_attrs.datetime_publish_start'} if ($env{'video_attrs.datetime_publish_start'} && (not $env{'video_attrs.datetime_publish_start'}=~/^\d/));
		$columns{'datetime_publish_start'}="NOW()" unless $columns{'datetime_publish_start'};
		
		$env{'video_attrs.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_video_attrs",
			'columns' =>
			{
				%columns,
				'ID_entity' => $env{'video.ID'},
#				'order_id' => $order_id,
				'lng' => "'$env{'video_attrs.lng'}'",
			},
			'-journalize' => 1,
		);
#		%video_attrs=App::020::SQL::functions::get_ID(
#			'ID' => $env{'video_attrs.ID'},
#			'db_h' => "main",
#			'db_name' => $App::510::db_name,
#			'tb_name' => "a510_video_attrs",
#			'columns' => {'*'=>1}
#		);
		$content_updated=1;
		$content_reindex=1;
	}
	
	
	# VIDEO_ENT
	
	my %video_ent;
	if (!$env{'video_ent.ID_entity'})
	{
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::510::db_name`.`a510_video_ent`
			WHERE
				ID_entity='$env{'video.ID_entity'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%video_ent=$sth0{'sth'}->fetchhash();
		$env{'video_ent.ID_entity'}=$video_ent{'ID_entity'};
		$env{'video_ent.ID'}=$video_ent{'ID'};
	}
	if (!$env{'video_ent.ID_entity'})
	{
		# create one entity representation of video
		my %columns;
		$columns{'datetime_rec_start'}="NOW()" unless $columns{'datetime_rec_start'};
		$env{'video_ent.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_video_ent",
			'columns' =>
			{
				%columns,
				'ID_entity' => $env{'video.ID_entity'},
			},
			'-journalize' => 1,
		);
		$content_updated=1;
		$content_reindex=1;
	}
	
	if (!$video_ent{'posix_owner'} && !$env{'video_ent.posix_owner'})
	{
		$env{'video_ent.posix_owner'}=$main::USRM{'ID_user'};
	}
	
	# update if necessary
	if ($env{'video_ent.ID'})
	{
		my %columns;
		$columns{'posix_author'}="'".$env{'video_ent.posix_author'}."'"
			if ($env{'video_ent.posix_author'} && ($env{'video_ent.posix_author'} ne $video_ent{'posix_author'}));
		$columns{'posix_owner'}="'".TOM::Security::form::sql_escape($env{'video_ent.posix_owner'})."'"
			if ($env{'video_ent.posix_owner'} && ($env{'video_ent.posix_owner'} ne $video_ent{'posix_owner'}));
		$columns{'keywords'}="'".TOM::Security::form::sql_escape($env{'video_ent.keywords'})."'"
			if (exists $env{'video_ent.keywords'} && ($env{'video_ent.keywords'} ne $video_ent{'keywords'}));
		
		$columns{'movie_release_year'}="'".TOM::Security::form::sql_escape($env{'video_ent.movie_release_year'})."'"
			if (exists $env{'video_ent.movie_release_year'} && ($env{'video_ent.movie_release_year'} ne $video_ent{'movie_release_year'}));
		$columns{'movie_release_date'}="'".TOM::Security::form::sql_escape($env{'video_ent.movie_release_date'})."'"
			if (exists $env{'video_ent.movie_release_date'} && ($env{'video_ent.movie_release_date'} ne $video_ent{'movie_release_date'}));
		$columns{'movie_country_code'}="'".TOM::Security::form::sql_escape($env{'video_ent.movie_country_code'})."'"
			if (exists $env{'video_ent.movie_country_code'} && ($env{'video_ent.movie_country_code'} ne $video_ent{'movie_country_code'}));
		$columns{'movie_imdb'}="'".TOM::Security::form::sql_escape($env{'video_ent.movie_imdb'})."'"
			if (exists $env{'video_ent.movie_imdb'} && ($env{'video_ent.movie_imdb'} ne $video_ent{'movie_imdb'}));
		$columns{'movie_catalog_number'}="'".TOM::Security::form::sql_escape($env{'video_ent.movie_catalog_number'})."'"
			if (exists $env{'video_ent.movie_catalog_number'} && ($env{'video_ent.movie_catalog_number'} ne $video_ent{'movie_catalog_number'}));
		$columns{'movie_length'}="'".TOM::Security::form::sql_escape($env{'video_ent.movie_length'})."'"
			if (exists $env{'video_ent.movie_length'} && ($env{'video_ent.movie_length'} ne $video_ent{'movie_length'}));
		$columns{'movie_note'}="'".TOM::Security::form::sql_escape($env{'video_ent.movie_note'})."'"
			if (exists $env{'video_ent.movie_note'} && ($env{'video_ent.movie_note'} ne $video_ent{'movie_note'}));
		
		$columns{'status_encryption'}="'".TOM::Security::form::sql_escape($env{'video_ent.status_encryption'})."'"
			if (exists $env{'video_ent.status_encryption'} && ($env{'video_ent.status_encryption'} ne $video_ent{'status_encryption'}));
		$columns{'status_geoblock'}="'".TOM::Security::form::sql_escape($env{'video_ent.status_geoblock'})."'"
			if (exists $env{'video_ent.status_geoblock'} && ($env{'video_ent.status_geoblock'} ne $video_ent{'status_geoblock'}));
		$columns{'status_embedblock'}="'".TOM::Security::form::sql_escape($env{'video_ent.status_embedblock'})."'"
			if (exists $env{'video_ent.status_embedblock'} && ($env{'video_ent.status_embedblock'} ne $video_ent{'status_embedblock'}));
		
		if ((not exists $env{'video_ent.metadata'}) && (!$video_ent{'metadata'})){$env{'video_ent.metadata'}=$App::510::metadata_default;}
		$columns{'metadata'}="'".TOM::Security::form::sql_escape($env{'video_ent.metadata'})."'"
			if (exists $env{'video_ent.metadata'} && ($env{'video_ent.metadata'} ne $video_ent{'metadata'}));
		
		if ($columns{'metadata'})
		{
			App::020::functions::metadata::metaindex_set(
				'db_h' => 'main',
				'db_name' => $App::510::db_name,
				'tb_name' => 'a510_video_ent',
				'ID' => $env{'video_ent.ID'},
				'metadata' => {App::020::functions::metadata::parse($env{'video_ent.metadata'})}
			);
		}
		
		if (keys %columns)
		{
			App::020::SQL::functions::update(
				'ID' => $env{'video_ent.ID'},
				'db_h' => "main",
				'db_name' => $App::510::db_name,
				'tb_name' => "a510_video_ent",
				'columns' => {%columns},
				'-journalize' => 1
			);
			$content_updated=1;
			$content_reindex=1;
		}
	}
	
	
	
	my %env0=video_part_add
	(
		'file' => $env{'file'},
		'file_nocopy' => $env{'file_nocopy'},
		'file_thumbnail' => $env{'file_thumbnail'},
		'file_dontcheck' => $env{'file_dontcheck'},
		'video.ID_entity' => $env{'video.ID_entity'},
		'video.datetime_rec_start' => $video{'datetime_rec_start'},
		'video_attrs.name' => $video_attrs{'name'},
		'video_format.ID' => $env{'video_format.ID'},
		'video_part.ID' => $env{'video_part.ID'},
		'video_part.ID_brick' => $env{'video_part.ID_brick'},
		'video_part.keywords' => $env{'video_part.keywords'},
		'video_part.part_id' => $env{'video_part.part_id'},
		'video_part.datetime_air' => $env{'video_part.datetime_air'},
		'video_part_attrs.lng' => $env{'video_attrs.lng'},
		'video_part_attrs.name' => $env{'video_part_attrs.name'},
		'video_part_attrs.description' => $env{'video_part_attrs.description'},
		'video_part_file.from_parent' => $env{'video_part_file.from_parent'}
	);
	$env{'video_part.ID'} = $env0{'video_part.ID'} if $env0{'video_part.ID'};
	if (!$env{'video_part.ID'})
	{
		$t->close();
		return undef
	};
	
	if ($env{'video_attrs.ID'})
	{
		# detect language
		%video_attrs=App::020::SQL::functions::get_ID(
			'ID' => $env{'video_attrs.ID'},
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_video_attrs",
			'columns' => {'*'=>1}
		);
		main::_log("loaded %video_attrs video_attrs.ID='$video_attrs{'ID'}' video_attrs.ID_category='$video_attrs{'ID_category'}'");
	}
	
	main::_log("video_attrs.ID='$env{'video_attrs.ID'}' video_attrs.ID_category='$env{'video_attrs.ID_category'}' video_attrs{ID_category}='$video_attrs{'ID_category'}'");
	if ($env{'video_attrs.ID'} &&
	(
		# ID_category
		($env{'video_attrs.ID_category'} && ($env{'video_attrs.ID_category'} ne $video_attrs{'ID_category'}))
	))
	{
		my %columns;
		main::_log("video_attrs.ID='$video_attrs{'ID'}' video_attrs.status='$video_attrs{'status'}'");
		$columns{'ID_category'}=$env{'video_attrs.ID_category'};
		my $sql=qq{
			SELECT
				ID
			FROM
				`$App::510::db_name`.a510_video_attrs
			WHERE
				ID_entity=$video_attrs{'ID_entity'} AND
				status IN ('Y','N','L')
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		while (my %db0_line=$sth0{'sth'}->fetchhash())
		{
#			main::_log("update video_attrs.ID='$db0_line{'ID'}'");
			App::020::SQL::functions::update(
				'ID' => $db0_line{'ID'},
				'db_h' => "main",
				'db_name' => $App::501::db_name,
				'tb_name' => "a510_video_attrs",
				'columns' => {%columns},
				'-journalize' => 1
			);
			$content_updated=1;
			$content_reindex=1;
		}
		
	}
	
	
	if ($env{'video_attrs.ID'})
	{
		my %columns;
		
#		$columns{'ID_category'}=$env{'video_attrs.ID_category'}
#			if ($env{'video_attrs.ID_category'} && ($env{'video_attrs.ID_category'} ne $video_attrs{'ID_category'}));
		$columns{'name'}="'".TOM::Security::form::sql_escape($env{'video_attrs.name'})."'"
			if ($env{'video_attrs.name'} && ($env{'video_attrs.name'} ne $video_attrs{'name'}));
		$columns{'name_url'}="'".TOM::Net::URI::rewrite::convert($env{'video_attrs.name'})."'"
			if ($env{'video_attrs.name'} && ($env{'video_attrs.name'} ne $video_attrs{'name'}));
		$columns{'description'}="'".TOM::Security::form::sql_escape($env{'video_attrs.description'})."'"
			if (exists $env{'video_attrs.description'} && ($env{'video_attrs.description'} ne $video_attrs{'description'}));
		# datetime_start
		$columns{'datetime_publish_start'}="'".$env{'video_attrs.datetime_publish_start'}."'"
			if ($env{'video_attrs.datetime_publish_start'} && ($env{'video_attrs.datetime_publish_start'} ne $video_attrs{'datetime_publish_start'}));
		$columns{'datetime_publish_start'}=$env{'video_attrs.datetime_publish_start'}
			if (($env{'video_attrs.datetime_publish_start'} && ($env{'video_attrs.datetime_publish_start'} ne $video_attrs{'datetime_publish_start'})) && (not $env{'video_attrs.datetime_publish_start'}=~/^\d/));
		# datetime_stop
		if (exists $env{'video_attrs.datetime_publish_stop'} && ($env{'video_attrs.datetime_publish_stop'} ne $video_attrs{'datetime_publish_stop'}))
		{
			if (!$env{'video_attrs.datetime_publish_stop'})
			{
				$columns{'datetime_publish_stop'}="NULL";
			}
			else
			{
				$columns{'datetime_publish_stop'}="'".$env{'video_attrs.datetime_publish_stop'}."'";
			}
		}
		$columns{'status'}="'".TOM::Security::form::sql_escape($env{'video_attrs.status'})."'"
			if ($env{'video_attrs.status'} && ($env{'video_attrs.status'} ne $video_attrs{'status'}));
		
		if (keys %columns)
		{
			App::020::SQL::functions::update(
				'ID' => $env{'video_attrs.ID'},
				'db_h' => "main",
				'db_name' => $App::510::db_name,
				'tb_name' => "a510_video_attrs",
				'columns' => {%columns},
				'-journalize' => 1
			);
			$content_updated=1;
			$content_reindex=1;
		}
	}
	
	main::_log("video.ID='$env{'video.ID'}' added/updated");
	
	if ($content_updated)
	{
		App::020::SQL::functions::_save_changetime({'db_h'=>'main','db_name'=>$App::510::db_name,'tb_name'=>'a510_video'});
	}
	
	if ($content_reindex)
	{
		_video_index('ID_entity'=>$env{'video.ID_entity'});
		video_encryption_generate('ID_entity'=>$env{'video.ID_entity'});
	}
	
	$tr->close(); # commit transaction
	$t->close();
	return %env;
}







=head2 video_part_add()

Adds new video-part to gallery, or updates old video

Add new video-part (uploading new original sized video)

 video_part_add
 (
   'file' => '/path/to/file',
   'video.ID_entity' => '',
 # 'video_part_attrs.lng' => 'en',
 # 'video.ID_entity' => '',
 # 'video_format.ID' => '',
 # 'video_attrs.ID_category' => '',
 # 'video_attrs.name' => '',
 # 'video_attrs.description' => '',
 # 'video_part.ID' => '',
 # 'video_part.keywords' => '',
 # 'video_part.part_id' => '',
 # 'video_part_attrs.ID_category' => '',
 # 'video_part_attrs.name' => '',
 # 'video_part_attrs.description' => '',
 );

=cut

sub video_part_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::video_part_add()");
	
	$env{'video_format.ID'}=$App::510::video_format_original_ID unless $env{'video_format.ID'};
	
	my $content_updated=0;
	my $content_reindex=0;
	
	# get video informations
	
	my %video;
	if ($env{'video.ID'})
	{
		# detect language
		%video=App::020::SQL::functions::get_ID(
			'ID' => $env{'video.ID'},
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_video",
			'columns' => {'*'=>1}
		);
		$env{'video.ID_entity'}=$video{'ID_entity'} unless $env{'video.ID_entity'};
	}
	if (!$env{'video.ID'})
	{
		$env{'video.ID'}=$video{'ID'} if $video{'ID'};
	}
	
#	if (!$env{'video_part.ID'} && !$env{'video_part.part_id'} && !$env{'file'})
#	{
#		$env{'video_part.part_id'}=1;
#	}
	
	$env{'video_part_attrs.lng'}=$tom::lng unless $env{'video_part_attrs.lng'};
	main::_log("lng='$env{'video_part_attrs.lng'}'");
	
	
	# try to find video_part by defined video_part.part_id
	my %video_part;
	if ($env{'video_part.part_id'} && !$env{'video_part.ID'})
	{
		main::_log("video_part.part_id='$env{'video_part.part_id'}', video.ID_entity='$env{'video.ID_entity'}', !video_part.ID = checking if part_id exists");
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::510::db_name`.`a510_video_part`
			WHERE
				ID_entity='$env{'video.ID_entity'}' AND
				part_id='$env{'video_part.part_id'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%video_part=$sth0{'sth'}->fetchhash();
		$env{'video_part.ID'}=$video_part{'ID'} if $video_part{'ID'};
		main::_log("video_part.ID='$env{'video_part.ID'}'");
		
		if ($env{'file_thumbnail'} && $video_part{'thumbnail_lock'} ne 'Y' && $video_part{'ID'})
		{
			# lock this thumbnail to not regenerate it
			App::020::SQL::functions::update(
				'ID' => $video_part{'ID'},
				'db_h' => "main",
				'db_name' => $App::510::db_name,
				'tb_name' => "a510_video_part",
				'columns' =>
				{
					'thumbnail_lock' => "'Y'"
				},
				'-journalize' => 1
			);
			$content_updated=1;
			$content_reindex=1;
		}
		
	}
	
	if (!$env{'video_part.ID'})
	{
		# finding free part_id
		if (!$env{'video_part.part_id'})
		{
			my $sql=qq{
				SELECT MAX(part_id) AS part_id
				FROM `$App::510::db_name`.`a510_video_part`
				WHERE ID_entity='$env{'video.ID_entity'}'
				LIMIT 1;
			};
			my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
			my %db0_line=$sth0{'sth'}->fetchhash();
			$env{'video_part.part_id'}=$db0_line{'part_id'}+1;
			main::_log("new video_part.part_id='$env{'video_part.part_id'}'");
		}
		# generating new video_part!
		main::_log("adding new video_part");
		my %columns;
		$columns{'ID_entity'}=$env{'video.ID_entity'};
		$columns{'keywords'}=$env{'video_part.keywords'} if $env{'video_part.keywords'};
		$columns{'part_id'}=$env{'video_part.part_id'} if $env{'video_part.part_id'};
		$columns{'thumbnail_lock'}="'Y'" if $env{'file_thumbnail'};
		$columns{'ID_brick'}=$env{'video_part.ID_brick'};
			if (!$columns{'ID_brick'} && ($columns{'ID_brick'} ne "0"))
			{
				$columns{'ID_brick'} = $App::510::brick_default || 'NULL';
			}
		
		if ($env{'video_part.datetime_air'})
		{
			$columns{'datetime_air'}="'".$env{'video_part.datetime_air'}."'";
		}
		else
		{
			$columns{'datetime_air'}="NOW()";
		}
		
		$env{'video_part.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_video_part",
			'columns' =>
			{
				%columns,
			},
			'-journalize' => 1,
		);
		main::_log("generated video_part ID='$env{'video_part.ID'}'");
		$content_updated=1;
		$content_reindex=1;
	}
	
	# update if necessary
	if ($env{'video_part.ID'})
	{
		my %columns;
		$columns{'keywords'}="'".$env{'video_part.keywords'}."'"
			if (exists $env{'video_part.keywords'} && ($env{'video_part.keywords'} ne $video_part{'keywords'}));
		$columns{'datetime_air'}="'".$env{'video_part.datetime_air'}."'"
			if ($env{'video_part.datetime_air'} && ($env{'video_part.datetime_air'} ne $video_part{'datetime_air'}));
		
		if (keys %columns)
		{
			App::020::SQL::functions::update(
				'ID' => $env{'video_part.ID'},
				'db_h' => "main",
				'db_name' => $App::510::db_name,
				'tb_name' => "a510_video_part",
				'columns' => {%columns},
				'-journalize' => 1
			);
			$content_updated=1;
			$content_reindex=1;
		}
		
		%video_part=App::020::SQL::functions::get_ID(
			'ID' => $env{'video_part.ID'},
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_video_part",
			'columns' => {'*'=>1}
		);
		
	}
	
	my %video_part_attrs;
	if (!$env{'video_part_attrs.ID'})
	{
		main::_log("finding video_part_attrs.ID");
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::510::db_name`.`a510_video_part_attrs`
			WHERE
				ID_entity='$env{'video_part.ID'}' AND
				lng='$env{'video_part_attrs.lng'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%video_part_attrs=$sth0{'sth'}->fetchhash();
		$env{'video_part_attrs.ID'}=$video_part_attrs{'ID'};
		main::_log("video_part_attrs.ID=$env{'video_part_attrs.ID'}");
	}
	
	
	if (!$env{'video_part_attrs.ID'})
	{
		# create one language representation of video_part
		my %columns;
		#$columns{'ID_category'}=$env{'video_attrs.ID_category'} if $env{'video_attrs.ID_category'};
		$env{'video_part_attrs.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_video_part_attrs",
			'columns' =>
			{
				%columns,
				'ID_entity' => $env{'video_part.ID'},
				'lng' => "'$env{'video_part_attrs.lng'}'",
			},
			'-journalize' => 1,
		);
		$content_updated=1;
		$content_reindex=1;
	}
	
	
	if ($env{'file'})
	{
		main::_log("file='$env{'file'}', video_part.ID='$env{'video_part.ID'}', video_format.ID='$env{'video_format.ID'}' is specified, so updating video_part_file");
		
		$env{'video_part_file.ID'}=video_part_file_add
		(
			'file' => $env{'file'},
			'file_nocopy' => $env{'file_nocopy'},
			'file_thumbnail' => $env{'file_thumbnail'},
			'file_dontcheck' => $env{'file_dontcheck'},
			'video_part.ID' => $env{'video_part.ID'},
			'video_format.ID' => $env{'video_format.ID'},
			'from_parent' => ($env{'video_part_file.from_parent'} || "N"),
			# used to detect optimal filename
			'video.datetime_rec_start' => $env{'video.datetime_rec_start'},
			'video_attrs.name' => $env{'video_attrs.name'},
			'video_part_attrs.name' => $env{'video_part_attrs.name'},
		);
		if (!$env{'video_part_file.ID'})
		{
			$t->close();
			return undef;
		}
	}
	else
	{
		if ($env{'video_part.ID_brick'} || ($env{'video_part.ID_brick'} eq "0"))
		{
			if ($env{'video_part.ID_brick'} ne $video_part{'ID_brick'})
			{
				main::_log("changing brick from '$video_part{'ID_brick'}' to '$env{'video_part.ID_brick'}'");
				
				App::510::functions::video_part_brick_change(
						'-jobify' => 1,
					'video_part.ID' => $env{'video_part.ID'},
					'video_part.ID_brick' => $env{'video_part.ID_brick'},
				);
				
			}
		}
	}
	
	if ($env{'video_part_attrs.ID'})
	{
		my %columns;
		
		$columns{'name'}="'".TOM::Security::form::sql_escape($env{'video_part_attrs.name'})."'"
			if ($env{'video_part_attrs.name'} && ($env{'video_part_attrs.name'} ne $video_part_attrs{'name'}));
		$columns{'name_url'}="'".TOM::Net::URI::rewrite::convert($env{'video_part_attrs.name'})."'"
			if ($env{'video_part_attrs.name'} && ($env{'video_part_attrs.name'} ne $video_part_attrs{'name'}));
		$columns{'description'}="'".TOM::Security::form::sql_escape($env{'video_part_attrs.description'})."'"
			if (exists $env{'video_part_attrs.description'} && ($env{'video_part_attrs.description'} ne $video_part_attrs{'description'}));
		
		if (keys %columns)
		{
			App::020::SQL::functions::update(
				'ID' => $env{'video_part_attrs.ID'},
				'db_h' => "main",
				'db_name' => $App::510::db_name,
				'tb_name' => "a510_video_part_attrs",
				'columns' => {%columns},
				'-journalize' => 1
			);
			$content_updated=1;
			$content_reindex=1;
		}
	}
	
	main::_log("video_part.ID='$env{'video_part.ID'}' added/updated");
	
	if ($content_updated)
	{
		App::020::SQL::functions::_save_changetime({'db_h'=>'main','db_name'=>$App::510::db_name,'tb_name'=>'a510_video',
			'ID_entity'=>$env{'video.ID_entity'}});
	}
	
	if ($content_reindex)
	{
		_video_index('ID_entity'=>$env{'video.ID_entity'});
	}
	
	$t->close();
	return %env;
}










=head2 video_part_file_add()

Adds new file to video, or updates old

 $video_part_file{'ID'}=video_part_file_add
 (
   'file' => '/path/to/file',
   'video_part.ID' => '',
   'video_format.ID' => '',
 # 'thumbnail_lock_ignore' => 1 # regenerate thumbnail when locked
 )

=cut

sub video_part_file_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::video_part_file_add()");
	
	my $content_updated=0; # not yet implemented
	
	# check if video_part_file already not exists
	if (!$env{'file'})
	{
		main::_log("missing param file",1);
		$t->close();
		return undef;
	}
	
	if (! -e $env{'file'})
	{
		main::_log("file is missing or can't be read",1);
		$t->close();
		return undef;
	}
	
	if (!$env{'video_part.ID'})
	{
		main::_log("missing param video_part.ID",1);
		$t->close();
		return undef;
	}
	
	if (!$env{'video_format.ID'})
	{
		main::_log("missing param video_format.ID",1);
		$t->close();
		return undef;
	}
	
	
	my %part=App::020::SQL::functions::get_ID(
		'ID' => $env{'video_part.ID'},
		'db_h' => "main",
		'db_name' => $App::510::db_name,
		'tb_name' => "a510_video_part",
		'columns' => {'*'=>1}
	);
	
	my %brick;
	%brick=App::020::SQL::functions::get_ID(
		'ID' => $part{'ID_brick'},
		'db_h' => "main",
		'db_name' => $App::510::db_name,
		'tb_name' => "a510_video_brick",
		'columns' => {'*'=>1}
	) if $part{'ID_brick'};
	
	# override modifytime
	App::020::SQL::functions::_save_changetime({
		'db_h' => 'main',
		'db_name' => $App::510::db_name,
		'tb_name' => 'a510_video',
		'ID_entity' => $part{'ID_entity'}
	});
	
	my $sql=qq{
		SELECT
			video.ID_entity AS ID_entity_video,
			video.ID AS ID_video,
			video_attrs.ID AS ID_attrs,
			video_part.ID AS ID_part,
			video_part_attrs.ID AS ID_part_attrs,
			
			LEFT(video.datetime_rec_start, 16) AS datetime_rec_start,
			LEFT(video_attrs.datetime_create, 18) AS datetime_create,
			LEFT(video.datetime_rec_start,10) AS date_recorded,
			LEFT(video.datetime_rec_stop, 16) AS datetime_rec_stop,
			
			video_attrs.ID_category,
			
			video_attrs.name,
			video_attrs.name_url,
			video_attrs.description,
			video_attrs.order_id,
			video_attrs.priority_A,
			video_attrs.priority_B,
			video_attrs.priority_C,
			video_attrs.lng,
			
			video_part_attrs.name AS part_name,
			video_part_attrs.description AS part_description,
			video_part.part_id AS part_id,
			video_part.keywords AS part_keywords,
			video_part.visits,
			video_part_attrs.lng AS part_lng,
			
			video_part.rating_score,
			video_part.rating_votes,
			(video_part.rating_score/video_part.rating_votes) AS rating,
			
			video_attrs.status,
			video_part.status AS status_part
			
		FROM
			`$App::510::db_name`.`a510_video` AS video
		INNER JOIN `$App::510::db_name`.`a510_video_ent` AS video_ent ON
		(
			video_ent.ID_entity = video.ID_entity
		)
		LEFT JOIN `$App::510::db_name`.`a510_video_attrs` AS video_attrs ON
		(
			video_attrs.ID_entity = video.ID
		)
		INNER JOIN `$App::510::db_name`.`a510_video_part` AS video_part ON
		(
			video_part.ID_entity = video.ID_entity
		)
		LEFT JOIN `$App::510::db_name`.`a510_video_part_attrs` AS video_part_attrs ON
		(
			video_part_attrs.ID_entity = video_part.ID AND
			video_part_attrs.lng = video_attrs.lng
		)
		
		WHERE
			video.ID AND
			video_attrs.ID AND
			video_part.ID=$env{'video_part.ID'}
		
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	my %video_db=$sth0{'sth'}->fetchhash();
	main::_log("video.ID='$video_db{'ID_video'}' video.name='$video_db{'name'}'");
	$env{'from_parent'}='N' unless $env{'from_parent'};
	
	return undef unless $video_db{'ID_video'};
	
	# file must be analyzed
	
	# size
	my $file_size=(stat($env{'file'}))[7];
	main::_log("file size=".format_bytes($file_size));
	
	if (!$file_size)
	{
		$t->close();
		return undef;
	}
	
	my $checksum;
	my $checksum_method;
	
	# checksum
	if ($env{'file_dontcheck'})
	{
		main::_log("calculating checksum 'size'");
		$checksum = $file_size;
		$checksum_method = 'size';
	}
	else
	{
		main::_log("calculating checksum SHA1");
		open(CHKSUM,'<'.$env{'file'});
		my $ctx = Digest::SHA1->new;
		$ctx->addfile(*CHKSUM); # when script hangs here, check file permissions
		$checksum = $ctx->hexdigest;
		$checksum_method = 'SHA1';
	}
	main::_log("file checksum $checksum_method:$checksum");
	
	my $out;
	if ($^O eq 'linux'){$out=`file -b $env{'file'}`;chomp($out);}
	my $file_ext;#
	
	# find if this file type exists
	foreach my $reg (@App::542::mimetypes::filetype_ext)
	{
		if ($out=~/$reg->[0]/){$file_ext=$reg->[1];last;}
	}
	$file_ext='avi' unless $file_ext;
	$file_ext=$env{'ext'} if $env{'ext'};
	
	main::_log("type='$out' ext='$file_ext'");
	
	
	my $vd = Movie::Info->new || die "Couldn't find an mplayer to use\n";
	
	# file must be copied to have correct extension
	# if (not already has it)
	my $file3=new TOM::Temp::file('ext'=>$file_ext,'dir'=>$main::ENV{'TMP'},'nocreate'=>1);
	my %video;
	if ((not $env{'file'}=~/\.$file_ext$/) && (!$env{'file_dontcheck'}))
	{
		# this can be very very slow
		main::_log("copying and detecting filetype");
		File::Copy::copy($env{'file'},$file3->{'filename'});
		%video = $vd->info($file3->{'filename'});
	}
	elsif (!$env{'file_dontcheck'})
	{
		# this can be very slow
		main::_log("detecting filetype");
		%video = $vd->info($env{'file'});
	}
	else
	{
		
	}
	
	# output video info
	foreach (keys %video)
	{
		main::_log("key $_='$video{$_}'");
	}
	
	# override extension by videofile metadata
	$file_ext='flv' if $video{'ID_VIDEO_FORMAT'} eq "1FLV";
	
	main::_log("get video_part_file_path");
	my $brick_class='App::510::brick';
		$brick_class.="::".$brick{'name'}
			if $brick{'name'};
	my $video_=$brick_class->video_part_file_path({
		'video_part.ID' => $env{'video_part.ID'},
		'video_format.ID' => $env{'video_format.ID'},
#		'video_part_file.name' => $name, # why not?
		'video_part_file.file_ext' => $file_ext,
		'video_part.datetime_air' => $part{'datetime_air'},
		
		'video.datetime_rec_start' => ($env{'video.datetime_rec_start'} || $video_db{'datetime_rec_start'}),
		'video_attrs.name' => ($env{'video_attrs.name'} || $video_db{'name'} || $video_db{'ID_video'}),
		'video_part_attrs.name' => ($env{'video_part_attrs.name'} || $video_db{'part_name'})
	});
	
	my $name=$video_->{'video_part_file.name'};
	
	if (
			(
				$env{'video_format.ID'} eq "1"
#				|| $env{'video_format.ID'} eq $App::510::video_format_full_ID
			)
			||($env{'file_thumbnail'})
		)
	{
		# generate thumbnail from full
		my $rel;
		main::_log("checking if generate thumbnail");
		my $tmpjpeg=new TOM::Temp::file('ext'=>'jpeg','dir'=>$main::ENV{'TMP'},'nocreate'=>1);
		
		if (!$env{'file_thumbnail'} &&
			($part{'thumbnail_lock'} eq 'N' || $env{'thumbnail_lock_ignore'}))
		{
			main::_log("generate thumbnail from 'full' video_format.name");
			$rel=1;
			_video_part_file_thumbnail(
				'file' => $env{'file'},
				'file2' => $tmpjpeg->{'filename'},
#				'timestamps' => [
#					'5',
	#				'10',
	#				'15'
#				]
			) || do
			{
				$rel=0;#$t->close();return undef
			};
#			$rel=1;
		}
		elsif ($env{'file_thumbnail'})
		{
			main::_log("add existing thumbnail to video_part");
			File::Copy::copy($env{'file_thumbnail'},$tmpjpeg->{'filename'});
			$rel=1;
		}
		else
		{
			main::_log("thumbnail already added to video_part");
		}
		
		if ($rel)
		{
			my $image_name=
				$env{'video_part_attrs.name'} ||
				$env{'video_attrs.name'} ||
				'video_part #'.$env{'video_part.ID'};
				
			# find if already exists relation to any thumbnail in a501
			my $relation=(App::160::SQL::get_relations(
				'l_prefix' => 'a510',
				'l_table' => 'video_part',
				'l_ID_entity' => $env{'video_part.ID'},
				'rel_type' => 'thumbnail',
				'r_db_name' => $App::501::db_name,
				'r_prefix' => 'a501',
				'r_table' => 'image',
	#			'r_ID_entity' => '2'
				'limit' => 1,
				'status' => 'Y'
			))[0];
			if (!$relation->{'ID'})
			{
				# add image to gallery
				main::_log("adding image");
				my %image=App::501::functions::image_add(
					'file' => $tmpjpeg->{'filename'},
					'image_attrs.ID_category' => $App::510::thumbnail_cat_ID_entity,
					'image_attrs.name' => $image_name,
					'image_attrs.status' => 'Y',
	#				'image_attrs.description' => $desc
				);
				if (!$image{'image.ID'})
				{
					$t->close();
					return undef;
				};
				main::_log("added image $image{'image.ID_entity'}");
				App::501::functions::image_regenerate(
					'image.ID' => $image{'image.ID'}
				);
				App::160::SQL::new_relation(
					'l_prefix' => 'a510',
					'l_table' => 'video_part',
					'l_ID_entity' => $env{'video_part.ID'},
					'rel_type' => 'thumbnail',
					'r_db_name' => $App::501::db_name,
					'r_prefix' => 'a501',
					'r_table' => 'image',
					'r_ID_entity' => $image{'image.ID_entity'},
					'status' => 'Y'
				);
			}
			else
			{
				# updating related image
#				main::_log("updating related image $relation->{'r_ID_entity'} to category '$App::510::thumbnail_cat{$tom::LNG}'");
#				main::_log("updating related image $relation->{'r_ID_entity'} to category '$App::510::thumbnail_cat{$tom::LNG}'");
				main::_log("can't update already generated image $relation->{'r_ID_entity'}");
				
				
				if ($env{'thumbnail_lock_ignore'})
				{
					my %image=App::501::functions::image_add(
						'image.ID_entity' => $relation->{'r_ID_entity'},
						'file' => $tmpjpeg->{'filename'},
						'image_attrs.ID_category' => $App::510::thumbnail_cat_ID_entity,
						'image_attrs.name' => $image_name,
					);
				}
				
				# add here check if this image is another category than $App::510::thumbnail_cat{$tom::LNG}
				# don't update it
				
#				my %image=App::501::functions::image_add(
#					'image.ID_entity' => $relation->{'r_ID_entity'},
#					'file' => $tmpjpeg->{'filename'},
#					'image_attrs.ID_category' => $App::510::thumbnail_cat{$tom::LNG},
#					'image_attrs.name' => $image_name,
#				);
			}
		}
		
		my $tmpjpeg=new TOM::Temp::file('ext'=>'jpeg','dir'=>$main::ENV{'TMP'},'nocreate'=>1);
		my ($out,$data)=_video_part_file_previews(
			'length' => $video{'length'},
			'file' => $env{'file'},
			'file2' => $tmpjpeg->{'filename'}
		);
		if ($out)
		{
			
			my $part_ID = $env{'video_part.ID'};
			my @previews;
			opendir (DIR, $data->{'pattern_dir'});
			my $i;
			use POSIX;
			foreach my $file (sort { $a cmp $b } grep {$_=~/^$data->{'pattern_file'}$/} readdir(DIR))
			{
				$i++;
				my $hms=strftime("\%H:\%M:\%S", gmtime(($i - 0.5) * $data->{'interval'}));
				$hms=strftime("\%H:\%M:\%S", gmtime(0)) unless $i;
				my %image=App::501::functions::image_add(
					'file' => $data->{'pattern_dir'}.'/'.$file,
					'image_attrs.ID_category' => $App::510::thumbnail_cat_ID_entity,
					'image_attrs.name' => '#'.$part_ID.' '.$hms,
					'image_attrs.status' => 'Y',
					'check_duplicity' => 1,
				);
				unlink $data->{'pattern_dir'}.'/'.$file;
				push @previews,{
					'hms' => $hms,
					'image' => $image{'image.ID_entity'},
				};
			}
			foreach my $relation (App::160::SQL::get_relations(
				'l_prefix' => 'a510',
				'l_table' => 'video_part',
				'l_ID_entity' => $part_ID,
	#			'rel_type' => 'preview',
				'r_db_name' => $App::501::db_name,
				'r_prefix' => 'a501',
				'r_table' => 'image',
				'limit' => 1000,
				'status' => 'Y'
			))
			{
				next unless $relation->{'rel_type'}=~/^preview_(.*?)$/;
				$relation->{'hms'}=$1;
				my $found;
				foreach my $preview (@previews)
				{
					if ($preview->{'hms'} eq $relation->{'hms'} && $preview->{'image'} eq $relation->{'r_ID_entity'})
					{
						$preview={};
						$found=1;
						last;
					}
				}
				next if $found;
				App::160::SQL::remove_relation(
					'l_prefix' => 'a510',
					'l_table' => 'video_part',
					'ID' => $relation->{'ID'}
				);
			}
			foreach my $preview (@previews)
			{
				next unless $preview->{'image'};
				App::160::SQL::new_relation(
					'l_prefix' => 'a510',
					'l_table' => 'video_part',
					'l_ID_entity' => $part_ID,
					'rel_type' => 'preview_'.$preview->{'hms'},
					'rel_name' => $preview->{'hms'},
					'r_db_name' => $App::501::db_name,
					'r_prefix' => 'a501',
					'r_table' => 'image',
					'r_ID_entity' => $preview->{'image'},
					'status' => 'Y'
				);
			}
			
		}
		
	}
	
	
	# Check if video_part_file for this format exists
	my $sql=qq{
		SELECT
			*
		FROM
			`$App::510::db_name`.`a510_video_part_file`
		WHERE
			ID_entity=$env{'video_part.ID'} AND
			ID_format=$env{'video_format.ID'}
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	if (my %db0_line=$sth0{'sth'}->fetchhash)
	{
		# file updating
		main::_log("check for update video_part_file");
		main::_log("checkum in database = '$db0_line{'file_checksum'}'");
		main::_log("checkum from file = '$checksum_method:$checksum'");
		if ($db0_line{'file_checksum'} eq "$checksum_method:$checksum")
		{
			main::_log("same checksum, just enabling file when disabled");
			
			my %columns;
			
			if ($env{'file_nocopy'})
			{$columns{'file_alt_src'}="'".$env{'file'}."'";}
			else
			{$columns{'file_alt_src'}='NULL';}
			
			App::020::SQL::functions::update(
				'ID' => $db0_line{'ID'},
				'db_h' => 'main',
				'db_name' => $App::510::db_name,
				'tb_name' => 'a510_video_part_file',
				'columns' =>
				{
					'video_width' => "'$video{'width'}'",
					'video_height' => "'$video{'height'}'",
					'video_codec' => "'$video{'codec'}'",
					'video_fps' => "'$video{'fps'}'",
					'video_bitrate' => "'$video{'bitrate'}'",
					'audio_codec' => "'$video{'audio_codec'}'",
					'audio_bitrate' => "'$video{'audio_bitrate'}'",
					'length' => "SEC_TO_TIME(".int($video{'length'}).")",
					'file_size' => "'$file_size'",
					'from_parent' => "'$env{'from_parent'}'",
					'regen' => "'N'",
					'status' => "'Y'",
#					'datetime_create' => "FROM_UNIXTIME($main::time_current)", # hack
					%columns
				},
				'-journalize' => 1,
			);
			$t->close();
			
			# override modifytime
			App::020::SQL::functions::_save_changetime({
				'db_h' => 'main',
				'db_name' => $App::510::db_name,
				'tb_name' => 'a510_video',
				'ID_entity' => $part{'ID_entity'}
			});
			video_part_smil_generate('video_part.ID' => $env{'video_part.ID'});
			_video_index('ID_entity'=>$part{'ID_entity'});
			return $db0_line{'ID'};
		}
		else
		{
			main::_log("checksum differs");
			my %columns;
			
			if ($env{'file_nocopy'})
			{$columns{'file_alt_src'}="'".$env{'file'}."'";}
			else
			{$columns{'file_alt_src'}='NULL';}
			
			if (!$env{'file_nocopy'})
			{
				
				my $video_=$brick_class->video_part_file_path({
					'video_part.ID' => $part{'ID'},
					'video_part.datetime_air' => $part{'datetime_air'},
	#				'video.ID' => $video{'ID_video'},
					'video_part_file.ID' => $db0_line{'ID'},
					'video_format.ID' => $env{'video_format.ID'},
					'video_part_file.name' => $name,
					'video_part_file.file_ext' => $file_ext,
				});
				
				my $path=$video_->{'dir'}.'/'.$video_->{'file_path'};
				
				if ($brick_class->can('upload'))
				{
					$brick_class->upload(
						$env{'file'},
						$path
					) || do {
						main::_log("file can't be uploaded",1);
						$t->close();
						return undef;
					};
				}
				else
				{
					main::_log("copy file '$env{'file'}' to '$path'");
					if (File::Copy::copy($env{'file'},$path))
					{
					}
					else
					{
						main::_log("file can't be copied: $!",1);
						$t->close();
						return undef;
					}
				}
				
			}
			
			App::020::SQL::functions::update(
				'ID' => $db0_line{'ID'},
				'db_h' => 'main',
				'db_name' => $App::510::db_name,
				'tb_name' => 'a510_video_part_file',
				'columns' =>
				{
					'name' => "'$name'",
					'video_width' => "'$video{'width'}'",
					'video_height' => "'$video{'height'}'",
					'video_codec' => "'$video{'codec'}'",
					'video_fps' => "'$video{'fps'}'",
					'video_bitrate' => "'$video{'bitrate'}'",
					'audio_codec' => "'$video{'audio_codec'}'",
					'audio_bitrate' => "'$video{'audio_bitrate'}'",
					'length' => "SEC_TO_TIME(".int($video{'length'}).")",
					'file_size' => "'$file_size'",
					'file_checksum' => "'$checksum_method:$checksum'",
					'file_ext' => "'$file_ext'",
					'from_parent' => "'$env{'from_parent'}'",
					'regen' => "'N'",
					'status' => "'Y'",
#					'datetime_create' => "FROM_UNIXTIME($main::time_current)", # hack
					%columns
				},
				'-journalize' => 1,
			);
			
			$t->close();
			# override modifytime
			App::020::SQL::functions::_save_changetime({
				'db_h' => 'main',
				'db_name' => $App::510::db_name,
				'tb_name' => 'a510_video',
				'ID_entity' => $part{'ID_entity'}
			});
			video_part_smil_generate('video_part.ID' => $env{'video_part.ID'});
			_video_index('ID_entity'=>$part{'ID_entity'});
			return $db0_line{'ID'};
		}
	}
	else
	{
		# file creating
		main::_log("creating video_part_file");
		my %columns;
		$columns{'file_alt_src'}="'$env{'file'}'" if $env{'file_nocopy'};
		
		$columns{'status'}="'Y'";
		$columns{'status'}="'W'" if $env{'file_dontcheck'};
		
		my $ID=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_video_part_file",
			'columns' =>
			{
				'ID_entity' => $env{'video_part.ID'},
				'ID_format' => $env{'video_format.ID'},
				'name' => "'$name'",
				'video_width' => "'$video{'width'}'",
				'video_height' => "'$video{'height'}'",
				'video_codec' => "'$video{'codec'}'",
				'video_fps' => "'$video{'fps'}'",
				'video_bitrate' => "'$video{'bitrate'}'",
				'audio_codec' => "'$video{'audio_codec'}'",
				'audio_bitrate' => "'$video{'audio_bitrate'}'",
				'length' => "SEC_TO_TIME(".int($video{'length'}).")",
				'file_size' => "'$file_size'",
				'file_checksum' => "'$checksum_method:$checksum'",
				'file_ext' => "'$file_ext'",
				'from_parent' => "'$env{'from_parent'}'",
#				'datetime_create' => "FROM_UNIXTIME($main::time_current)", # hack
				%columns,
				'status' => "'X'",
			},
#			'-journalize' => 1
		);
		if (!$ID)
		{
			$t->close();
			return undef
		};
		$ID=sprintf("%08d",$ID);
		main::_log("ID='$ID'");
		
		if (!$env{'file_nocopy'})
		{
			
			my $video_=$brick_class->video_part_file_path({
				'video_part.ID' => $env{'video_part.ID'},
				'video_part.datetime_air' => $part{'datetime_air'},
#				'video.ID' => $video{'ID_video'},
				'video_part_file.ID' => $ID,
				'video_format.ID' => $env{'video_format.ID'},
				'video_part_file.name' => $name,
				'video_part_file.file_ext' => $file_ext,
			});
			
			my $path=$video_->{'dir'}.'/'.$video_->{'file_path'};
			
			if ($brick_class->can('upload'))
			{
				$brick_class->upload(
					$env{'file'},
					$path
				) || do {
					main::_log("file can't be uploaded",1);
					App::020::SQL::functions::update(
						'ID' => $ID,
						'db_h' => 'main',
						'db_name' => $App::510::db_name,
						'tb_name' => 'a510_video_part_file',
						'columns' =>
						{
							'status' => "'E'"
						},
						'-journalize' => 1,
					);
					$t->close();
					return undef;
				};
			}
			else
			{
				main::_log("copy file '$env{'file'}' to '$path'");
				if (File::Copy::copy($env{'file'},$path))
				{
				}
				else
				{
					main::_log("file can't be copied: $!",1);
					App::020::SQL::functions::update(
						'ID' => $ID,
						'db_h' => 'main',
						'db_name' => $App::510::db_name,
						'tb_name' => 'a510_video_part_file',
						'columns' =>
						{
							'status' => "'E'"
						},
						'-journalize' => 1,
					);
					$t->close();
					return undef;
				}
			}
			
		}
		$t->close();
		
		# override modifytime
		App::020::SQL::functions::update(
			'ID' => $ID,
			'db_h' => 'main',
			'db_name' => $App::510::db_name,
			'tb_name' => 'a510_video_part_file',
			'columns' =>
			{
				'status' => $columns{'status'}
			},
			'-journalize' => 1,
		);
		App::020::SQL::functions::_save_changetime({
			'db_h' => 'main',
			'db_name' => $App::510::db_name,
			'tb_name' => 'a510_video',
			'ID_entity' => $part{'ID_entity'}
		});
		video_part_smil_generate('video_part.ID' => $env{'video_part.ID'});
		_video_index('ID_entity'=>$part{'ID_entity'});
		return $ID;
	}
	
	# override modifytime
	App::020::SQL::functions::_save_changetime({
		'db_h' => 'main',
		'db_name' => $App::510::db_name,
		'tb_name' => 'a510_video',
		'ID_entity' => $part{'ID_entity'}
	});
	
	video_part_smil_generate('video_part.ID' => $env{'video_part.ID'});
	main::_log("calling _video_index()");
	_video_index('ID_entity'=>$part{'ID_entity'});
	
	$t->close();
	return 1;
}



sub _video_part_file_thumbnail
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::_video_part_file_thumbnail()");
	
	main::_log("file='$env{'file'}'");
	
	if (!$env{'file2'})
	{
		$t->close();
		return undef;
	}
	
	if (!$env{'timestamps'})
	{
		$env{'timestamps'}=[300,120,60,30,20,10,5,1,0];
	}
	
	my $out2;
	foreach my $timestamp(@{$env{'timestamps'}})
	{
		main::_log("timestamp = ".$timestamp."s");
		
		if ($avconv_exec)
		{
			my $cmd2=$avconv_exec.' -i '.$env{'file'}.' -ss '.$timestamp.' -vframes 1 '.$env{'file2'};
			main::_log("$cmd2");system("$cmd2 >/dev/null 2>/dev/null");
			
			my $size=-s $env{'file2'};
			if ($size > 0)
			{
				$out2 = 1;
				last;
			}
			
			next;
		}
		
		my $cmd2="$ffmpeg_exec -y -i $env{'file'} -ss $timestamp -t 0.001 -f mjpeg -an $env{'file2'}";
		main::_log("$cmd2");system("$cmd2 >/dev/null 2>/dev/null");
		
		my $size=-s $env{'file2'};
		#main::_log("size=$size");
		if ($size > 0)
		{
			$out2=1;
			last;
		}
	}
	if (!$out2)
	{
		main::_log("thumbnail can't be generated",1);
		$t->close();
		return undef;
	}
	
	my $image1 = new Image::Magick;
	$image1->Read($env{'file2'});
	$image1->Write($env{'file2'});
	
	$t->close();
	return 1;
}


sub _video_part_file_previews
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::_video_part_file_previews()");
	
	$env{'interval'}||=60;
	if ($env{'length'})
	{
		if ($env{'length'} >= 7200)
		{
			$env{'interval'}=300;
		}
		elsif ($env{'length'} >= 3600)
		{
			$env{'interval'}=120;
		}
		elsif ($env{'length'} >= 1200)
		{
			$env{'interval'}=30;
		}
		else
		{
			$env{'interval'}=10;
		}
	}
	
	main::_log("file='$env{'file'}'");
	
	$env{'file2'}=~s|^(.*)\.(.*?)$|$1-%04d.$2|;
	
	$env{'pattern_file'}=$env{'file2'};
	$env{'pattern_file'}=~s|^(.*)/||;$env{'pattern_dir'}=$1;
	$env{'pattern_file'}=~s|([\.\-])|\\$1|gms;
	$env{'pattern_file'}=~s|\%04d|.*|;
	
	if (!$env{'file2'})
	{
		$t->close();
		return undef;
	}
	
	if ($avconv_exec)
	{
		my $cmd2=$avconv_exec.' -i '.$env{'file'}.' -c:v mjpeg -qscale 1 -vsync vfr -vf "fps=1/'.$env{'interval'}.',scale=-1:100" '.$env{'file2'};
		main::_log("$cmd2");system("$cmd2 >/dev/null 2>/dev/null");
	}
	else
	{
		$t->close();
		return undef;
	}
	
	$t->close();
	return 1,\%env;
}


=head2 video_part_file_newhash()

Find new unique hash for file

=cut

sub video_part_file_newhash
{
	my $optimal_hash=shift;
	if ($optimal_hash)
	{
		$optimal_hash=Int::charsets::encode::UTF8_ASCII($optimal_hash);
		$optimal_hash=~tr/[A-Z]/[a-z]/;
		$optimal_hash=~s|[^a-z0-9]|_|g;
		1 while ($optimal_hash=~s|__|_|g);
		my $max=120;
		if (length($optimal_hash)>$max)
		{
			$optimal_hash=substr($optimal_hash,0,$max);
		}
		main::_log("optimal_hash='$optimal_hash'");
	}
	
	my $okay=0;
	my $hash;
	
	while (!$okay)
	{
		
		$hash=$optimal_hash || TOM::Utils::vars::genhash(8);
		main::_log("testing hash='$hash'");
		my $sql=qq{
			(
				SELECT ID
				FROM
					`$App::510::db_name`.a510_video_part_file
				WHERE
					name LIKE '}.(TOM::Security::form::sql_escape($hash)).qq{'
				LIMIT 1
			)
			UNION ALL
			(
				SELECT ID
				FROM
					`$App::510::db_name`.a510_video_part_file_j
				WHERE
					name LIKE '}.(TOM::Security::form::sql_escape($hash)).qq{'
				LIMIT 1
			)
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		if (!$sth0{'sth'}->fetchhash())
		{
			main::_log("found hash '$hash'");
			$okay=1;
			last;
		}
		undef $optimal_hash;
	}
	
	return $hash;
}



=head2 video_part_visit()

Increase number of video_part visits

=cut

sub video_part_visit
{
	my $ID_part=shift;
	
	if ($Redis)
	{
		my $key='main::'.$App::510::db_name.'::a510_video_part::ID_'.$ID_part;
		my $count_visits = $Redis->hmget('C3|db_entity|'.$key,'_firstvisit','visits');
		if (
			($count_visits->[0] <= ($main::time_current - 1200)) # save every 10 minutes
			|| $count_visits->[1] >= 1000)
		{
			# it's time to save
			TOM::Database::SQL::execute(qq{
				UPDATE `$App::510::db_name`.a510_video_part
				SET visits = visits + $count_visits->[1]
				WHERE ID = $ID_part
				LIMIT 1
			},'quiet'=>1,'-jobify'=>1) if $count_visits->[1];
			$Redis->hmset('C3|db_entity|'.$key,
				'visits',1,
				'_firstvisit', $main::time_current,
				sub {}
			);
			$Redis->expire($key,(86400 * 7 * 4),sub {});
		}
		else
		{
			$Redis->hincrby('C3|db_entity|'.$key,'visits',1,sub {});
			if (!$count_visits->[0])
			{
				$Redis->expire($key,(86400 * 7 * 4),sub {});
			}
		}
		return 1;
	}
	
	# check if this visit is in video_part
	my $cache={};
	$cache=$Ext::CacheMemcache::cache->get(
		'namespace' => $App::510::db_name.".a510_video_part.visit",
		'key' => $ID_part
	) if $TOM::CACHE_memcached;
	if (!$cache->{'time'} && $TOM::CACHE_memcached)# try again when memcached sends empty key (bug)
	{
		usleep(3000); # 3 miliseconds
		$cache=$Ext::CacheMemcache::cache->get(
			'namespace' => $App::510::db_name.".a510_video_part.visit",
			'key' => $ID_part
		)
	}
	
	if (!$cache->{'time'})
	{
		$cache->{'visits'}=1;
		$Ext::CacheMemcache::cache->set
		(
			'namespace' => $App::510::db_name.".a510_video_part.visit",
			'key' => $ID_part,
			'value' =>
			{
				'time' => time(),
				'visits' => $cache->{'visits'}
			},
			'expiration' => "24H"
		) if $TOM::CACHE_memcached;
		# update SQL
		TOM::Database::SQL::execute(qq{
			UPDATE `$App::510::db_name`.a510_video_part
			SET visits=visits+1
			WHERE ID=$ID_part
			LIMIT 1
		},'quiet'=>1,'-jobify'=>1) unless $TOM::CACHE_memcached;
		return 1;
	}
	
	# return unless memcached available
	return 1 unless $TOM::CACHE_memcached;
	
	$cache->{'visits'}++;
	
	my $old=time()-$cache->{'time'};
	
	if ($old > (60*10))
	{
		# update database
		TOM::Database::SQL::execute(qq{
			UPDATE `$App::510::db_name`.a510_video_part
			SET visits=visits+$cache->{'visits'}
			WHERE ID=$ID_part
			LIMIT 1
		},'quiet'=>1,'-jobify'=>1);
		$cache->{'visits'}=0;
		$cache->{'time'}=time();
	}
	
	$Ext::CacheMemcache::cache->set
	(
		'namespace' => $App::510::db_name.".a510_video_part.visit",
		'key' => $ID_part,
		'value' =>
		{
			'time' => $cache->{'time'},
			'visits' => $cache->{'visits'}
		},
		'expiration' => "24H"
	) if $TOM::CACHE_memcached;
	
	return 1;
}



=head2 get_video_part_file()

Return video_part_file columns. This is the fastest way (optimized SQL) to get informations about file in video_part. Informations are cached in memcached and cache is monitored by information of last change of a510_video.

	my %video_part_file=get_video_part_file(
		'video.ID_entity' => 1 or 'video_part.ID' = > 1
		'video_part.part_id' => 1 # default for video.ID_entity
		'video_part_file.ID_format' => 1 # default
		'video_attrs.lng' => $tom::lng # default
		''
	)

=cut

sub get_video_part_file
{
	my %env=@_;
	
	if (!$env{'video.ID_entity'} && !$env{'video_part.ID'})
	{
		return undef;
	}
	
	$env{'video_part_file.ID_format'} ||= $env{'video_format.ID'};
	$env{'video_part_file.ID_format'} ||= $App::510::video_format_full_ID;
	$env{'video_attrs.lng'}=$tom::lng unless $env{'video_attrs.lng'};
	
	my $sql=qq{
		SELECT
			video.ID_entity,
			video.ID,
			
			video.ID_entity AS ID_entity_video,
			video.ID AS ID_video,
			video_attrs.ID AS ID_attrs,
			video_part.ID AS ID_part,
			video_part_attrs.ID AS ID_part_attrs,
			video_part.ID_brick AS part_ID_brick,
			video_brick.name AS brick_name,
			
			video_ent.keywords,
			video_ent.status_geoblock,
			video_ent.status_embedblock,
			
			LEFT(video.datetime_rec_start, 16) AS datetime_rec_start,
			LEFT(video_part_file.datetime_create, 16) AS datetime_create,
			LEFT(video.datetime_rec_start,10) AS date_recorded,
			LEFT(video_ent.datetime_rec_stop, 16) AS datetime_rec_stop,
			
			video_attrs.ID_category,
			video_cat.name AS ID_category_name,
			
			video_attrs.name,
			video_attrs.name_url,
			
			video_part_attrs.name AS part_name,
			video_part_attrs.description AS part_description,
			video_part.keywords AS part_keywords,
			LEFT(video_part.datetime_air, 16) AS part_datetime_air,
			
			video_part_file.ID AS file_ID,
			video_part_file.video_width,
			video_part_file.video_height,
			video_part_file.video_bitrate,
			video_part_file.length,
			video_part_file.file_size,
			video_part_file.file_ext,
			video_part_file.file_alt_src,
			video_part_file.name AS file_name,
			video_part_file.status AS file_status,
			video_part_file.regen AS file_regen,
			
			video_part_smil.name AS smil_name,
			
			video_format.ID AS format_ID,
			video_format.name AS video_format_name,
			
			CONCAT(video_part_file.ID_format,'/',SUBSTR(video_part_file.ID,1,4),'/',video_part_file.name,'.',video_part_file.file_ext) AS file_part_path
	};
	
	if ($env{'video.ID_entity'})
	{
		$env{'video_part.part_id'} = 1 unless $env{'video_part.part_id'};
		$sql.=qq{
		FROM
			`$App::510::db_name`.`a510_video` AS video
		INNER JOIN `$App::510::db_name`.`a510_video_ent` AS video_ent ON
		(
			video_ent.ID_entity = video.ID_entity
		)
		LEFT JOIN `$App::510::db_name`.`a510_video_attrs` AS video_attrs ON
		(
			video_attrs.ID_entity = video.ID
		)
		LEFT JOIN `$App::510::db_name`.`a510_video_part` AS video_part ON
		(
			video_part.ID_entity = video.ID_entity
		)
		LEFT JOIN `$App::510::db_name`.`a510_video_part_attrs` AS video_part_attrs ON
		(
			video_part_attrs.ID_entity = video_part.ID AND
			video_part_attrs.lng = video_attrs.lng
		)
		LEFT JOIN `$App::510::db_name`.`a510_video_part_file` AS video_part_file ON
		(
			video_part_file.ID_entity = video_part.ID
		)
		LEFT JOIN `$App::510::db_name`.`a510_video_cat` AS video_cat ON
		(
			video_cat.ID_entity = video_attrs.ID_category
		)
		LEFT JOIN `$App::510::db_name`.`a510_video_brick` AS video_brick ON
		(
			video_brick.ID = video_part.ID_brick
		)
		LEFT JOIN `$App::510::db_name`.`a510_video_part_smil` AS video_part_smil ON
		(
			video_part_smil.ID_entity = video_part.ID
		)
		INNER JOIN `$App::510::db_name`.`a510_video_format` AS video_format ON
		(
			video_format.ID = video_part_file.ID_format
		)
		WHERE
			video.ID_entity=$env{'video.ID_entity'} AND
			video_part.part_id=$env{'video_part.part_id'} AND
			video_part_file.ID_format=$env{'video_part_file.ID_format'} AND
			video_attrs.lng='$env{'video_attrs.lng'}'
		LIMIT 1
		};
	}
	else
	{
		# get ID_entity for cache
		my %sth0=TOM::Database::SQL::execute(qq{SELECT ID_entity FROM `$App::510::db_name`.`a510_video` WHERE ID='$env{'video.ID'}' LIMIT 1},'quiet'=>1,'-slave'=>1,'-cache'=>3600);
		my %db0_line=$sth0{'sth'}->fetchhash();
		$env{'video.ID_entity'}=$db0_line{'ID_entity'};
		
		$sql.=qq{
		FROM
			`$App::510::db_name`.`a510_video_part` AS video_part
		LEFT JOIN `$App::510::db_name`.`a510_video` AS video ON
		(
			video_part.ID_entity = video.ID_entity
		)
		INNER JOIN `$App::510::db_name`.`a510_video_ent` AS video_ent ON
		(
			video_ent.ID_entity = video.ID_entity
		)
		LEFT JOIN `$App::510::db_name`.`a510_video_attrs` AS video_attrs ON
		(
			video_attrs.ID_entity = video.ID
		)
		LEFT JOIN `$App::510::db_name`.`a510_video_part_attrs` AS video_part_attrs ON
		(
			video_part_attrs.ID_entity = video_part.ID AND
			video_part_attrs.lng = video_attrs.lng
		)
		LEFT JOIN `$App::510::db_name`.`a510_video_part_file` AS video_part_file ON
		(
			video_part_file.ID_entity = video_part.ID
		)
		LEFT JOIN `$App::510::db_name`.`a510_video_cat` AS video_cat ON
		(
			video_cat.ID_entity = video_attrs.ID_category
		)
		LEFT JOIN `$App::510::db_name`.`a510_video_brick` AS video_brick ON
		(
			video_brick.ID = video_part.ID_brick
		)
		LEFT JOIN `$App::510::db_name`.`a510_video_part_smil` AS video_part_smil ON
		(
			video_part_smil.ID_entity = video_part.ID
		)
		INNER JOIN `$App::510::db_name`.`a510_video_format` AS video_format ON
		(
			video_format.ID = video_part_file.ID_format
		)
		WHERE
			video_part.ID=$env{'video_part.ID'} AND
			video_part_file.ID_format=$env{'video_part_file.ID_format'} AND
			video_attrs.lng='$env{'video_attrs.lng'}'
		LIMIT 1
		};
	}
	
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1,'-slave'=>1,
		'-cache' => 3600, #24H max
		'-cache_changetime' => App::020::SQL::functions::_get_changetime({
			'db_h'=>"main",'db_name'=>$App::510::db_name,'tb_name'=>"a510_video",
			'ID_entity' => $env{'video.ID_entity'}
		})
	);
	if ($sth0{'rows'})
	{
		my %video=$sth0{'sth'}->fetchhash();
		my $brick_class='App::510::brick';
			$brick_class.="::".$video{'brick_name'}
				if $video{'brick_name'};
			my $video_=$brick_class->video_part_file_path({
					'-notest' => 1,
				'video_part.ID' => $video{'ID_part'},
				'video_part.datetime_air' => $video{'part_datetime_air'},
				'video.ID' => $video{'ID_video'},
				'video_part_file.ID' => $video{'file_ID'},
				'video_format.ID' => $video{'format_ID'},
				'video_part_file.file_ext' => $video{'file_ext'},
				'video_part_file.file_alt_src' => $video{'file_alt_src'},
				'video_part_file.name' => $video{'file_name'},
			});
			$video{'dir'}=$video_->{'dir'};
			$video{'file_part_path'}=$video_->{'file_path'};
		return %video;
	}
	
	return 1;
}


=head2 get_video_part_file_process_front()

Returns front of video_part_file's to process by encoder.

	foreach my $video_part_file=(get_video_part_file_process_front(
		'limit' => 10
	);

=cut


sub get_video_part_file_process_front
{
	my %env=@_;
	$env{'limit'}=10 unless $env{'limit'};
	
	my $sql_where;
	my @sql_bind;
	
	if ($env{'video_part_file.ID_entity'})
	{
		$sql_where.=" AND video_part.ID=?";
		push @sql_bind, $env{'video_part_file.ID_entity'}
	}
	elsif ($env{'video_part.ID'})
	{
		$sql_where.=" AND video_part.ID=?";
		push @sql_bind, $env{'video_part.ID'}
	}
	
	my @data;
	my $sql=qq{
		SELECT
			video_part.ID_entity AS ID_entity_video,
			video_part.ID AS ID_part,
			video_format.ID_entity AS ID_entity_format,
			video_format.datetime_create AS format_datetime_create,
			video_format_p.ID_entity AS ID_entity_format_p,
			video_part_file.ID AS ID_file,
			video_part_file.datetime_create AS file_datetime_create,
			video_part_file.status AS file_status,
			video_part_file_p.file_size AS file_size_p,
			video_part_file_process.status AS process,
			video_part.ID_brick,
			video_brick.dontprocess AS brick_dontprocess
		FROM
			`$App::510::db_name`.a510_video_part AS video_part
		
		
		INNER JOIN `$App::510::db_name`.a510_video AS video ON
		(
			video_part.ID_entity = video.ID_entity
		)
		INNER JOIN `$App::510::db_name`.a510_video_attrs AS video_attrs ON
		(
			video_attrs.ID_entity = video.ID
		)
		
		
		LEFT JOIN `$App::510::db_name`.a510_video_format AS video_format ON
		(
			video_format.status IN ('Y','L')
--			AND video_format.name NOT LIKE 'original'
		)
		LEFT JOIN `$App::510::db_name`.a510_video_part_file AS video_part_file ON
		(
			video_part.ID = video_part_file.ID_entity AND
			video_part_file.ID_format = video_format.ID_entity AND
			video_part_file.status IN ('Y','N','E','W','X')
		)
		LEFT JOIN `$App::510::db_name`.a510_video_part_file_process AS video_part_file_process ON
		(
			video_part_file_process.ID_part = video_part.ID AND
--			video_part_file_process.ID_format = video_format.ID_entity AND
			video_part_file_process.datetime_start >= video_format.datetime_create AND
			video_part_file_process.datetime_start <= NOW() AND
			video_part_file_process.status = 'W' AND
			video_part_file_process.datetime_stop IS NULL
		)
		
		/* join parent format */
		LEFT JOIN `$App::510::db_name`.a510_video_format AS video_format_p ON
		(
			video_format_p.status IN ('Y','L') AND
			video_format_p.ID_charindex LIKE LEFT(video_format.ID_charindex,LENGTH(video_format.ID_charindex)-4)
		)
		LEFT JOIN `$App::510::db_name`.a510_video_part_file AS video_part_file_p ON
		(
			video_part.ID = video_part_file_p.ID_entity AND
			video_part_file_p.ID_format = video_format_p.ID_entity AND
			video_part_file_p.status IN ('Y','E')
		)
		LEFT JOIN `$App::510::db_name`.a510_video_part_file_process AS video_part_file_process_p ON
		(
			video_part_file_process_p.ID_part = video_part.ID AND
			video_part_file_process_p.ID_format = video_format_p.ID_entity AND
			video_part_file_process_p.datetime_start >= video_format_p.datetime_create AND
			video_part_file_process_p.datetime_start <= NOW() AND
			video_part_file_process_p.status = 'W' AND
			video_part_file_process_p.datetime_stop IS NULL
		)
		
		LEFT JOIN `$App::510::db_name`.a510_video_brick AS video_brick ON
		(
			video_part.ID_brick = video_brick.ID
		)
		
		WHERE
			/* only not trashed video parts */
			video_part.status IN ('Y') AND
			
			/* only not trashed videos */
			video.status IN ('Y') AND
			
			/* only not trashed video_attrs */
			video_attrs.status IN ('Y','N') AND
			
			/* skip videos locked */
			video_part.process_lock = 'N' AND
			
			/* skip video bricks locked */
			(video_part.ID_brick IS NULL OR video_part.ID_brick=0 OR video_brick.dontprocess != 'Y') AND
			
			/* skip videos in processing */
			video_part_file_process.ID IS NULL AND
			/* skip videos where depending format is in processing */
			video_part_file_process_p.ID IS NULL
			
			/* parent video file must exists or we are processing 'original' */
			AND
			(
				video_format.name LIKE 'original'
				OR
				(
					video_part_file_p.ID
					AND video_part_file_p.status='Y'
				)
			)
			
			/* cases when video_part_file must be re-encoded */
			AND
			(
				(
					/* video_part_file is missing, but required */
					video_format.name != 'original' AND
					video_part_file.ID IS NULL AND
					video_format.required='Y' AND
					(
						video_format.required_min_height IS NULL
						OR (video_format.required_min_height <= video_part_file_p.video_height)
					)
					AND
					(
						video_format.required_min_bitrate IS NULL
						OR (video_format.required_min_bitrate <= video_part_file_p.video_bitrate)
					)
				)
				OR
				(
					/* can be in error state, but the error state is older than new video format definition */
					video_format.name != 'original' AND
					video_part_file.ID IS NOT NULL AND
					video_format.datetime_create > video_part_file.datetime_create
				)
				OR
				(
					/* or parent file has been changed */
					video_format.name != 'original' AND
					video_part_file.ID IS NOT NULL AND
					video_part_file.datetime_create < video_part_file_p.datetime_create AND
					video_part_file.status NOT IN ('X')
				)
				OR
				(
					/* or regeneration is required */
--					video_format.name != 'original' AND
					video_part_file.regen = 'Y'
				)
				OR
				(
					/* or regeneration is awaiting */
--					video_format.name != 'original' AND
					video_part_file.status = 'W'
				)
				OR
				(
					/* or original file must be re-encoded, because is new */
					video_format.name = 'original'
					AND video_format.process IS NOT NULL
					AND video_format.process != ''
					AND video_part_file.from_parent = 'N'
				)
			)
			$sql_where
		GROUP BY
			video_part.ID, video_format.ID
	};
	my $i;
	if ($env{'count'})
	{
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT COUNT(*) AS cnt FROM ($sql) AS t2
		},'bind'=>[@sql_bind]);
		my %db0_line=$sth0{'sth'}->fetchhash();
		return $db0_line{'cnt'};
	}
	my %sth0=TOM::Database::SQL::execute($sql.qq{
		ORDER BY
			video_format.ID_charindex ASC, video.datetime_create DESC
		LIMIT $env{'limit'}
	},'bind'=>[@sql_bind]);
	while (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		$i++;
		main::_log("[$i/$sth0{'rows'}] brick='$db0_line{'ID_brick'}/$db0_line{'brick_dontprocess'}' video.ID_entity=$db0_line{'ID_entity_video'} video_part.ID=$db0_line{'ID_part'} video_format.ID_entity='$db0_line{'ID_entity_format'}' video_format.datetime_create='$db0_line{'format_datetime_create'}' video_part_file.ID=$db0_line{'ID_file'} video_part_file.datetime_create='$db0_line{'file_datetime_create'}' video_part_file.status='$db0_line{'file_status'}' video_format_p.ID_entity='$db0_line{'ID_entity_format_p'}'");
		push @data,{%db0_line};
	}
	
	return @data;
}


sub _a210_by_cat
{
	my $cats=shift;
	my %env=@_;
	
	$env{'lng'}=$tom::lng unless $env{'lng'};
	$env{'db_name'}=$App::210::db_name unless $env{'db_name'};
	my $cache_key=$env{'db_name'}.'::'.$env{'lng'}.'::'.join('::',@{$cats});
	
	# changetimes
	my $changetime_a510=App::020::SQL::functions::_get_changetime({
		'db_name' => $App::510::db_name,
		'tb_name' => 'a510_video_cat',
	});
	my $changetime_a210=App::020::SQL::functions::_get_changetime({
		'db_name' => $env{'db_name'},
		'tb_name' => 'a210_page',
	});
	
	if ($TOM::CACHE && $TOM::CACHE_memcached && $main::cache)
	{
		my $cache=$Ext::CacheMemcache::cache->get(
			'namespace' => "fnc_cache",
			'key' => 'App::510::functions::_a210_by_cat::'.$cache_key
		);
		if (($cache->{'time'} > $changetime_a210) && ($cache->{'time'} > $changetime_a510))
		{
			return $cache->{'value'};
		}
	}
	
	# find path
	my @categories;
	my %sql_def=('db_h' => "main",'db_name' => $App::510::db_name,'tb_name' => "a510_video_cat");
	foreach my $cat(@{$cats})
	{
		my %sth0=TOM::Database::SQL::execute(
			qq{SELECT ID FROM $App::510::db_name.a510_video_cat WHERE ID_entity=? AND lng=? LIMIT 1},
			'bind'=>[$cat,$env{'lng'}],'log'=>0,'quiet'=>1,
			'-cache' => 86400*7,
			'-cache_changetime' => App::020::SQL::functions::_get_changetime({
				'db_name' => $App::510::db_name,
				'tb_name' => 'a510_video_cat',
			})
		);
		next unless $sth0{'rows'};
		my %db0_line=$sth0{'sth'}->fetchhash();
		my $i;
		foreach my $p(
			App::020::SQL::functions::tree::get_path(
				$db0_line{'ID'},
				%sql_def,
				'-slave' => 1,
				'-cache' => 86400*7
				# autocached by changetime
			)
		)
		{
			push @{$categories[$i]},$p->{'ID_entity'};
			$i++;
		}
	}
	
	my $category;
	for my $i (1 .. @categories)
	{
		foreach my $cat (@{$categories[-$i]})
		{
			my %db0_line;
			foreach my $relation(App::160::SQL::get_relations(
				'db_name' => $env{'db_name'},
				'l_prefix' => 'a210',
				'l_table' => 'page',
				#'l_ID_entity' = > ???
				'r_prefix' => "a510",
				'r_table' => "video_cat",
				'r_ID_entity' => $cat,
				'rel_type' => "link",
				'status' => "Y"
			))
			{
				# je toto relacia na moju jazykovu verziu a je aktivna?
				my %sth0=TOM::Database::SQL::execute(
				qq{SELECT ID FROM $env{'db_name'}.a210_page WHERE ID_entity=? AND lng=? AND status IN ('Y','L') LIMIT 1},
				'bind'=>[$relation->{'l_ID_entity'},$env{'lng'}],'quiet'=>1,
					'-cache' => 86400*7,
					'-cache_changetime' => App::020::SQL::functions::_get_changetime({
						'db_name' => $env{'db_name'},
						'tb_name' => 'a210_page',
					})
				);
				next unless $sth0{'rows'};
				%db0_line=$sth0{'sth'}->fetchhash();
				last;
			}
			
			next unless $db0_line{'ID'};
			
			$category=$db0_line{'ID'};
			
			last;
		}
		last if $category;
	}
	
	if ($TOM::CACHE && $TOM::CACHE_memcached)
	{
		$Ext::CacheMemcache::cache->set(
			'namespace' => "fnc_cache",
			'key' => 'App::510::functions::_a210_by_cat::'.$cache_key,
			'value' => {
				'time' => time(),
				'value' => $category
			},
			'expiration' => '86400S'
		);
	}
	
	return $category;
}


sub _video_index
{
	return 1 if TOM::Engine::jobify(\@_,{'routing_key' => 'db:'.$App::510::db_name,'class'=>'indexer'}); # do it in background
	
	my %env=@_;
	return undef unless $env{'ID_entity'}; # product.ID
	return undef unless $Ext::Solr;
	
	my $t=track TOM::Debug(__PACKAGE__."::_video_index($env{'ID_entity'})",'timer'=>1);
	
	my $solr = Ext::Solr::service();
	
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			video.*,
--			video_ent.datetime_rec_start,
--			video_ent.datetime_rec_stop,
			video_ent.keywords,
			video_ent.metadata,
			video_ent.movie_release_year,
			video_ent.movie_release_date,
			video_ent.movie_country_code,
			video_ent.movie_imdb,
			video_ent.movie_catalog_number,
			video_ent.movie_length,
			video_ent.movie_note,
			video_attrs.lng
		FROM
			$App::510::db_name.a510_video AS video
		INNER JOIN $App::510::db_name.a510_video_ent AS video_ent ON
		(
			video_ent.ID_entity = video.ID_entity AND
			video_ent.status IN ('Y','L')
		)
		INNER JOIN $App::510::db_name.a510_video_attrs AS video_attrs ON
		(
			video_attrs.ID_entity = video.ID AND
			video_attrs.status IN ('Y','L')
		)
		INNER JOIN $App::510::db_name.a510_video_part AS video_part ON
		(
			video_part.ID_entity = video.ID_entity AND
			video_part.status IN ('Y','L') AND
			video_part.part_id = 1
		)
		INNER JOIN $App::510::db_name.a510_video_part_file AS video_part_file ON
		(
			video_part_file.ID_entity = video_part.ID AND
			video_part_file.status IN ('Y','L') AND
			video_part_file.ID_format = $App::510::video_format_full_ID
		)
		WHERE
			video.status IN ('Y','L') AND
			video.ID_entity = ?
	},'quiet'=>1,'bind'=>[$env{'ID_entity'}]);
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		
		#my $id=$App::510::db_name.".a510_video.".$db0_line{'lng'}.".".$db0_line{'ID_entity'};
#		main::_log("index id='$id'");
		
		my @video_ent;
		
		push @video_ent,
#			WebService::Solr::Field->new( 'id' => $id ),
			WebService::Solr::Field->new( 'db_s' => $App::510::db_name ),
			WebService::Solr::Field->new( 'addon_s' => 'a510_video' ),
			WebService::Solr::Field->new( 'lng_s' => $db0_line{'lng'} ),
			WebService::Solr::Field->new( 'ID_i' => $db0_line{'ID'} ),
			WebService::Solr::Field->new( 'ID_entity_i' => $db0_line{'ID_entity'} ),
			WebService::Solr::Field->new( 'a510_video.ID_entity_i' => $db0_line{'ID_entity'} ),
			
			WebService::Solr::Field->new( 'keywords' => $db0_line{'keywords'} )
			
			;
		
		if ($db0_line{'datetime_rec_start'})
		{
			$db0_line{'datetime_rec_start'}=~s| (\d\d)|T$1|;
			$db0_line{'datetime_rec_start'}.="Z";
			push @video_ent,
				WebService::Solr::Field->new( 'datetime_rec_start_dt' => $db0_line{'datetime_rec_start'} )
		}
		
		# all visits
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT
				SUM(video_part.visits) AS visits
			FROM
				$App::510::db_name.a510_video_part AS video_part
			WHERE
				video_part.ID_entity = ? AND
				video_part.status IN ('Y','L')
		},'quiet'=>1,'bind'=>[$env{'ID_entity'}]);
		my %db1_line=$sth1{'sth'}->fetchhash();
		main::_log(" visits=$db1_line{'visits'}");
		push @video_ent, WebService::Solr::Field->new( 'visits_i' => $db1_line{'visits'} );
		
		# visits 7d
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT
				SUM((
					SELECT COUNT(*)
					FROM $App::510::db_name.a510_video_part_callback
					WHERE datetime_create >= DATE_SUB(NOW(),INTERVAL 7 DAY) AND ID_part = video_part.ID
				)) AS visits
			FROM
				$App::510::db_name.a510_video_part AS video_part
			WHERE
				video_part.ID_entity = ? AND
				video_part.status IN ('Y','L')
		},'quiet'=>1,'-slave'=>1,'bind'=>[$env{'ID_entity'}]);
		my %db1_line=$sth1{'sth'}->fetchhash();
		main::_log(" 7d visits=$db1_line{'visits'}");
		push @video_ent, WebService::Solr::Field->new( 'visits_7d_i' => $db1_line{'visits'} );
		
		# visits 24h
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT
				SUM((
					SELECT COUNT(*)
					FROM $App::510::db_name.a510_video_part_callback
					WHERE datetime_create >= DATE_SUB(NOW(),INTERVAL 1 DAY) AND ID_part = video_part.ID
				)) AS visits
			FROM
				$App::510::db_name.a510_video_part AS video_part
			WHERE
				video_part.ID_entity = ? AND
				video_part.status IN ('Y','L')
		},'quiet'=>1,'-slave'=>1,'bind'=>[$env{'ID_entity'}]);
		my %db1_line=$sth1{'sth'}->fetchhash();
		main::_log(" 24h visits=$db1_line{'visits'}");
		push @video_ent, WebService::Solr::Field->new( 'visits_24h_i' => $db1_line{'visits'} );
		
		my %video_attrs;
		my %video_attrs_;
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT
				video_attrs.*,
				video_cat.ID AS cat_ID,
				video_cat.name AS cat_name,
				video_cat.ID_charindex AS cat_ID_charindex
			FROM
				$App::510::db_name.a510_video AS video
			INNER JOIN $App::510::db_name.a510_video_ent AS video_ent ON
			(
				video_ent.ID_entity = video.ID_entity AND
				video_ent.status IN ('Y','L')
			)
			LEFT JOIN $App::510::db_name.a510_video_attrs AS video_attrs ON
			(
				video_attrs.ID_entity = video.ID AND
				video_attrs.status IN ('Y','L')
			)
			LEFT JOIN $App::510::db_name.a510_video_cat AS video_cat ON
			(
				video_cat.ID_entity = video_attrs.ID_category AND
				video_cat.lng = video_attrs.lng AND
				video_cat.status IN ('Y','L')
			)
			WHERE
				video.status IN ('Y','L') AND
				video.ID_entity = ? AND
				video_attrs.ID_entity IS NOT NULL
		},'quiet'=>1,'bind'=>[$env{'ID_entity'}]);
		while (my %db1_line=$sth1{'sth'}->fetchhash())
		{
			main::_log(" attrs $db1_line{'lng'} $db1_line{'name'}");
			
			for my $part('description')
			{
				$db0_line{$part}=~s|<.*?>||gms;
				$db0_line{$part}=~s|&nbsp;| |gms;
				$db0_line{$part}=~s|  | |gms;
			}
			
			push @{$video_attrs{$db1_line{'lng'}}},
				WebService::Solr::Field->new( 'title' => $db1_line{'name'} );
			
			$video_attrs_{$db1_line{'lng'}}{'name'}=WebService::Solr::Field->new( 'name' => $db1_line{'name'} )
				if (!$video_attrs_{$db1_line{'lng'}}{'name'} && $db1_line{'name'});
			$video_attrs_{$db1_line{'lng'}}{'description'}=WebService::Solr::Field->new( 'description' => $db1_line{'description'} )
				if (!$video_attrs_{$db1_line{'lng'}}{'description'} && $db1_line{'description'});
			
			
			if ($db1_line{'cat_ID'})
			{
				push @{$video_attrs{$db1_line{'lng'}}},WebService::Solr::Field->new( 'cat_charindex_sm' =>  $db1_line{'cat_ID_charindex'});
				push @{$video_attrs{$db1_line{'lng'}}},WebService::Solr::Field->new( 'cat_name_sm' =>  $db1_line{'cat_name'});
				push @{$video_attrs{$db1_line{'lng'}}},WebService::Solr::Field->new( 'cat_name_tm' =>  $db1_line{'cat_name'});
				push @{$video_attrs{$db1_line{'lng'}}},WebService::Solr::Field->new( 'cat' =>  $db1_line{'cat_ID'});
				
				my %sql_def=('db_h' => "main",'db_name' => $App::510::db_name,'tb_name' => "a510_video_cat");
				foreach my $p(
					App::020::SQL::functions::tree::get_path(
						$db1_line{'cat_ID'},
						%sql_def,
						'-cache' => 86400*7
					)
				)
				{
					push @{$video_attrs{$db1_line{'lng'}}},WebService::Solr::Field->new( 'cat_path_sm' =>  $p->{'ID_entity'});
				}
			}
			
		}
		
		foreach my $lng(keys %video_attrs)
		{
			my $doc = WebService::Solr::Document->new();	
			my $id=$App::510::db_name.".a510_video.".$lng.".".$db0_line{'ID_entity'};
			$doc->add_fields((
				WebService::Solr::Field->new( 'id' => $id ),
				@video_ent,
				@{$video_attrs{$lng}},
				$video_attrs_{$db1_line{'lng'}}{'name'},
				$video_attrs_{$db1_line{'lng'}}{'description'}
			));
			
			$solr->add($doc);
		}
		
	}
	else
	{
		
		main::_log("not found active ID_entity",1);
		my $response = $solr->search( "id:".$App::510::db_name.".a510_video* AND a510_video.ID_entity_i:$env{'ID_entity'}" );
		for my $doc ( $response->docs )
		{
			$solr->delete_by_id($doc->value_for('id'));
		}
		
	}
	
	$t->close();
	return 1;
}


sub _video_cat_index
{
	my %env=@_;
	return undef unless $env{'ID'};
	return undef unless $Ext::Solr;
	
	my $t=track TOM::Debug(__PACKAGE__."::_video_cat_index()",'timer'=>1);
	
	my $solr = Ext::Solr::service();
	
	my %content;
	
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			*
		FROM
			$App::510::db_name.a510_video_cat
		WHERE
			status IN ('Y','L')
			AND ID=?
	},'quiet'=>1,'bind'=>[$env{'ID'}]);
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		main::_log("found");
		
		my $id=$App::510::db_name.".a510_video_cat.".$db0_line{'lng'}.".".$db0_line{'ID_entity'};
		main::_log("index id='$id'");
		
		my $doc = WebService::Solr::Document->new();
		
		$db0_line{'description'}=~s|<.*?>||gms;
		$db0_line{'description'}=~s|&nbsp;| |gms;
		$db0_line{'description'}=~s|  | |gms;
		
		$db0_line{'datetime_create'}=~s| (\d\d)|T$1|;
		$db0_line{'datetime_create'}.="Z";
		
		my @metadata_fields;
		
		my %metadata=App::020::functions::metadata::parse($db0_line{'metadata'});
		foreach my $sec(keys %metadata)
		{
			foreach (keys %{$metadata{$sec}})
			{
				next unless $metadata{$sec}{$_};
				if ($_=~s/\[\]$//)
				{
					# this is comma separated array
					foreach my $val (split(';',$metadata{$sec}{$_.'[]'}))
					{push @metadata_fields,WebService::Solr::Field->new( $sec.'.'.$_.'_sm' => $val)}
					push @metadata_fields,WebService::Solr::Field->new( 'metadata_used_sm' => $sec.'.'.$_);
					next;
				}
				
				push @metadata_fields,WebService::Solr::Field->new( $sec.'.'.$_.'_s' => "$metadata{$sec}{$_}" );
				if ($metadata{$sec}{$_}=~/^[0-9]{1,9}$/)
				{
					push @metadata_fields,WebService::Solr::Field->new( $sec.'.'.$_.'_i' => "$metadata{$sec}{$_}" );
				}
				if ($metadata{$sec}{$_}=~/^[0-9\.]{1,9}$/)
				{
					push @metadata_fields,WebService::Solr::Field->new( $sec.'.'.$_.'_f' => "$metadata{$sec}{$_}" );
				}
				
				# list of used metadata fields
				push @metadata_fields,WebService::Solr::Field->new( 'metadata_used_sm' => $sec.'.'.$_ );
			}
		}
		
		$doc->add_fields((
			WebService::Solr::Field->new( 'id' => $id ),
			
			WebService::Solr::Field->new( 'name' => $db0_line{'name'} ),
			WebService::Solr::Field->new( 'title' => $db0_line{'name'} ),
			WebService::Solr::Field->new( 'name_url_s' => $db0_line{'name_url'} || ''),
			
			WebService::Solr::Field->new( 'keywords' => $db0_line{'keywords'} ),
			WebService::Solr::Field->new( 'description' => $db0_line{'description'} ),
			
			WebService::Solr::Field->new( 'last_modified' => $db0_line{'datetime_create'} ),
			
			WebService::Solr::Field->new( 'db_s' => $App::510::db_name ),
			WebService::Solr::Field->new( 'addon_s' => 'a510_video_cat' ),
			WebService::Solr::Field->new( 'lng_s' => $db0_line{'lng'} ),
			WebService::Solr::Field->new( 'ID_i' => $db0_line{'ID'} ),
			WebService::Solr::Field->new( 'ID_entity_i' => $db0_line{'ID_entity'} ),
			@metadata_fields
		));
		
		$solr->add($doc);
	}
	else
	{
		main::_log("not found active ID",1);
		my $response = $solr->search( "id:".$App::510::db_name.".a510_video_cat.* AND ID_i:$env{'ID'}" );
		for my $doc ( $response->docs )
		{
			$solr->delete_by_id($doc->value_for('id'));
		}
	}
	
	$t->close();
}


sub broadcast_program_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::broadcast_program_add()");
	
	my %program;
	if ($env{'program.ID'})
	{
		%program=App::020::SQL::functions::get_ID(
			'ID' => $env{'program.ID'},
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_broadcast_program",
			'columns' => {'*'=>1}
		);
	}
	elsif ($env{'program.ID_entity'})
	{
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				`$App::510::db_name`.`a510_broadcast_program`
			WHERE
				ID_entity=?
			LIMIT 1
		},'-bind'=>[$env{'program.ID_entity'}],'quiet'=>1);
		if (%program=$sth0{'sth'}->fetchhash())
		{
			$env{'program.ID'}=$program{'ID'};
				$env{'program.ID_entity'}=$program{'ID_entity'};
		}
	}
	elsif ($env{'program.program_code'})
	{
		if ($env{'program.datetime_air_start'})
		{
			if ($env{'program.ID_channel'})
			{
				main::_log("search for program by ID_channel=$env{'program.ID_channel'} datetime_air_start=$env{'program.datetime_air_start'} program_code=$env{'program.program_code'}");
				my %sth0=TOM::Database::SQL::execute(qq{
					SELECT
						*
					FROM
						`$App::510::db_name`.a510_broadcast_program
					WHERE
						program_code=?
						AND ID_channel=?
						AND ABS(TIME_TO_SEC(TIMEDIFF(?,datetime_air_start))) <= 3600
					ORDER BY
						ABS(TIME_TO_SEC(TIMEDIFF(?,datetime_air_start))) ASC
					LIMIT 1
				},'bind'=>[
					$env{'program.program_code'},
					$env{'program.ID_channel'},
					$env{'program.datetime_air_start'},
					$env{'program.datetime_air_start'}
				],'quiet'=>1);
				if (%program=$sth0{'sth'}->fetchhash())
				{
					main::_log("found $sth0{'rows'} programs, selected program.ID=$program{'ID'}");
					$env{'program.ID'}=$program{'ID'};
					$env{'program.ID_entity'}=$program{'ID_entity'};
				}
			}
			else
			{
				my %sth0=TOM::Database::SQL::execute(qq{
					SELECT
						*
					FROM
						`$App::510::db_name`.a510_broadcast_program
					WHERE
						program_code=?
						AND ABS(TIME_TO_SEC(TIMEDIFF(?,datetime_air_start))) <= 3600
	--					AND status IN ('Y','N','L','W')
					ORDER BY
						ABS(TIME_TO_SEC(TIMEDIFF(?,datetime_air_start))) ASC
					LIMIT 1
				},'bind'=>[
					$env{'program.program_code'},
					$env{'program.datetime_air_start'},
					$env{'program.datetime_air_start'}
				],'quiet'=>1);
				if (%program=$sth0{'sth'}->fetchhash())
				{
					$env{'program.ID'}=$program{'ID'};
					$env{'program.ID_entity'}=$program{'ID_entity'};
				}
			}
		}
		else
		{
			my %sth0=TOM::Database::SQL::execute(qq{
				SELECT
					*
				FROM
					`$App::510::db_name`.a510_broadcast_program
				WHERE
					program_code=?
--					AND status IN ('Y','N','L','W')
				LIMIT 1
			},'bind'=>[$env{'program.program_code'}],'quiet'=>1);
			if (%program=$sth0{'sth'}->fetchhash())
			{
				$env{'program.ID'}=$program{'ID'};
				$env{'program.ID_entity'}=$program{'ID_entity'};
			}
		}
	}
	
	if (!$env{'program.ID'})
	{
		main::_log("new program.ID");
		
		$env{'program.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_broadcast_program",
			'data' =>
			{
				'ID_entity' => $env{'program.ID_entity'},
				'ID_channel' => $env{'program.ID_channel'},
				'name' => $env{'program.name'} || '',
				'status' => $env{'program.status'} || 'N',
			},
			'columns' => 
			{
				'datetime_air_start' => 'NOW()',
				'datetime_air_stop' => 'DATE_ADD(NOW(), INTERVAL 3600 SECOND)'
			},
			'-posix' => 1,
			'-journalize' => 1,
		);
		# reload
		%program=App::020::SQL::functions::get_ID(
			'ID' => $env{'program.ID'},
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_broadcast_program",
			'columns' => {'*'=>1}
		);
		$env{'program.ID'}=$program{'ID'};
		$env{'program.ID_entity'}=$program{'ID_entity'};
	}
	
	# update if necessary
	if ($env{'program.ID'})
	{
		my %columns;
		my %data;
		
		$data{'ID_channel'}=$env{'program.ID_channel'}
			if ($env{'program.ID_channel'} && ($env{'program.ID_channel'} ne $program{'ID_channel'}));
		$data{'name'}=$env{'program.name'}
			if (exists $env{'program.name'} && ($env{'program.name'} ne $program{'name'}));
		$env{'program.name_url'}=TOM::Net::URI::rewrite::convert($env{'program.name'})
			if $env{'program.name'};
		$data{'name_url'}=$env{'program.name_url'}
			if (exists $env{'program.name_url'} && ($env{'program.name_url'} ne $program{'name_url'}));
		
		$env{'program.video_aspect'}=sprintf('%.3f',$env{'program.video_aspect'})
			if $env{'program.video_aspect'};
		
		foreach (
			'ID_series',
			'ID_video',
			'name_original',
			'subtitle',
			'synopsis',
			'description',
			'program_code',
			'program_sec_codes',
			'record_id',
			'program_type_code',
			'authoring_country',
			'authoring_year',
			'authoring_cast',
			'authoring_authors',
			'series_ID',
			'series_type',
			'series_code',
			'series_episode',
			'series_episodes',
			'video_aspect',
			'video_bw',
			'video_quality',
			'audio_mode',
			'audio_dubbing',
			'audio_desc',
			'rating_pg',
			'accessibility_deaf',
			'accessibility_cc',
			'status_archive',
			'status_live',
			'status_live_geoblock',
			'status_premiere',
			'status_internet',
			'status_geoblock',
			'status_embedblock',
			'status_highlight',
			'recording',
			'datetime_real_start',
			'datetime_real_start_msec',
			'datetime_real_stop',
			'datetime_real_stop_msec',
			'datetime_real_status',
			'license_valid_to',
			'priority_A',
			'priority_B',
			'priority_C',
			'metadata'
		)
		{
			if (exists $env{'program.'.$_} && ($env{'program.'.$_} ne $program{$_}))
			{
				main::_log("$_: '$program{$_}'<>'".$env{'program.'.$_}."'");
				
				if ($env{'program.'.$_} || $env{'program.'.$_} eq "0")
				{
					$data{$_}=$env{'program.'.$_};
				}
				else
				{
					$columns{$_}='NULL';
				}
			}
		}
		
		$data{'datetime_air_start'}=$env{'program.datetime_air_start'}
			if ($env{'program.datetime_air_start'} && ($env{'program.datetime_air_start'} ne $program{'datetime_air_start'}));
		
		main::_log("dur='$env{'program.datetime_air_duration'}' start='$env{'program.datetime_air_start'}'")
			if $env{'program.datetime_air_duration'};
		
		if ($env{'program.datetime_air_duration'} && $env{'program.datetime_air_start'}=~/^(\d\d\d\d)\-(\d\d)\-(\d\d) (\d\d):(\d\d):(\d\d)/)
		{
			use DateTime;
			my $dt=DateTime->new(
				'year' => $1,
				'month' => $2,
				'day' => $3,
				'hour' => $4,
				'minute' => $5,
				'second' => $6
			);
			$dt->add('seconds' => $env{'program.datetime_air_duration'});
			$env{'program.datetime_air_stop'} = $dt->strftime("%F %T");
			main::_log_stdout(" $env{'program.datetime_air_start'}/$env{'program.datetime_air_duration'} air_stop=$env{'program.datetime_air_stop'}");
		}
		$data{'datetime_air_stop'}=$env{'program.datetime_air_stop'}
			if ($env{'program.datetime_air_stop'} && ($env{'program.datetime_air_stop'} ne $program{'datetime_air_stop'}));
		
		$data{'status'}=$env{'program.status'}
			if ($env{'program.status'} && ($env{'program.status'} ne $program{'status'}));
			
		if (keys %columns || keys %data)
		{
			App::020::SQL::functions::update(
				'ID' => $env{'program.ID'},
				'db_h' => "main",
				'db_name' => $App::510::db_name,
				'tb_name' => "a510_broadcast_program",
				'columns' => {%columns},
				'data' => {%data},
				'-posix' => 1,
				'-journalize' => 1
			);
			# reload
			%program=App::020::SQL::functions::get_ID(
				'ID' => $env{'program.ID'},
				'db_h' => "main",
				'db_name' => $App::510::db_name,
				'tb_name' => "a510_broadcast_program",
				'columns' => {'*'=>1}
			);
			_broadcast_program_index('ID_entity' => $env{'program.ID_entity'});
		}
	}
	
	if (
		$program{'ID'} &&
		$program{'ID_channel'} &&
		$program{'program_code'} &&
		$program{'datetime_air_start'} &&
		$program{'status'}=~/^[YLW]$/
	)
	{
		# najst konflikty a trashovat
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				`$App::510::db_name`.a510_broadcast_program
			WHERE
				ID != ?
				AND ID_channel=?
				AND (datetime_air_start >= ? AND datetime_air_start < ?)
				AND status IN ('Y','L','W')
		},'bind'=>[
			$program{'ID'},
			$program{'ID_channel'},
			$program{'datetime_air_start'},
			$program{'datetime_air_stop'}
		],'quiet'=>1);
		while (my %program0=$sth0{'sth'}->fetchhash())
		{
			main::_log("conflict start with $program0{'ID'} '$program0{'name'}'",1);
#			next;
			App::020::SQL::functions::update(
				'ID' => $program0{'ID'},
				'db_h' => "main",
				'db_name' => $App::510::db_name,
				'tb_name' => "a510_broadcast_program",
				'columns' => {'status'=>'"T"'},
				'-journalize' => 1
			);
			_broadcast_program_index('ID_entity' => $program0{'ID_entity'});
		}
		
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				`$App::510::db_name`.a510_broadcast_program
			WHERE
				ID != ?
				AND ID_channel=?
				AND datetime_air_start < ?
				AND datetime_air_stop >= ?
				AND status IN ('Y','L','W')
		},'bind'=>[
			$program{'ID'},
			$program{'ID_channel'},
			$program{'datetime_air_stop'},
			$program{'datetime_air_stop'}
		],'quiet'=>1);
		while (my %program0=$sth0{'sth'}->fetchhash())
		{
			main::_log("conflict stop with $program0{'ID'}",1);
			App::020::SQL::functions::update(
				'ID' => $program0{'ID'},
				'db_h' => "main",
				'db_name' => $App::510::db_name,
				'tb_name' => "a510_broadcast_program",
				'columns' => {'status'=>'"T"'},
				'-journalize' => 1
			);
			_broadcast_program_index('ID_entity' => $program0{'ID_entity'});
		}
		
	}
	
	$t->close();
	foreach (%program){$env{'program.'.$_}=$program{$_}};
	return %env;
}


sub broadcast_series_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::broadcast_series_add()");
	
	my %series;
	if ($env{'series.ID'})
	{
		%series=App::020::SQL::functions::get_ID(
			'ID' => $env{'series.ID'},
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_broadcast_series",
			'columns' => {'*'=>1}
		);
	}
	elsif ($env{'series.ID_entity'})
	{
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				`$App::510::db_name`.`a510_broadcast_series`
			WHERE
				ID_entity=?
			LIMIT 1
		},'-bind'=>[$env{'series.ID_entity'}],'quiet'=>1);
		if (%series=$sth0{'sth'}->fetchhash())
		{
			$env{'series.ID'}=$series{'ID'};
				$env{'series.ID_entity'}=$series{'ID_entity'};
		}
	}
	
	if (!$env{'series.ID'})
	{
		main::_log("new series.ID");
		
		$env{'series.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_broadcast_series",
			'data' =>
			{
				'ID_entity' => $env{'series.ID_entity'},
#				'ID_channel' => $env{'program.ID_channel'},
#				'name' => $env{'program.name'},
#				'status' => $env{'program.status'},
			},
#			'columns' => 
#			{
#				'datetime_air_start' => 'NOW()',
#				'datetime_air_stop' => 'DATE_ADD(NOW(), INTERVAL 3600 SECOND)'
#			},
			'-posix' => 1,
			'-journalize' => 1,
		);
		# reload
		%series=App::020::SQL::functions::get_ID(
			'ID' => $env{'series.ID'},
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_broadcast_series",
			'columns' => {'*'=>1}
		);
		$env{'series.ID'}=$series{'ID'};
		$env{'series.ID_entity'}=$series{'ID_entity'};
	}
	
	# update if necessary
	if ($env{'series.ID'})
	{
		my %columns;
		my %data;
		
#		$data{'ID_channel'}=$env{'program.ID_channel'}
#			if ($env{'program.ID_channel'} && ($env{'program.ID_channel'} ne $program{'ID_channel'}));
		$data{'name'}=$env{'series.name'}
			if (exists $env{'series.name'} && ($env{'series.name'} ne $series{'name'}));
		$env{'series.name_url'}=TOM::Net::URI::rewrite::convert($env{'series.name'})
			if $env{'series.name'};
		$data{'name_url'}=$env{'series.name_url'}
			if (exists $env{'series.name_url'} && ($env{'series.name_url'} ne $series{'name_url'}));
		
		$data{'body'}=$env{'series.body'}
			if (exists $env{'series.body'} && ($env{'series.body'} ne $series{'body'}));
		
		# with NULL
		foreach (
			'name_original',
			'program_code',
			'program_type_code',
			'synopsis',
			'parent_ID',
			'series_ID',
			'series_type',
			'series_code',
			'series_episodes',
			'priority_A',
			'priority_B',
			'priority_C',
			'authoring_country',
			'authoring_year',
			'authoring_cast',
			'authoring_authors'
		)
		{
			if (exists $env{'series.'.$_} && ($env{'series.'.$_} ne $series{$_}))
			{
				main::_log("$_: '$series{$_}'<>'".$env{'series.'.$_}."'");
				
				if ($_=~/^priority_(.)$/ && $env{'series.'.$_} < 0)
				{
					my $symbol=$1;
					$env{'series.'.$_} = $App::510::priority{$symbol};
				}
				elsif ($_=~/^priority_(.)$/ && $env{'series.'.$_} == 0)
				{
					undef $env{'series.'.$_};
				}
				
				if ($env{'series.'.$_} || $env{'series.'.$_} eq "0")
				{
					$data{$_}=$env{'series.'.$_};
				}
				else
				{
					$columns{$_}='NULL';
				}
			}
		}
		
		$data{'status'}=$env{'series.status'}
			if ($env{'series.status'} && ($env{'series.status'} ne $series{'status'}));
			
		if (keys %columns || keys %data)
		{
			App::020::SQL::functions::update(
				'ID' => $env{'series.ID'},
				'db_h' => "main",
				'db_name' => $App::510::db_name,
				'tb_name' => "a510_broadcast_series",
				'columns' => {%columns},
				'data' => {%data},
				'-posix' => 1,
				'-journalize' => 1
			);
			# reload
			%series=App::020::SQL::functions::get_ID(
				'ID' => $env{'series.ID'},
				'db_h' => "main",
				'db_name' => $App::510::db_name,
				'tb_name' => "a510_broadcast_series",
				'columns' => {'*'=>1}
			);
			_broadcast_series_index('ID_entity' => $env{'series.ID_entity'});
		}
	}
	
	$t->close();
	foreach (%series){$env{'series.'.$_}=$series{$_}};
	return %env;
}



sub video_part_cuepoint_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::video_part_cuepoint_add()");
	
	my %cuepoint;
	if ($env{'cuepoint.ID'})
	{
		%cuepoint=App::020::SQL::functions::get_ID(
			'ID' => $env{'cuepoint.ID'},
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_video_part_cuepoint",
			'columns' => {'*'=>1}
		);
	}
	
	if (!$env{'cuepoint.ID'})
	{
		main::_log("new video_part_cuepoint.ID");
		
		$env{'cuepoint.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_video_part_cuepoint",
			'data' =>
			{
				'ID_entity' => $env{'cuepoint.ID_entity'},
				'time_cuepoint' => $env{'cuepoint.time_cuepoint'}
			},
			'-posix' => 1,
			'-journalize' => 1,
		);
		# reload
		%cuepoint=App::020::SQL::functions::get_ID(
			'ID' => $env{'cuepoint.ID'},
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_video_part_cuepoint",
			'columns' => {'*'=>1}
		);
		$env{'cuepoint.ID'}=$cuepoint{'ID'};
		$env{'cuepoint.ID_entity'}=$cuepoint{'ID_entity'};
	}
	
	# update if necessary
	if ($env{'cuepoint.ID'})
	{
		my %columns;
		my %data;
		
		# with NULL
		foreach (
			'title',
			'body'
		)
		{
			if (exists $env{'cuepoint.'.$_} && ($env{'cuepoint.'.$_} ne $cuepoint{$_}))
			{
				main::_log("$_: '$cuepoint{$_}'<>'".$env{'cuepoint.'.$_}."'");
				if ($env{'cuepoint.'.$_} || $env{'cuepoint.'.$_} eq "0")
				{
					$data{$_}=$env{'cuepoint.'.$_};
				}
				else
				{
					$columns{$_}='NULL';
				}
			}
		}
		
		$data{'time_cuepoint'}=$env{'cuepoint.time_cuepoint'}
			if ($env{'cuepoint.time_cuepoint'} && ($env{'cuepoint.time_cuepoint'} ne $cuepoint{'time_cuepoint'}));
		
		$data{'status'}=$env{'cuepoint.status'}
			if ($env{'cuepoint.status'} && ($env{'cuepoint.status'} ne $cuepoint{'status'}));
			
		if (keys %columns || keys %data)
		{
			App::020::SQL::functions::update(
				'ID' => $env{'cuepoint.ID'},
				'db_h' => "main",
				'db_name' => $App::510::db_name,
				'tb_name' => "a510_video_part_cuepoint",
				'columns' => {%columns},
				'data' => {%data},
				'-posix' => 1,
				'-journalize' => 1
			);
			# reload
			%cuepoint=App::020::SQL::functions::get_ID(
				'ID' => $env{'cuepoint.ID'},
				'db_h' => "main",
				'db_name' => $App::510::db_name,
				'tb_name' => "a510_video_part_cuepoint",
				'columns' => {'*'=>1}
			);
#			_broadcast_series_index('ID_entity' => $env{'series.ID_entity'});
		}
	}
	
	$t->close();
	foreach (%cuepoint){$env{'cuepoint.'.$_}=$cuepoint{$_}};
	return %env;
}



sub _broadcast_program_index
{
	return 1 if TOM::Engine::jobify(\@_,{'routing_key' => 'db:'.$App::510::db_name,'class'=>'indexer'}); # do it in background
	
	my %env=@_;
	return undef unless $env{'ID_entity'};
	
	if ($Elastic) # the new way in Cyclone3 :)
	{
		my $t=track TOM::Debug(__PACKAGE__."::_broadcast_program_index::elastic(".$env{'ID_entity'}.")",'timer'=>1);
		
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				a510_broadcast_program.*
			FROM `$App::510::db_name`.a510_broadcast_program
			WHERE
				a510_broadcast_program.ID_entity = ? AND
				a510_broadcast_program.status IN ('Y','L')
			LIMIT 1
		},'quiet'=>1,'bind'=>[$env{'ID_entity'}]);
		if (!$sth0{'rows'})
		{
			main::_log("broadcast_program.ID_entity=$env{'ID_entity'} not found, removing from index",1);
			if ($Elastic->exists(
				'index' => 'cyclone3.'.$App::510::db_name,
				'type' => 'a510_broadcast_program',
				'id' => $env{'ID_entity'}
			))
			{
				main::_log("removing from Elastic",1);
				$Elastic->delete(
					'index' => 'cyclone3.'.$App::510::db_name,
					'type' => 'a510_broadcast_program',
					'id' => $env{'ID_entity'}
				);
			}
			$t->close();
			return 1;
		}
		
		my %program=$sth0{'sth'}->fetchhash();
		delete $program{'datetime_real_start_msec'};
		delete $program{'datetime_real_stop_msec'};
		foreach (keys %program){delete $program{$_} unless $program{$_};}
		$Elastic->index(
			'index' => 'cyclone3.'.$App::510::db_name,
			'type' => 'a510_broadcast_program',
			'id' => $env{'ID_entity'},
			'body' => {
				%program
			}
		);
		
		$t->close();
		return 1;
	}
	
	return undef unless $Ext::Solr;
	
	
	
	return 1;
}

sub _broadcast_series_index
{
	return 1 if TOM::Engine::jobify(\@_,{'routing_key' => 'db:'.$App::510::db_name,'class'=>'indexer'}); # do it in background
	
	my %env=@_;
	return undef unless $env{'ID_entity'};
	
	if ($Elastic) # the new way in Cyclone3 :)
	{
		my $t=track TOM::Debug(__PACKAGE__."::_broadcast_series_index::elastic(".$env{'ID_entity'}.")",'timer'=>1);
		
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				a510_broadcast_series.*
			FROM `$App::510::db_name`.a510_broadcast_series
			WHERE
				a510_broadcast_series.ID_entity = ? AND
				a510_broadcast_series.status IN ('Y','L')
			LIMIT 1
		},'quiet'=>1,'bind'=>[$env{'ID_entity'}]);
		if (!$sth0{'rows'})
		{
			main::_log("broadcast_series.ID_entity=$env{'ID_entity'} not found, removing from index",1);
			if ($Elastic->exists(
				'index' => 'cyclone3.'.$App::510::db_name,
				'type' => 'a510_broadcast_series',
				'id' => $env{'ID_entity'}
			))
			{
				main::_log("removing from Elastic",1);
				$Elastic->delete(
					'index' => 'cyclone3.'.$App::510::db_name,
					'type' => 'a510_broadcast_series',
					'id' => $env{'ID_entity'}
				);
			}
			$t->close();
			return 1;
		}
		
		my %series=$sth0{'sth'}->fetchhash();
		foreach (keys %series){delete $series{$_} unless $series{$_};}
		$Elastic->index(
			'index' => 'cyclone3.'.$App::510::db_name,
			'type' => 'a510_broadcast_series',
			'id' => $env{'ID_entity'},
			'body' => {
				%series
			}
		);
		
		$t->close();
		return 1;
	}
	
	return undef unless $Ext::Solr;
	
	
	
	return 1;
}


=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
