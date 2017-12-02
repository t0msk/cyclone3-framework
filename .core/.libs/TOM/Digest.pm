package TOM::Digest;

=head1 NAME

TOM::Digest

=head1 DESCRIPTION

Access to digest alg.

=cut

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
use Encode;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our $sha;
our $sha1;
#our $murmur;
our $md5;

BEGIN
{
	eval {require Digest::SHA;};
	if (!$@)
	{
		main::_log("<={LIB} Digest::SHA");
		$sha=1;
	}
	else
	{
		eval {require Digest::SHA1;};
		if (!$@)
		{
			main::_log("<={LIB} Digest::SHA1");
			$sha1=1;
		}
		else
		{
			main::_log("<={LIB} Digest::SHA1 not found",1);
			eval {require Digest::MD5;};
			if (!$@)
			{
				main::_log("<={LIB} Digest::MD5");
				$md5=1;
			};
		}
	}
};

sub hash
{
	if ($sha)
	{
		return length($_[0]).'.'.Digest::SHA::sha256_hex(Encode::encode_utf8(shift));
	}
	elsif ($sha1)
	{
		return length($_[0]).'.'.Digest::SHA1::sha1_hex(Encode::encode_utf8(shift));
	}
	elsif ($md5)
	{
		return length($_[0]).'.'.Digest::MD5::md5_hex(Encode::encode_utf8(shift));
	}
}

1;
