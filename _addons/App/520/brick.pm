#!/bin/perl
package App::520::brick; # default audio storage brick
use File::Path;

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our $journalize=0;
our $brick_path=$tom::P.'/!media/a520/audio';

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
	
	$audio->{'dir'}=$brick_path;
	
	my $newfile;
	if (!$audio->{'audio_part_file.name'})
	{
		# generate optimized, or random 
		
		my $hash=sprintf('%08d',$audio->{'audio_part.ID'})
			.'-'.$audio->{'audio_format.ID'}.'-'.TOM::Utils::vars::genhash(4);
		
		$audio->{'audio_part_file.name'}=$hash;
		
		$newfile=1;
	}
	
	my $id_path=sprintf('%08d',$audio->{'audio_part.ID'});
	
	$audio->{'file_path'}=
		substr($id_path,0,2)
		.'/'.substr($id_path,0,4)
		.'/'.substr($id_path,0,6)
		.'/'.$audio->{'audio_part_file.name'}.'.'.$audio->{'audio_part_file.file_ext'};
	
	my $fullpath=$audio->{'dir'}.'/'.$audio->{'file_path'};
		$fullpath=~s|^(.*)/.*?$|$1|g;
	
	if ($newfile && -e $audio->{'dir'} && !-d $fullpath)
	{
		File::Path::mkpath($fullpath);
		chmod 0777, $fullpath;
	}
	
	return $audio;
}



sub audio_part_smil_path
{
	shift;
	my $audio=shift;
	
	$audio->{'dir'}=$brick_path;
	
	if (!$audio->{'audio_part_smil.name'})
	{
		$audio->{'audio_part_smil.name'}=
			sprintf('%08d',$audio->{'audio_part.ID'}).'-'.TOM::Utils::vars::genhash(4);
	}
	
	my $id_path=sprintf('%08d',$audio->{'audio_part.ID'});
	
	$audio->{'smil_path'}=
		substr($id_path,0,2)
		.'/'.substr($id_path,0,4)
		.'/'.substr($id_path,0,6)
		.'/'.$audio->{'audio_part_smil.name'}.'.smil';
	
	return $audio;
}

1;
