#!/bin/perl
package App::510::functions;

=head1 NAME

App::510::functions

=head1 DESCRIPTION

Functions to handle basic actions with videos.

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 DEPENDS

=over

=item *

L<App::510::_init|app/"510/_init.pm">

=item *

L<App::160::_init|app/"160/_init.pm">

=item *

L<App::542::mimetypes|app/"542/mimetypes.pm">

=item *

File::Path

=item *

Digest::MD5

=item *

Digest::SHA1

=item *

File::Type

=item *

Movie::Info

=back

=cut

use App::510::_init;
use App::160::_init;
use App::542::mimetypes;
use File::Path;
use Digest::MD5  qw(md5 md5_hex md5_base64);
use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);
use File::Type;
use Movie::Info;
use File::Which qw(where);
use Time::HiRes qw(usleep);

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
			'part_id' => 1,
		}
	);
	
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
	
	if ($format_parent{'status'} ne "Y" &&  $format_parent{'status'} ne "L")
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
	
	if ($file_parent{'status'} ne "Y")
	{
		main::_log("parent video_part_file.ID='$file_parent{'ID'}' is disabled or not available",1);
		$t->close();
		return undef;
	}
	
	
	my $sql=qq{
		INSERT INTO `$App::510::db_name`.`a510_video_part_file_process`
		(
			`ID_part`,
			`ID_format`,
			`hostname`,
			`hostname_PID`,
			`process`,
			`datetime_start`
		)
		VALUES
		(
			'$video_part{'ID'}',
			'$format{'ID'}',
			'$TOM::hostname',
			'$$',
			'',
			NOW()
		)
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	my $process_ID=$sth0{'sth'}->insertid();
	
	
	my $video1_path=$file_parent{'file_alt_src'} || $tom::P.'/!media/a510/video/part/file/'._video_part_file_genpath
	(
		$format_parent{'ID'},
		$file_parent{'ID'},
		$file_parent{'name'},
		$file_parent{'file_ext'}
	);
	
	main::_log("path to parent video_part_file='$video1_path'");
	my $video2=new TOM::Temp::file('dir'=>$main::ENV{'TMP'});
	
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
		
		my $sql=qq{
			UPDATE `$App::510::db_name`.`a510_video_part_file_process`
			SET datetime_stop=NOW(), status='E'
			WHERE ID=$process_ID
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		
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
		$t->close();
		return undef;
	}
	
	my $sql=qq{
		UPDATE `$App::510::db_name`.`a510_video_part_file_process`
		SET datetime_stop=NOW(), status='Y'
		WHERE ID=$process_ID
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	
	video_part_file_add
	(
		'file' => $video2->{'filename'},
		'ext' => $out{'ext'},
		'video_part.ID' => $video_part{'ID'},
		'video_format.ID' => $format{'ID'},
		'from_parent' => "Y",
		'thumbnail_lock_ignore' => $env{'thumbnail_lock_ignore'}
	) || do {$t->close();return undef};
	
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
	
	my $pth=$tom::P.'/!media/a510/video/part/file/'.$format.'/'.$ID;
	if (!-d $pth)
	{
		File::Path::mkpath($tom::P.'/!media/a510/video/part/file/'.$format.'/'.$ID);
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
	
	my $temp_passlog=new TOM::Temp::file('unlink_ext'=>'-0.log','ext'=>'log','dir'=>$main::ENV{'TMP'});
	
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
		$line=~s|\r||;
		next unless $line;
		my @ref=split('=',$line);
		main::_log("target definition key $ref[0]='$ref[1]'");
		
#		if ($movie1_info{$ref[0]} ne $ref[1]){$target_is_same=0;last;}
		
		my $ref1_same=0;
		foreach (split(';',$ref[1])){$ref1_same=1 if $movie1_info{$ref[0]} eq $_};
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
			
			push @files,new TOM::Temp::file('ext'=>'avi','dir'=>$main::ENV{'TMP'});
			
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
				if ($env{'g'}){push @encoder_env, '-g '.$env{'g'};}
				if ($env{'strict'}){push @encoder_env, '-strict '.$env{'strict'};}
				if ($env{'keyint_min'}){push @encoder_env, '-keyint_min '.$env{'keyint_min'};}
#				if ($env{'keyint'}){push @encoder_env, '-keyint '.$env{'keyint'};}
				if ($env{'sc_threshold'}){push @encoder_env, '-sc_threshold '.$env{'sc_threshold'};}
				if ($env{'i_qfactor'}){push @encoder_env, '-i_qfactor '.$env{'i_qfactor'};}
				if ($env{'bt'}){push @encoder_env, '-bt '.$env{'bt'};}
				if ($env{'rc_eq'}){push @encoder_env, "-rc_eq '".$env{'rc_eq'}."'";}
				if ($env{'qcomp'}){push @encoder_env, '-qcomp '.$env{'qcomp'};}
				if ($env{'qblur'}){push @encoder_env, '-qblur '.$env{'qblur'};}
				if ($env{'qmin'}){push @encoder_env, '-qmin '.$env{'qmin'};}
				if ($env{'qmax'}){push @encoder_env, '-qmax '.$env{'qmax'};}
				if ($env{'qdiff'}){push @encoder_env, '-qdiff '.$env{'qdiff'};}
				if ($env{'vcodec'}){push @encoder_env, '-vcodec '.$env{'vcodec'};}
				if (exists $env{'threads'}){push @encoder_env, '-threads '.$env{'threads'};}
				if ($env{'b'}){push @encoder_env, '-b '.$env{'b'};}
				if ($env{'s_width'})
					{$env{'s'}=$env{'s_width'}.'x'.(int($movie1_info{'height'}/($movie1_info{'width'}/$env{'s_width'})/2)*2);}
				if ($env{'s_height'} && $movie1_info{'height'})
					{$env{'s'}=(int($movie1_info{'width'}/($movie1_info{'height'}/$env{'s_height'})/2)*2).'x'.$env{'s_height'};}
				if ($env{'s'}){push @encoder_env, '-s '.$env{'s'};}
				if ($env{'r'}){push @encoder_env, '-r '.$env{'r'};}
				if ($env{'acodec'}){push @encoder_env, '-acodec '.$env{'acodec'};}
				if ($env{'ab'}){push @encoder_env, '-ab '.$env{'ab'};}
				if ($env{'ar'}){push @encoder_env, '-ar '.$env{'ar'};}
				if ($env{'ac'}){push @encoder_env, '-ac '.$env{'ac'};}
				if ($env{'fs'}){push @encoder_env, '-fs '.$env{'fs'};}
				if ($env{'ss'}){push @encoder_env, '-ss '.$env{'ss'};}
				if ($env{'t'}){push @encoder_env, '-t '.$env{'t'};}
				
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
					$temp_video=new TOM::Temp::file('ext'=>$ext,'dir'=>$main::ENV{'TMP'});
					$files_key{'pass'}=$temp_video;
				}
			}
			$temp_video=new TOM::Temp::file('ext'=>$ext,'dir'=>$main::ENV{'TMP'}) unless $temp_video;
			# don't erase files after partial encode()
			push @files, $temp_video;
			$files_key{$env{'o_key'}}=$temp_video if $env{'o_key'};
			
			
			#main::_log("encoding to file '$temp_video->{'filename'}'");
			my $ff=$env{'video1'};
			$ff=~s| |\\ |g;
			my $cmd="/usr/bin/mencoder ".$ff." -o ".($env{'o'} || $temp_video->{'filename'});
			
			$cmd="cd $main::ENV{'TMP'};$ffmpeg_exec -y -i ".$ff if $env{'encoder'} eq "ffmpeg";
			
			foreach (@encoder_env){$cmd.=" $_";}
			$cmd.=" ".($env{'o'} || $temp_video->{'filename'}) if $env{'encoder'} eq "ffmpeg";
			main::_log("cmd=$cmd");
			
			$outret{'return'}=system("$cmd");main::_log("out=$outret{'return'}");
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
			
			my $temp_video=new TOM::Temp::file('ext'=>'mp4','nocreate'=>1,'dir'=>$main::ENV{'TMP'});
			
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
				
				my $temp_video_input=new TOM::Temp::file('ext'=>'mp4','nocreate'=>1,'dir'=>$main::ENV{'TMP'});
				
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
	my $t=track TOM::Debug(__PACKAGE__."::video_add()");
	my $tr=new TOM::Database::SQL::transaction('db_h'=>"main");
	
	$env{'video_format.ID'}=$App::510::video_format_original_ID unless $env{'video_format.ID'};
	$env{'video_part.part_id'}=1 unless $env{'video_part.part_id'};
	
	my $content_updated=0;
	
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
	if ($env{'video_attrs.ID_category'} && $env{'video_attrs.ID_category'} ne 'NULL')
	{
		# detect language
		%category=App::020::SQL::functions::get_ID(
			'ID' => $env{'video_attrs.ID_category'},
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_video_cat",
			'columns' => {'*'=>1}
		);
		$env{'video_attrs.lng'}=$category{'lng'};
		main::_log("setting lng='$env{'video_attrs.lng'}' from video_attrs.ID_category");
	}
	
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
		}
	}
	
	
	if (!$env{'video_attrs.ID'})
	{
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
	}
	
	
	if (!$env{'video_attrs.ID'})
	{
		# create one language representation of video
		my %columns;
		$columns{'ID_category'}=$env{'video_attrs.ID_category'} if $env{'video_attrs.ID_category'};
		$columns{'status'}="'$env{'video_attrs.status'}'" if $env{'video_attrs.status'};
		
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
		%video_attrs=App::020::SQL::functions::get_ID(
			'ID' => $env{'video_attrs.ID'},
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_video_attrs",
			'columns' => {'*'=>1}
		);
		
		$content_updated=1;
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
		'video_part.keywords' => $env{'video_part.keywords'},
		'video_part.part_id' => $env{'video_part.part_id'},
		'video_part_attrs.lng' => $env{'video_attrs.lng'},
		'video_part_attrs.name' => $env{'video_part_attrs.name'},
		'video_part_attrs.description' => $env{'video_part_attrs.description'},
	);
	$env{'video_part.ID'} = $env0{'video_part.ID'} if $env0{'video_part.ID'};
	if (!$env{'video_part.ID'})
	{
		$t->close();
		return undef
	};
	
	# MUST be rewrited - update only if necessary
	if ($env{'video_attrs.ID'})
	{
		my %columns;
		
		$columns{'ID_category'}=$env{'video_attrs.ID_category'}
			if ($env{'video_attrs.ID_category'} && ($env{'video_attrs.ID_category'} ne $video_attrs{'ID_category'}));
		$columns{'name'}="'".TOM::Security::form::sql_escape($env{'video_attrs.name'})."'"
			if ($env{'video_attrs.name'} && ($env{'video_attrs.name'} ne $video_attrs{'name'}));
		$columns{'name_url'}="'".TOM::Net::URI::rewrite::convert($env{'video_attrs.name'})."'"
			if ($env{'video_attrs.name'} && ($env{'video_attrs.name'} ne $video_attrs{'name'}));
		$columns{'description'}="'".TOM::Security::form::sql_escape($env{'video_attrs.description'})."'"
			if (exists $env{'video_attrs.description'} && ($env{'video_attrs.description'} ne $video_attrs{'description'}));
		
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
		}
	}
	
	main::_log("video.ID='$env{'video.ID'}' added/updated");
	
	if ($content_updated)
	{
		App::020::SQL::functions::_save_changetime({'db_h'=>'main','db_name'=>$App::510::db_name,'tb_name'=>'a510_video'});
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
	}
	
	# update if necessary
	if ($env{'video_part.ID'})
	{
		my %columns;
		$columns{'keywords'}="'".$env{'video_part.keywords'}."'"
			if (exists $env{'video_part.keywords'} && ($env{'video_part.keywords'} ne $video_part{'keywords'}));
		
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
		}
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
			'from_parent' => "N",
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
		}
	}
	
	main::_log("video_part.ID='$env{'video_part.ID'}' added/updated");
	
	if ($content_updated)
	{
		App::020::SQL::functions::_save_changetime({'db_h'=>'main','db_name'=>$App::510::db_name,'tb_name'=>'a510_video'});
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
	
	my $sql=qq{
		SELECT
			video.*
		FROM
			`$App::510::db_name`.a510_video_view AS video
		WHERE
			video.ID_part=$env{'video_part.ID'} AND
			video.ID_format=$App::510::video_format_original_ID
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	my %video_db=$sth0{'sth'}->fetchhash();
	main::_log("video.ID='$video_db{'ID_video'}' video.name='$video_db{'name'}'");
	$env{'from_parent'}='N' unless $env{'from_parent'};
	
	
	# file must be analyzed
	
	# size
	my $file_size=(stat($env{'file'}))[7];
	main::_log("file size='$file_size'");
	
	if (!$file_size)
	{
		$t->close();
		return undef;
	}
	
	# checksum
	open(CHKSUM,'<'.$env{'file'});
	my $ctx = Digest::SHA1->new;
	$ctx->addfile(*CHKSUM); # when script hangs here, check file permissions
	my $checksum = $ctx->hexdigest;
	my $checksum_method = 'SHA1';
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
	my $file3=new TOM::Temp::file('ext'=>$file_ext,'dir'=>$main::ENV{'TMP'});
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
	
	
	# generate new unique hash
	my $optimal_hash=
		($env{'video.datetime_rec_start'} || $video_db{'datetime_rec_start'})
		."-".($env{'video_attrs.name'} || $video_db{'name'} || $video_db{'ID_video'})
		."-".$video_db{'part_id'}
		."-".($env{'video_part_attrs.name'} || $video_db{'part_name'})
		."-".$video_db{'ID_format'}
		;
	main::_log("optimal_hash='$optimal_hash'");
	my $name=video_part_file_newhash($optimal_hash);
	
	
	
	
	
	if (
			($env{'video_format.ID'} eq $App::510::video_format_full_ID)
			||($env{'file_thumbnail'})
		)
	{
		# generate thumbnail from full
		my $rel;
		main::_log("checking if generate thumbnail");
		my $tmpjpeg=new TOM::Temp::file('ext'=>'jpeg','dir'=>$main::ENV{'TMP'});
		
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
					'datetime_create' => "FROM_UNIXTIME($main::time_current)", # hack
					%columns
				},
				'-journalize' => 1,
			);
			$t->close();
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
					'datetime_create' => "FROM_UNIXTIME($main::time_current)", # hack
					%columns
				},
				'-journalize' => 1,
			);
			if (!$env{'file_nocopy'})
			{
				my $path=$tom::P.'/!media/a510/video/part/file/'._video_part_file_genpath
				(
					$env{'video_format.ID'},
					$db0_line{'ID'},
					$name,
					$file_ext
				);
				main::_log("copy to $path");
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
			$t->close();
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
#				'status' => "'Y'",
				'datetime_create' => "FROM_UNIXTIME($main::time_current)", # hack
				%columns
			},
			'-journalize' => 1
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
			my $path=$tom::P.'/!media/a510/video/part/file/'._video_part_file_genpath
			(
				$env{'video_format.ID'},
				$ID,
				$name,
				$file_ext
			);
			main::_log("copy to $path");
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
		$t->close();
		return $ID;
	}
	
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
		
		#-msglevel all=-1
		#my $cmd="/usr/bin/mencoder $env{'file'} -o $tmp->{'filename'} -ss $timestamp -oac copy -ovc lavc -lavcopts vcodec=mpeg4 -frames 5";
		#main::_log("$cmd");
		#my $out=system("$cmd >/dev/null 2>/dev/null");
		#last if $out;
		
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
	
	#File::Copy::copy($env{'file2'},'/www/TOM/test.jpg');
	
	my $image1 = new Image::Magick;
	$image1->Read($env{'file2'});
	$image1->Write($env{'file2'});
	
	#File::Copy::copy($env{'file2'},'/www/TOM/test.jpg');
	
	$t->close();
	return 1;
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
		},'quiet'=>1) unless $TOM::CACHE_memcached;
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
		},'quiet'=>1);
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
	
	$env{'video_part_file.ID_format'} = $App::510::video_format_full_ID unless $env{'video_part_file.ID_format'};
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
			
			LEFT(video.datetime_rec_start, 18) AS datetime_rec_start,
			LEFT(video_attrs.datetime_create, 18) AS datetime_create,
			LEFT(video.datetime_rec_start,10) AS date_recorded,
			LEFT(video_ent.datetime_rec_stop, 18) AS datetime_rec_stop,
			
			video_attrs.ID_category,
			video_cat.name AS ID_category_name,
			
			video_attrs.name,
			video_attrs.name_url,
			
			video_part_attrs.name AS part_name,
			video_part_attrs.description AS part_description,
			video_part.keywords AS part_keywords,
			
			video_part_file.video_width,
			video_part_file.video_height,
			video_part_file.video_bitrate,
			video_part_file.length,
			video_part_file.file_size,
			video_part_file.file_ext,
			video_part_file.file_alt_src,
			
			CONCAT(video_part_file.ID_format,'/',SUBSTR(video_part_file.ID,1,4),'/',video_part_file.name,'.',video_part_file.file_ext) AS file_part_path
	};

	
	if ($env{'video.ID_entity'})
	{
		$env{'video_part.part_id'} = 1 unless $env{'video_part.part_id'};
		$sql.=qq{
		FROM
			`$App::510::db_name`.`a510_video` AS video
		LEFT JOIN `$App::510::db_name`.`a510_video_ent` AS video_ent ON
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
		LEFT JOIN `$App::510::db_name`.`a510_video_ent` AS video_ent ON
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
		WHERE
			video_part.ID=$env{'video_part.ID'} AND
			video_part_file.ID_format=$env{'video_part_file.ID_format'} AND
			video_attrs.lng='$env{'video_attrs.lng'}'
		LIMIT 1
		};
	}
	
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1,'-slave'=>1,
		'-cache' => 86400, #24H max
		'-cache_min' => 600, # when changetime before this limit 10min
		'-cache_changetime' => App::020::SQL::functions::_get_changetime({
			'db_h'=>"main",'db_name'=>$App::510::db_name,'tb_name'=>"a510_video",
			'ID_entity' => $env{'video.ID_entity'}
		})
	);
	if ($sth0{'rows'})
	{
		return $sth0{'sth'}->fetchhash();
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
			video_part_file_process.status AS process
		FROM
			`$App::510::db_name`.a510_video_part AS video_part
		
		
		LEFT JOIN `$App::510::db_name`.a510_video AS video ON
		(
			video_part.ID_entity = video.ID_entity
		)
		LEFT JOIN `$App::510::db_name`.a510_video_attrs AS video_attrs ON
		(
			video_attrs.ID_entity = video.ID
		)
		
		
		LEFT JOIN `$App::510::db_name`.a510_video_format AS video_format ON
		(
			video_format.status IN ('Y','L') AND
			video_format.name NOT LIKE 'original'
		)
		LEFT JOIN `$App::510::db_name`.a510_video_part_file AS video_part_file ON
		(
			video_part.ID = video_part_file.ID_entity AND
			video_part_file.ID_format = video_format.ID_entity AND
			video_part_file.status IN ('Y','E','W')
		)
		LEFT JOIN `$App::510::db_name`.a510_video_part_file_process AS video_part_file_process ON
		(
			video_part_file_process.ID_part = video_part.ID AND
			video_part_file_process.ID_format = video_format.ID_entity AND
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
		
		WHERE
			/* only not trashed video parts */
			video_part.status IN ('Y','N') AND
			
			/* only not trashed videos */
			video.status IN ('Y','N') AND
			
			/* only not trashed video_attrs */
			video_attrs.status IN ('Y','N') AND
			
			/* skip videos locked */
			video_part.process_lock = 'N'
			
			/* skip videos in processing */
			AND video_part_file_process.ID IS NULL
			AND video_part_file_process_p.ID IS NULL
			
			/* parent video must exists */
			AND video_part_file_p.ID
			AND video_part_file_p.status='Y'
			
			/* cases when video_part_file must be re-encoded */
			AND
			(
				(
					/* video_part_file is missing, but required */
					video_part_file.ID IS NULL AND
					video_format.required='Y'
				)
				OR
				(
					/* can be in error state, but the error state is older than new video format definition */
					video_part_file.ID IS NOT NULL AND
					video_format.datetime_create > video_part_file.datetime_create
				)
				OR
				(
					/* or parent file has been changed */
					video_part_file.ID IS NOT NULL AND
					video_part_file.datetime_create <= video_part_file_p.datetime_create
				)
				OR
				(
					/* or regeneration is required */
					video_part_file.regen = 'Y'
				)
				OR
				(
					/* or regeneration is awaiting */
					video_part_file.status = 'W'
				)
			)
		
		GROUP BY
			video_part.ID, video_format.ID
			
		ORDER BY
			video_format.ID_charindex, video_part.datetime_create DESC
			
		LIMIT $env{'limit'}
	};
	my $i;
	my %sth0=TOM::Database::SQL::execute($sql);
	while (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		$i++;
		main::_log("[$i/$sth0{'rows'}] video.ID_entity=$db0_line{'ID_entity_video'} video_part.ID=$db0_line{'ID_part'} video_format.ID_entity='$db0_line{'ID_entity_format'}' video_format.datetime_create='$db0_line{'format_datetime_create'}' video_part_file.ID=$db0_line{'ID_file'} video_part_file.datetime_create='$db0_line{'file_datetime_create'}' video_part_file.status='$db0_line{'file_status'}' video_format_p.ID_entity='$db0_line{'ID_entity_format_p'}'");
		push @data,{%db0_line};
	}
	
	return @data;
}


=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
