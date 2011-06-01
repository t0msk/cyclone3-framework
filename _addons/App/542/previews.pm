#!/bin/perl
package App::542::previews;

=head1 NAME

App::542::previews

=head1 DESCRIPTION

Generates previews for a542 files when such a preview is available.

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DEPENDS

=over

=item *

L<App::542::_init|app/"542/_init.pm">

=item *

TOM::Temp::file

=item *

Image::Magick

=back

=cut

use TOM::Temp::file;
use App::542::_init;
use Image::Magick;

=head1 FUNCTIONS

=head2 generate_preview()


=cut


sub get_extension_for_file
{
	my $filename = shift;
	$filename =~ /\.([^\.]+)$/;
	my $ext = $1;

	return $ext;
}

sub generate_preview_for_file
{
	my %env = @_;

	return undef unless $env{'file'};

	# get ext, if not supplied
	$env{'ext'} = get_extension_for_file($env{'file'}) unless ($env{'ext'});
	
	
	main::_log('Generating preview for file: '.$env{'file'}.', extension: '.$env{'ext'});

	main::_log('ENV EXT: '.$env{'ext'});

	if ($env{'ext'} =~ /^pdf$/i)
	{
		my $image = new Image::Magick;
	
		# supress standard error, ImageMagick is stupid	
		main::_log('Trying to redirect stderr to '."$TOM::P/_logs/stderr.log");
		# open STDERR, '>', "$TOM::P/_logs/stderr.log";
		

		main::_log('Redirection successful');
		# read file
		$image->Read($env{'file'});	
		main::_log('First page..');
		# select first page of the PDF
		my $page1 = $image->[0];
	
		# prepare a new outfile
		my $outfile = new TOM::Temp::file('ext' => 'jpg', 'dir'=>$main::ENV{'TMP'});

		if ($outfile && $page1)
		{	
			# write first page to image file
			$page1->Write($outfile->{'filename'});
		} else
		{
			main::_log('conversion error, returning undef..');
			return undef;
		}
	
		# check if outfile size is >0, return outfile object or return null and destroy outfile
	
		my $size = -s $outfile->{'filename'};
	
		main::_log('Generated temporary file: '.$outfile->{'filename'}.' size: '.$size. ' If size >0 I will return TOM::Temp::File object.');
	
		if ($size)
		{
			# return outfile object	
			return $outfile;
		} else
		{
			return undef;
		}

	} else
	{
		return undef;
	}
}



1;