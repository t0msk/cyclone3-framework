package TOM::Utils::datetime;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


sub mail_current
{
	my $date=`LC_TIME="en_US.UTF-8" date "+%a, %e %b %Y %H:%M:%S %z (%Z)"`;
	$date=~s|[\n\r]||g;
	return $date;
}


sub datetime_collapse
{
	my $datetime_string=shift;
	my %datetime;
	
	if ($datetime_string=~/^(\d+)\-(\d+)\-(\d+) (\d+):(\d+):(\d+)/)
	{
		$datetime{'year'}=$1;
		$datetime{'month'}=$2;
		$datetime{'mday'}=$3;
		
		$datetime{'hour'}=$4;
		$datetime{'min'}=$5;
		$datetime{'sec'}=$6;
	}
	elsif ($datetime_string=~/^(\d+)\-(\d+)\-(\d+) (\d+):(\d+)/)
	{
		$datetime{'year'}=$1;
		$datetime{'month'}=$2;
		$datetime{'mday'}=$3;
		
		$datetime{'hour'}=$4;
		$datetime{'min'}=$5;
	}
	elsif ($datetime_string=~/^(\d+)\-(\d+)\-(\d+)/)
	{
		$datetime{'year'}=$1;
		$datetime{'month'}=$2;
		$datetime{'mday'}=$3;
	}
	
	return %datetime;
}

1;
