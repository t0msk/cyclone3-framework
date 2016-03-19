package TOM::rev;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

our $git_lib;
BEGIN {
	eval{main::_log("<={LIB} ".__PACKAGE__);};
	eval{require Git;$git_lib=1};
}

if ($git_lib)
{
	my $repo = Git->repository('Directory' => $TOM::P);
	my $command=$repo->command('log','--format=%h:%cd','--date=short','-n'=>'1',$TOM::P);chomp($command);
	if ($command=~/^(.*?):(\d\d\d\d)-(\d\d)-(\d\d)$/)
	{
		$TOM::core_version=$2.".".$3.".".$4;
		$TOM::core_revision=$1;
		main::_log("Cyclone3 GIT Date='$TOM::core_version' Revision='$TOM::core_revision'");
	}
}

sub get_last_stable_revision
{
	
}

sub get_uri_content
{
	
}

1;
