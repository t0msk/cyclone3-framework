package TOM::rev;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

#neskor zistovanie verzie pomocou dostupnych SVN kniznic
#use SVN::Core;
#use SVN::Repos;
#use SVN::Fs;

our $svn_info=`/usr/lobal/bin/svn info $TOM::P/.core` || `/usr/bin/svn info $TOM::P/.core`;

if ($svn_info=~/Revision: (\d+)/)
{
	$TOM::core_revision=$1;
	if ($svn_info=~/Last Changed Date: (\d\d\d\d)-(\d\d)-(\d\d)/)
	{
		$TOM::core_build=$1.$2.$3;
	}
	
	main::_log("SVN Revision='$TOM::core_revision' Date='$TOM::core_build'");
}

1;
