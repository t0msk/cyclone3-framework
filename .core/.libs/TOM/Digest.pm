package TOM::Digest;

=head1 NAME

TOM::Digest

=head1 DESCRIPTION

Access to digest alg.

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
use Encode;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our $murmur;
our $md5;

BEGIN
{
	eval {require Digest::MurmurHash;};
	if (!$@)
	{
		main::_log("<={LIB} Digest::MurmurHash");
		$murmur=1;
	}
	else
	{
		main::_log("<={LIB} Digest::MurmurHash not found",1);
		eval {require Digest::MD5;};
		if (!$@)
		{
			main::_log("<={LIB} Digest::MD5");
			$md5=1;
		};
	}
};

sub hash
{
	if ($murmur)
	{
		return Digest::MurmurHash::murmur_hash(shift);
	}
	elsif ($md5)
	{
		return Digest::MD5::md5_hex(Encode::encode_utf8(shift));
	}
}

1;
