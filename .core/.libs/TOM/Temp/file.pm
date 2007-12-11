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
	
	loop_file:
	
	$self->{'unique'}=TOM::Utils::vars::genhash(32);
	$self->{'filename'}=$TOM::P.'/_temp/tmp-'.$self->{'unique'};
	$self->{'filename'}.='.'.$env{'ext'} if $env{'ext'};
	$self->{'unlink'}=1;
	
	if (-e $self->{'filename'}){goto loop_file;}
	
	main::_log("opened tempfile $self->{'filename'}");
	
	open(HND_CNT,'>'.$self->{'filename'});binmode HND_CNT;close(HND_CNT);
	
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
		main::_log("destroying tempfile $self->{'filename'} (if exists)");
		unlink $self->{'filename'};
	}
	
	return undef;
}

1;