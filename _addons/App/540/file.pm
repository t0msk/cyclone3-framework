#!/bin/perl

package App::540::file;

use File::Basename;
use App::540::_init;
use App::540::dir;
use Utils::vars;
use File::Type;
use strict;

sub get
{
 	my %args;
 	if (@_==0)
	{
# Get ALL files
		$args{id}="*";
	}
# ID only get
 	if (@_==1)
	{
 		$args{ID}=shift;
	}
 	else
# Get By Hash
	{
 		%args = @_;
	}
# Execute
 	$args{table}="a540";
 	my @files = App::540::sql_get( %args );
# Add filename
	my $filec = scalar(@files);
	for (my $i=0;$i<$filec;$i++)
	{
		$files[$i]{ID}=~/^(....)/i;
		$files[$i]{fullpath} = "../!media/540/$1/".$files[$i]{hash};
	}
# Return
	return @files;
}

sub del
{

 	my %args;
# ID only get
 	if (@_==1)
	{
 		$args{ID}=shift;
	}
 	else
# Get By Hash
	{
		%args = @_;
	}
# Delete All Files
	my @files = get(%args);
	my $filec = scalar(@files);
	for (my $i=0;$i<$filec;$i++)
	{
# Delete file only if it is not referenced
		main::_log("App::540::file::del : Will be Deleted ".$files[$i]{fullpath},0);
		my @ret = get(hash=>$files[$i]{hash},limit=>2);
		next if (scalar(@ret)>1);
		main::_log("App::540::file::del : Unlinked ".$files[$i]{fullpath},0);
		unlink($files[$i]{fullpath});
}
# Delete From DB
	$args{table}="a540";
	return App::540::sql_del( %args );
}

sub new
{
	my %args = @_;
# Use Modern version if file id is passed
	return new2(%args) if ( exists $args{file});
# Check required arguments
	if (not exists $args{handle})
	{
		main::_log("App::540::file::new : Treba predať 'handle' na súbor, ktorý sa má uložiť",1);
		return -1;
	}
	if (not exists $args{name})
	{
		main::_log("App::540::file::new : Treba predať 'name' súboru",1);
		return -1;
	}
	if (not exists $args{ID_dir})
	{
		$args{ID_dir} = "";
		main::_log("App::540::file::new : WARNING: Ziadne 'ID_dir', subor bude umistneny do root-u",0);
	}
# Name Fix
	main::_log("App::540::file::new : original name ".$args{name},0);
	$args{name} = basename($args{name});
	fileparse_set_fstype("MSWin32"); # MicroSoft Stupidity Fix
	$args{name} = basename($args{name});
	main::_log("App::540::file::new : base name ".$args{name},0);
# Copy handle
	my $handle = $args{handle};
	delete $args{handle};

# Generate hash
	$args{hash}=Utils::vars::genhash(16) if not exists $args{hash};
	while ( scalar(get(hash=>$args{hash})) == 1 )
	{
		$args{hash}=Utils::vars::genhash(16)
	}

	$args{table}="a540";

# Time
	$args{'time'} = $main::time_current if not exists $args{'time'};

# Default user
	$args{owner} = $main::USRM{IDhash} if not exists $args{owner};

# Get Filesize
	$args{size} = length( $handle );

# In mime was not specified ... guess.
	if ($args{mime} eq "auto" )
	{
		my $type = File::Type->new();
		$args{mime} = $type->mime_type( substr($handle,0,256) );
#		$args{mime} = $type->mime_type( $handle );
	}

# Check ID_dir for existence
	if ($args{ID_dir} ne "")
	{
		if (scalar(App::540::dir::get(ID_dir=>$args{ID_dir})) == 0 )
		{
			main::_log("App::540::file::new : Adresár s daným 'ID_dir' (".$args{ID_dir}.") neexistuje");
			return -1;
		}
	}

# SQL Insert
	my $id = App::540::sql_insert( %args );

# Failed
	if ($id < 0)
	{
		main::_log("App::540::file::new : SQL insert failed",1);
		return -2;
	}
	main::_log("App::540::file::new : File inserted ID: $id",0);

# Prepare filename
	my $zero_id = sprintf ('%07d', $id);
	$zero_id=~/^(....)/i;
	my $dir = "../!media/540/$1";
# Make directory
	mkdir("../!media/540");
	mkdir($dir);
	my $filename = "$dir/$args{hash}";

# Save file
	if (!open (OUT, ">$filename"))
	{
		main::_log("App::540::file::new : Cannot save file! : $filename",1);
		del($id);
		return -3;
	}
	binmode OUT;
	print OUT $handle;
	close (OUT);
	chmod(0770,$filename);

	main::_log("App::540::file::new : File saved as: $filename",0);
	return $id;
}

sub new2
{
	my %args = @_;

# Check required arguments
	if (not exists $args{file})
	{
		main::_log("App::540::file::new : Treba predať 'file' na súbor, ktorý sa má uložiť",1);
		return -1;
	}
	if (not exists $args{name})
	{
		$args{name}=$args{file};
	}
	if (not exists $args{ID_dir})
	{
		$args{ID_dir} = "";
		main::_log("App::540::file::new : WARNING: Ziadne 'ID_dir', subor bude umistneny do root-u",0);
	}
# Name Fix
	main::_log("App::540::file::new : original name ".$args{name},0);
	$args{name} = basename($args{name});
	fileparse_set_fstype("MSWin32"); # MicroSoft Stupidity Fix
	$args{name} = basename($args{name});
	main::_log("App::540::file::new : base name ".$args{name},0);

# CGI
	main::_log("App::540::file::new : file ".$args{file},0);
	my $cgi_file = $main::CGI->param($args{file});
	my $fileinfo=CGI::uploadInfo($cgi_file);
	main::_log("App::540::file::new : fileinfo ".$fileinfo,0);
	my $tmpfilename = $main::CGI->tmpFileName($cgi_file);
	main::_log("App::540::file::new : TMP ".$tmpfilename,0);
	delete $args{file};

# Generate hash
	$args{hash}=Utils::vars::genhash(16) if not exists $args{hash};
	while ( scalar(get(hash=>$args{hash})) == 1 )
	{
		$args{hash}=Utils::vars::genhash(16)
	}
	$args{table}="a540";

# Time
	$args{'time'} = $main::time_current if not exists $args{'time'};

# Default user
	$args{owner} = $main::USRM{IDhash} if not exists $args{owner};

# Get Filesize
	$args{size} = (stat($tmpfilename))[7];

# In mime was not specified ... guess.
	if ($args{mime} eq "auto" )
	{
		my $type = File::Type->new();
		$args{mime} = $type->checktype_filename( $tmpfilename );
	}

# Check ID_dir for existence
	if ($args{ID_dir} ne "")
	{
		if (scalar(App::540::dir::get(ID_dir=>$args{ID_dir})) == 0 )
		{
			main::_log("App::540::file::new : Adresár s daným 'ID_dir' (".$args{ID_dir}.") neexistuje");
			return -1;
		}
	}

# SQL Insert
	my $id = App::540::sql_insert( %args );

# Failed
	if ($id < 0)
	{
		main::_log("App::540::file::new : SQL insert failed",1);
		return -2;
	}
	main::_log("App::540::file::new : File inserted ID: $id",0);

# Prepare filename
	my $zero_id = sprintf ('%07d', $id);
	$zero_id=~/^(....)/i;
	my $dir = "../!media/540/$1";
# Make directory
	mkdir("../!media/540");
	mkdir($dir);
	my $filename = "$dir/$args{hash}";

# Save file
	use File::Copy;
	if (!copy($tmpfilename,$filename))
	{
		main::_log("App::540::file::new : Cannot copy $tmpfilename to $filename!",1);
		del($id);
		return -3;
	}
	chmod(0770,$filename);
	main::_log("App::540::file::new : File $tmpfilename saved as $filename",0);
	return $id;
}


sub dup
{
	my %args = @_;

# ID only DUP
 	if (@_==1)
{
 		$args{ID}=shift;
}
# Check required arguments
	if (not exists $args{ID})
{
		main::_log("App::540::file::dup : Treba predať 'ID' súboru ktorý sa má duplikovať",1);
		return -1;
}

# GET original file
	my @files = get($args{ID});
	my $size = scalar( @files );
	if ($size == 0 )
{
	main::_log("App::540::file::dup : subor s ID=".$args{ID}." neexistuje",0);
	return -1;
}
# Merge updates
	foreach my $key (keys %{$files[0]})
{
		my $value = $files[0]{$key};
		$args{$key} = $value if (not exists $args{$key});
		main::_log("App::540::file::dup : Key: ".$key." Val:".$value,0);
}
	delete ($args{ID});
	delete ($args{fullpath});


# Name Fix
	main::_log("App::540::file::dup : original name ".$args{name},0);
	$args{name} = basename($args{name});
	fileparse_set_fstype("MSWin32"); # MicroSoft Stupidity Fix
	$args{name} = basename($args{name});
	main::_log("App::540::file::dup : base name ".$args{name},0);

# DB
	$args{table}="a540";

# Check ID_dir for existence
	if ($args{ID_dir} ne "")
	{
		if (scalar(App::540::dir::get(ID_dir=>$args{ID_dir})) == 0 )
		{
			main::_log("App::540::file::new : Adresár s daným 'ID_dir' (".$args{ID_dir}.") neexistuje");
			return -1;
		}
	}

# SQL Insert
	my $id = App::540::sql_insert( %args );

# Failed
	if ($id < 0)
{
		main::_log("App::540::file::dup : SQL insert failed",1);
		return -2;
}
	main::_log("App::540::file::dup : File duplicated ID: $id",0);
	return $id;
}
1;

sub set
{
	my %args = @_;

# ID only DUP
 	if (@_==1)
{
		main::_log("App::540::file::set : Argumenty musia byť v tvare hashu",1);
		return -1;
}
# Check required arguments
	if (not exists $args{ID})
{
		main::_log("App::540::file::set : Treba predať 'ID' súboru",1);
		return -1;
}

# GET original file
	my @files = get($args{ID});
	my $size = scalar( @files );
	if ($size == 0 )
{
	main::_log("App::540::file::set : subor s ID=".$args{ID}." neexistuje",0);
	return -1;
}
# Merge updates
	foreach my $key (keys %{$files[0]})
{
		my $value = $files[0]{$key};
		$args{$key} = $value if (not exists $args{$key});
}
	delete ($args{fullpath});


# Name Fix
	main::_log("App::540::file::set : original name ".$args{name},0);
	$args{name} = basename($args{name});
	fileparse_set_fstype("MSWin32"); # MicroSoft Stupidity Fix
	$args{name} = basename($args{name});
	main::_log("App::540::file::set : base name ".$args{name},0);

# DB
	$args{table}="a540";

# Check ID_dir for existence
	if ($args{ID_dir} ne "")
	{
		if (scalar(App::540::dir::get(ID_dir=>$args{ID_dir})) == 0 )
		{
			main::_log("App::540::file::new : Adresár s daným 'ID_dir' (".$args{ID_dir}.") neexistuje");
			return -1;
		}
	}

# SQL Insert
	my $id = App::540::sql_insert( %args );

# Failed
	if ($id < 0)
{
		main::_log("App::540::file::set : SQL insert failed",1);
		return -2;
}
	main::_log("App::540::file::set : Updated ID: $id",0);
	return $id;
}
1;
