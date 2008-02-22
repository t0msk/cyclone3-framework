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

L<App::541::mimetypes|app/"541/mimetypes.pm">

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
use App::541::mimetypes;
use File::Path;
use Digest::MD5  qw(md5 md5_hex md5_base64);
use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);
use File::Type;
use Movie::Info;



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
	
	my $video1_path=$file_parent{'file_alt_src'} || $tom::P.'/!media/a510/video/part/file/'._video_part_file_genpath
	(
		$format_parent{'ID'},
		$file_parent{'ID'},
		$file_parent{'name'},
		$file_parent{'file_ext'}
	);
	
	main::_log("path to parent video_part_file='$video1_path'");
	my $video2=new TOM::Temp::file();
	
	my $out=video_part_file_process(
		'video1' => $video1_path,
		'video2' => $video2->{'filename'},
		'process' => $env{'process'} || $format{'process'}
	);
	
	main::_log("out=$out");
		
	if (!$out)
	{
		main::_log("parent video_part_file can't be processed",1);
		
		if ($file_parent{'ID_format'} == $App::510::video_format_original_ID && ($out <=> 512))
		{
			main::_log("lock processing of video_part.ID='$env{'video_part.ID'}'",1);
			App::020::SQL::functions::update(
				'ID' => $env{'video_part.ID'},
				'db_h' => "main",
				'db_name' => $App::510::db_name,
				'tb_name' => "a510_video_part",
				'columns' =>
				{
					'process_lock' => "'E'"
				},
				'-journalize' => 1
			);
		}
		$t->close();
		return undef;
	}
	
	video_part_file_add
	(
		'file' => $video2->{'filename'},
		'video_part.ID' => $video_part{'ID'},
		'video_format.ID' => $format{'ID'},
		'from_parent' => "Y",
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
	my $t=track TOM::Debug(__PACKAGE__."::video_part_file_process()");
	main::_log("video1='$env{'video1'}'");
	main::_log("video2='$env{'video2'}'");
	
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
	
	$env{'fps'}=$movie1_info{'fps'} if $movie1_info{'fps'};
	
	my @files;
	my %files_key;
	$env{'process'}=~s|\s+$||m;
	$env{'process'}.="\nencode()" unless $env{'process'}=~/encode\(\)$/m;
	
	if (-e 'frameno.avi'){main::_log("removing frameno.avi");unlink 'frameno.avi'}
	
	foreach my $function(split('\n',$env{'process'}))
	{
		$function=~s|\s+$||g;
		$function=~s|^\s+||g;
		
		next if $function=~/^#/;
		next unless $function=~/^([\w_]+)\((.*)\)/;
		
		my $function_name=$1;
		my $function_params=$2;
		
		my @params;
		foreach my $param (split(',',$function_params))
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
		
		if ($function_name eq "encode")
		{
			main::_log("exec $function_name()");
			
			# add params in this order
			my @encoder_env;
			my $ext='avi';
			if (!$env{'encoder'} || $env{'encoder'} eq "mencoder")
			{
				if ($env{'oac'}){push @encoder_env, '-oac '.$env{'oac'};}
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
				$ext='264' if ($env{'x264encopts'} && exists $env{'nosound'});
			}
			elsif ($env{'encoder'} eq "ffmpeg")
			{
				if ($env{'pass'}){push @encoder_env, '-pass '.$env{'pass'};}
				if ($env{'vframes'}){push @encoder_env, '-vframes '.$env{'vframes'};}
				if ($env{'f'}){push @encoder_env, '-f '.$env{'f'};}
				if (exists $env{'an'}){push @encoder_env, '-an'}
				if ($env{'flags'}){push @encoder_env, '-flags '.$env{'flags'};}
				if ($env{'cmp'}){push @encoder_env, '-cmp '.$env{'cmp'};}
				if ($env{'partitions'}){push @encoder_env, '-partitions '.$env{'partitions'};}
				if ($env{'flags2'}){push @encoder_env, '-flags2 '.$env{'flags2'};}
				if ($env{'me'}){push @encoder_env, '-me '.$env{'me'};}
				if ($env{'subq'}){push @encoder_env, '-subq '.$env{'subq'};}
				if ($env{'trellis'}){push @encoder_env, '-trellis '.$env{'trellis'};}
				if ($env{'refs'}){push @encoder_env, '-refs '.$env{'refs'};}
				if ($env{'bf'}){push @encoder_env, '-bf '.$env{'bf'};}
				if ($env{'b_strategy'}){push @encoder_env, '-b_strategy '.$env{'b_strategy'};}
				if ($env{'coder'}){push @encoder_env, '-coder '.$env{'coder'};}
				if ($env{'me_range'}){push @encoder_env, '-me_range '.$env{'me_range'};}
				if ($env{'q'}){push @encoder_env, '-q '.$env{'q'};}
				if ($env{'keyint_min'}){push @encoder_env, '-keyint_min '.$env{'keyint_min'};}
				if ($env{'sc_threshold'}){push @encoder_env, '-sc_threshold '.$env{'sc_threshold'};}
				if ($env{'i_qfactor'}){push @encoder_env, '-i_qfactor '.$env{'i_qfactor'};}
				if ($env{'bt'}){push @encoder_env, '-bt '.$env{'bt'};}
				if ($env{'rc_eq'}){push @encoder_env, "-rc_eq '".$env{'rc_eq'}."'";}
				if ($env{'qcomp'}){push @encoder_env, '-qcomp '.$env{'qcomp'};}
				if ($env{'qmin'}){push @encoder_env, '-qmin '.$env{'qmin'};}
				if ($env{'qmax'}){push @encoder_env, '-qmax '.$env{'qmax'};}
				if ($env{'qdiff'}){push @encoder_env, '-qdiff '.$env{'qdiff'};}
				if ($env{'vcodec'}){push @encoder_env, '-vcodec '.$env{'vcodec'};}
				if ($env{'b'}){push @encoder_env, '-b '.$env{'b'};}
				if ($env{'s_width'})
					{$env{'s'}=$env{'s_width'}.'x'.(int($movie1_info{'height'}/($movie1_info{'width'}/$env{'s_width'})/2)*2);}
				if ($env{'s'}){push @encoder_env, '-s '.$env{'s'};}
				if ($env{'r'}){push @encoder_env, '-r '.$env{'r'};}
				if ($env{'acodec'}){push @encoder_env, '-acodec '.$env{'acodec'};}
				if ($env{'ab'}){push @encoder_env, '-ab '.$env{'ab'};}
				
				# suggest extension
				$ext='mp4' if $env{'f'} eq "mp4";
			}
			
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
					$temp_video=new TOM::Temp::file('ext'=>$ext);
					$files_key{'pass'}=$temp_video;
				}
			}
			$temp_video=new TOM::Temp::file('ext'=>$ext) unless $temp_video;
			# don't erase files after partial encode()
			push @files, $temp_video;
			$files_key{$env{'o_key'}}=$temp_video if $env{'o_key'};
			
			
			#main::_log("encoding to file '$temp_video->{'filename'}'");
			my $cmd="/usr/bin/mencoder ".$env{'video1'}." -o ".($env{'o'} || $temp_video->{'filename'});
			$cmd="cd /www/TOM/_temp;/usr/bin/ffmpeg -y -i ".$env{'video1'} if $env{'encoder'} eq "ffmpeg";
			
			foreach (@encoder_env){$cmd.=" $_";}
			$cmd.=" ".($env{'o'} || $temp_video->{'filename'}) if $env{'encoder'} eq "ffmpeg";
			main::_log("cmd=$cmd");
			
			my $out=system("$cmd");main::_log("out=$out");
			if ($out){$t->close();return undef}
			
			$procs++;
			next;
		}
		
		if ($function_name eq "MP4BoxImport")
		{
			main::_log("exec $function_name()");
			
			my $temp_video=new TOM::Temp::file('ext'=>'mp4','nocreate'=>1);
			
			if ($files_key{'video'})
			{
				main::_log("adding m4v");
				my $cmd='cd /www/TOM/_temp;/usr/bin/MP4Box -add '.$files_key{'video'}->{'filename'}.'#video '.$temp_video->{'filename'};
				main::_log("cmd=$cmd");
				my $out=system("$cmd");main::_log("out=$out");
				if ($out){$t->close();return undef}
				
				if ($files_key{'audio'})
				{
					main::_log("adding m4a");
					my $cmd='cd /www/TOM/_temp;/usr/bin/MP4Box -add '.$files_key{'audio'}->{'filename'}.'#audio '.$temp_video->{'filename'};
					main::_log("cmd=$cmd");
					my $out=system("$cmd");main::_log("out=$out");
					if ($out){$t->close();return undef}
				}
				
			}
			elsif ($files_key{'audiovideo'})
			{
				
				my $temp_video_input=new TOM::Temp::file('ext'=>'mp4','nocreate'=>1);
				
				main::_log("adding m4v");
				my $cmd='cd /www/TOM/_temp;/usr/bin/MP4Box -add '.$files_key{'audiovideo'}->{'filename'}.'#video '.$temp_video->{'filename'};
				main::_log("cmd=$cmd");
				my $out=system("$cmd");main::_log("out=$out");
				if ($out){$t->close();return undef}
				
				main::_log("adding m4a");
				my $cmd='cd /www/TOM/_temp;/usr/bin/MP4Box -add '.$files_key{'audiovideo'}->{'filename'}.'#audio '.$temp_video->{'filename'};
				main::_log("cmd=$cmd");
				my $out=system("$cmd");main::_log("out=$out");
				if ($out){$t->close();return undef}
			}
			elsif ($files_key{'all'})
			{
				main::_log("adding a+v");
				my $cmd='cd /www/TOM/_temp;/usr/bin/MP4Box -add '.$files_key{'all'}->{'filename'}.' '.$temp_video->{'filename'};
				main::_log("cmd=$cmd");
				my $out=system("$cmd");main::_log("out=$out");
				if ($out){$t->close();return undef}
			}
			else
			{
				main::_log("adding a+v last");
				my $cmd='cd /www/TOM/_temp;/usr/bin/MP4Box -add '.($files[@files-1]->{'filename'}).' '.$temp_video->{'filename'};
				main::_log("cmd=$cmd");
				my $out=system("$cmd");main::_log("out=$out");
				if ($out){$t->close();return undef}
			}
			
			push @files, $temp_video;
			$procs++;
			next;
		}
		
		main::_log("unknown '$function'",1);
		$t->close();
		return undef;
		
	}
	
	if ($procs)
	{
		main::_log("copying last processed file '$files[-1]->{'filename'}' ext='$env{'ext'}'");
		File::Copy::copy($files[-1]->{'filename'}, $env{'video2'});
		$t->close();
		return 1;
	}
	else
	{
		main::_log("copying same file '$env{'video2'}' ext='$env{'ext'}'");
		File::Copy::copy($env{'video1'}, $env{'video2'});
		$t->close();
		return 1;
	}
	
	$t->close();
	return undef;
}



=head2 video_add()

Adds new video to gallery, or updates old video

Add new video (uploading new original sized video)

 %video=video_add
 (
   'file' => '/path/to/file',
#   'video.ID' => '',
#   'video.ID_entity' => '',
#   'video_format.ID' => '',
#   'video_attrs.ID_category' => '',
#   'video_attrs.name' => '',
#   'video_attrs.description' => '',

#   'video_part.ID' => '',
#   'video_part.part_id' => '',

#   'video_part_attrs.ID_category' => '',
#   'video_part_attrs.name' => '',
#   'video_part_attrs.description' => '',
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
	if ($env{'video_attrs.ID_category'})
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
		#$env{'video.ID'}=$video{'ID'} if $video{'ID'};
	}
	
#	if (!$env{'video.ID'})
#	{
#		$env{'video.ID'}=$video{'ID'} if $video{'ID'};
#	}
	
	
	# check if this symlink with same ID_category not exists
	# and video.ID is unknown
	if ($env{'video_attrs.ID_category'} && !$env{'video.ID'} && $env{'video.ID_entity'})
	{
		main::_log("search for ID");
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::510::db_name`.`a510_video_view`
			WHERE
				ID_entity_video=$env{'video.ID_entity'} AND
				( ID_category = $env{'video_attrs.ID_category'} OR ID_category IS NULL )
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %db0_line=$sth0{'sth'}->fetchhash();
		if ($db0_line{'ID'})
		{
			$env{'video.ID'}=$db0_line{'ID_video'};
			$env{'video_attrs.ID'}=$db0_line{'ID_attrs'};
			main::_log("setup video.ID='$db0_line{'ID_video'}'");
		}
	}
	
	
	if (!$env{'video.ID'})
	{
		# generating new video!
		main::_log("adding new video");
		
		my %columns;
		
		$columns{'ID_entity'}=$env{'video.ID_entity'} if $env{'video.ID_entity'};
		if ($env{'video.datetime_rec_start'})
		{
			if ($env{'video.datetime_rec_start'}=~/^FROM/)
			{$columns{'datetime_rec_start'}=$env{'video.datetime_rec_start'};}
			else {$columns{'datetime_rec_start'}="'".$env{'video.datetime_rec_start'}."'"}
		}
		$columns{'datetime_rec_start'}="NOW()" unless $columns{'datetime_rec_start'};
		
		if ($env{'video.datetime_rec_stop'})
		{
			if ($env{'video.datetime_rec_stop'}=~/^FROM/)
			{$columns{'datetime_rec_stop'}=$env{'video.datetime_rec_stop'};}
			else {$columns{'datetime_rec_stop'}="'".$env{'video.datetime_rec_stop'}."'"}
		}
		#$columns{'datetime_rec_stop'}="NOW()" unless $columns{'datetime_rec_stop'};
		
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
	if ($video{'ID'} &&
	(
		# datetime_rec_start
		($env{'video.datetime_rec_start'} && ($env{'video.datetime_rec_start'} ne $video{'datetime_rec_start'})) ||
		# datetime_rec_stop
		(exists $env{'video.datetime_rec_stop'} && ($env{'video.datetime_rec_stop'} ne $video{'datetime_rec_stop'}))
	))
	{
		my %columns;
		
		# datetime_rec_start
		$columns{'datetime_rec_start'}="'".$env{'video.datetime_rec_start'}."'"
			if ($env{'video.datetime_rec_start'} && ($env{'video.datetime_rec_start'} ne $video{'datetime_rec_start'}));
		# datetime_rec_stop
		if (exists $env{'video.datetime_rec_stop'} && ($env{'video.datetime_rec_stop'} ne $video{'datetime_rec_stop'}))
		{
			if (!$env{'video.datetime_rec_stop'})
			{$columns{'datetime_rec_stop'}="NULL";}
			else
			{$columns{'datetime_rec_stop'}="'".$env{'video.datetime_rec_stop'}."'";}
		}
		
		App::020::SQL::functions::update(
			'ID' => $video{'ID'},
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_video",
			'columns' => {%columns},
			'-journalize' => 1
		);
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
	}
	
	$env{'video_part.ID'}=video_part_add
	(
		'file' => $env{'file'},
		'file_nocopy' => $env{'file_nocopy'},
		'file_thumbnail' => $env{'file_thumbnail'},
		'video.ID_entity' => $env{'video.ID_entity'},
		'video.datetime_rec_start' => $video{'datetime_rec_start'},
		'video_attrs.name' => $video_attrs{'name'},
		'video_format.ID' => $env{'video_format.ID'},
		'video_part.ID' => $env{'video_part.ID'},
		'video_part.part_id' => $env{'video_part.part_id'},
		'video_part_attrs.lng' => $env{'video_attrs.lng'},
		'video_part_attrs.name' => $env{'video_part_attrs.name'},
		'video_part_attrs.description' => $env{'video_part_attrs.description'},
	);
	if (!$env{'video_part.ID'})
	{
		$t->close();
		return undef
	};
	
	if ($env{'video_attrs.ID'} &&
	(
		$env{'video_attrs.name'} ||
		$env{'video_attrs.description'} ||
		$env{'video_attrs.ID_category'}
	))
	{
		my %columns;
		
		$columns{'ID_category'}=$env{'video_attrs.ID_category'} if $env{'video_attrs.ID_category'};
		$columns{'name'}="'".$env{'video_attrs.name'}."'" if $env{'video_attrs.name'};
		$columns{'name_url'}="'".TOM::Net::URI::rewrite::convert($env{'video_attrs.name'})."'" if $env{'video_attrs.name'};
		$columns{'description'}="'".$env{'video_attrs.description'}."'" if $env{'video_attrs.description'};
		
		App::020::SQL::functions::update(
			'ID' => $env{'video_attrs.ID'},
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_video_attrs",
			'columns' => {%columns},
			'-journalize' => 1
		);
	}
	
	main::_log("video.ID='$env{'video.ID'}' added");
	
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
   
#   'video_part_attrs.lng' => 'en',
   
#   'video.ID_entity' => '',
#   'video_format.ID' => '',
#   'video_attrs.ID_category' => '',
#   'video_attrs.name' => '',
#   'video_attrs.description' => '',

#   'video_part.ID' => '',
#   'video_part.part_id' => '',

#   'video_part_attrs.ID_category' => '',
#   'video_part_attrs.name' => '',
#   'video_part_attrs.description' => '',

 );

=cut

sub video_part_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::video_part_add()");
	
	$env{'video_format.ID'}=$App::510::video_format_original_ID unless $env{'video_format.ID'};
	
	
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
	
	if (!$env{'video_part.ID'} && !$env{'video_part.part_id'} && !$env{'file'})
	{
		$env{'video_part.part_id'}=1;
	}
	
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
	}
	
	
	if (!$env{'video_part_attrs.ID'})
	{
		main::_log("finding video_part_attrs.ID");
		my $sql=qq{
			SELECT
				ID
			FROM
				`$App::510::db_name`.`a510_video_part_attrs`
			WHERE
				ID_entity='$env{'video_part.ID'}' AND
				lng='$env{'video_part_attrs.lng'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %db0_line=$sth0{'sth'}->fetchhash();
		$env{'video_part_attrs.ID'}=$db0_line{'ID'};
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
	}
	
	
	if ($env{'file'})
	{
		main::_log("file='$env{'file'}', video_part.ID='$env{'video_part.ID'}', video_format.ID='$env{'video_format.ID'}' is specified, so updating video_part_file");
		
		$env{'video_part_file.ID'}=video_part_file_add
		(
			'file' => $env{'file'},
			'file_nocopy' => $env{'file_nocopy'},
			'file_thumbnail' => $env{'file_thumbnail'},
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
	
	if ($env{'video_part_attrs.ID'} &&
	(
		$env{'video_part_attrs.name'} ||
		$env{'video_part_attrs.description'}
	))
	{
		my %columns;
		
		$columns{'name'}="'".$env{'video_part_attrs.name'}."'" if $env{'video_part_attrs.name'};
		$columns{'name_url'}="'".TOM::Net::URI::rewrite::convert($env{'video_part_attrs.name'})."'" if $env{'video_part_attrs.name'};
		$columns{'description'}="'".$env{'video_part_attrs.description'}."'" if $env{'video_part_attrs.description'};
		
		App::020::SQL::functions::update(
			'ID' => $env{'video_part_attrs.ID'},
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_video_part_attrs",
			'columns' => {%columns},
			'-journalize' => 1
		);
	}
	
	main::_log("video_part.ID='$env{'video_part.ID'}' added");
	
	$t->close();
	return 1;
}










=head2 video_part_file_add()

Adds new file to video, or updates old

 $video_part_file{'ID'}=video_part_file_add
 (
   'file' => '/path/to/file',
   'video_part.ID' => '',
   'video_format.ID' => '',
   ''
 )

=cut

sub video_part_file_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::video_part_file_add()");
	
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
	my %sth0=TOM::Database::SQL::execute($sql);
	my %video_db=$sth0{'sth'}->fetchhash();
	main::_log("video.ID='$video_db{'ID'}' video.name='$video_db{'name'}'");
	$env{'from_parent'}='N' unless $env{'from_parent'};
	
	
	# file must be analyzed
	
	# size
	my $file_size=(stat($env{'file'}))[7];
	main::_log("file size='$file_size'");
	
	# checksum
	open(CHKSUM,'<'.$env{'file'});
	my $ctx = Digest::SHA1->new;
	$ctx->addfile(*CHKSUM);
	my $checksum = $ctx->hexdigest;
	my $checksum_method = 'SHA1';
	main::_log("file checksum $checksum_method:$checksum");
	
	my $out=`file -b $env{'file'}`;chomp($out);
	my $file_ext;#
	
	# find if this file type exists
	foreach my $reg (@App::541::mimetypes::filetype_ext)
	{
		if ($out=~/$reg->[0]/){$file_ext=$reg->[1];last;}
	}
	$file_ext='avi' unless $file_ext;
	
	main::_log("type='$out' ext='$file_ext'");
	
	
	my $vd = Movie::Info->new || die "Couldn't find an mplayer to use\n";
	
	# file must be copied to have correct extension
	# if (not already has it)
	my $file3=new TOM::Temp::file('ext'=>$file_ext);
	my %video;
	if (not $env{'file'}=~/\.$file_ext$/)
	{
		File::Copy::copy($env{'file'},$file3->{'filename'});
		%video = $vd->info($file3->{'filename'});
	}
	else {%video = $vd->info($env{'file'});}
	
	# play video
	foreach (keys %video)
	{
		main::_log("key $_='$video{$_}'");
	}
	
	# generate new unique hash
	my $optimal_hash=
		($env{'video.datetime_rec_start'} || $video_db{'datetime_rec_start'})
		."-".($env{'video_attrs.name'} || $video_db{'name'} || $video_db{'ID'})
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
		
		my $tmpjpeg=new TOM::Temp::file('ext'=>'jpeg');
		
		if (!$env{'file_thumbnail'} && ($part{'thumbnail_lock'} eq 'N' ))
		{
			main::_log("generate thumbnail from 'full' video_format.name");
			_video_part_file_thumbnail(
				'file' => $env{'file'},
				'file2' => $tmpjpeg->{'filename'},
#				'timestamps' => [
#					'5',
	#				'10',
	#				'15'
#				]
			) || do {$t->close();return undef};
			$rel=1;
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
				'limit' => 1
			))[0];
			if (!$relation->{'ID'})
			{
				# add image to gallery
				main::_log("adding image");
				my %image=App::501::functions::image_add(
					'file' => $tmpjpeg->{'filename'},
					'image_attrs.ID_category' => $App::510::thumbnail_cat{$tom::LNG},
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
				App::160::SQL::new_relation(
					'l_prefix' => 'a510',
					'l_table' => 'video_part',
					'l_ID_entity' => $env{'video_part.ID'},
					'rel_type' => 'thumbnail',
					'r_db_name' => $App::501::db_name,
					'r_prefix' => 'a501',
					'r_table' => 'image',
					'r_ID_entity' => $image{'image.ID_entity'}
				);
			}
			else
			{
				# updating related image
				main::_log("updating related image $relation->{'r_ID_entity'} to category '$App::510::thumbnail_cat{$tom::LNG}'");
				my %image=App::501::functions::image_add(
					'image.ID_entity' => $relation->{'r_ID_entity'},
					'file' => $tmpjpeg->{'filename'},
					'image_attrs.ID_category' => $App::510::thumbnail_cat{$tom::LNG},
					'image_attrs.name' => $image_name,
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
		if ($db0_line{'file_checksum'} eq "$checksum_method:$checksum")
		{
			main::_log("same checksum, just enabling file when disabled");
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
					'length' => "'".int($video{'length'})."'",
					'file_size' => "'$file_size'",
					'from_parent' => "'$env{'from_parent'}'",
					'regen' => "'N'",
					'status' => "'Y'",
				},
				'-journalize' => 1,
			);
			$t->close();
			return $db0_line{'ID'};
		}
		else
		{
			main::_log("checksum differs");
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
					'length' => "'".int($video{'length'})."'",
					'file_size' => "'$file_size'",
					'file_checksum' => "'$checksum_method:$checksum'",
					'file_ext' => "'$file_ext'",
					'from_parent' => "'$env{'from_parent'}'",
					'regen' => "'N'",
					'status' => "'Y'",
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
				File::Copy::copy($env{'file'},$path);
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
				'length' => "'".int($video{'length'})."'",
				'file_size' => "'$file_size'",
				'file_checksum' => "'$checksum_method:$checksum'",
				'file_ext' => "'$file_ext'",
				'from_parent' => "'$env{'from_parent'}'",
				'status' => "'Y'",
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
			my $out=File::Copy::copy($env{'file'},$path);
			if (!$out)
			{
				main::_log("can't copy file $!",1);
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
		$env{'timestamps'}=[300,120,60,30,20,10,5,1];
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
		
		my $cmd2="/usr/bin/ffmpeg -y -i $env{'file'} -ss $timestamp -t 0.001 -f mjpeg -an $env{'file2'}";
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
	
	File::Copy::copy($env{'file2'},'/www/TOM/test.jpg');
	
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
					name LIKE '$hash'
				LIMIT 1
			)
			UNION ALL
			(
				SELECT ID
				FROM
					`$App::510::db_name`.a510_video_part_file_j
				WHERE
					name LIKE '$hash'
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


=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
