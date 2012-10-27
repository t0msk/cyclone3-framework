package Google::Ads::AdWords::v201109_1::Operand;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/cm/v201109_1' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %AdExtensionOverride_of :ATTR(:get<AdExtensionOverride>);
my %AdGroupAd_of :ATTR(:get<AdGroupAd>);
my %AdGroupCriterion_of :ATTR(:get<AdGroupCriterion>);
my %AdGroup_of :ATTR(:get<AdGroup>);
my %Ad_of :ATTR(:get<Ad>);
my %Budget_of :ATTR(:get<Budget>);
my %CampaignAdExtension_of :ATTR(:get<CampaignAdExtension>);
my %CampaignCriterion_of :ATTR(:get<CampaignCriterion>);
my %Campaign_of :ATTR(:get<Campaign>);
my %Job_of :ATTR(:get<Job>);
my %Media_of :ATTR(:get<Media>);
my %PlaceHolder_of :ATTR(:get<PlaceHolder>);
my %TargetList_of :ATTR(:get<TargetList>);
my %Target_of :ATTR(:get<Target>);

__PACKAGE__->_factory(
    [ qw(        AdExtensionOverride
        AdGroupAd
        AdGroupCriterion
        AdGroup
        Ad
        Budget
        CampaignAdExtension
        CampaignCriterion
        Campaign
        Job
        Media
        PlaceHolder
        TargetList
        Target

    ) ],
    {
        'AdExtensionOverride' => \%AdExtensionOverride_of,
        'AdGroupAd' => \%AdGroupAd_of,
        'AdGroupCriterion' => \%AdGroupCriterion_of,
        'AdGroup' => \%AdGroup_of,
        'Ad' => \%Ad_of,
        'Budget' => \%Budget_of,
        'CampaignAdExtension' => \%CampaignAdExtension_of,
        'CampaignCriterion' => \%CampaignCriterion_of,
        'Campaign' => \%Campaign_of,
        'Job' => \%Job_of,
        'Media' => \%Media_of,
        'PlaceHolder' => \%PlaceHolder_of,
        'TargetList' => \%TargetList_of,
        'Target' => \%Target_of,
    },
    {
        'AdExtensionOverride' => 'Google::Ads::AdWords::v201109_1::AdExtensionOverride',
        'AdGroupAd' => 'Google::Ads::AdWords::v201109_1::AdGroupAd',
        'AdGroupCriterion' => 'Google::Ads::AdWords::v201109_1::AdGroupCriterion',
        'AdGroup' => 'Google::Ads::AdWords::v201109_1::AdGroup',
        'Ad' => 'Google::Ads::AdWords::v201109_1::Ad',
        'Budget' => 'Google::Ads::AdWords::v201109_1::Budget',
        'CampaignAdExtension' => 'Google::Ads::AdWords::v201109_1::CampaignAdExtension',
        'CampaignCriterion' => 'Google::Ads::AdWords::v201109_1::CampaignCriterion',
        'Campaign' => 'Google::Ads::AdWords::v201109_1::Campaign',
        'Job' => 'Google::Ads::AdWords::v201109_1::Job',
        'Media' => 'Google::Ads::AdWords::v201109_1::Media',
        'PlaceHolder' => 'Google::Ads::AdWords::v201109_1::PlaceHolder',
        'TargetList' => 'Google::Ads::AdWords::v201109_1::TargetList',
        'Target' => 'Google::Ads::AdWords::v201109_1::Target',
    },
    {

        'AdExtensionOverride' => 'AdExtensionOverride',
        'AdGroupAd' => 'AdGroupAd',
        'AdGroupCriterion' => 'AdGroupCriterion',
        'AdGroup' => 'AdGroup',
        'Ad' => 'Ad',
        'Budget' => 'Budget',
        'CampaignAdExtension' => 'CampaignAdExtension',
        'CampaignCriterion' => 'CampaignCriterion',
        'Campaign' => 'Campaign',
        'Job' => 'Job',
        'Media' => 'Media',
        'PlaceHolder' => 'PlaceHolder',
        'TargetList' => 'TargetList',
        'Target' => 'Target',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201109_1::Operand

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
Operand from the namespace https://adwords.google.com/api/adwords/cm/v201109_1.

A marker interface for entities that can be operated upon in mutate operations. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * AdExtensionOverride


=item * AdGroupAd


=item * AdGroupCriterion


=item * AdGroup


=item * Ad


=item * Budget


=item * CampaignAdExtension


=item * CampaignCriterion


=item * Campaign


=item * Job


=item * Media


=item * PlaceHolder


=item * TargetList


=item * Target




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::v201109_1::Operand
   # One of the following elements.
   # No occurance checks yet, so be sure to pass just one...
   AdExtensionOverride =>  $a_reference_to, # see Google::Ads::AdWords::v201109_1::AdExtensionOverride
   AdGroupAd =>  $a_reference_to, # see Google::Ads::AdWords::v201109_1::AdGroupAd
   AdGroupCriterion =>  $a_reference_to, # see Google::Ads::AdWords::v201109_1::AdGroupCriterion
   AdGroup =>  $a_reference_to, # see Google::Ads::AdWords::v201109_1::AdGroup
   Ad =>  $a_reference_to, # see Google::Ads::AdWords::v201109_1::Ad
   Budget =>  $a_reference_to, # see Google::Ads::AdWords::v201109_1::Budget
   CampaignAdExtension =>  $a_reference_to, # see Google::Ads::AdWords::v201109_1::CampaignAdExtension
   CampaignCriterion =>  $a_reference_to, # see Google::Ads::AdWords::v201109_1::CampaignCriterion
   Campaign =>  $a_reference_to, # see Google::Ads::AdWords::v201109_1::Campaign
   Job =>  $a_reference_to, # see Google::Ads::AdWords::v201109_1::Job
   Media =>  $a_reference_to, # see Google::Ads::AdWords::v201109_1::Media
   PlaceHolder =>  $a_reference_to, # see Google::Ads::AdWords::v201109_1::PlaceHolder
   TargetList =>  $a_reference_to, # see Google::Ads::AdWords::v201109_1::TargetList
   Target =>  $a_reference_to, # see Google::Ads::AdWords::v201109_1::Target
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

