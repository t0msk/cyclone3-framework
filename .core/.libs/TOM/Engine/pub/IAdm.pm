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

Knižnica zabezpečuje obsluhu IAdm módu a IAdm kľúča v publisheri (+ITst)

=cut

BEGIN
{
	# kontrola ci dana instalacia ma vytvoreny IAdm a ITst kluce
	if (not -e $TOM::P.'/_config/IAdm.key')
	{
		main::_log("generating IAdm.key");
		my $key=TOM::Utils::vars::genhash(2048);
		open(HND,'>'.$TOM::P.'/_config/IAdm.key') || die "$!";
		print HND $key;
		close (HND);
	}
	
	if (not -e $TOM::P.'/_config/ITst.key')
	{
		main::_log("generating ITst.key");
		my $key=TOM::Utils::vars::genhash(2048);
		open(HND,'>'.$TOM::P.'/_config/ITst.key') || die "$!";
		print HND $key;
		close (HND);
	}
	
}

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
