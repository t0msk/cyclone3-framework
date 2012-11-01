
package Google::Ads::AdWords::v201206::MediaService::upload;
use strict;
use warnings;

{ # BLOCK to scope variables

sub get_xmlns { 'https://adwords.google.com/api/adwords/cm/v201206' }

__PACKAGE__->__set_name('upload');
__PACKAGE__->__set_nillable();
__PACKAGE__->__set_minOccurs();
__PACKAGE__->__set_maxOccurs();
__PACKAGE__->__set_ref();

use base qw(
    SOAP::WSDL::XSD::Typelib::Element
    SOAP::WSDL::XSD::Typelib::ComplexType
);

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %media_of :ATTR(:get<media>);

__PACKAGE__->_factory(
    [ qw(        media

    ) ],
    {
        'media' => \%media_of,
    },
    {
        'media' => 'Google::Ads::AdWords::v201206::Media',
    },
    {

        'media' => 'media',
    }
);

} # end BLOCK






} # end of BLOCK



1;


=pod

=head1 NAME

Google::Ads::AdWords::v201206::MediaService::upload

=head1 DESCRIPTION

Perl data type class for the XML Schema defined element
upload from the namespace https://adwords.google.com/api/adwords/cm/v201206.

Uploads new media. Currently, you can only upload {@link Image} files. @param media A list of {@code Media} objects, each containing the data to be uploaded. @return A list of uploaded media in the same order as the argument list. 





=head1 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * media

 $element->set_media($data);
 $element->get_media();





=back


=head1 METHODS

=head2 new

 my $element = Google::Ads::AdWords::v201206::MediaService::upload->new($data);

Constructor. The following data structure may be passed to new():

 {
   media =>  $a_reference_to, # see Google::Ads::AdWords::v201206::Media
 },

=head1 AUTHOR

Generated by SOAP::WSDL

=cut
