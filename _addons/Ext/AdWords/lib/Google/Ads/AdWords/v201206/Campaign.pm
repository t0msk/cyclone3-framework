package Google::Ads::AdWords::v201206::Campaign;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/cm/v201206' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %id_of :ATTR(:get<id>);
my %name_of :ATTR(:get<name>);
my %status_of :ATTR(:get<status>);
my %servingStatus_of :ATTR(:get<servingStatus>);
my %startDate_of :ATTR(:get<startDate>);
my %endDate_of :ATTR(:get<endDate>);
my %budget_of :ATTR(:get<budget>);
my %biddingStrategy_of :ATTR(:get<biddingStrategy>);
my %conversionOptimizerEligibility_of :ATTR(:get<conversionOptimizerEligibility>);
my %campaignStats_of :ATTR(:get<campaignStats>);
my %adServingOptimizationStatus_of :ATTR(:get<adServingOptimizationStatus>);
my %frequencyCap_of :ATTR(:get<frequencyCap>);
my %settings_of :ATTR(:get<settings>);
my %networkSetting_of :ATTR(:get<networkSetting>);
my %forwardCompatibilityMap_of :ATTR(:get<forwardCompatibilityMap>);

__PACKAGE__->_factory(
    [ qw(        id
        name
        status
        servingStatus
        startDate
        endDate
        budget
        biddingStrategy
        conversionOptimizerEligibility
        campaignStats
        adServingOptimizationStatus
        frequencyCap
        settings
        networkSetting
        forwardCompatibilityMap

    ) ],
    {
        'id' => \%id_of,
        'name' => \%name_of,
        'status' => \%status_of,
        'servingStatus' => \%servingStatus_of,
        'startDate' => \%startDate_of,
        'endDate' => \%endDate_of,
        'budget' => \%budget_of,
        'biddingStrategy' => \%biddingStrategy_of,
        'conversionOptimizerEligibility' => \%conversionOptimizerEligibility_of,
        'campaignStats' => \%campaignStats_of,
        'adServingOptimizationStatus' => \%adServingOptimizationStatus_of,
        'frequencyCap' => \%frequencyCap_of,
        'settings' => \%settings_of,
        'networkSetting' => \%networkSetting_of,
        'forwardCompatibilityMap' => \%forwardCompatibilityMap_of,
    },
    {
        'id' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'name' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'status' => 'Google::Ads::AdWords::v201206::CampaignStatus',
        'servingStatus' => 'Google::Ads::AdWords::v201206::ServingStatus',
        'startDate' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'endDate' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'budget' => 'Google::Ads::AdWords::v201206::Budget',
        'biddingStrategy' => 'Google::Ads::AdWords::v201206::BiddingStrategy',
        'conversionOptimizerEligibility' => 'Google::Ads::AdWords::v201206::ConversionOptimizerEligibility',
        'campaignStats' => 'Google::Ads::AdWords::v201206::CampaignStats',
        'adServingOptimizationStatus' => 'Google::Ads::AdWords::v201206::AdServingOptimizationStatus',
        'frequencyCap' => 'Google::Ads::AdWords::v201206::FrequencyCap',
        'settings' => 'Google::Ads::AdWords::v201206::Setting',
        'networkSetting' => 'Google::Ads::AdWords::v201206::NetworkSetting',
        'forwardCompatibilityMap' => 'Google::Ads::AdWords::v201206::String_StringMapEntry',
    },
    {

        'id' => 'id',
        'name' => 'name',
        'status' => 'status',
        'servingStatus' => 'servingStatus',
        'startDate' => 'startDate',
        'endDate' => 'endDate',
        'budget' => 'budget',
        'biddingStrategy' => 'biddingStrategy',
        'conversionOptimizerEligibility' => 'conversionOptimizerEligibility',
        'campaignStats' => 'campaignStats',
        'adServingOptimizationStatus' => 'adServingOptimizationStatus',
        'frequencyCap' => 'frequencyCap',
        'settings' => 'settings',
        'networkSetting' => 'networkSetting',
        'forwardCompatibilityMap' => 'forwardCompatibilityMap',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201206::Campaign

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
Campaign from the namespace https://adwords.google.com/api/adwords/cm/v201206.

Data representing an AdWords campaign. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * id


=item * name


=item * status


=item * servingStatus


=item * startDate


=item * endDate


=item * budget


=item * biddingStrategy


=item * conversionOptimizerEligibility


=item * campaignStats


=item * adServingOptimizationStatus


=item * frequencyCap


=item * settings


=item * networkSetting


=item * forwardCompatibilityMap




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::v201206::Campaign
   id =>  $some_value, # long
   name =>  $some_value, # string
   status => $some_value, # CampaignStatus
   servingStatus => $some_value, # ServingStatus
   startDate =>  $some_value, # string
   endDate =>  $some_value, # string
   budget =>  $a_reference_to, # see Google::Ads::AdWords::v201206::Budget
   biddingStrategy =>  $a_reference_to, # see Google::Ads::AdWords::v201206::BiddingStrategy
   conversionOptimizerEligibility =>  $a_reference_to, # see Google::Ads::AdWords::v201206::ConversionOptimizerEligibility
   campaignStats =>  $a_reference_to, # see Google::Ads::AdWords::v201206::CampaignStats
   adServingOptimizationStatus => $some_value, # AdServingOptimizationStatus
   frequencyCap =>  $a_reference_to, # see Google::Ads::AdWords::v201206::FrequencyCap
   settings =>  $a_reference_to, # see Google::Ads::AdWords::v201206::Setting
   networkSetting =>  $a_reference_to, # see Google::Ads::AdWords::v201206::NetworkSetting
   forwardCompatibilityMap =>  $a_reference_to, # see Google::Ads::AdWords::v201206::String_StringMapEntry
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

