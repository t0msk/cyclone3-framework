package TOM::Utils::datetime;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


sub mail_current
{
	my $date=`date "+%a,%e %b %Y %H:%M:%S %z (%Z)"`;
	$date=~s|[\n\r]||g;
	return $date;
}


1;
