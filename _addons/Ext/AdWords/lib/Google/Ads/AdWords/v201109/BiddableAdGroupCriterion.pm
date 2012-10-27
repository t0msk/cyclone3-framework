package Google::Ads::AdWords::v201109::BiddableAdGroupCriterion;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/cm/v201109' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}


use base qw(Google::Ads::AdWords::v201109::AdGroupCriterion);
# Variety: sequence
use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %adGroupId_of :ATTR(:get<adGroupId>);
my %criterionUse_of :ATTR(:get<criterionUse>);
my %criterion_of :ATTR(:get<criterion>);
my %AdGroupCriterion__Type_of :ATTR(:get<AdGroupCriterion__Type>);
my %userStatus_of :ATTR(:get<userStatus>);
my %systemServingStatus_of :ATTR(:get<systemServingStatus>);
my %approvalStatus_of :ATTR(:get<approvalStatus>);
my %destinationUrl_of :ATTR(:get<destinationUrl>);
my %bids_of :ATTR(:get<bids>);
my %experimentData_of :ATTR(:get<experimentData>);
my %firstPageCpc_of :ATTR(:get<firstPageCpc>);
my %qualityInfo_of :ATTR(:get<qualityInfo>);
my %stats_of :ATTR(:get<stats>);

__PACKAGE__->_factory(
    [ qw(        adGroupId
        criterionUse
        criterion
        AdGroupCriterion__Type
        userStatus
        systemServingStatus
        approvalStatus
        destinationUrl
        bids
        experimentData
        firstPageCpc
        qualityInfo
        stats

    ) ],
    {
        'adGroupId' => \%adGroupId_of,
        'criterionUse' => \%criterionUse_of,
        'criterion' => \%criterion_of,
        'AdGroupCriterion__Type' => \%AdGroupCriterion__Type_of,
        'userStatus' => \%userStatus_of,
        'systemServingStatus' => \%systemServingStatus_of,
        'approvalStatus' => \%approvalStatus_of,
        'destinationUrl' => \%destinationUrl_of,
        'bids' => \%bids_of,
        'experimentData' => \%experimentData_of,
        'firstPageCpc' => \%firstPageCpc_of,
        'qualityInfo' => \%qualityInfo_of,
        'stats' => \%stats_of,
    },
    {
        'adGroupId' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'criterionUse' => 'Google::Ads::AdWords::v201109::CriterionUse',
        'criterion' => 'Google::Ads::AdWords::v201109::Criterion',
        'AdGroupCriterion__Type' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'userStatus' => 'Google::Ads::AdWords::v201109::UserStatus',
        'systemServingStatus' => 'Google::Ads::AdWords::v201109::SystemServingStatus',
        'approvalStatus' => 'Google::Ads::AdWords::v201109::ApprovalStatus',
        'destinationUrl' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'bids' => 'Google::Ads::AdWords::v201109::AdGroupCriterionBids',
        'experimentData' => 'Google::Ads::AdWords::v201109::BiddableAdGroupCriterionExperimentData',
        'firstPageCpc' => 'Google::Ads::AdWords::v201109::Bid',
        'qualityInfo' => 'Google::Ads::AdWords::v201109::QualityInfo',
        'stats' => 'Google::Ads::AdWords::v201109::Stats',
    },
    {

        'adGroupId' => 'adGroupId',
        'criterionUse' => 'criterionUse',
        'criterion' => 'criterion',
        'AdGroupCriterion__Type' => 'AdGroupCriterion.Type',
        'userStatus' => 'userStatus',
        'systemServingStatus' => 'systemServingStatus',
        'approvalStatus' => 'approvalStatus',
        'destinationUrl' => 'destinationUrl',
        'bids' => 'bids',
        'experimentData' => 'experimentData',
        'firstPageCpc' => 'firstPageCpc',
        'qualityInfo' => 'qualityInfo',
        'stats' => 'stats',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201109::BiddableAdGroupCriterion

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
BiddableAdGroupCriterion from the namespace https://adwords.google.com/api/adwords/cm/v201109.

A biddable (positive) criterion in an adgroup. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * userStatus


=item * systemServingStatus


=item * approvalStatus


=item * destinationUrl


=item * bids


=item * experimentData


=item * firstPageCpc


=item * qualityInfo


=item * stats




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::v201109::BiddableAdGroupCriterion
   userStatus => $some_value, # UserStatus
   systemServingStatus => $some_value, # SystemServingStatus
   approvalStatus => $some_value, # ApprovalStatus
   destinationUrl =>  $some_value, # string
   bids =>  $a_reference_to, # see Google::Ads::AdWords::v201109::AdGroupCriterionBids
   experimentData =>  $a_reference_to, # see Google::Ads::AdWords::v201109::BiddableAdGroupCriterionExperimentData
   firstPageCpc =>  $a_reference_to, # see Google::Ads::AdWords::v201109::Bid
   qualityInfo =>  $a_reference_to, # see Google::Ads::AdWords::v201109::QualityInfo
   stats =>  $a_reference_to, # see Google::Ads::AdWords::v201109::Stats
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

