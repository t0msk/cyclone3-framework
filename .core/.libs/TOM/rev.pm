package TOM::rev;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our $repository='http://svn.cyclone3.org/trunk/frame';
our $stablefile='http://svn.cyclone3.org/helpers/stable';

#neskor zistovanie verzie pomocou dostupnych SVN kniznic
#use SVN::Core;
#use SVN::Repos;
#use SVN::Fs;

our $svn_info=`/usr/local/bin/svn info $TOM::P/.core` || `/usr/bin/svn info $TOM::P/.core`;

if ($svn_info=~/Revision: (\d+)/)
{
	$TOM::core_revision=$1;
	if ($svn_info=~/Last Changed Date: (\d\d\d\d)-(\d\d)-(\d\d)/)
	{
		$TOM::core_build=$1.$2.$3;
	}
	
	main::_log("SVN Revision='$TOM::core_revision' Date='$TOM::core_build'");
}



sub get_last_stable_revision
{
	my $ctx = new SVN::Client();
	my $tmp_file=new TOM::Temp::file();
	open(HNDF,'>'.$tmp_file->{'filename'});
	eval {$ctx->cat(\*HNDF, $TOM::rev::stablefile, 'HEAD')};
	if ($@){return 1;}
	open(HNDF,'<'.$tmp_file->{'filename'});
	my $data;
	do
	{
		local $/;
		$data=<HNDF>;
	};
	$data=~/Cyclone3 Framework:(.*?):(.*)/;
	return $2;
}

sub get_uri_content
{
	my $uri=shift;
	return undef unless $uri;
	
	my $ctx = new SVN::Client();
	my $tmp_file=new TOM::Temp::file();
	open(HNDF,'>'.$tmp_file->{'filename'});
	eval {$ctx->cat(\*HNDF, $uri, 'HEAD')};
	if ($@){return 1;}
	open(HNDF,'<'.$tmp_file->{'filename'});
	my $data;
	do
	{
		local $/;
		$data=<HNDF>;
	};
	chomp($data);
	return $data;
}

1;
