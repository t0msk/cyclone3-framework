package Template::Plugin::Digest::SHA;

use strict;
use vars qw($VERSION);

$VERSION = 0.03;

use base qw(Template::Plugin);
use Template::Plugin;
use Template::Stash;
use Digest::SHA qw(hmac_sha1_hex hmac_sha256_hex); 

#$Template::Stash::SCALAR_OPS->{'md5'} = \&_md5;
#$Template::Stash::SCALAR_OPS->{'md5_hex'} = \&_md5_hex;
#$Template::Stash::SCALAR_OPS->{'md5_base64'} = \&_md5_base64;

sub new {
	my ($class, $context, $options) = @_;
	
	# now define the filter and return the plugin
	$context->define_filter('hmac_sha1_hex', [\&_hmac_sha1_hex => 1]);
	$context->define_filter('hmac_sha256_hex', [\&_hmac_sha256_hex => 1]);
	
	return bless {}, $class;
}


sub _hmac_sha1_hex {
	my ($context, @args) = @_;
	return sub {
		my $text = shift;
		hmac_sha1_hex($text, $args[0]);
	}
}

sub _hmac_sha256_hex {
	my ($context, @args) = @_;
	return sub {
		my $text = shift;
		hmac_sha256_hex($text, $args[0]);
	}
}

1;
