package TOM::Engine::pub::IAdm;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

=head1 NAME

TOM::Engine::pub::IAdm

=cut

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use TOM::Utils::vars;

=head1 DESCRIPTION

This library maintained handling for special mode of webpage browsing named admin mode (IAdm) and test mode (ITst)

When library is loaded, IAdm in /www/TOM/_config and ITast in domain directory is automatically created ( when not exists ).

=cut

BEGIN
{
	# kontrola ci dana instalacia ma vytvoreny IAdm a ITst kluce
#	if (not -e $TOM::P.'/_config/IAdm.key')
#	{
#		main::_log("generating IAdm.key");
#		my $key=TOM::Utils::vars::genhash(512);
#		open(HND,'>'.$TOM::P.'/_config/IAdm.key');# || die "$!";
#		print HND $key;
#		close (HND);
#	}
	
#	if (not -e $tom::P.'/ITst.key')
#	{
#		main::_log("generating ITst.key");
#		my $key=TOM::Utils::vars::genhash(512);
#		open(HND,'>'.$tom::P.'/ITst.key');# || die "$!";
#		print HND $key;
#		close (HND);
#	}
	
}

=head1 FUNCTIONS

=head2 load()

Load ( if possible ) required keys for IAdm and ITst.

=cut

sub load
{
	# nacitanie ITsd a IAdm klucov
	main::_log("loading IAdm.key");
	if (open (KEY,"<".$tom::P."/IAdm.key")
		|| open (KEY,"<".$tom::Pm."/IAdm.key")
		|| open (KEY,"<".$TOM::P."/_config/IAdm.key")
		)
	{
		local $/;
		$TOM::IAdm_key=<KEY>;
		close(KEY);
	}
	
	main::_log("loading ITst.key");
	if (open (KEY,"<".$tom::P."/ITst.key")
		|| open (KEY,"<".$tom::Pm."/ITst.key")
		|| open (KEY,"<".$TOM::P."/_config/ITst.key")
		)
	{
		local $/;
		$TOM::ITst_key=<KEY>;
		close(KEY);
	}
}

1;
