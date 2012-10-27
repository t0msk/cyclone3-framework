package Google::Ads::AdWords::v201109::AdWordsConversionTracker;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/cm/v201109' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}


use base qw(Google::Ads::AdWords::v201109::ConversionTracker);
# Variety: sequence
use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %id_of :ATTR(:get<id>);
my %name_of :ATTR(:get<name>);
my %status_of :ATTR(:get<status>);
my %category_of :ATTR(:get<category>);
my %stats_of :ATTR(:get<stats>);
my %viewthroughLookbackWindow_of :ATTR(:get<viewthroughLookbackWindow>);
my %viewthroughConversionDeDupSearch_of :ATTR(:get<viewthroughConversionDeDupSearch>);
my %isProductAdsChargeable_of :ATTR(:get<isProductAdsChargeable>);
my %productAdsChargeableConversionWindow_of :ATTR(:get<productAdsChargeableConversionWindow>);
my %ConversionTracker__Type_of :ATTR(:get<ConversionTracker__Type>);
my %snippet_of :ATTR(:get<snippet>);
my %markupLanguage_of :ATTR(:get<markupLanguage>);
my %httpProtocol_of :ATTR(:get<httpProtocol>);
my %textFormat_of :ATTR(:get<textFormat>);
my %conversionPageLanguage_of :ATTR(:get<conversionPageLanguage>);
my %backgroundColor_of :ATTR(:get<backgroundColor>);
my %userRevenueValue_of :ATTR(:get<userRevenueValue>);

__PACKAGE__->_factory(
    [ qw(        id
        name
        status
        category
        stats
        viewthroughLookbackWindow
        viewthroughConversionDeDupSearch
        isProductAdsChargeable
        productAdsChargeableConversionWindow
        ConversionTracker__Type
        snippet
        markupLanguage
        httpProtocol
        textFormat
        conversionPageLanguage
        backgroundColor
        userRevenueValue

    ) ],
    {
        'id' => \%id_of,
        'name' => \%name_of,
        'status' => \%status_of,
        'category' => \%category_of,
        'stats' => \%stats_of,
        'viewthroughLookbackWindow' => \%viewthroughLookbackWindow_of,
        'viewthroughConversionDeDupSearch' => \%viewthroughConversionDeDupSearch_of,
        'isProductAdsChargeable' => \%isProductAdsChargeable_of,
        'productAdsChargeableConversionWindow' => \%productAdsChargeableConversionWindow_of,
        'ConversionTracker__Type' => \%ConversionTracker__Type_of,
        'snippet' => \%snippet_of,
        'markupLanguage' => \%markupLanguage_of,
        'httpProtocol' => \%httpProtocol_of,
        'textFormat' => \%textFormat_of,
        'conversionPageLanguage' => \%conversionPageLanguage_of,
        'backgroundColor' => \%backgroundColor_of,
        'userRevenueValue' => \%userRevenueValue_of,
    },
    {
        'id' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'name' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'status' => 'Google::Ads::AdWords::v201109::ConversionTracker::Status',
        'category' => 'Google::Ads::AdWords::v201109::ConversionTracker::Category',
        'stats' => 'Google::Ads::AdWords::v201109::ConversionTrackerStats',
        'viewthroughLookbackWindow' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
        'viewthroughConversionDeDupSearch' => 'SOAP::WSDL::XSD::Typelib::Builtin::boolean',
        'isProductAdsChargeable' => 'SOAP::WSDL::XSD::Typelib::Builtin::boolean',
        'productAdsChargeableConversionWindow' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
        'ConversionTracker__Type' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'snippet' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'markupLanguage' => 'Google::Ads::AdWords::v201109::AdWordsConversionTracker::MarkupLanguage',
        'httpProtocol' => 'Google::Ads::AdWords::v201109::AdWordsConversionTracker::HttpProtocol',
        'textFormat' => 'Google::Ads::AdWords::v201109::AdWordsConversionTracker::TextFormat',
        'conversionPageLanguage' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'backgroundColor' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'userRevenueValue' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    },
    {

        'id' => 'id',
        'name' => 'name',
        'status' => 'status',
        'category' => 'category',
        'stats' => 'stats',
        'viewthroughLookbackWindow' => 'viewthroughLookbackWindow',
        'viewthroughConversionDeDupSearch' => 'viewthroughConversionDeDupSearch',
        'isProductAdsChargeable' => 'isProductAdsChargeable',
        'productAdsChargeableConversionWindow' => 'productAdsChargeableConversionWindow',
        'ConversionTracker__Type' => 'ConversionTracker.Type',
        'snippet' => 'snippet',
        'markupLanguage' => 'markupLanguage',
        'httpProtocol' => 'httpProtocol',
        'textFormat' => 'textFormat',
        'conversionPageLanguage' => 'conversionPageLanguage',
        'backgroundColor' => 'backgroundColor',
        'userRevenueValue' => 'userRevenueValue',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201109::AdWordsConversionTracker

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
AdWordsConversionTracker from the namespace https://adwords.google.com/api/adwords/cm/v201109.

A conversion tracker created through AdWords Conversion Tracking. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * snippet


=item * markupLanguage


=item * httpProtocol


=item * textFormat


=item * conversionPageLanguage


=item * backgroundColor


=item * userRevenueValue




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::v201109::AdWordsConversionTracker
   snippet =>  $some_value, # string
   markupLanguage => $some_value, # AdWordsConversionTracker.MarkupLanguage
   httpProtocol => $some_value, # AdWordsConversionTracker.HttpProtocol
   textFormat => $some_value, # AdWordsConversionTracker.TextFormat
   conversionPageLanguage =>  $some_value, # string
   backgroundColor =>  $some_value, # string
   userRevenueValue =>  $some_value, # string
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

