#!/bin/perl
package App::510::brick;
use File::Path;

# _default_ brick

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__.' (_default_)');};}


sub video_part_file_path
{
	shift;
	my $video=shift;
	
	if ($video->{'video_part_file.file_alt_src'})
	{
		$video->{'dir'} = $video->{'video_part_file.file_alt_src'};
		$video->{'dir'} =~s|^(.*)/(.*?)$|$1|;
		$video->{'file_path'}=$2;
		return $video;
	}
	
	return $video if
		$video->{'video_part_file.file_alt_src'};
	
	$video->{'dir'}=$tom::P_media.'/a510/video/part/file';
	
	if (!$video->{'video_part_file.name'})
	{
		# generate optimized, or random 
		my $optimal_hash;
		if ($video->{'video_attrs.name'} || $video->{'video_part_attrs.name'})
		{
			$video->{'video.datetime_rec_start'}=~s| \d\d:\d\d$||;
			$optimal_hash.=$video->{'video.datetime_rec_start'}.'-'
				if $video->{'video.datetime_rec_start'};
			$optimal_hash.=$video->{'video_attrs.name'}.'-'
				if $video->{'video_attrs.name'};
			$optimal_hash.=$video->{'video_part_attrs.name'}.'-'
				if $video->{'video_part_attrs.name'};
			$optimal_hash.=$video->{'video_format.ID'}.'-'
				if $video->{'video_format.ID'};
			$optimal_hash=~s|-$||;
				
			$optimal_hash=Int::charsets::encode::UTF8_ASCII($optimal_hash);
			$optimal_hash=~tr/[A-Z]/[a-z]/;
			$optimal_hash=~s|[^a-z0-9\-]|_|g;
			1 while ($optimal_hash=~s|__|_|g);
			my $max=120;
			if (length($optimal_hash)>$max)
			{
				$optimal_hash=substr($optimal_hash,0,$max);
			}
		}
		else
		{
			$optimal_hash=TOM::Utils::vars::genhash(8);
		}
		
		my $okay=0;
		my $hash=$optimal_hash;
		
		while (!$okay)
		{
			my $sql=qq{
				(
					SELECT ID
					FROM
						`$App::510::db_name`.a510_video_part_file
					WHERE
						name LIKE ?
					LIMIT 1
				)
				UNION ALL
				(
					SELECT ID
					FROM
						`$App::510::db_name`.a510_video_part_file_j
					WHERE
						name LIKE ?
					LIMIT 1
				)
				LIMIT 1
			};
			my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1,'bind'=>[$hash,$hash]);
			if (!$sth0{'sth'}->fetchhash())
			{
				main::_log("tested new video_part_file.name '$hash'");
				$okay=1;
				last;
			}
			
			$hash=~s|\-(....)$|-|;
			$hash.=TOM::Utils::vars::genhash(4);
		}
		
		$video->{'video_part_file.name'}=$hash;
		
#		return $video;
	}

	$video->{'file_path'}=
		$video->{'video_format.ID'}
		.'/'.substr($video->{'video_part_file.ID'},0,4)
		.'/'.$video->{'video_part_file.name'}.'.'.$video->{'video_part_file.file_ext'};
	
	my $fullpath=$video->{'dir'}.'/'.$video->{'file_path'};
		$fullpath=~s|^(.*)/.*?$|$1|g;
	
	if (!-d $fullpath)
	{
		File::Path::mkpath($fullpath);
		chmod 0777, $fullpath;
	}
	
	return $video;
}



sub video_part_smil_path
{
	shift;
	my $video=shift;
	
	$video->{'dir'}=$tom::P_media.'/a510/video/part';
	
	if (!$video->{'video_part_smil.name'})
	{
		$video->{'video_part_smil.name'}=TOM::Utils::vars::genhash(32);
	}
	
	$video->{'smil_path'}=$video->{'video_part_smil.name'}.".smil";
	
	return $video;
}

1;
