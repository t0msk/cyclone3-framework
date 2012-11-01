
package Google::Ads::AdWords::v201206::ConversionTrackerService::mutateResponse;
use strict;
use warnings;

{ # BLOCK to scope variables

sub get_xmlns { 'https://adwords.google.com/api/adwords/cm/v201206' }

__PACKAGE__->__set_name('mutateResponse');
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

my %rval_of :ATTR(:get<rval>);

__PACKAGE__->_factory(
    [ qw(        rval

    ) ],
    {
        'rval' => \%rval_of,
    },
    {
        'rval' => 'Google::Ads::AdWords::v201206::ConversionTrackerReturnValue',
    },
    {

        'rval' => 'rval',
    }
);

} # end BLOCK






} # end of BLOCK



1;


=pod

=head1 NAME

Google::Ads::AdWords::v201206::ConversionTrackerService::mutateResponse

=head1 DESCRIPTION

Perl data type class for the XML Schema defined element
mutateResponse from the namespace https://adwords.google.com/api/adwords/cm/v201206.







=head1 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * rval

 $element->set_rval($data);
 $element->get_rval();





=back


=head1 METHODS

=head2 new

 my $element = Google::Ads::AdWords::v201206::ConversionTrackerService::mutateResponse->new($data);

Constructor. The following data structure may be passed to new():

 {
   rval =>  $a_reference_to, # see Google::Ads::AdWords::v201206::ConversionTrackerReturnValue
 },

=head1 AUTHOR

Generated by SOAP::WSDL

=cut
