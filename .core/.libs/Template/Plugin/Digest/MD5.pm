package Template::Plugin::Digest::MD5;

use strict;
use vars qw($VERSION);

$VERSION = 0.03;

use base qw(Template::Plugin);
use Template::Plugin;
use Template::Stash;
use Digest::MD5 qw(md5 md5_hex md5_base64);

$Template::Stash::SCALAR_OPS->{'md5'} = \&_md5;
$Template::Stash::SCALAR_OPS->{'md5_hex'} = \&_md5_hex;
$Template::Stash::SCALAR_OPS->{'md5_base64'} = \&_md5_base64;

sub new {
    my ($class, $context, $options) = @_;

    # now define the filter and return the plugin
    $context->define_filter('md5',    \&_md5);
    $context->define_filter('md5_hex',    \&_md5_hex);
    $context->define_filter('md5_base64', \&_md5_base64);
    return bless {}, $class;
}


sub _md5 {
    my $options = ref $_[-1] eq 'HASH' ? pop : { };
    return md5(join('', @_));
}

sub _md5_hex {
    my $options = ref $_[-1] eq 'HASH' ? pop : { };
    return md5_hex(join('', @_));
}

sub _md5_base64 {
    my $options = ref $_[-1] eq 'HASH' ? pop : { };
    return md5_base64(join('', @_));
}



1;
__END__



=head1 NAME

Template::Plugin::Digest::MD5 - TT2 interface to the MD5 Algorithm

=head1 SYNOPSIS

  [% USE Digest.MD5 -%]
  [% checksum = content FILTER md5 -%]
  [% checksum = content FILTER md5_hex -%]
  [% checksum = content FILTER md5_base64 -%]
  [% checksum = content.md5 -%]
  [% checksum = content.md5_hex -%]
  [% checksum = content.md5_base64 -%]

=head1 DESCRIPTION

The I<Digest.MD5> Template Toolkit plugin provides access to the MD5
algorithm via the C<Digest::MD5> module.  It is used like a plugin but
installs filters and vmethods into the current context.

When you invoke

    [% USE Digest.MD5 %]

the following filters (and vmethods of the same name) are installed
into the current context:

=over 4

=item C<md5>

Calculate the MD5 digest of the input, and return it in binary form.
The returned string will be 16 bytes long.

=item C<md5_hex>

Same as C<md5>, but will return the digest in hexadecimal form. The
length of the returned string will be 32 and it will only contain
characters from this set: '0'..'9' and 'a'..'f'.

=item C<md5_base64>

Same as C<md5>, but will return the digest as a base64 encoded
string.  The length of the returned string will be 22 and it will
only contain characters from this set: 'A'..'Z', 'a'..'z',
'0'..'9', '+' and '/'.

Note that the base64 encoded string returned is not padded to be a
multiple of 4 bytes long.  If you want interoperability with other
base64 encoded md5 digests you might want to append the redundant
string "==" to the result.

=back

As the filters are also available as vmethods the following are all
equivalent:

    FILTER md5_hex; content; END;
    content FILTER md5_hex;
    content.md5_base64;



=head1 WARNING

The L<Digest::MD5> man page notes that the MD5 algorithm is not as
strong as it used to be.  It has since 2005 been easy to generate
different messages that produce the same MD5 digest.  It still seems
hard to generate messages that produce a given digest, but it is
probably wise to move to stronger algorithms for applications that
depend on the digest to uniquely identify a message.


=head1 AUTHOR

Andrew Ford E<lt>A.Ford@ford-mason.co.ukE<gt>

Thanks to Darren Chamberlain for a patch for vmethod support.

=head1 COPYRIGHT

Copyright (C) 2006 Andrew Ford.  All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

C<Digest::MD5>, L<Template>

=cut 
