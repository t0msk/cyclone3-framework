package TOM::Temp::file;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use TOM;
use TOM::Utils::vars;


sub new
{
	my $class=shift;
	my $self={};
	my %env=@_;
	
	my $file_notexists=1;
	while ($file_notexists)
	{
		$self->{'unique'}=$$.'-'.TOM::Utils::vars::genhash(32);
		
		if ($env{'dir'})
		{
			$self->{'filename'}=$env{'dir'}.'/Cyclone3TMP-'.$self->{'unique'};
		}
		else
		{
			$self->{'filename'}=$TOM::P.'/_temp/tmp-'.$self->{'unique'};	
		}
		
		$self->{'filename'}.='.'.$env{'ext'} if $env{'ext'};
		$self->{'unlink_ext'}=$env{'unlink_ext'} if $env{'unlink_ext'};
		$self->{'unlink'}=1;
		
		$file_notexists=0;
		if (-e $self->{'filename'})
		{
			$file_notexists=1;
		}
	}
	
	main::_log("opened tempfile $self->{'filename'}");
	
	if (!$env{'nocreate'})
	{
		main::_log("create temp file ".$self->{'filename'});
		open(HND_CNT,'>'.$self->{'filename'});binmode HND_CNT;close(HND_CNT);
		chmod 0666, $self->{'filename'};
	}
	
	return bless $self, $class;
}


sub save_content
{
	my $self=shift;
	my $content=shift;
	
	open(HND_CNT,'>'.$self->{'filename'});
	binmode HND_CNT;
	
	if (ref($content))
	{
		print HND_CNT \$content;
	}
	else
	{
		main::_log("saving to file='$self->{'filename'}' content length='".(length($content))."'");
		print HND_CNT $content;
	}
	
	close (HND_CNT);
	
	$self->{'unlink'}=1;
	
	return 1;
}


sub DESTROY
{
	my $self=shift;
	
	if ($self->{'unlink'})
	{
		my $size=(stat $self->{'filename'})[7];
		if ($self->{'unlink_ext'} eq "*")
		{
			my $dir=($self->{'filename'}=~/^(.*\/)/)[0];
			opendir (DIR, $dir) || main::_log("$!",1);
			my $file=($self->{'filename'}=~/^.*\/(.*?)$/)[0];
#			main::_log("file $file");
			foreach (grep {$_=~/^$file/} readdir DIR)
			{
				main::_log("destroying tempfile $dir$_");
				unlink $dir.$_ || main::_log("$!",1);
#				main::_log("unlink $_");
			}
		}
		elsif ($self->{'unlink_ext'})
		{
			unlink $self->{'filename'}.$self->{'unlink_ext'};
		}
		if (-e $self->{'filename'})
		{
			main::_log("destroying tempfile $self->{'filename'} size=".$size."b");
			unlink $self->{'filename'};
		}
	}
	
	return undef;
}

1;