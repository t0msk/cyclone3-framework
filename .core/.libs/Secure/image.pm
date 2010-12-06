package Secure::image;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

use Image::Magick;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

sub genimagehash
{
	my $size=shift;
	my $width=shift;
	my $height=shift;
	my $path=shift;
	
	$size=4 unless $size;
	$width=90 unless $width;
	$height=30 unless $height;
	$path=$tom::P_media.'/grf/temp' unless $path;
	
	my $image = Image::Magick->new;
	$image->Set(size=>$width.'x'.$height);
	$image->ReadImage('xc:gray');
	
	my $hash=Utils::vars::genhash($size);
	$image->Annotate(font=>$TOM::P.'/_data/serifab.ttf', pointsize=>int(($height/10)*9), fill=>'black', text=>$hash, x=>10, y=>int((($height/10)*8) + ($height/20)));
	
	# pridame par nahodnych bodov
	my $hustota=($width*$height)/10;
	for (1..$hustota){$image->Draw(fill=>'black', primitive=>'point',points=>int(rand($width)).','.int(rand($height)));}
	for (1..$hustota){$image->Draw(fill=>'gray', primitive=>'point',points=>int(rand($width)).','.int(rand($height)));}
	#$image->AddNoise(noise=>'Poisson');
	
	my $file=Utils::vars::genhash(8);
	system("mkdir -p ".$path);
	$image->Write(filename=>$path.'/'.$file.'.png', compression=>'None');
	#system("chmod 660 ".$path."/".$file.".png");
	chmod 0664, $path."/".$file.".png";
	
	return $file,$hash;
}

sub genimagehash_ng
{
	my %env=@_;
	# size
	# width
	# height
	# path
	# color_bg
	# color_font
	# color_noise1
	# color_noise2
	
	$env{size}=4 unless $env{size};
	$env{width}=90 unless $env{width};
	$env{height}=30 unless $env{height};
	$env{path}=$tom::P_media.'/grf/temp' unless $env{path};
	
	$env{color_bg}='gray' unless $env{color_bg};
	$env{color_font}='black' unless $env{color_font};
	
	$env{color_noise1}=$env{color_font} unless $env{color_noise1};
	$env{color_noise2}=$env{color_bg} unless $env{color_noise2};
	
	my $image = Image::Magick->new;
	$image->Set(size=>$env{width}.'x'.$env{height});
	$image->ReadImage('xc:'.$env{color_bg});
	
	my $hash=Utils::vars::genhash($env{size});
	$image->Annotate(
		font=>$TOM::P.'/_data/serifab.ttf',
		pointsize=>int(($env{height}/10)*9),
		fill=>$env{color_font},
		text=>$hash,
		x=>10,
		y=>int((($env{height}/10)*8) + ($env{height}/20))
	);
	
	# pridame par nahodnych bodov
	my $hustota=($env{width}*$env{height})/10;
	for (1..$hustota){$image->Draw(fill=>$env{color_noise1}, primitive=>'point',points=>int(rand($env{width})).','.int(rand($env{height})));}
	for (1..$hustota){$image->Draw(fill=>$env{color_noise2}, primitive=>'point',points=>int(rand($env{width})).','.int(rand($env{height})));}
	#$image->AddNoise(noise=>'Poisson');
	
	my $file=Utils::vars::genhash(8);
	system("mkdir -p ".$env{path});
	$image->Write(filename=>$env{path}.'/'.$file.'.png', compression=>'None');
	#system("chmod 660 ".$path."/".$file.".png");
	chmod 0664, $env{path}."/".$file.".png";
	
	return $file,$hash;
}




1;
