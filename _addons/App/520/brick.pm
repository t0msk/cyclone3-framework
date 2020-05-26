#!/bin/perl
package App::520::brick; # default audio storage brick
use File::Path;

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our $journalize=0;
our $brick_path=$tom::P_media.'/a520/audio';

sub audio_part_file_path
{
	shift;
	my $audio=shift;
	
	if ($audio->{'audio_part_file.file_alt_src'})
	{
		$audio->{'dir'} = $audio->{'audio_part_file.file_alt_src'};
		$audio->{'dir'} =~s|^(.*)/(.*?)$|$1|;
		$audio->{'file_path'}=$2;
		return $audio;
	}
	
	return $audio if
		$audio->{'audio_part_file.file_alt_src'};
	
	$audio->{'dir'}=$tom::P_media.'/a520/audio';
	
	my $create;
	if (!$audio->{'audio_part_file.name'})
	{
		# generate optimized, or random 
		my $optimal_hash;
		if ($audio->{'audio_attrs.name'} || $audio->{'audio_part_attrs.name'})
		{
			$audio->{'audio.datetime_rec_start'}=~s| \d\d:\d\d$||;
			$optimal_hash.=$audio->{'audio.datetime_rec_start'}.'-'
				if $audio->{'audio.datetime_rec_start'};
			$optimal_hash.=$audio->{'audio_attrs.name'}.'-'
				if $audio->{'audio_attrs.name'};
			$optimal_hash.=$audio->{'audio_part_attrs.name'}.'-'
				if $audio->{'audio_part_attrs.name'};
			$optimal_hash.=$audio->{'audio_format.ID'}.'-'
				if $audio->{'audio_format.ID'};
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
						`$App::510::db_name`.a520_audio_part_file
					WHERE
						name LIKE ?
					LIMIT 1
				)
				UNION ALL
				(
					SELECT ID
					FROM
						`$App::510::db_name`.a520_audio_part_file_j
					WHERE
						name LIKE ?
					LIMIT 1
				)
				LIMIT 1
			};
			my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1,'bind'=>[$hash,$hash]);
			if (!$sth0{'sth'}->fetchhash())
			{
				main::_log("tested new audio_part_file.name '$hash'");
				$okay=1;
				last;
			}
			
			$hash=~s|\-(....)$|-|;
			$hash.=TOM::Utils::vars::genhash(4);
		}
		
		$audio->{'audio_part_file.name'}=$hash;
		
		$create=1;
	}
	
	my $id_path=sprintf('%08d',$audio->{'audio_part.ID'});
	
	$audio->{'file_path'}=
		substr($id_path,0,2)
		.'/'.substr($id_path,0,4)
		.'/'.substr($id_path,0,6)
		.'/'.$audio->{'audio_part_file.name'}.'.'.$audio->{'audio_part_file.file_ext'};
	
	my $fullpath=$audio->{'dir'}.'/'.$audio->{'file_path'};
	main::_log("[brick] audio_part_file_path '$fullpath' audio_format.ID=$audio->{'audio_format.ID'} audio_part_file.ID=$audio->{'audio_part_file.ID'}");
		$fullpath=~s|^(.*)/.*?$|$1|g;
	
	if (!$audio->{'-notest'})
	{
		testdir(undef,$fullpath);
	}
	
	return $audio;
}

our %testdir_already;
sub testdir
{
	shift;
	my $fullpath=shift;
	return 1 if $testdir_already{$fullpath};
	main::_log("[brick] testdir '$fullpath'");
	$testdir_already{$fullpath}++;
	if (!-d $fullpath)
	{
		File::Path::mkpath($fullpath);
		chmod 0777, $fullpath;
	}
	return 1;
}
sub testfile
{
	shift;
	my $fullpath=shift;
	return 1 if -e $fullpath;
	return undef;
}

1;
