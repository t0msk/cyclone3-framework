#!/bin/perl
package App::501::functions;

=head1 NAME

App::501::functions

=head1 DESCRIPTION



=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 DEPENDS

=over

=item *

L<App::501::_init|app/"501/_init.pm">

=item *

L<App::542::mimetypes|app/"542/mimetypes.pm">

=item *

L<TOM::Security::form|lib/"TOM/Security/form.pm">

=item *

Image::Magick

=item *

File::Path

=item *

Digest::MD5

=item *

Digest::SHA1

=item *

File::Type

=back

=cut

use App::501::_init;
use App::542::mimetypes;
use TOM::Security::form;
use Image::Magick;
use File::Path;
use Digest::MD5  qw(md5 md5_hex md5_base64);
use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);
use File::Type;


=head1 FUNCTIONS

=head2 image_regenerate()

 image_regenerate
 (
   'image.ID_entity' => '' # related image.ID_entity
   'image.ID' => '' # related image.ID
 )

=cut


sub image_regenerate
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::image_regenerate()");
	
	# get info about image
	my %image;
	$image{'ID'}=$env{'image.ID'};
	$image{'ID_entity'}=$env{'image.ID_entity'};
	if ($env{'image.ID_entity'} && !$env{'image.ID'})
	{
		%image=%{(App::020::SQL::functions::get_ID_entity(
			'ID_entity' => $env{'image.ID_entity'},
			'db_h' => 'main',
			'db_name' => $App::501::db_name,
			'tb_name' => 'a501_image',
			'columns' =>
			{
				'status' => 1,
			}
		))[0]};
	}
	elsif ($env{'image.ID'})
	{
		%image=App::020::SQL::functions::get_ID(
			'ID' => $env{'image.ID'},
			'db_h' => 'main',
			'db_name' => $App::501::db_name,
			'tb_name' => 'a501_image',
			'columns' =>
			{
				'status' => 1,
			}
		);
	}
	
	main::_log("image ID='$image{'ID'}' ID_entity='$image{'ID_entity'}' status='$image{'status'}'");
	
	if ($image{'status'} ne "Y" && $image{'status'} ne "N")
	{
		main::_log("image is not available",1);
		$t->close();
		return undef;
	}
	
	my $sql=qq{
		SELECT
			*
		FROM
			`$App::501::db_name`.a501_image_format
		WHERE
			status IN ('Y','L') AND
			required LIKE 'Y' AND
			name NOT LIKE 'original'
		ORDER BY
			ID_charindex
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	while (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		App::501::functions::image_file_generate(
			'image.ID' => $image{'ID'},
			'image_format.ID' => $db0_line{'ID'}
		);
	}
	
	$t->close();
	return 1;
}

=head2 image_file_generate()

 image_file_generate
 (
   'image.ID' => '' # related image.ID
   'image.ID_entity' => '' # related image.ID_entity
   'image_format.ID' => '' # related image_format.ID
   #'image_format.name' => '' # realted image_format.name
 )

=cut



sub image_file_generate
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::image_file_generate($env{'image.ID_entity'},".
		($env{'image_format.ID'}||$env{'image_format.name'}).")");
	
	# get info about image
	my %image;
	$image{'ID'}=$env{'image.ID'};
	$image{'ID_entity'}=$env{'image.ID_entity'};
	if ($env{'image.ID_entity'} && !$env{'image.ID'})
	{
		%image=%{(App::020::SQL::functions::get_ID_entity(
			'ID_entity' => $env{'image.ID_entity'},
			'db_h' => 'main',
			'db_name' => $App::501::db_name,
			'tb_name' => 'a501_image',
			'columns' =>
			{
				'status' => 1,
			}
		))[0]};
	}
	elsif ($env{'image.ID'})
	{
		%image=App::020::SQL::functions::get_ID(
			'ID' => $env{'image.ID'},
			'db_h' => 'main',
			'db_name' => $App::501::db_name,
			'tb_name' => 'a501_image',
			'columns' =>
			{
				'status' => 1,
			}
		);
	}
	
	main::_log("image ID='$image{'ID'}' ID_entity='$image{'ID_entity'}' status='$image{'status'}'");
	
	if ($image{'status'} ne "Y" && $image{'status'} ne "N")
	{
		main::_log("image is not available",1);
		$t->close();
		return undef;
	}
	
	my %format;
	
	if ($env{'image_format.ID'})
	{
		%format=App::020::SQL::functions::get_ID(
			'ID' => $env{'image_format.ID'},
			'db_h' => 'main',
			'db_name' => $App::501::db_name,
			'tb_name' => 'a501_image_format',
			'columns' =>
			{
				'name' => 1,
				'process' => 1,
			}
		);
	}
	
	main::_log("image_format ID='$format{'ID'}' name='$format{'name'}' status='$format{'status'}'");
	
	if ($format{'status'} ne "Y" &&  $format{'status'} ne "L")
	{
		main::_log("image_format is disabled or not available",1);
		$t->close();
		return undef;
	}
	
	
	# find parent
	my %format_parent=App::020::SQL::functions::tree::get_parent_ID(
		'ID' => $format{'ID'},
		'db_h' => 'main',
		'db_name' => $App::501::db_name,
		'tb_name' => 'a501_image_format'
	);
	
	if ($format_parent{'status'} ne "Y" &&  $format_parent{'status'} ne "L")
	{
		main::_log("parent image_format is disabled or not available",1);
		$t->close();
		return undef;
	}
	
	# find image_file defined by parent image_format (to convert from)
	
	# image.ID_entity is related to image_file.ID_entity
	
	my $sql=qq{
		SELECT
			*
		FROM
			`$App::501::db_name`.`a501_image_file`
		WHERE
			ID_entity=$image{'ID_entity'} AND
			ID_format=$format_parent{'ID'}
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	my %file_parent=$sth0{'sth'}->fetchhash();
	
	if ($file_parent{'status'} ne "Y")
	{
		main::_log("parent image_file is disabled or not available",1);
		image_file_add_error
		(
			'image.ID_entity' => $image{'ID_entity'},
			'image_format.ID' => $format{'ID'}
		);
		$t->close();
		return undef;
	}
		
	my $image1_path=_image_file_genpath
	(
		$format_parent{'ID'},
		$file_parent{'ID'},
		$file_parent{'name'},
		$file_parent{'file_ext'}
	);
	
	main::_log("path to parent image_file='$image1_path'");
	my $image2=new TOM::Temp::file('dir'=>$main::ENV{'TMP'});
	
	my ($out,$ext)=image_file_process(
		'image1' => $tom::P.'/!media/a501/image/file/'.$image1_path,
		'image2' => $image2->{'filename'},
		'process' => $format{'process'},
		'unlink' => 1,
	);
	
	main::_log("out=$out, ext=$ext");
	
	if (!$out)
	{
		main::_log("parent image_file can't be processed into format '$format{'ID'}', inserting 'E' status",1);
		image_file_add_error
		(
			'image.ID_entity' => $image{'ID_entity'},
			'image_format.ID' => $format{'ID'}
		);
		$t->close();
		return undef;
	}
	
	image_file_add
	(
		'file' => $image2->{'filename'},
		'image.ID_entity' => $image{'ID_entity'},
		'image_format.ID' => $format{'ID'}
	);
	
	$t->close();
	return 1;
}



sub _image_file_genpath
{
	my $format=shift;
	my $ID=shift;
	my $name=shift;
	my $ext=shift;
	$ID=~s|^(....).*$|\1|;
	
	my $path=$tom::P.'/!media/a501/image/file/'.$format.'/'.$ID;
	if (!-e $path)
	{
		File::Path::mkpath($path);
		chmod (0777,$path);
	}
	return "$format/$ID/$name.$ext";
};



sub image_file_process
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::image_file_process()");
	main::_log("image1='$env{'image1'}'");
	main::_log("image2='$env{'image2'}'");
	
	my $procs; # how many changes have been made in image2 file
	
	if (!$env{'ext'})
	{
		$env{'ext'}=$App::501::image_format_ext_default;
		$procs++;
	}
	
	# read the first image
	use Image::Magick;
	main::_log("reading file '$env{'image1'}'");
	
	if (!-e $env{'image1'})
	{
		main::_log("image file not exists",1);
		$t->close();
		return undef;
	}
	
	my $image1 = new Image::Magick;
	my $out=$image1->Read($env{'image1'});
	
	if ($out)
	{
		main::_log("$out",1);
		unlink $env{'image1'} if $env{'unlink'};
		$t->close();
		return undef;
	}
	
	# GIF magick
	$image1=$image1->[0] if $image1->Get('magick') eq 'GIF';
	
	foreach my $function(split('\n',$env{'process'}))
	{
		$function=~s|\s+$||g;
		$function=~s|^\s+||g;
		
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
			$env{$params[0]}=$params[1];
			$procs++;
			next;
		}
		
		if ($function_name eq "resize")
		{
			main::_log("exec $function_name($params[0],$params[1])");
			$image1->Resize('width'=>$params[0],'height'=>$params[1]);
			main::_log("width=".($image1->Get('width'))." height=".($image1->Get('height')));
			$procs++;
			next;
		}
		
		if ($function_name eq "downscale")
		{
			main::_log("check exec $function_name($params[0],$params[1]) from (".$image1->Get('width').",".$image1->Get('height').")");
			if ($image1->Get('width') > $params[0] || $image1->Get('height') > $params[1])
			{
				main::_log("exec $function_name($params[0],$params[1])");
				$image1->Resize('geometry'=>$params[0].'x'.$params[1]);
				main::_log("width=".($image1->Get('width'))." height=".($image1->Get('height')));
				$procs++;
			}
			next;
		}
		
		if ($function_name eq "geometry" || $function_name eq "scale")
		{
			main::_log("exec $function_name($params[0],$params[1])");
			$image1->Resize('geometry'=>$params[0].'x'.$params[1]);
			main::_log("width=".($image1->Get('width'))." height=".($image1->Get('height')));
			$procs++;
			next;
		}
		
		if ($function_name eq "face_debug" || $function_name eq "dimensions")
		{
			main::_log("exec facedetection() over $function_name()");
			
			my $tmpfile=new TOM::Temp::file('ext'=>'jpg','dir'=>$main::ENV{'TMP'});
			$image1->Write('jpg:'.$tmpfile->{'filename'});
			my $out;
			if (-x '/www/TOM/_addons/App/501/FaceDetect/fdetect')
			{
				$out=`cd /www/TOM/_addons/App/501/FaceDetect/;./fdetect $tmpfile->{'filename'}`;
			}
			
			$env{'red_area'}={};
			$env{'green_area'}={};
			
			foreach my $face (split('\n',$out))
			{
				$face=~s|^(\d+):||;
				$face=~/(\d+),(\d+)-(\d+),(\d+)/;
				my $x1=$1;my $y1=$2;my $x2=$3;my $y2=$4;
				main::_log("face on $x1 $y1 $x2 $y2");
				
				if ($function_name eq "face_debug")
				{
					$image1->Draw(stroke=>'red', primitive=>'rectangle', points=>"$x1,$y1 $x2,$y2");
				}
				
				$env{'red_area'}{'x1'} = $x1 if ($env{'red_area'}{'x1'} > $x1 || !$env{'red_area'}{'x1'});
				$env{'red_area'}{'y1'} = $y1 if ($env{'red_area'}{'y1'} > $y1 || !$env{'red_area'}{'y1'});
				$env{'red_area'}{'x2'} = $x2 if ($env{'red_area'}{'x2'} < $x2);
				$env{'red_area'}{'y2'} = $y2 if ($env{'red_area'}{'y2'} < $y2);
				
				# safe face area
				my $width=$x2-$x1;
				my $height=$y2-$y1;
				
				$y1=int($y1-($height/6));
				$y2=int($y2+($height/3));
				
				$x1=int($x1-($width/8));
				$x2=int($x2+($width/8));
				
				$env{'green_area'}{'x1'} = $x1 if ($env{'green_area'}{'x1'} > $x1 || !$env{'green_area'}{'x1'});
				$env{'green_area'}{'y1'} = $y1 if ($env{'green_area'}{'y1'} > $y1 || !$env{'green_area'}{'y1'});
				$env{'green_area'}{'x2'} = $x2 if ($env{'green_area'}{'x2'} < $x2);
				$env{'green_area'}{'y2'} = $y2 if ($env{'green_area'}{'y2'} < $y2);
				
				if ($function_name eq "face_debug")
				{
					$image1->Draw(stroke=>'green', primitive=>'rectangle', points=>"$x1,$y1 $x2,$y2");
				}
				
				$env{'red_area'}{'x1'} = 0 if ($env{'red_area'}{'x1'} < 0);
				$env{'red_area'}{'y1'} = 0 if ($env{'red_area'}{'y1'} < 0);
				$env{'red_area'}{'x2'} = $image1->Get('width') if ($env{'red_area'}{'x2'} > $image1->Get('width'));
				$env{'red_area'}{'y2'} = $image1->Get('height') if ($env{'red_area'}{'y2'} > $image1->Get('height'));
				main::_log("red area $env{'red_area'}{'x1'},$env{'red_area'}{'y1'} $env{'red_area'}{'x2'},$env{'red_area'}{'y2'}");
				
				$env{'green_area'}{'x1'} = 0 if ($env{'green_area'}{'x1'} < 0);
				$env{'green_area'}{'y1'} = 0 if ($env{'green_area'}{'y1'} < 0);
				$env{'green_area'}{'x2'} = $image1->Get('width') if ($env{'green_area'}{'x2'} > $image1->Get('width'));
				$env{'green_area'}{'y2'} = $image1->Get('height') if ($env{'green_area'}{'y2'} > $image1->Get('height'));
				main::_log("green area $env{'green_area'}{'x1'},$env{'green_area'}{'y1'} $env{'green_area'}{'x2'},$env{'green_area'}{'y2'}");
				
			}
			
			undef $tmpfile;
			$procs++;
			#next;
		}
		
		if ($function_name eq "dimensions")
		{
			main::_log("exec $function_name($params[0],$params[1])");
			
			my $width=$image1->Get('width');
			my $height=$image1->Get('height');
			
			my $scale_new=int(($params[0]/$params[1])*100)/100;
			my $scale_old=int(($width/$height)*100)/100;
			
			main::_log("w=$width h=$height $scale_old -> $scale_new");
			
			my $scale='1:1';
			my $scale_x=$params[0];
			my $scale_y=$params[1];
			
			my $nwidth;
			my $nheight;
			
			my $scl;
			
			if ($scale_old>$scale_new)
			#if ($scale_y>$scale_x)
			{
				$scl=$height/$scale_y;
				$nwidth=$scale_x*$scl;
				$nheight=$scale_y*$scl;
			}
			else
			{
				#main::_log("scale_x=$scale_x");
				$scl=$width/$scale_x;
				$nwidth=$scale_x*$scl;
				$nheight=$scale_y*$scl;
			}
			
			main::_log("w=$nwidth h=$nheight");
			
			my $x;
			my $y;
			
			$x=($width-$nwidth)/2;
			$y=($height-$nheight)/2;
			
			if ($height > $nheight)
			{
				main::_log("vertical moving");
				if ($env{'green_area'}{'x1'})
				{
					$y=$env{'green_area'}{'y1'}+(($env{'green_area'}{'y2'}-$env{'green_area'}{'y1'})/2)-($nheight/2);
				}
				else
				{
					#$y-=(($height-$nheight)/2)*0.25;
				}
			}
			$y=0 if $y<0;
			
			if ($width > $nwidth)
			{
				main::_log("horizontal moving");
				if ($env{'green_area'}{'x1'})
				{
					$x=$env{'green_area'}{'x1'}+(($env{'green_area'}{'x2'}-$env{'green_area'}{'x1'})/2)-($nwidth/2);
				}
				else
				{
					#$x-=(($width-$nwidth)/2)*0.25;
				}
			}
			$x=0 if $x<0;
			
			$image1->Crop('x'=>$x,'y'=>$y,'width'=>$nwidth,'height'=>$nheight);
			#$image1->Draw(stroke=>'yellow', primitive=>'rectangle', points=>"$x,$y ".($x+$nwidth).",".($y+$nheight));
			main::_log("new width=".($image1->Get('width'))." height=".($image1->Get('height')));
			$procs++;
			next;
		}
		
		if ($function_name eq "thumbnail")
		{
			main::_log("exec $function_name($params[0],$params[1])");
			my $out=$image1->Thumbnail('geometry'=>$params[0].'x'.$params[1]);
			main::_log("new width=".($image1->Get('width'))." height=".($image1->Get('height')));
			$procs++;
			next;
		}
		
		if ($function_name eq "clean")
		{
			main::_log("exec $function_name()");
			my $out=$image1->Thumbnail('width'=>$image1->Get('width'),'x'=>$image1->Get('height'));
			$procs++;
			next;
		}
		
		if ($function_name eq "face_debug")
		{
			next;
		}
		
		main::_log("unknown '$function'",1);
		$t->close();
		return undef;
		
	}
	
	my @out;
	
	if ($procs)
	{
		
		if ($env{'quality'})
		{
			main::_log("set quality to '$env{'quality'}'");
			$image1->Set('quality'=>$env{'quality'});
		}
		
		main::_log("writing file '$env{'image2'}' ext='$env{'ext'}'");
		$out[1]=$env{'ext'};
		$out[0]=$image1->Write($env{'ext'}.':'.$env{'image2'});
		if ($out[0])
		{
			main::_log("error in writing",1);
			$out[0]=undef;
		}
		else
		{
			$out[0]=1;
		}
	}
	else
	{
		main::_log("copying same file '$env{'image2'}' ext='$env{'ext'}'");
		$out[1]=$env{'ext'};
		$out[0]=1;
		File::Copy::copy($env{'image1'},$env{'image2'});
	}
	
	$t->close();
	return @out;
}






=head2 image_add()

Adds new image to gallery, or updates old image

Add new image (uploading new original sized image)

 image_add
 (
   'file' => '/path/to/file',
   'image.ID' => '',
   'image.ID_entity' => '',
   'image_format.ID' => '',
#   'image_attrs.ID_category' => '',
#   'image_attrs.name' => '',
#   'image_attrs.description' => '',
 );

=cut

sub image_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::image_add()");
	
#	foreach (sort keys %env)
#	{
#		main::_log("input $_='$env{$_}'");
#	}
	
	my $content_updated=0;
	
	$env{'image_format.ID'}=$App::501::image_format_original_ID unless $env{'image_format.ID'};
	
	if ($env{'file'})
	{
		if (! -e $env{'file'})
		{
			main::_log("file is missing or can't be read",1);
			$t->close();
			return undef;
		}
		my $file_size=(stat($env{'file'}))[7];
		main::_log("file size='$file_size'");
		if (!$file_size)
		{
			main::_log("file is empty",1);
			$t->close();
			return undef;
		}
	}
	
	my %category;
	if ($env{'image_cat.ID'} && $env{'image_cat.ID'} ne 'NULL')
	{
		# detect language
		%category=App::020::SQL::functions::get_ID(
			'ID' => $env{'image_cat.ID'},
			'db_h' => "main",
			'db_name' => $App::501::db_name,
			'tb_name' => "a501_image_cat",
			'columns' => {'*'=>1}
		);
		$env{'image_attrs.lng'}=$category{'lng'};
		$env{'image_attrs.ID_category'}=$category{'ID_entity'};
		main::_log("setting lng='$env{'image_attrs.lng'}' from image_cat.ID='$env{'image_cat.ID'}'");
		main::_log("setting image_attrs.ID_category='$env{'image_attrs.ID_category'}' from image_cat.ID='$env{'image_cat.ID'}'");
	}
	$env{'image_attrs.ID_category'}='NULL' if $env{'image_cat.ID'} eq 'NULL';
	
	$env{'image_attrs.lng'}=$tom::lng unless $env{'image_attrs.lng'};
	main::_log("lng='$env{'image_attrs.lng'}'");
	
	
	# IMAGE
	
	my %image;
	my %image_attrs;
	if ($env{'image.ID'})
	{
		%image=App::020::SQL::functions::get_ID(
			'ID' => $env{'image.ID'},
			'db_h' => "main",
			'db_name' => $App::501::db_name,
			'tb_name' => "a501_image",
			'columns' => {'*'=>1}
		);
		$env{'image.ID_entity'}=$image{'ID_entity'} unless $env{'image.ID_entity'};
	}
	
#	if (!$env{'image.ID'})
#	{
#		$env{'image.ID'}=$image{'ID'} if $image{'ID'};
#	}
	
	
	# check if this symlink with same ID_category not already exists
	# and image.ID is unknown
	if ($env{'image_attrs.ID_category'} && !$env{'image.ID'} && $env{'image.ID_entity'} && !$env{'forcesymlink'})
	{
		main::_log("search for image.ID by image_attrs.ID_category='$env{'image_attrs.ID_category'}' and image.ID_entity='$env{'image.ID_entity'}'");
		my $sql=qq{
			SELECT
				image.ID AS ID_image,
				image_attrs.ID AS ID_attrs
			FROM
				`$App::501::db_name`.a501_image AS image
			LEFT JOIN `$App::501::db_name`.a501_image_attrs AS image_attrs
				ON ( image.ID = image_attrs.ID_entity )
			WHERE
				image.ID_entity=$env{'image.ID_entity'} AND
				( image_attrs.ID_category = $env{'image_attrs.ID_category'} OR ID_category IS NULL ) AND
				image_attrs.status IN ('Y','N','L')
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %db0_line=$sth0{'sth'}->fetchhash();
		if ($db0_line{'ID_image'})
		{
			$env{'image.ID'}=$db0_line{'ID_image'};
			$env{'image_attrs.ID'}=$db0_line{'ID_attrs'};
			main::_log("setup image.ID='$db0_line{'ID_image'}' image_attrs.ID='$env{'image_attrs.ID'}'");
		}
	}
	
	
	if (!$env{'image.ID'})
	{
		# generating new image!
		main::_log("adding new image");
		
		my %columns;
		$columns{'ID_entity'}=$env{'image.ID_entity'} if $env{'image.ID_entity'};
		
		$env{'image.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::501::db_name,
			'tb_name' => "a501_image",
			'columns' =>
			{
				%columns,
			},
			'-journalize' => 1,
		);
		$content_updated=1;
		
		main::_log("generated image.ID='$env{'image.ID'}'");
	}
	
	
	if (!$env{'image.ID_entity'})
	{
		if ($image{'ID_entity'})
		{
			$env{'image.ID_entity'}=$image{'ID_entity'};
		}
		elsif ($env{'image.ID'})
		{
			%image=App::020::SQL::functions::get_ID(
				'ID' => $env{'image.ID'},
				'db_h' => "main",
				'db_name' => $App::501::db_name,
				'tb_name' => "a501_image",
				'columns' => {'*'=>1}
			);
			$env{'image.ID_entity'}=$image{'ID_entity'};
		}
		else
		{
			die "ufff\n";
		}
	}
	
	if (!$env{'image.ID_entity'})
	{
		die "ufff, missing image.ID_entity\n";
	}
	
	if (!$env{'image_attrs.ID'})
	{
		main::_log("finding image_attrs.ID by image.ID=$env{'image.ID'} and image_attrs.lng='$env{'image_attrs.lng'}'");
		my $sql=qq{
			SELECT
				ID
			FROM
				`$App::501::db_name`.`a501_image_attrs`
			WHERE
				ID_entity='$env{'image.ID'}' AND
				lng='$env{'image_attrs.lng'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %db0_line=$sth0{'sth'}->fetchhash();
		$env{'image_attrs.ID'}=$db0_line{'ID'};
		main::_log("image_attrs.ID='$env{'image_attrs.ID'}'");
	}
	
	if (!$env{'image_attrs.ID'} && !$env{'image_attrs.ID_category'} && $env{'image.ID'})
	{ # find target ID_category if not defined
		main::_log("finding image_attrs.ID_category by image.ID=$env{'image.ID'}");
		my $sql=qq{
			SELECT
				ID_category
			FROM
				`$App::501::db_name`.`a501_image_attrs`
			WHERE
				ID_entity='$env{'image.ID'}' AND
				status IN ('Y','N','L')
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %db0_line=$sth0{'sth'}->fetchhash();
		$env{'image_attrs.ID_category'}=$db0_line{'ID_category'};# if $sth0{'rows'};
		main::_log("image_attrs.ID_category='$env{'image_attrs.ID_category'}'");
	}
	
	if (!$env{'image_attrs.ID'})
	{
		# create one language representation of image
		my %columns;
		$columns{'ID_category'}=$env{'image_attrs.ID_category'} if $env{'image_attrs.ID_category'};
		#$columns{'status'}="'".$env{'image_attrs.status'}."'" if $env{'image_attrs.status'};
		$env{'image_attrs.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::501::db_name,
			'tb_name' => "a501_image_attrs",
			'columns' =>
			{
				%columns,
				'ID_entity' => $env{'image.ID'},
#				'order_id' => $order_id,
				'lng' => "'$env{'image_attrs.lng'}'",
			},
			'-journalize' => 1,
		);
		$content_updated=1;
		main::_log("created new image_attrs.ID='$env{'image_attrs.ID'}'");
	}
	
	
	if ($env{'file'})
	{
		main::_log("file='$env{'file'}', image.ID_entity='$env{'image.ID_entity'}', image_format.ID='$env{'image_format.ID'}' is specified, so updating image_file");
		$env{'image_file.ID'}=image_file_add
		(
			'file' => $env{'file'},
			'image.ID_entity' => $env{'image.ID_entity'},
			'image_format.ID' => $env{'image_format.ID'}
		);
	}
	
	
	if ($env{'image_attrs.ID'})
	{
		# detect language
		%image_attrs=App::020::SQL::functions::get_ID(
			'ID' => $env{'image_attrs.ID'},
			'db_h' => "main",
			'db_name' => $App::501::db_name,
			'tb_name' => "a501_image_attrs",
			'columns' => {'*'=>1}
		);
		main::_log("loaded %image_attrs image_attrs.ID='$image_attrs{'ID'}' image_attrs.ID_category='$image_attrs{'ID_category'}'");
	}
	
	main::_log("image_attrs.ID='$env{'image_attrs.ID'}' image_attrs.ID_category='$env{'image_attrs.ID_category'}' image_attrs{ID_category}='$image_attrs{'ID_category'}'");
	if ($env{'image_attrs.ID'} &&
	(
		# ID_category
		($env{'image_attrs.ID_category'} && ($env{'image_attrs.ID_category'} ne $image_attrs{'ID_category'}))
	))
	{
		my %columns;
		main::_log("image_attrs.ID='$image_attrs{'ID'}' image_attrs.status='$image_attrs{'status'}'");
		$columns{'ID_category'}=$env{'image_attrs.ID_category'};
		my $sql=qq{
			SELECT
				ID
			FROM
				`$App::501::db_name`.a501_image_attrs
			WHERE
				ID_entity=$image_attrs{'ID_entity'} AND
				status IN ('Y','N','L')
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		while (my %db0_line=$sth0{'sth'}->fetchhash())
		{
#			main::_log("update image_attrs.ID='$db0_line{'ID'}'");
			App::020::SQL::functions::update(
				'ID' => $db0_line{'ID'},
				'db_h' => "main",
				'db_name' => $App::501::db_name,
				'tb_name' => "a501_image_attrs",
				'columns' => {%columns},
				'-journalize' => 1
			);
			$content_updated=1;
		}
		
	}
	
	if ($env{'image_attrs.ID'})
	{
		my %columns;
		
		$columns{'name'}="'".TOM::Security::form::sql_escape($env{'image_attrs.name'})."'"
			if ($env{'image_attrs.name'} && ($env{'image_attrs.name'} ne $image_attrs{'name'}));
		$columns{'description'}="'".TOM::Security::form::sql_escape($env{'image_attrs.description'})."'"
			if (exists $env{'image_attrs.description'} && ($env{'image_attrs.description'} ne $image_attrs{'description'}));
		$columns{'keywords'}="'".TOM::Security::form::sql_escape($env{'image_attrs.keywords'})."'"
			if (exists $env{'image_attrs.keywords'} && ($env{'image_attrs.keywords'} ne $image_attrs{'keywords'}));
#		$columns{'ID_category'}=$env{'image_attrs.ID_category'}
#			if ($env{'image_attrs.ID_category'} && ($env{'image_attrs.ID_category'} ne $image_attrs{'ID_category'}));
		$columns{'status'}="'".TOM::Security::form::sql_escape($env{'image_attrs.status'})."'"
			if ($env{'image_attrs.status'} && ($env{'image_attrs.status'} ne $image_attrs{'status'}));
		
		if (keys %columns)
		{
			App::020::SQL::functions::update(
				'ID' => $env{'image_attrs.ID'},
				'db_h' => "main",
				'db_name' => $App::501::db_name,
				'tb_name' => "a501_image_attrs",
				'columns' => {%columns},
				'-journalize' => 1
			);
			$content_updated=1;
		}
	}
	
	
	# IMAGE_ENT
	
	my %image_ent;
	if (!$env{'image_ent.ID_entity'})
	{
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::501::db_name`.`a501_image_ent`
			WHERE
				ID_entity='$env{'image.ID_entity'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%image_ent=$sth0{'sth'}->fetchhash();
		$env{'image_ent.ID_entity'}=$image_ent{'ID_entity'};
		$env{'image_ent.ID'}=$image_ent{'ID'};
	}
	if (!$env{'image_ent.ID_entity'})
	{
		# create one entity representation of image
		my %columns;
		
		$env{'image_ent.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::501::db_name,
			'tb_name' => "a501_image_ent",
			'columns' =>
			{
				%columns,
				'ID_entity' => $env{'image.ID_entity'},
			},
			'-journalize' => 1,
		);
		$content_updated=1;
	}
	
	if (!$image_ent{'posix_owner'} && !$env{'image_ent.posix_owner'})
	{
		$env{'image_ent.posix_owner'}=$main::USRM{'ID_user'};
	}
	
	# update if necessary
	if ($env{'image_ent.ID'})
	{
		my %columns;
		$columns{'posix_author'}="'".$env{'image_ent.posix_author'}."'"
			if ($env{'image_ent.posix_author'} && ($env{'image_ent.posix_author'} ne $image_ent{'posix_author'}));
		$columns{'posix_owner'}="'".TOM::Security::form::sql_escape($env{'image_ent.posix_owner'})."'"
			if ($env{'image_ent.posix_owner'} && ($env{'image_ent.posix_owner'} ne $image_ent{'posix_owner'}));
		$columns{'datetime_produce'}="'".TOM::Security::form::sql_escape($env{'image_ent.datetime_produce'})."'"
			if (exists $env{'image_ent.datetime_produce'} && ($env{'image_ent.datetime_produce'} ne $image_ent{'datetime_produce'}));
		$columns{'datetime_produce'}='NULL' if $columns{'datetime_produce'} eq "''";
		
		if (keys %columns)
		{
			App::020::SQL::functions::update(
				'ID' => $env{'image_ent.ID'},
				'db_h' => "main",
				'db_name' => $App::501::db_name,
				'tb_name' => "a501_image_ent",
				'columns' => {%columns},
				'-journalize' => 1
			);
			$content_updated=1;
		}
	}
	
	if ($content_updated)
	{
		App::020::SQL::functions::_save_changetime({'db_h'=>'main','db_name'=>$App::501::db_name,'tb_name'=>'a501_image','ID_entity'=>$env{'image.ID_entity'}});
	}
	
	$t->close();
	return %env;
}



=head2 image_del()

Remove image from gallery

=cut

sub image_del
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::image_del($env{'image.ID_entity'})");
	
	my $tr=new TOM::Database::SQL::transaction('db_h'=>"main");
	
	foreach my $entity (App::020::SQL::functions::get_ID_entity
	(
		'ID_entity' => $env{'image.ID_entity'},
		'db_h' => 'main',
		'db_name' => $App::501::db_name,
		'tb_name' => 'a501_image',
	))
	{
		main::_log("image.ID='$entity->{'ID'}'");
		
		foreach my $entity1 (App::020::SQL::functions::get_ID_entity
		(
			'ID_entity' => $entity->{'ID'},
			'db_h' => 'main',
			'db_name' => $App::501::db_name,
			'tb_name' => 'a501_image_attrs',
		))
		{
			main::_log("image_attrs.ID='$entity1->{'ID'}'");
			App::020::SQL::functions::delete(
				'ID' => $entity1->{'ID'},
				'db_h' => 'main',
				'db_name' => $App::501::db_name,
				'tb_name' => 'a501_image_attrs',
				'-journalize' => 1
			);
		}
		
		App::020::SQL::functions::delete(
			'ID' => $entity->{'ID'},
			'db_h' => 'main',
			'db_name' => $App::501::db_name,
			'tb_name' => 'a501_image',
			'-journalize' => 1
		);
		
	}
	
	foreach my $entity1 (App::020::SQL::functions::get_ID_entity
	(
		'ID_entity' => $env{'image.ID_entity'},
		'db_h' => 'main',
		'db_name' => $App::501::db_name,
		'tb_name' => 'a501_image_file',
	))
	{
		main::_log("image_file.ID='$entity1->{'ID'}'");
		App::020::SQL::functions::delete(
			'ID' => $entity1->{'ID'},
			'db_h' => 'main',
			'db_name' => $App::501::db_name,
			'tb_name' => 'a501_image_file',
			'-journalize' => 1
		);
	}
	
	$tr->close();
	
	$t->close();
	return %env;
}



=head2 image_file_add()

Adds new file to image, or updates old

 $image_file{'ID'}=image_file_add
 (
   'file' => '/path/to/file',
   'image.ID_entity' => '',
   'image_format.ID' => ''
 )

=cut

sub image_file_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::image_file_add()");
	
	# check if image_file already not exists
	if (!$env{'file'})
	{
		main::_log("missing param 'file' to proceed",1);
		$t->close();
		return undef;
	}
	
	if (! -e $env{'file'})
	{
		main::_log("file '$env{'file'}' is missing or can't be read",1);
		$t->close();
		return undef;
	}
	
	if (!$env{'image.ID_entity'})
	{
		main::_log("missing param image.ID_entity to proceed",1);
		$t->close();
		return undef;
	}
	
	if (!$env{'image_format.ID'})
	{
		main::_log("missing param image_format.ID to proceed",1);
		$t->close();
		return undef;
	}
	
	# file must be analyzed
	
	# size
	my $file_size=(stat $env{'file'})[7];
	main::_log("file size='$file_size'");
	if (!$file_size)
	{
		main::_log("image_file '$env{'file'}' is empty",1);
		$t->close();
		return undef;
	}
	
	# file mimetype
	my $ft = File::Type->new();
	my $type_from_file = $ft->checktype_filename($env{'file'});
	my $file_ext = $App::542::mimetypes::mime{$type_from_file};
	main::_log("file mimetype='$type_from_file'");
	
	# optional file ext
	$file_ext='jpg' unless $file_ext;
	main::_log("file ext='$file_ext'");
	
	# checksum
	open(CHKSUM,'<'.$env{'file'});
	my $ctx = Digest::SHA1->new;
	$ctx->addfile(*CHKSUM);
	my $checksum = $ctx->hexdigest;
	my $checksum_method = 'SHA1';
	main::_log("file checksum $checksum_method:$checksum");
	
	# width, height
	my $image = new Image::Magick;
	$image->Read($env{'file'});
	my $image_width=$image->Get('width');
	my $image_height=$image->Get('height');
	main::_log("image width=$image_width height=$image_height");
		
	# generate new unique hash
	my $name=image_file_newhash();
	
	# Check if image_file for this format exists
	my $sql=qq{
		SELECT
			*
		FROM
			`$App::501::db_name`.`a501_image_file`
		WHERE
			ID_entity=$env{'image.ID_entity'} AND
			ID_format=$env{'image_format.ID'}
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);	
	if (my %db0_line=$sth0{'sth'}->fetchhash)
	{
		# file updating
		main::_log("check for update image_file");
		if ($db0_line{'file_checksum'} eq "$checksum_method:$checksum")
		{
			main::_log("same checksum, just enabling file when disabled");
			App::020::SQL::functions::update(
				'ID' => $db0_line{'ID'},
				'db_h' => 'main',
				'db_name' => $App::501::db_name,
				'tb_name' => 'a501_image_file',
				'columns' =>
				{
					'image_width' => $image_width,
					'image_height' => $image_height,
					'file_size' => $file_size,
#					'file_ext' => "'$file_ext'",
					'status' => "'Y'",
				},
				#'-journalize' => 1, -- must be disabled
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
				'db_name' => $App::501::db_name,
				'tb_name' => 'a501_image_file',
				'columns' =>
				{
					'name' => "'$name'",
					'image_width' => $image_width,
					'image_height' => $image_height,
					'file_size' => $file_size,
					'file_checksum' => "'$checksum_method:$checksum'",
					'file_ext' => "'$file_ext'",
					'status' => "'Y'",
				},
				'-journalize' => 1,
			);
			my $path=$tom::P.'/!media/a501/image/file/'._image_file_genpath
			(
				$env{'image_format.ID'},
				$db0_line{'ID'},
				$name,
				$file_ext
			);
			main::_log("copy to $path");
			File::Copy::copy($env{'file'},$path);
			$t->close();
			return $db0_line{'ID'};
		}
	}
	else
	{
		# file creating
		main::_log("creating image_file");
		
		my $ID=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::501::db_name,
			'tb_name' => "a501_image_file",
			'columns' =>
			{
				'ID_entity' => $env{'image.ID_entity'},
				'ID_format' => $env{'image_format.ID'},
				'name' => "'$name'",
				'image_width' => $image_width,
				'image_height' => $image_height,
				'file_size' => $file_size,
				'file_checksum' => "'$checksum_method:$checksum'",
				'file_ext' => "'$file_ext'",
				'status' => "'Y'"
			},
			'-journalize' => 1
		);
		$ID=sprintf("%08d",$ID);
		main::_log("ID='$ID'");
		
		my $path=$tom::P.'/!media/a501/image/file/'._image_file_genpath
		(
			$env{'image_format.ID'},
			$ID,
			$name,
			$file_ext
		);
		main::_log("copy to $path");
		File::Copy::copy($env{'file'},$path);
		$t->close();
		return $ID;
	}
	
	$t->close();
	return 1;
}


sub image_file_add_error
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::image_file_add_error()");
	
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::501::db_name`.`a501_image_file`
			WHERE
				ID_entity=$env{'image.ID_entity'} AND
				ID_format=$env{'image_format.ID'}
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);	
		if (my %db0_line=$sth0{'sth'}->fetchhash)
		{
			# file updating
			App::020::SQL::functions::update(
				'ID' => $db0_line{'ID'},
				'db_h' => 'main',
				'db_name' => $App::501::db_name,
				'tb_name' => 'a501_image_file',
				'columns' =>
				{
					'status' => "'Y'",
				},
			);
		}
		else
		{
			my $ID=App::020::SQL::functions::new(
				'db_h' => "main",
				'db_name' => $App::501::db_name,
				'tb_name' => "a501_image_file",
				'columns' =>
				{
					'ID_entity' => $env{'image.ID_entity'},
					'ID_format' => $env{'image_format.ID'},
					'status' => "'E'"
				},
				'-journalize' => 1
			);
		}
	
	$t->close();
	return 1;
}




=head2 image_file_rewrite()

Rewrite file with new content, or just update datetime_create when content of new file is the same as old

 image_file_rewrite
 (
 	file => '/path/to/file'
 	columns => # columns to change
 	{
 		'status' => 'Y'
 	}
 )

=cut

sub image_file_rewrite
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::image_file_rewrite()");
	
	
	
	$t->close();
	return 1;
}



=head2 image_file_newhash()

Find new unique hash for file

=cut

sub image_file_newhash
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
					`$App::501::db_name`.a501_image_file
				WHERE
					name LIKE '$hash'
				LIMIT 1
			)
			UNION ALL
			(
				SELECT ID
				FROM
					`$App::501::db_name`.a501_image_file_j
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



=head2 get_image_file()

Return image_file columns. This is the fastest way (optimized SQL) to get informations about file in image. Informations are cached in memcached and cache is monitored by information of last change of a501_image.

	my %image_file=get_image_file(
		'image.ID_entity' => 1 or 'image.ID' = > 1
		'image_file.ID_format' => 1 # default
		'image_attrs.lng' => $tom::lng # default
		''
	)

=cut

sub get_image_file
{
	my %env=@_;
	
	if (!$env{'image.ID_entity'} && !$env{'image.ID'})
	{
		return undef;
	}
	
	$env{'image_file.ID_format'} = $App::501::image_format_fullsize_ID unless $env{'image_file.ID_format'};
	$env{'image_attrs.lng'}=$tom::lng unless $env{'image_attrs.lng'};
	
	my $sql=qq{
		SELECT
			image.ID_entity AS ID_entity_image,
			image.ID AS ID_image,
			image_file.ID_format AS ID_format,
			image_file.ID AS ID_file,
			image_ent.posix_owner,
			image_ent.posix_author,
			image_attrs.name,
			image_file.image_width,
			image_file.image_height,
			image_file.file_size,
			image_file.file_ext,
			CONCAT(image_file.ID_format,'/',SUBSTR(image_file.ID,1,4),'/',image_file.name,'.',image_file.file_ext) AS file_path
	};

	
	if ($env{'image.ID_entity'})
	{
		$sql.=qq{
		FROM
			`$App::501::db_name`.`a501_image` AS image
		LEFT JOIN `$App::501::db_name`.`a501_image_ent` AS image_ent ON
		(
			image_ent.ID_entity = image.ID_entity
		)
		LEFT JOIN `$App::501::db_name`.`a501_image_attrs` AS image_attrs ON
		(
			image_attrs.ID_entity = image.ID AND
			image_attrs.lng='$env{'image_attrs.lng'}'
		)
		LEFT JOIN `$App::501::db_name`.`a501_image_file` AS image_file ON
		(
			image_file.ID_entity = image.ID_entity AND
			image_file.ID_format=$env{'image_file.ID_format'} AND
			image_file.status IN ('Y','N','L','E')
		)
		WHERE
			image.ID_entity='$env{'image.ID_entity'}'
		LIMIT 1
		};
	}
	else
	{
		# get ID_entity for cache
		my %sth0=TOM::Database::SQL::execute(qq{SELECT ID_entity FROM `$App::501::db_name`.`a501_image` WHERE ID='$env{'image.ID'}' LIMIT 1},'quiet'=>1,'-slave'=>1,'-cache'=>3600);
		my %db0_line=$sth0{'sth'}->fetchhash();
		$env{'image.ID_entity'}=$db0_line{'ID_entity'};
		main::_log("ID_entity=$env{'image.ID_entity'}");
		
		$sql.=qq{
		FROM
			`$App::501::db_name`.`a501_image` AS image
		LEFT JOIN `$App::501::db_name`.`a501_image_ent` AS image_ent ON
		(
			image_ent.ID_entity = image.ID_entity
		)
		LEFT JOIN `$App::501::db_name`.`a501_image_attrs` AS image_attrs ON
		(
			image_attrs.ID_entity = image.ID AND
			image_attrs.lng='$env{'image_attrs.lng'}'
		)
		LEFT JOIN `$App::501::db_name`.`a501_image_file` AS image_file ON
		(
			image_file.ID_entity = image.ID_entity AND
			image_file.ID_format=$env{'image_file.ID_format'} AND
			image_file.status IN ('Y','N','L','E')
		)
		WHERE
			image.ID='$env{'image.ID'}'
		LIMIT 1
		};
	}
	
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1,'-slave'=>1,
		'-cache' => 86400, #24H max
		'-cache_min' => 600, # when changetime before this limit 10min
		'-cache_changetime' => App::020::SQL::functions::_get_changetime({
			'db_h'=>"main",'db_name'=>$App::501::db_name,'tb_name'=>"a501_image",
			'ID_entity' => $env{'image.ID_entity'}
		}),
		'-recache' => $env{'-recache'}
	);
	if ($sth0{'rows'})
	{
		my %image=$sth0{'sth'}->fetchhash();
		if (!$image{'ID_file'})
		{
			main::_log("this image does not have format '$env{'image_file.ID_format'}'");
			# trying to regenerate (can be very slow...)
			App::501::functions::image_file_generate(
				'image.ID_entity' => $image{'ID_entity_image'},
				'image_format.ID' => $env{'image_file.ID_format'}
			);
			if (!$env{'-recursive'}) # don't run again
			{
				return get_image_file(%env,'-recache'=>1,'-recursive'=>1);
			}
		}
		return %image;
	}
	
	return 1;
}




=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
