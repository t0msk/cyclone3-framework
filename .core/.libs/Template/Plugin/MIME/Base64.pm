package Template::Plugin::MIME::Base64;

use strict;
use vars qw($VERSION);

$VERSION = 0.03;

use base qw(Template::Plugin);
use Template::Plugin;
use Template::Stash;
use MIME::Base64;

#$Template::Stash::SCALAR_OPS->{'md5'} = \&_md5;
#$Template::Stash::SCALAR_OPS->{'md5_hex'} = \&_md5_hex;
#$Template::Stash::SCALAR_OPS->{'md5_base64'} = \&_md5_base64;

sub new {
	my ($class, $context, $options) = @_;
	
	# now define the filter and return the plugin
	$context->define_filter('encode_base64', [\&_encode_base64 => 1]);
	
	return bless {}, $class;
}


sub _encode_base64 {
	my ($context, @args) = @_;
	return sub {
		my $text = shift;
		encode_base64($text);
	}
}

1;
