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
			'status' => 1,
		}
	);
	
	main::_log("video_part ID='$video_part{'ID'}' part_id='$video_part{'part_id'}' status='$video_part{'status'}'");
	
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
		main::_log("parent video_part_file is disabled or not available",1);
		$t->close();
		return undef;
	}
	
	my $video1_path=$file_parent{'file_alt_src'} || _video_part_file_genpath
	(
		$format_parent{'ID'},
		$file_parent{'ID'},
		$file_parent{'name'},
		$file_parent{'file_ext'}
	);
	
	main::_log("path to parent video_part_file='$video1_path'");
	my $video2=new TOM::Temp::file();
	
	my $out=video_part_file_process(
		'video1' => $tom::P.'/!media/a510/video/part/file/'.$video1_path,
		'video2' => $video2->{'filename'},
		'process' => $format{'process'}
	);
	
	main::_log("out=$out");
		
	if (!$out)
	{
		main::_log("parent video_part_file can't be processed",1);
		$t->close();
		return undef;
	}
	
	video_part_file_add
	(
		'file' => $video2->{'filename'},
		'video_part.ID' => $video_part{'ID'},
		'video_format.ID' => $format{'ID'}
	);
	
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
	File::Path::mkpath($tom::P.'/!media/a510/video/part/file/'.$format.'/'.$ID);
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
	
	my @env0;
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
			push @env0, '-'.$params[0].' '.$params[1];
			#$env0{$params[0]}=$params[1];
			$procs++;
			next;
		}
		
		main::_log("unknown '$function'",1);
		$t->close();
		return undef;
		
	}
		
	if ($procs)
	{
		main::_log("encoding file '$env{'video2'}' ext='$env{'ext'}'");
		my $cmd="/usr/bin/mencoder ".$env{'video1'}." -o ".$env{'video2'};
		foreach (@env0)
		{
			$cmd.=" $_";
		}
		main::_log("$cmd");
		my $out=system("$cmd 2>/www/TOM/_logs/stderr.log");
		main::_log("out=$out");
		$t->close();
		return 1 if $out == 0;
		return undef;
	}
	else
	{
		main::_log("copying same file '$env{'video2'}' ext='$env{'ext'}'");
		File::Copy::copy($env{'video1'},$env{'video2'});
		return 1;
	}
	
	$t->close();
	return undef;
}



=head2 video_add()

Adds new video to gallery, or updates old video

Add new video (uploading new original sized video)

 video_add
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
	
	$env{'video_format.ID'}=$App::510::video_format_original_ID unless $env{'video_format.ID'};
	
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
		$env{'video.ID'}=$video{'ID'} if $video{'ID'};
	}
	
	
	$env{'video_attrs.lng'}=$tom::lng unless $env{'video_attrs.lng'};
	main::_log("lng='$env{'video_attrs.lng'}'");
	
	
	if (!$env{'video.ID'})
	{
		# generating new video!
		main::_log("adding new video");
		
		my %columns;
		$columns{'ID_entity'}=$env{'video.ID_entity'} if $env{'video.ID_entity'};
		
		$env{'video.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_video",
			'columns' =>
			{
				%columns,
			}
#			'-journalize' => 1,
		);
		
		main::_log("generated video ID='$env{'video.ID'}'");
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
	
	
	if (!$env{'video_attrs.ID'})
	{
		my $sql=qq{
			SELECT
				ID
			FROM
				`$App::510::db_name`.`a510_video_attrs`
			WHERE
				ID_entity='$env{'video.ID'}' AND
				lng='$env{'video_attrs.lng'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %db0_line=$sth0{'sth'}->fetchhash();
		$env{'video_attrs.ID'}=$db0_line{'ID'};
	}
	
	
	if (!$env{'video_attrs.ID'})
	{
		# create one language representation of video
		my %columns;
		$columns{'ID_category'}=$env{'video_attrs.ID_category'} if $env{'video_attrs.ID_category'};
		
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
			}
#			'-journalize' => 1,
		);
	}
	
	$env{'video_part.ID'}=video_part_add
	(
		'file' => $env{'file'},
		'video.ID_entity' => $env{'video.ID_entity'},
		'video_format.ID' => $env{'video_format.ID'},
		'video_part.ID' => $env{'video_part.ID'},
		'video_part.part_id' => $env{'video_part.part_id'},
		'video_part_attrs.lng' => $env{'video_attrs.lng'},
		'video_part_attrs.name' => $env{'video_part_attrs.name'},
		'video_part_attrs.description' => $env{'video_part_attrs.description'},
	);
	
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
	
	$t->close();
	return ($env{'video.ID'},$env{'video.ID_entity'});
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
		main::_log("video_part.part_id, !video_part.ID = checking if part_id exists");
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
		$env{'video_part.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_video_part",
			'columns' =>
			{
				%columns,
			}
#			'-journalize' => 1,
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
			}
#			'-journalize' => 1,
		);
	}
	
	
	if ($env{'file'})
	{
		main::_log("file='$env{'file'}', video_part.ID='$env{'video_part.ID'}', video_format.ID='$env{'video_format.ID'}' is specified, so updating video_part_file");
		
		$env{'video_part_file.ID'}=video_part_file_add
		(
			'file' => $env{'file'},
			'video_part.ID' => $env{'video_part.ID'},
			'video_format.ID' => $env{'video_format.ID'},
		);
		
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
	
	$t->close();
	return 1;
}










=head2 video_part_file_add()

Adds new file to video, or updates old

 $video_part_file{'ID'}=video_part_file_add
 (
   'file' => '/path/to/file',
   'video_part.ID' => '',
   'video_format.ID' => ''
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
	
	
	if ($env{'video_format.ID'} eq $App::510::video_format_full_ID)
	{
		# generate thumbnail from full
		main::_log("generate thumbnail from 'full' video_format.name");
		
		my $tmpjpeg=new TOM::Temp::file('ext'=>'jpeg');
		my $out=_video_part_file_thumbnail(
			'file' => $env{'file'},
			'file2' => $tmpjpeg->{'filename'},
			'timestamps' => [
				'5',
#				'10',
#				'15'
			]
		);
		
		return undef unless $out;
		
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
				'image_attrs.ID_category' => $App::501::thumbnail_cat{$tom::LNG},
				'image_attrs.name' => 'video_part #'.$env{'video_part.ID'},
#				'image_attrs.description' => $desc
			);
			main::_log("added image $image{'image.ID_entity'}");
			return undef unless $image{'image.ID_entity'};
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
			main::_log("updating related image $relation->{'r_ID_entity'}");
			my %image=App::501::functions::image_add(
				'image.ID_entity' => $relation->{'r_ID_entity'},
				'file' => $tmpjpeg->{'filename'},
				'image_attrs.ID_category' => $App::501::thumbnail_cat{$tom::LNG},
				'image_attrs.name' => 'video_part #'.$env{'video_part.ID'},
			);
		}
		
	}
	
	
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
	my $file_ext=$App::541::mimetypes::filetype_ext{$out};
		$file_ext='avi' unless $file_ext;
	main::_log("type='$out' ext='$file_ext'");
	
	# file must be copied to have correct extension
	my $file3=new TOM::Temp::file('ext'=>$file_ext);
	File::Copy::copy($env{'file'},$file3->{'filename'});
	
	my $vd = Movie::Info->new || die "Couldn't find an mplayer to use\n";
	my %video = $vd->info($file3->{'filename'});
	foreach (keys %video)
	{
		main::_log("key $_='$video{$_}'");
	}
	
	# generate new unique hash
	my $name=video_part_file_newhash();
	
	
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
					'video_width' => $video{'width'},
					'video_height' => $video{'height'},
					'video_codec' => "'$video{'codec'}'",
					'video_fps' => $video{'fps'},
					'video_bitrate' => $video{'bitrate'},
					'audio_codec' => "'$video{'audio_codec'}'",
					'audio_bitrate' => $video{'audio_bitrate'},
					'length' => int($video{'length'}),
					'file_size' => $file_size,
					'status' => "'Y'",
				},
				#'-journalize' => 1,
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
					'video_width' => $video{'width'},
					'video_height' => $video{'height'},
					'video_codec' => "'$video{'codec'}'",
					'video_fps' => $video{'fps'},
					'video_bitrate' => $video{'bitrate'},
					'audio_codec' => "'$video{'audio_codec'}'",
					'audio_bitrate' => $video{'audio_bitrate'},
					'length' => int($video{'length'}),
					'file_size' => $file_size,
					'file_checksum' => "'$checksum_method:$checksum'",
					'file_ext' => "'$file_ext'",
					'status' => "'Y'",
				},
				'-journalize' => 1,
			);
			my $path=$tom::P.'/!media/a510/video/part/file/'._video_part_file_genpath
			(
				$env{'video_format.ID'},
				$db0_line{'ID'},
				$name,
				$file_ext
			);
			main::_log("copy to $path");
			File::Copy::copy($file3->{'filename'},$path);
			$t->close();
			return $db0_line{'ID'};
		}
	}
	else
	{
		# file creating
		main::_log("creating video_part_file");
		
		my $ID=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::510::db_name,
			'tb_name' => "a510_video_part_file",
			'columns' =>
			{
				'ID_entity' => $env{'video_part.ID'},
				'ID_format' => $env{'video_format.ID'},
				'name' => "'$name'",
				'video_width' => $video{'width'},
				'video_height' => $video{'height'},
				'video_codec' => "'$video{'codec'}'",
				'video_fps' => $video{'fps'},
				'video_bitrate' => $video{'bitrate'},
				'audio_codec' => "'$video{'audio_codec'}'",
				'audio_bitrate' => $video{'audio_bitrate'},
				'length' => int($video{'length'}),
				'file_size' => $file_size,
				'file_checksum' => "'$checksum_method:$checksum'",
				'file_ext' => "'$file_ext'",
				'status' => "'Y'"
			},
			'-journalize' => 1
		);
		$ID=sprintf("%08d",$ID);
		main::_log("ID='$ID'");
		
		my $path=$tom::P.'/!media/a510/video/part/file/'._video_part_file_genpath
		(
			$env{'video_format.ID'},
			$ID,
			$name,
			$file_ext
		);
		main::_log("copy to $path");
		File::Copy::copy($file3->{'filename'},$path);
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
		$env{'timestamps'}=[5,10,60];
	}
	
	
	foreach my $timestamp(@{$env{'timestamps'}})
	{
		main::_log("timestamp = $timestamp");
		
		#-msglevel all=-1
		#my $cmd="/usr/bin/mencoder $env{'file'} -o $tmp->{'filename'} -ss $timestamp -oac copy -ovc lavc -lavcopts vcodec=mpeg4 -frames 5";
		#main::_log("$cmd");
		#my $out=system("$cmd >/dev/null 2>/dev/null");
		#last if $out;
		
		my $cmd2="/usr/bin/ffmpeg -y -i $env{'file'} -ss $timestamp -t 0.001 -f mjpeg -an $env{'file2'}";
		main::_log("$cmd2");
		my $out2=system("$cmd2 >/dev/null 2>/dev/null");
		last if $out2;
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
	
	my $okay=0;
	my $hash;
	
	while (!$okay)
	{
		
		$hash=TOM::Utils::vars::genhash(8);
		
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
			$okay=1;
		}
	}
	
	return $hash;
}


=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
