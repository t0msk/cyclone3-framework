#!/bin/perl
package App::501::functions;

=head1 NAME

App::501::functions

=head1 DESCRIPTION



=cut

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
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
	if ($format{'ID'} == $App::501::image_format_original_ID && ($env{'process'} || $format{'process'}))
	{
		# generate from itself
		%format_parent=App::020::SQL::functions::get_ID(
			'ID' => $format{'ID'},
			'db_h' => 'main',
			'db_name' => $App::501::db_name,
			'tb_name' => 'a501_image_format',
			'columns' => {'*'=>1}
		);
	}
	
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
		if ($file_parent{'status'} ne "E" && $format_parent{'ID'} ne $App::501::image_format_original_ID )
		{
			main::_log("try to generate parent");
			my $out=image_file_generate(
				'image.ID_entity' => $image{'ID_entity'},
				'image_format.ID' => $format_parent{'ID'}
			);
			if ($out)
			{
				main::_log("parent generated, try to reload");
				my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
				%file_parent=$sth0{'sth'}->fetchhash();
				if ($file_parent{'status'} ne "Y")
				{
					main::_log("file info can't be reloaded",1);
					image_file_add_error
					(
						'image.ID_entity' => $image{'ID_entity'},
						'image_format.ID' => $format{'ID'}
					);
					$t->close();
					return undef;
				}
			}
			else
			{
				main::_log("parent can't be generated",1);
				image_file_add_error
				(
					'image.ID_entity' => $image{'ID_entity'},
					'image_format.ID' => $format{'ID'}
				);
				$t->close();
				return undef;
			}
		}
		else
		{
			image_file_add_error
			(
				'image.ID_entity' => $image{'ID_entity'},
				'image_format.ID' => $format{'ID'}
			);
			$t->close();
			return undef;
		}
	}
		
	my $image1_path=_image_file_genpath
	(
		$format_parent{'ID'},
		$file_parent{'ID'},
		$file_parent{'name'},
		$file_parent{'file_ext'}
	);
	
	main::_log("path to parent image_file='$image1_path' size=".((stat($tom::P_media.'/a501/image/file/'.$image1_path))[7])."b");
	my $image2=new TOM::Temp::file('dir'=>$main::ENV{'TMP'});
	
	my ($out,$ext)=image_file_process(
		'image1' => $tom::P_media.'/a501/image/file/'.$image1_path,
		'image2' => $image2->{'filename'},
		'process' => $env{'process'} || $format{'process'},
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
	
	App::020::SQL::functions::_save_changetime({'db_h'=>'main','db_name'=>$App::501::db_name,'tb_name'=>'a501_image','ID_entity'=>$image{'ID_entity'}});
	
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
	
	my $path=$tom::P_media.'/a501/image/file/'.$format.'/'.$ID;
	if (!-e $path)
	{
		File::Path::mkpath($path);
		chmod (0777,$path);
		$path=$tom::P_media.'/a501/image/file/'.$format;
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
		if ($env{'image1'}=~/^.*\.(.{3,5})$/)
		{
			# save the format of original image by default
			$env{'ext'}=$1;
		}
		else
		{
			$env{'ext'}=$App::501::image_format_ext_default;
			$procs++;
		}
	}
	
	# read the first image
	use Image::Magick;
	main::_log("reading file '$env{'image1'}'");
	
	if (!-e $env{'image1'} || -d $env{'image1'})
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
	
	if ($image1->Get('magick') eq 'PSD')
	{
		main::_log("unsupported format 'PSD'",1);
		unlink $env{'image1'} if $env{'unlink'};
		$t->close();
		return undef;
	}
	
	# GIF magick
	$image1=$image1->[0] if $image1->Get('magick') eq 'GIF';
#	$image1->Profile('profile'=>'');
	main::_log("units=".$image1->Get('units'));
	my $density=$image1->Get('density');
	main::_log("density=".$density);
	main::_log("width=".($image1->Get('width'))." height=".($image1->Get('height')));
	main::_log("orientation=".$image1->Get('orientation'));
#	$image1->Set('units'=>"PixelsPerInch");
#	$image1->Set('density'=>"72x72");
	
	if ($density=~/^([\d\.]+)x/ && $1 < 1)
	{
		main::_log("fixing density");
		$image1->Set('units' => "PixelsPerInch");
		if ($1 == 0.0072)
		{
			$image1->Set('density' => "100x100");
		}
		else
		{
			$image1->Set('density' => "72x72");
		}
	}
	# CMYK magick
#	$image1->Set('colorspace'=>'RGB') if $image1->Get('colorspace') eq "CMYK";
	# Profile magick (reduces size)
#	$image1->Profile('profile'=>'');
	
	$env{'facedetect'}='true';
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
			undef $env{$params[0]} if $params[1] eq "false";
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
		
		if ($function_name eq "autorotate")
		{
			main::_log("check exec $function_name($params[0])");
			#main::_log(" Orientation=".$image1->Get('format', '%[EXIF:*]');
#			if ($image1->Get('width') > $params[0] || $image1->Get('height') > $params[1])
#			{
#				$image1->AutoOrient();
#				$procs++;
#			}
			next;
		}
		
		if ($function_name eq "autoorient")
		{
			main::_log("exec $function_name()");
			
			my $exif = $image1->Get('format', '%[EXIF:*]');
#			print $exif;
			my %exifdata;
			foreach (split(/[\r\n]/, $exif))
			{
#				main::_log(" $_");
				if ( /exif:([^=]+)=(.*)$/ )
				{
					$exifdata{$1} = $2;
				}
			}
			
			if ($exifdata{'Orientation'})
			{
				main::_log(" found exif Orientation=".$exifdata{'Orientation'});
			}
			
#			if ($exifdata{'Orientation'} == 1)
#			{
#				main::_log(" rotate(90)");
#				$image1->Rotate(90);
#			}
#			else
#			{
				main::_log(" orientation=".$image1->Get('orientation'));
				main::_log(" Orientation=".$image1->Get('Orientation'));
				main::_log(" autoorient()");
				$image1->AutoOrient();
				main::_log(" orientation=".$image1->Get('orientation'));
				main::_log(" width=".($image1->Get('width'))." height=".($image1->Get('height')));
#			}
			$procs++;
			next;
		}
		
		if ($function_name eq "downscale")
		{
			main::_log("check exec $function_name($params[0],$params[1]) from (".$image1->Get('width').",".$image1->Get('height').")");
			if ($image1->Get('width') > $params[0] || $image1->Get('height') > $params[1])
			{
				main::_log(" exec $function_name($params[0],$params[1])");
				main::_log(" width=".($image1->Get('width'))." height=".($image1->Get('height')));
				$image1->Resize('geometry'=>$params[0].'x'.$params[1]);
				main::_log(" new width=".($image1->Get('width'))." height=".($image1->Get('height')));
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
		
		if ($function_name eq "autotrim")
		{
			main::_log("exec $function_name()");
			$image1->Trim();
			$image1->Set(page=>'0x0+0+0');
			$procs++;
			next;
		}
		
		if ($function_name eq "trim")
		{
			main::_log("exec $function_name($params[0])");
			$params[0]=0.09 unless $params[0]; # set default tolerance
			main::_log(" width=".($image1->Get('width'))." height=".($image1->Get('height')));
			# find points colors
			my $pixel_rt=($image1->GetPixel('x'=>$image1->Get('width'),'y'=>1))[0];
			main::_log(" pixel_rt=$pixel_rt");
			my $pixel_rb=($image1->GetPixel('x'=>$image1->Get('width'),'y'=>$image1->Get('height')))[0];
			main::_log(" pixel_rb=$pixel_rb");
			my $pixel_lt=($image1->GetPixel('x'=>1,'y'=>1))[0];
			main::_log(" pixel_lt=$pixel_lt");
			my $pixel_lb=($image1->GetPixel('x'=>1,'y'=>$image1->Get('height')))[0];
			main::_log(" pixel_lb=$pixel_lb");
			# check if we can start trimming (corner pixel in tolerance)
			my $tol=abs($pixel_lt-$pixel_rt);main::_log(" tolerance lt-rt=$tol");
			if ($tol>$params[0]){main::_log(" out of tolerance, skip function");next;};
			my $tol=abs($pixel_lt-$pixel_lb);main::_log(" tolerance lt-lb=$tol");
			if ($tol>$params[0]){main::_log(" out of tolerance, skip function");next;};
			my $tol=abs($pixel_lt-$pixel_rb);main::_log(" tolerance lt-rb=$tol");
			if ($tol>$params[0]){main::_log(" out of tolerance, skip function");next;};
			# find left crop
			my $tol_boolean;
			my $pixel_l;
			for my $x (1..int($image1->Get('width')/2)-1)
			{
				$pixel_l=$x;
				for my $y (1..$image1->Get('height'))
				{
					my $px=($image1->GetPixel('x'=>$x,'y'=>$y))[0];
					my $tol=abs($pixel_lt-$px);
					if ($tol>$params[0]){main::_log(" out of tolerance at l=$x");$tol_boolean=1;last;};
				}
				last if $tol_boolean;
			}
			# find right crop
			my $tol_boolean;
			my $pixel_r;
			for my $x (1..int($image1->Get('width')/2)-1)
			{
				$pixel_r=$image1->Get('width')-$x;
				for my $y (1..$image1->Get('height'))
				{
					my $px=($image1->GetPixel('x'=>$image1->Get('width')-$x,'y'=>$y))[0];
					my $tol=abs($pixel_lt-$px);
					if ($tol>$params[0]){main::_log(" out of tolerance at r=$pixel_r");$tol_boolean=1;last;};
				}
				last if $tol_boolean;
			}
			# find top crop
			my $tol_boolean;
			my $pixel_t;
			for my $y (1..int($image1->Get('height')/2)-1)
			{
				$pixel_t=$y;
				for my $x (1..$image1->Get('width'))
				{
					my $px=($image1->GetPixel('x'=>$x,'y'=>$y))[0];
					my $tol=abs($pixel_lt-$px);
					if ($tol>$params[0]){main::_log(" out of tolerance at t=$y");$tol_boolean=1;last;};
				}
				last if $tol_boolean;
			}
			# find bottom crop
			my $tol_boolean;
			my $pixel_b;
			for my $y (1..int($image1->Get('height')/2)-1)
			{
				$pixel_b=$image1->Get('height')-$y;
				for my $x (1..$image1->Get('width'))
				{
					my $px=($image1->GetPixel('x'=>$x,'y'=>$image1->Get('height')-$y))[0];
					my $tol=abs($pixel_lt-$px);
					if ($tol>$params[0]){main::_log(" out of tolerance at b=$pixel_b");$tol_boolean=1;last;};
				}
				last if $tol_boolean;
			}
			# setup border
			my $border=int(($pixel_r-$pixel_l+$pixel_b-$pixel_t)/2*0.05);
			main::_log(" setup border to $border px");
			if ($border)
			{
				main::_log(" cropping");
				$pixel_l-=$border;
				$pixel_l=1 if $pixel_l<1;
				$pixel_t-=$border;
				$pixel_t=1 if $pixel_t<1;
				$pixel_r+=$border;
				$pixel_r=$image1->Get('width') if $pixel_r>$image1->Get('width');
				$pixel_b+=$border;
				$pixel_b=$image1->Get('height') if $pixel_b>$image1->Get('height');
				# execute crop
				$image1->Crop('x'=>$pixel_l,'y'=>$pixel_t,'width'=>$pixel_r-$pixel_l,'height'=>$pixel_b-$pixel_t);
	#			$image1->Trim();
				main::_log(" new width=".($image1->Get('width'))." height=".($image1->Get('height')));
			}
			$procs++;
			next;
		}
		
		if ($function_name eq "crop")
		{
			main::_log("exec $function_name($params[0],$params[1],$params[2],$params[3])");
			$image1->Crop('x'=>$params[0],'y'=>$params[1],'width'=>$params[2]-$params[0],'height'=>$params[3]-$params[1]);
			main::_log(" new width=".($image1->Get('width'))." height=".($image1->Get('height')));
			$procs++;
			next;
		}
		
		if (($function_name eq "face_debug" || $function_name eq "dimensions") && $env{'facedetect'})
		{
			main::_log("exec facedetection() over $function_name()");
			
			my $tmpfile=new TOM::Temp::file('ext'=>'jpg','dir'=>$main::ENV{'TMP'});
			$image1->Write('jpg:'.$tmpfile->{'filename'});
			my $out;
			if ($App::501::fdetect)
			{
				main::_log_stdout("go fdetect");
				my $cascade = ($App::501::fdetect_cascade_file || $TOM::P.'/_addons/App/501/FaceDetect/cascade.xml');
				my $file = $tmpfile->{'filename'};
				my $detector = Image::ObjectDetect->new($cascade);
				my @faces = $detector->detect($file);
				use Data::Dumper;
				main::_log(Dumper(\@faces));
				for my $face (@faces) {
					$out.="0:".$face->{'x'}.",".$face->{'y'}."-".($face->{'x'}+$face->{'width'}).",".($face->{'y'}+$face->{'height'})."\n";
#					main::_log_stdout("x=".$face->{'x'});
#					print $face->{'x'}, "\n";
#					print $face->{'y'}, "\n";
#					print $face->{'width'}, "\n";
#					print $face->{'height'}, "\n";
				}
			}
			elsif (-x '/www/TOM/_addons/App/501/FaceDetect/fdetect')
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
		
		if ($function_name eq "autoalpha")
		{
			main::_log("exec $function_name($params[0])");
			
			$image1->Write($env{'ext'}.':'.$env{'image2'});
			
			system("/usr/bin/convert \"$env{'image2'}\" -bordercolor white -border 1x1 -alpha set -channel RGBA -fuzz ".$params[0]."% -fill none -floodfill +0+0 white -shave 1x1 \"$env{'image2'}\"");
			main::_log("failed? $?");
			
			$image1->Read($env{'image2'});
			
			$procs++;
			next;
		}
		
		if ($function_name eq "dimensions")
		{
			main::_log("exec $function_name($params[0],$params[1])");
			
			my $width=$image1->Get('width');
			my $height=$image1->Get('height');
			
			my $scale_new=int(($params[0]/$params[1])*10000)/10000;
			my $scale_old=int(($width/$height)*10000)/10000;
			
			main::_log("w=$width h=$height current scale:$scale_old requested scale:$scale_new");
			
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
			
			$nwidth=int($nwidth);
			$nheight=int($nheight);
			
			main::_log("calculated new size to crop by scale $scale_new new w=$nwidth new h=$nheight");
			
			my $x;
			my $y;
			
			$x=($width-$nwidth)/2; # center crop
			my $x_max=$width-$nwidth;
			$y=($height-$nheight)/2; # center crop
			my $y_max=$height-$nheight;
			
			if ($height > $nheight)
			{
				main::_log("vertical moving to position y:$env{'green_area'}{'y1'} (free pixels to move:$y_max)");
				if ($env{'green_area'}{'y1'})
				{
					$y=$env{'green_area'}{'y1'}+(($env{'green_area'}{'y2'}-$env{'green_area'}{'y1'})/2)-($nheight/2);
					$y=$y_max if ($y > $y_max);
				}
				else
				{
					#$y-=(($height-$nheight)/2)*0.25;
				}
			}
			$y=0 if $y<0;
			
			if ($width > $nwidth)
			{
				main::_log("horizontal moving to position x:$env{'green_area'}{'x1'} (free pixels to move:$x_max)");
				if ($env{'green_area'}{'x1'})
				{
					$x=$env{'green_area'}{'x1'}+(($env{'green_area'}{'x2'}-$env{'green_area'}{'x1'})/2)-($nwidth/2);
					$x=$x_max if ($x > $x_max);
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
		
		if ($function_name eq "edimensions")
		{
			main::_log("exec $function_name($params[0],$params[1])");
			
			my $width=$image1->Get('width');
			my $height=$image1->Get('height');
			
			my $scale_new=int(($params[0]/$params[1])*10000)/10000;
			my $scale_old=int(($width/$height)*10000)/10000;
			
			main::_log("w=$width h=$height current scale:$scale_old requested scale:$scale_new");
			
			my $scale='1:1';
			my $scale_x=$params[0];
			my $scale_y=$params[1];
			
			my $nwidth;
			my $nheight;
			
			my $scl;
			
			if ($scale_old<$scale_new)
			{
				$scl=$height/$scale_y;
				$nwidth=$scale_x*$scl;
				$nheight=$scale_y*$scl;
			}
			else
			{
				$scl=$width/$scale_x;
				$nwidth=$scale_x*$scl;
				$nheight=$scale_y*$scl;
			}
			
			$nwidth=int($nwidth);
			$nheight=int($nheight);
			
			main::_log("calculated new size to extent by scale $scale_new new w=$nwidth new h=$nheight");
			
			$image1->Extent('width' => $nwidth, 'height' => $nheight,
				'x'=> int(($nwidth-$width)/2),
				'y'=>int(($nheight-$height)/2)
			);
			
			$procs++;
			next;
		}
		
		if ($function_name eq "border")
		{
			main::_log("exec $function_name($params[0]");
			
			my $width=$image1->Get('width');
			my $height=$image1->Get('height');
			
			main::_log("w=$width h=$height");
			
			my $nwidth=$width+int($params[0]*2);
			my $nheight=$height+int($params[0]*2);
			
			$image1->Extent('width' => $nwidth, 'height' => $nheight,
				'x'=> int(($nwidth-$width)/2),
				'y'=>int(($nheight-$height)/2)
			);
			
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
		
		if ($function_name eq "rotate")
		{
			main::_log("exec $function_name($params[0])");
			my $out=$image1->Rotate('degrees'=>$params[0]);
			$procs++;
			next;
		}
		
		if ($function_name eq "face_debug")
		{
			next;
		}
		
		if ($function_name eq "grayscale")
		{
			main::_log("exec $function_name()");
			$image1->Quantize('colorspace'=>'gray');
			$procs++;
			next;
		}
		
		if ($function_name eq "copyright")
		{
			main::_log("exec $function_name()");
			
			my $image_composite = new Image::Magick;
			$image_composite->Read($tom::P_media.'/a501/copyright.png');
			my $max=0.8;
			my $downscale_width=$image_composite->Get('width');
				if ($downscale_width>$image1->Get('width')*$max)
				{
					$downscale_width=int($image1->Get('width')*$max);
				}
			my $downscale_height=$image_composite->Get('height');
				if ($downscale_height>$image1->Get('height')*$max)
				{
					$downscale_height=int($image1->Get('height')*$max);
				}
			
			my $image_composite_points=$image_composite->Get('width')*$image_composite->Get('height');
			my $image1_points=$image1->Get('width')*$image1->Get('height');
			
			my $max=0.02;
			if (($image_composite_points/$image1_points)>$max) # max 5%
			{
				my $downscale_width2=int($image_composite->Get('width')*(1- ( ($image_composite_points/$image1_points)-$max ) ));
					$downscale_width=$downscale_width2 if $downscale_width>$downscale_width2;
				my $downscale_height2=int($image_composite->Get('height')*(1- ( ($image_composite_points/$image1_points)-$max ) ));
					$downscale_height=$downscale_height2 if $downscale_height>$downscale_height2;
			}
			
			main::_log("composite max_geometry=$downscale_width x $downscale_height");
			
			$image_composite->Resize('geometry'=>$downscale_width.'x'.$downscale_height);
			
			$image1->Composite(
				'image'=>$image_composite,
#				'compose'=>'Difference',
				'x' => 1,
				'y' => $image1->Get('height')-$image_composite->Get('height'),
			);
			
			
			$procs++;
			next;
		}
		
		if ($function_name eq "escale")
		{
			#downscalnem obrazok na zelanu velkost a vyplnim v danom rozmere pozadie biele
			main::_log("exec $function_name($params[0],$params[1])");
			
			if ($image1->Get('width') > $params[0] || $image1->Get('height') > $params[1])
			{
				main::_log(" exec $function_name($params[0],$params[1])");
				main::_log(" width=".($image1->Get('width'))." height=".($image1->Get('height')));
				$image1->Resize('geometry'=>$params[0].'x'.$params[1]);
				main::_log(" new width=".($image1->Get('width'))." height=".($image1->Get('height')));
			}
			
			
			my $image_composite = Image::Magick->new();
			$image_composite->Read($tom::P.'/!media/grf/t.gif');
			$image_composite->Resize('width'=>$params[0],'height'=>$params[1]);
			$image_composite->Draw(fill=>'white', primitive=>'rectangle', points=>'0,0 '.$params[0].','.$params[1]);
			
#			my $image_composite = new Image::Magick;
#			$image_composite = Image::Magick->new;
#			$image_composite->Set(size=>$params[0].'x'.$params[0]);
#			$image_composite->ReadImage('canvas:white');
			
			my $posx = ($image_composite->Get('width')-$image1->Get('width'))/2;
			my $posy = ($image_composite->Get('height')-$image1->Get('height'))/2;
			
			$image_composite->Composite(
				'image'=>$image1,
				'x' => $posx,
				'y' => $posy,
			);
			
			$image1 = $image_composite;
			
			$procs++;
			next;
		}
		
		if ($function_name eq "optimize")
		{
#			next if $tom::test;
			main::_log("exec optimize (sampling-factor, strip, interlace, colorspace)");
			$image1->Set('sampling-factor'=>'4:2:0');
			$image1->Strip();
			$image1->Set('interlace'=>'JPEG');
			$image1->Colorspace('colorspace' => 'RGB')
				if $image1->get('version')=~/7\.\d\.\d/;
			next;
		}
		
		main::_log("unknown '$function'",1);
		$t->close();
		return undef;
		
	}
	
	my @out;
	
	if ($procs)
	{
		$image1->Profile('profile'=>'');
		
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
			main::_log($out[0]);

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
	if ($env{'-jobify'})
	{
		return 1 if TOM::Engine::jobify(\@_,{
			'routing_key' => 'db:'.$App::501::db_name,
#			'class' => 'encoder',
			'deduplication' => 1}); # do it in background
	}
	
	my $t=track TOM::Debug(__PACKAGE__."::image_add()");
	
#	foreach (sort keys %env)
#	{
#		main::_log("input $_='$env{$_}'");
#	}
	
	my $content_updated=0;
	
	$env{'image_format.ID'}=$App::501::image_format_original_ID unless $env{'image_format.ID'};
	
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
		
		# okay, adding new original
		# 1 - check if for original is not required processing
		# 2 - use that processed file
		my %format=App::020::SQL::functions::get_ID(
			'ID' => $App::501::image_format_original_ID,
			'db_h' => "main",
			'db_name' => $App::501::db_name,
			'tb_name' => "a501_image_format",
			'columns' => {'*'=>1}
		);
		if ($format{'process'})
		{
			$env{'file_temp'}=new TOM::Temp::file('dir'=>$main::ENV{'TMP'});
			my ($out,$ext)=image_file_process(
				'image1' => $env{'file'},
				'image2' => $env{'file_temp'}->{'filename'},
				'process' => $format{'process'},
			);
			$env{'file'}=$env{'file_temp'}->{'filename'};
		}
		
		# check if same image not already inserted
		if (!$env{'image.ID_entity'} && !$env{'image.ID'} && $env{'check_duplicity'} && !$App::501::disable_deduplication)
		{
			# calculate sha1
			open(CHKSUM,'<'.$env{'file'});
			my $ctx = Digest::SHA1->new;
			$ctx->addfile(*CHKSUM);
			my $checksum = $ctx->hexdigest;
			my $checksum_method = 'SHA1';
			main::_log("file checksum $checksum_method:$checksum");
			if ($checksum)
			{
				# find same checksum
				my %sth0=TOM::Database::SQL::execute(qq{
					SELECT
						a501_image.*
					FROM
						`$App::501::db_name`.a501_image_file
					INNER JOIN `$App::501::db_name`.a501_image ON
					(
						    a501_image.ID_entity = a501_image_file.ID_entity
						AND a501_image.status IN ('Y','N')
					)
					INNER JOIN `$App::501::db_name`.a501_image_ent ON
					(
						    a501_image_ent.ID_entity = a501_image_file.ID_entity
						AND a501_image_ent.status IN ('Y','N')
					)
					WHERE
						    a501_image_file.file_checksum="$checksum_method:$checksum"
						AND a501_image_file.status='Y'
					LIMIT 1
				},'quiet'=>1);
				if (my %db0_line=$sth0{'sth'}->fetchhash())
				{
					main::_log("same image already in database with ID_entity=$db0_line{'ID_entity'}");
					$env{'image.ID_entity'}=$db0_line{'ID_entity'};
					if (!$env{'image_attrs.ID_category'})
					{
						$env{'image.ID'}=$db0_line{'ID'};
					}
					undef $env{'file'};
				}
			}
		}
		
		# new image without ID (try to extract EXIF data)
		if (!$env{'image.ID_entity'} && !$env{'image.ID'})
		{
			my $image = Image::Magick->new();
			$image->Read($env{'file'});
			my $exif = $image->Get('format', '%[EXIF:*]');
			my %exifdata;
			foreach (split(/[\r\n]/, $exif))
			{
#				main::_log($_);
				if ( /exif:([^=]+)=(.*)$/ )
				{
					$exifdata{$1} = $2;
				}
			}
			if ($exifdata{'DateTime'} && !$env{'image_ent.datetime_produce'})
			{
				$env{'image_ent.datetime_produce'}=$exifdata{'DateTime'};
			}
			
			if (!$env{'image_ent.metadata'})
			{
				$env{'image_ent.metadata'} = App::020::functions::metadata::serialize('EXIF' => { %exifdata });	
			}
			
		}
		
		$content_updated=1;
	}
	
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
	if (!$env{'image.ID'} && $env{'image.ID_entity'} && !$env{'forcesymlink'})
	{
		$env{'image_attrs.ID_category'}='0' unless $env{'image_attrs.ID_category'};
		
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
				image_attrs.lng = '$env{'image_attrs.lng'}' AND
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
		$content_updated=1;
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
		
		
		# metadata
		my %metadata=App::020::functions::metadata::parse($image_ent{'metadata'});
		
		foreach my $section(split(';',$env{'image_ent.metadata.override_sections'}))
		{
			delete $metadata{$section};
		}
		
		if ($env{'image_ent.metadata.replace'})
		{
			if (!ref($env{'image_ent.metadata'}) && $env{'image_ent.metadata'})
			{
				%metadata=App::020::functions::metadata::parse($env{'image_ent.metadata'});
			}
			if (ref($env{'image_ent.metadata'}) eq "HASH")
			{
				%metadata=%{$env{'image_ent.metadata'}};
			}
		}
		else
		{
			if (!ref($env{'image_ent.metadata'}) && $env{'image_ent.metadata'})
			{
				# when metadata send as <metatree></metatree> then always replace
				%metadata=App::020::functions::metadata::parse($env{'image_ent.metadata'});
			}
			if (ref($env{'image_ent.metadata'}) eq "HASH")
			{
				# metadata overrride
				foreach my $section(keys %{$env{'image_ent.metadata'}})
				{
					foreach my $variable(keys %{$env{'image_ent.metadata'}{$section}})
					{
						$metadata{$section}{$variable}=$env{'image_ent.metadata'}{$section}{$variable};
					}
				}
			}
		}
		
		$env{'image_ent.metadata'}=App::020::functions::metadata::serialize(%metadata);
		
		$columns{'metadata'}="'".TOM::Security::form::sql_escape($env{'image_ent.metadata'})."'"
		if (exists $env{'image_ent.metadata'} && ($env{'image_ent.metadata'} ne $image_ent{'metadata'}));
		
#		if ((not exists $env{'image_ent.metadata'}) && (!$image_ent{'metadata'})){$env{'image_ent.metadata'}=$App::501::metadata_default;}
#		$columns{'metadata'}="'".TOM::Security::form::sql_escape($env{'image_ent.metadata'})."'"
#			if (exists $env{'image_ent.metadata'} && ($env{'image_ent.metadata'} ne $image_ent{'metadata'}));
		
		if ($columns{'metadata'})
		{
			App::020::functions::metadata::metaindex_set(
				'db_h' => 'main',
				'db_name' => $App::501::db_name,
				'tb_name' => 'a501_image_ent',
				'ID' => $env{'image_ent.ID'},
				'metadata' => {App::020::functions::metadata::parse($env{'image_ent.metadata'})}
			);
		}
		
		if (keys %columns)
		{
			main::_log("trying update");
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
	
	# optional default file ext
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
	my $out=$image->Read($env{'file'});
	if ($out)
	{
		main::_log("can't read '$out'",1);
		$t->close();
		return undef;
	}
	my $image_width=$image->Get('width');
	my $image_height=$image->Get('height');
	main::_log("image width=$image_width height=$image_height");
	
	if (!$image_width || !$image_height)
	{
		main::_log("can't read info about dimensions",1);
		$t->close();
		return undef;
	}
	
	# generate new unique hash
	my $name=image_file_newhash();
	# add asciied name of image
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			a501_image_attrs.name
		FROM
			`$App::501::db_name`.`a501_image`
		INNER JOIN `$App::501::db_name`.`a501_image_attrs` ON
		(
			a501_image_attrs.ID_entity = a501_image.ID AND
			a501_image_attrs.status IN ('Y','N')
		)
		WHERE
			a501_image.ID_entity=$env{'image.ID_entity'}
		LIMIT 1
	}); # language is not relevant
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		my $optimal_hash=Int::charsets::encode::UTF8_ASCII($db0_line{'name'});
		$optimal_hash=~tr/[A-Z]/[a-z]/;
		$optimal_hash=~s|[^a-z0-9]|_|g;
		1 while ($optimal_hash=~s|__|_|g);
		my $max=110;
		if (length($optimal_hash)>$max)
		{
			$optimal_hash=substr($optimal_hash,0,$max);
		}
		$name.=".".$optimal_hash if $optimal_hash;
	}
	
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
		my $filename_old=$tom::P_media.'/a501/image/file/'
			.$db0_line{'ID_format'}.'/'
			.substr($db0_line{'ID'},0,4).'/'
			.$db0_line{'name'}.'.'.$db0_line{'file_ext'};
		main::_log("check for update image_file $filename_old");
		if ($db0_line{'file_checksum'} eq "$checksum_method:$checksum" && -e $filename_old && !$App::501::checksum_eq_ignore)
		{
			main::_log("same checksum");
			
#			if ($db0_line{'status'} ne "Y")
#			{
#				main::_log("re-enabling file, because disabled");
				# nesmiem toto robit zbytocne, inak dochadza dookola k regenerovaniu obrazkov
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
				
#			}
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
			my $path=$tom::P_media.'/a501/image/file/'._image_file_genpath
			(
				$env{'image_format.ID'},
				$db0_line{'ID'},
				$name,
				$file_ext
			);
			main::_log("copy to $path");
			File::Copy::copy($env{'file'},$path) || main::_log("error $!");
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
			'-journalize' => 1,
			'-replace' => 1,
		);
		$ID=sprintf("%08d",$ID);
		main::_log("ID='$ID'");
		
		my $path=$tom::P_media.'/a501/image/file/'._image_file_genpath
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
		
		$hash=TOM::Utils::vars::genhash(4);
		
		my $sql=qq{
			(
				SELECT ID
				FROM
					`$App::501::db_name`.a501_image_file
				WHERE
					name LIKE '$hash%'
				LIMIT 1
			)
			UNION ALL
			(
				SELECT ID
				FROM
					`$App::501::db_name`.a501_image_file_j
				WHERE
					name LIKE '$hash%'
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
	my $debug=0;
	use JSON;
	
	if (!$env{'image.ID_entity'} && !$env{'image.ID'})
	{
		return undef;
	}
	
#	main::_log('ok getting image file');
	
	$env{'image_file.ID_format'} = $App::501::image_format_fullsize_ID unless $env{'image_file.ID_format'};
	$env{'image_attrs.lng'}=$tom::lng unless $env{'image_attrs.lng'};
	
	my $sql=qq{
		SELECT
			image.ID_entity,
			image.ID,
			image.ID_entity AS ID_entity_image,
			image.ID AS ID_image,
			image_file.ID_format AS ID_format,
			image_file.ID AS ID_file,
			image_ent.posix_owner,
			image_ent.posix_author,
			image_attrs.name,
			image_attrs.description,
			image_file.image_width,
			image_file.image_height,
			image_file.name AS file_name,
			image_file.file_size,
			image_file.file_checksum,
			image_file.file_ext,
			image_file.status AS file_status,
			CONCAT(image_file.ID_format,'/',SUBSTR(image_file.ID,1,4),'/',image_file.name,'.',image_file.file_ext) AS file_path,
			CASE image_attrs.lng
				WHEN '$env{'image_attrs.lng'}' THEN '1'
				ELSE '0'
			END AS lng_relevance
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
			image_attrs.ID_entity = image.ID
		)
		LEFT JOIN `$App::501::db_name`.`a501_image_file` AS image_file ON
		(
			image_file.ID_entity = image.ID_entity AND
			image_file.ID_format=$env{'image_file.ID_format'} AND
			image_file.status IN ('Y','N','L','E')
		)
		WHERE
			image.ID_entity='$env{'image.ID_entity'}'
		ORDER BY
			lng_relevance DESC
		LIMIT 1
		};
	}
	else
	{
		# get ID_entity for cache
		my %sth0=TOM::Database::SQL::execute(qq{SELECT ID_entity FROM `$App::501::db_name`.`a501_image` WHERE ID='$env{'image.ID'}' LIMIT 1},'quiet'=>1,'-slave'=>1,'-cache'=>3600);
		my %db0_line=$sth0{'sth'}->fetchhash();
		$env{'image.ID_entity'}=$db0_line{'ID_entity'};
		main::_log("found ID_entity=$env{'image.ID_entity'}",3,"debug") if $debug;
		
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
		'-cache' => 86400*7*4, #24H max
#		'-cache_min' => 600, # when changetime before this limit 10min
		'-cache_changetime' => App::020::SQL::functions::_get_changetime({
			'db_h'=>"main",'db_name'=>$App::501::db_name,'tb_name'=>"a501_image",
			'ID_entity' => $env{'image.ID_entity'}
		}),
		'-recache' => $env{'-recache'}
	);
	if ($sth0{'rows'})
	{
		my %image=$sth0{'sth'}->fetchhash();
		
		main::_log("found image ".to_json(\%image),3,"debug") if $debug;
		
#		if (!$image{'ID_file'})
		if (!$image{'file_name'})
		{
			undef $image{'file_path'};
			main::_log("this image does not have format '$env{'image_file.ID_format'}'");
			main::_log("this image does not have format '$env{'image_file.ID_format'}'",3,"debug") if $debug;
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
		
		if ($image{'file_status'} eq "E")
		{
			undef $image{'file_path'};
		}
		
#		main::_log("received image_file with status='$image{'file_status'}'");
		if ($env{'-regenerate'})
		{
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
	else
	{
		main::_log("not found image_file for image $env{'image.ID'} with format $env{'image_file.ID_format'}",1);
	}
	
	return undef;
}



sub image_file_resize
{
	my %env=@_;
	
	if (!$env{'image_file.ID'})
	{
		return undef;
	}
	
	return undef if (!$env{'width'} && !$env{'height'});
	
#	return undef unless $env{'width'};
#	return undef unless $env{'height'};
	$env{'method'}="resize" unless $env{'method'};
	$env{'method'}="resize" if $env{'method'} eq "auto";
	$env{'method'}="resize" if $env{'method'} eq "true";
	
	# najprv najdem dany file
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			*,
			CONCAT(ID_format,'/',SUBSTR(ID,1,4)) AS file_dir,
			CONCAT(ID_format,'/',SUBSTR(ID,1,4),'/',name,'.',file_ext) AS file_path
		FROM
			`$App::501::db_name`.a501_image_file
		WHERE
			ID = ?
	},'quiet'=>1,'bind'=>[$env{'image_file.ID'}]);
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		my $new_file_path=$env{'method'}.'/'.$db0_line{'file_dir'};
		#my $new_file=$db0_line{'name'}."_".$env{'width'}."_".$env{'height'}.'.'.$db0_line{'file_ext'};
		my $new_file=$db0_line{'name'}."_".($env{'width'} || 'U').'x'.($env{'height'}||'U').'.'.$db0_line{'file_ext'};
		if (-e $tom::P_media.'/a501/image/file_p/'.$new_file_path.'/'.$new_file)
		{
			# this resized file already exists
			$env{'file_path'}=$new_file_path.'/'.$new_file;
			return %env;
		}
		
		# not exists, also resizing
		# at first create directory
		if (!-e $tom::P_media.'/a501/image/file_p/'.$new_file_path)
		{
			File::Path::mkpath($tom::P_media.'/a501/image/file_p/'.$new_file_path) || return undef;
			chmod (0777,$tom::P_media.'/a501/image/file_p/'.$new_file_path) || return undef;
		}
		
		if (!-e $tom::P_media.'/a501/image/file/'.$db0_line{'file_path'})
		{
			# original file not exists
			return undef;
		}
		
		if ($env{'width'})
		{
			main::_log("resizing file to width='$env{'width'}'");
			
			my ($out,$ext)=image_file_process(
				'image1' => $tom::P_media.'/a501/image/file/'.$db0_line{'file_path'},
				'image2' => $tom::P_media.'/a501/image/file_p/'.$new_file_path.'/'.$new_file,
				'process' => qq{scale($env{'width'},)}
			);
			
			if ($out)
			{
				$env{'file_path'}=$new_file_path.'/'.$new_file;
				return %env;
			}
		}
		else
		{
			main::_log("resizing file to height='$env{'height'}'");
			
			my ($out,$ext)=image_file_process(
				'image1' => $tom::P_media.'/a501/image/file/'.$db0_line{'file_path'},
				'image2' => $tom::P_media.'/a501/image/file_p/'.$new_file_path.'/'.$new_file,
				'process' => qq{scale(,$env{'height'})}
			);
			
			if ($out)
			{
				$env{'file_path'}=$new_file_path.'/'.$new_file;
				return %env;
			}
		}
		
	}
	
	return undef;
}

sub image_file_crop
{
	my %env=@_;
	
	if (!$env{'image_file.ID'})
	{
		return undef;
	}
	
	return undef if (!$env{'crop'});
	
	# najprv najdem dany file
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			*,
			CONCAT(ID_format,'/',SUBSTR(ID,1,4)) AS file_dir,
			CONCAT(ID_format,'/',SUBSTR(ID,1,4),'/',name,'.',file_ext) AS file_path
		FROM
			`$App::501::db_name`.a501_image_file
		WHERE
			ID=?
	},'quiet'=>1,'bind'=>[$env{'image_file.ID'}]);
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		my $new_file_path=$env{'method'}.'/'.$db0_line{'file_dir'};
		
		my $new_file=$db0_line{'name'}."_".($env{'crop'}).'.'.$db0_line{'file_ext'};
		if (-e $tom::P_media.'/a501/image/file_p/'.$new_file_path.'/'.$new_file)
		{
			# this resized file already exists
			$env{'file_path'}=$new_file_path.'/'.$new_file;
			return %env;
		}
		
		# not exists, also resizing
		# at first create directory
		if (!-e $tom::P_media.'/a501/image/file_p/'.$new_file_path)
		{
			File::Path::mkpath($tom::P_media.'/a501/image/file_p/'.$new_file_path) || return undef;
			chmod (0777,$tom::P_media.'/a501/image/file_p/'.$new_file_path) || return undef;
		}
		
		if (!-e $tom::P_media.'/a501/image/file/'.$db0_line{'file_path'})
		{
			# original file not exists
			return undef;
		}
		
		main::_log("crop file to crop='$env{'crop'}'");
		
		my ($out,$ext)=image_file_process(
			'image1' => $tom::P_media.'/a501/image/file/'.$db0_line{'file_path'},
			'image2' => $tom::P_media.'/a501/image/file_p/'.$new_file_path.'/'.$new_file,
			'process' => qq{crop($env{'crop'})}
		);
		
		if ($out)
		{
			$env{'file_path'}=$new_file_path.'/'.$new_file;
			return %env;
		}
		
	}
	
	return undef;
}


sub _a210_by_cat
{
	my $cats=shift;
	my %env=@_;
	
	$env{'lng'}=$tom::lng unless $env{'lng'};
	$env{'db_name'}=$App::210::db_name unless $env{'db_name'};
	my $cache_key=$env{'db_name'}.'::'.$env{'lng'}.'::'.join('::',@{$cats});
	
	# changetimes
	my $changetime_a501=App::020::SQL::functions::_get_changetime({
		'db_name' => $App::501::db_name,
		'tb_name' => 'a501_image_cat',
	});
	my $changetime_a210=App::020::SQL::functions::_get_changetime({
		'db_name' => $env{'db_name'},
		'tb_name' => 'a210_page',
	});
	
	if ($TOM::CACHE && $TOM::CACHE_memcached && $main::cache)
	{
		my $cache=$Ext::CacheMemcache::cache->get(
			'namespace' => "fnc_cache",
			'key' => 'App::501::functions::_a210_by_cat::'.$cache_key
		);
		if (($cache->{'time'} > $changetime_a210) && ($cache->{'time'} > $changetime_a501))
		{
			return $cache->{'value'};
		}
	}
	
	# find path
	my @categories;
	my %sql_def=('db_h' => "main",'db_name' => $App::501::db_name,'tb_name' => "a501_image_cat");
	foreach my $cat(@{$cats})
	{
		my %sth0=TOM::Database::SQL::execute(
			qq{SELECT ID FROM $App::501::db_name.a501_image_cat WHERE ID_entity=? AND lng=? LIMIT 1},
			'bind'=>[$cat,$env{'lng'}],'log'=>0,'quiet'=>1,
			'-cache' => 86400*7,
			'-cache_changetime' => App::020::SQL::functions::_get_changetime({
				'db_name' => $App::501::db_name,
				'tb_name' => 'a501_image_cat',
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
				'r_prefix' => "a501",
				'r_table' => "image_cat",
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
			'key' => 'App::501::functions::_a210_by_cat::'.$cache_key,
			'value' => {
				'time' => time(),
				'value' => $category
			},
			'expiration' => '86400S'
		);
	}
	
	return $category;
}

=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
