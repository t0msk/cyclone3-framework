package Google::Ads::AdWords::v201109::ApiErrorReason;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/cm/v201109' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %AdErrorReason_of :ATTR(:get<AdErrorReason>);
my %AdExtensionErrorReason_of :ATTR(:get<AdExtensionErrorReason>);
my %AdExtensionOverrideErrorReason_of :ATTR(:get<AdExtensionOverrideErrorReason>);
my %AdGroupAdErrorReason_of :ATTR(:get<AdGroupAdErrorReason>);
my %AdGroupCriterionErrorReason_of :ATTR(:get<AdGroupCriterionErrorReason>);
my %AdGroupServiceErrorReason_of :ATTR(:get<AdGroupServiceErrorReason>);
my %AuthenticationErrorReason_of :ATTR(:get<AuthenticationErrorReason>);
my %AuthorizationErrorReason_of :ATTR(:get<AuthorizationErrorReason>);
my %BiddingErrorReason_of :ATTR(:get<BiddingErrorReason>);
my %BiddingTransitionErrorReason_of :ATTR(:get<BiddingTransitionErrorReason>);
my %BudgetErrorReason_of :ATTR(:get<BudgetErrorReason>);
my %BulkMutateJobErrorReason_of :ATTR(:get<BulkMutateJobErrorReason>);
my %CampaignAdExtensionErrorReason_of :ATTR(:get<CampaignAdExtensionErrorReason>);
my %CampaignCriterionErrorReason_of :ATTR(:get<CampaignCriterionErrorReason>);
my %CampaignErrorReason_of :ATTR(:get<CampaignErrorReason>);
my %ClientTermsErrorReason_of :ATTR(:get<ClientTermsErrorReason>);
my %CriterionErrorReason_of :ATTR(:get<CriterionErrorReason>);
my %DatabaseErrorReason_of :ATTR(:get<DatabaseErrorReason>);
my %DateErrorReason_of :ATTR(:get<DateErrorReason>);
my %DistinctErrorReason_of :ATTR(:get<DistinctErrorReason>);
my %EntityAccessDeniedReason_of :ATTR(:get<EntityAccessDeniedReason>);
my %EntityCountLimitExceededReason_of :ATTR(:get<EntityCountLimitExceededReason>);
my %EntityNotFoundReason_of :ATTR(:get<EntityNotFoundReason>);
my %IdErrorReason_of :ATTR(:get<IdErrorReason>);
my %ImageErrorReason_of :ATTR(:get<ImageErrorReason>);
my %InternalApiErrorReason_of :ATTR(:get<InternalApiErrorReason>);
my %JobErrorReason_of :ATTR(:get<JobErrorReason>);
my %MediaErrorReason_of :ATTR(:get<MediaErrorReason>);
my %NewEntityCreationErrorReason_of :ATTR(:get<NewEntityCreationErrorReason>);
my %NotEmptyErrorReason_of :ATTR(:get<NotEmptyErrorReason>);
my %NotWhitelistedErrorReason_of :ATTR(:get<NotWhitelistedErrorReason>);
my %NullErrorReason_of :ATTR(:get<NullErrorReason>);
my %OperationAccessDeniedReason_of :ATTR(:get<OperationAccessDeniedReason>);
my %OperatorErrorReason_of :ATTR(:get<OperatorErrorReason>);
my %PagingErrorReason_of :ATTR(:get<PagingErrorReason>);
my %PolicyViolationErrorReason_of :ATTR(:get<PolicyViolationErrorReason>);
my %QuotaCheckErrorReason_of :ATTR(:get<QuotaCheckErrorReason>);
my %QuotaErrorReason_of :ATTR(:get<QuotaErrorReason>);
my %RangeErrorReason_of :ATTR(:get<RangeErrorReason>);
my %RateExceededErrorReason_of :ATTR(:get<RateExceededErrorReason>);
my %ReadOnlyErrorReason_of :ATTR(:get<ReadOnlyErrorReason>);
my %RegionCodeErrorReason_of :ATTR(:get<RegionCodeErrorReason>);
my %RejectedErrorReason_of :ATTR(:get<RejectedErrorReason>);
my %RequestErrorReason_of :ATTR(:get<RequestErrorReason>);
my %RequiredErrorReason_of :ATTR(:get<RequiredErrorReason>);
my %SelectorErrorReason_of :ATTR(:get<SelectorErrorReason>);
my %SettingErrorReason_of :ATTR(:get<SettingErrorReason>);
my %SizeLimitErrorReason_of :ATTR(:get<SizeLimitErrorReason>);
my %StatsQueryErrorReason_of :ATTR(:get<StatsQueryErrorReason>);
my %StringLengthErrorReason_of :ATTR(:get<StringLengthErrorReason>);
my %TargetErrorReason_of :ATTR(:get<TargetErrorReason>);

__PACKAGE__->_factory(
    [ qw(        AdErrorReason
        AdExtensionErrorReason
        AdExtensionOverrideErrorReason
        AdGroupAdErrorReason
        AdGroupCriterionErrorReason
        AdGroupServiceErrorReason
        AuthenticationErrorReason
        AuthorizationErrorReason
        BiddingErrorReason
        BiddingTransitionErrorReason
        BudgetErrorReason
        BulkMutateJobErrorReason
        CampaignAdExtensionErrorReason
        CampaignCriterionErrorReason
        CampaignErrorReason
        ClientTermsErrorReason
        CriterionErrorReason
        DatabaseErrorReason
        DateErrorReason
        DistinctErrorReason
        EntityAccessDeniedReason
        EntityCountLimitExceededReason
        EntityNotFoundReason
        IdErrorReason
        ImageErrorReason
        InternalApiErrorReason
        JobErrorReason
        MediaErrorReason
        NewEntityCreationErrorReason
        NotEmptyErrorReason
        NotWhitelistedErrorReason
        NullErrorReason
        OperationAccessDeniedReason
        OperatorErrorReason
        PagingErrorReason
        PolicyViolationErrorReason
        QuotaCheckErrorReason
        QuotaErrorReason
        RangeErrorReason
        RateExceededErrorReason
        ReadOnlyErrorReason
        RegionCodeErrorReason
        RejectedErrorReason
        RequestErrorReason
        RequiredErrorReason
        SelectorErrorReason
        SettingErrorReason
        SizeLimitErrorReason
        StatsQueryErrorReason
        StringLengthErrorReason
        TargetErrorReason

    ) ],
    {
        'AdErrorReason' => \%AdErrorReason_of,
        'AdExtensionErrorReason' => \%AdExtensionErrorReason_of,
        'AdExtensionOverrideErrorReason' => \%AdExtensionOverrideErrorReason_of,
        'AdGroupAdErrorReason' => \%AdGroupAdErrorReason_of,
        'AdGroupCriterionErrorReason' => \%AdGroupCriterionErrorReason_of,
        'AdGroupServiceErrorReason' => \%AdGroupServiceErrorReason_of,
        'AuthenticationErrorReason' => \%AuthenticationErrorReason_of,
        'AuthorizationErrorReason' => \%AuthorizationErrorReason_of,
        'BiddingErrorReason' => \%BiddingErrorReason_of,
        'BiddingTransitionErrorReason' => \%BiddingTransitionErrorReason_of,
        'BudgetErrorReason' => \%BudgetErrorReason_of,
        'BulkMutateJobErrorReason' => \%BulkMutateJobErrorReason_of,
        'CampaignAdExtensionErrorReason' => \%CampaignAdExtensionErrorReason_of,
        'CampaignCriterionErrorReason' => \%CampaignCriterionErrorReason_of,
        'CampaignErrorReason' => \%CampaignErrorReason_of,
        'ClientTermsErrorReason' => \%ClientTermsErrorReason_of,
        'CriterionErrorReason' => \%CriterionErrorReason_of,
        'DatabaseErrorReason' => \%DatabaseErrorReason_of,
        'DateErrorReason' => \%DateErrorReason_of,
        'DistinctErrorReason' => \%DistinctErrorReason_of,
        'EntityAccessDeniedReason' => \%EntityAccessDeniedReason_of,
        'EntityCountLimitExceededReason' => \%EntityCountLimitExceededReason_of,
        'EntityNotFoundReason' => \%EntityNotFoundReason_of,
        'IdErrorReason' => \%IdErrorReason_of,
        'ImageErrorReason' => \%ImageErrorReason_of,
        'InternalApiErrorReason' => \%InternalApiErrorReason_of,
        'JobErrorReason' => \%JobErrorReason_of,
        'MediaErrorReason' => \%MediaErrorReason_of,
        'NewEntityCreationErrorReason' => \%NewEntityCreationErrorReason_of,
        'NotEmptyErrorReason' => \%NotEmptyErrorReason_of,
        'NotWhitelistedErrorReason' => \%NotWhitelistedErrorReason_of,
        'NullErrorReason' => \%NullErrorReason_of,
        'OperationAccessDeniedReason' => \%OperationAccessDeniedReason_of,
        'OperatorErrorReason' => \%OperatorErrorReason_of,
        'PagingErrorReason' => \%PagingErrorReason_of,
        'PolicyViolationErrorReason' => \%PolicyViolationErrorReason_of,
        'QuotaCheckErrorReason' => \%QuotaCheckErrorReason_of,
        'QuotaErrorReason' => \%QuotaErrorReason_of,
        'RangeErrorReason' => \%RangeErrorReason_of,
        'RateExceededErrorReason' => \%RateExceededErrorReason_of,
        'ReadOnlyErrorReason' => \%ReadOnlyErrorReason_of,
        'RegionCodeErrorReason' => \%RegionCodeErrorReason_of,
        'RejectedErrorReason' => \%RejectedErrorReason_of,
        'RequestErrorReason' => \%RequestErrorReason_of,
        'RequiredErrorReason' => \%RequiredErrorReason_of,
        'SelectorErrorReason' => \%SelectorErrorReason_of,
        'SettingErrorReason' => \%SettingErrorReason_of,
        'SizeLimitErrorReason' => \%SizeLimitErrorReason_of,
        'StatsQueryErrorReason' => \%StatsQueryErrorReason_of,
        'StringLengthErrorReason' => \%StringLengthErrorReason_of,
        'TargetErrorReason' => \%TargetErrorReason_of,
    },
    {
        'AdErrorReason' => 'Google::Ads::AdWords::v201109::AdError::Reason',
        'AdExtensionErrorReason' => 'Google::Ads::AdWords::v201109::AdExtensionError::Reason',
        'AdExtensionOverrideErrorReason' => 'Google::Ads::AdWords::v201109::AdExtensionOverrideError::Reason',
        'AdGroupAdErrorReason' => 'Google::Ads::AdWords::v201109::AdGroupAdError::Reason',
        'AdGroupCriterionErrorReason' => 'Google::Ads::AdWords::v201109::AdGroupCriterionError::Reason',
        'AdGroupServiceErrorReason' => 'Google::Ads::AdWords::v201109::AdGroupServiceError::Reason',
        'AuthenticationErrorReason' => 'Google::Ads::AdWords::v201109::AuthenticationError::Reason',
        'AuthorizationErrorReason' => 'Google::Ads::AdWords::v201109::AuthorizationError::Reason',
        'BiddingErrorReason' => 'Google::Ads::AdWords::v201109::BiddingError::Reason',
        'BiddingTransitionErrorReason' => 'Google::Ads::AdWords::v201109::BiddingTransitionError::Reason',
        'BudgetErrorReason' => 'Google::Ads::AdWords::v201109::BudgetError::Reason',
        'BulkMutateJobErrorReason' => 'Google::Ads::AdWords::v201109::BulkMutateJobError::Reason',
        'CampaignAdExtensionErrorReason' => 'Google::Ads::AdWords::v201109::CampaignAdExtensionError::Reason',
        'CampaignCriterionErrorReason' => 'Google::Ads::AdWords::v201109::CampaignCriterionError::Reason',
        'CampaignErrorReason' => 'Google::Ads::AdWords::v201109::CampaignError::Reason',
        'ClientTermsErrorReason' => 'Google::Ads::AdWords::v201109::ClientTermsError::Reason',
        'CriterionErrorReason' => 'Google::Ads::AdWords::v201109::CriterionError::Reason',
        'DatabaseErrorReason' => 'Google::Ads::AdWords::v201109::DatabaseError::Reason',
        'DateErrorReason' => 'Google::Ads::AdWords::v201109::DateError::Reason',
        'DistinctErrorReason' => 'Google::Ads::AdWords::v201109::DistinctError::Reason',
        'EntityAccessDeniedReason' => 'Google::Ads::AdWords::v201109::EntityAccessDenied::Reason',
        'EntityCountLimitExceededReason' => 'Google::Ads::AdWords::v201109::EntityCountLimitExceeded::Reason',
        'EntityNotFoundReason' => 'Google::Ads::AdWords::v201109::EntityNotFound::Reason',
        'IdErrorReason' => 'Google::Ads::AdWords::v201109::IdError::Reason',
        'ImageErrorReason' => 'Google::Ads::AdWords::v201109::ImageError::Reason',
        'InternalApiErrorReason' => 'Google::Ads::AdWords::v201109::InternalApiError::Reason',
        'JobErrorReason' => 'Google::Ads::AdWords::v201109::JobError::Reason',
        'MediaErrorReason' => 'Google::Ads::AdWords::v201109::MediaError::Reason',
        'NewEntityCreationErrorReason' => 'Google::Ads::AdWords::v201109::NewEntityCreationError::Reason',
        'NotEmptyErrorReason' => 'Google::Ads::AdWords::v201109::NotEmptyError::Reason',
        'NotWhitelistedErrorReason' => 'Google::Ads::AdWords::v201109::NotWhitelistedError::Reason',
        'NullErrorReason' => 'Google::Ads::AdWords::v201109::NullError::Reason',
        'OperationAccessDeniedReason' => 'Google::Ads::AdWords::v201109::OperationAccessDenied::Reason',
        'OperatorErrorReason' => 'Google::Ads::AdWords::v201109::OperatorError::Reason',
        'PagingErrorReason' => 'Google::Ads::AdWords::v201109::PagingError::Reason',
        'PolicyViolationErrorReason' => 'Google::Ads::AdWords::v201109::PolicyViolationError::Reason',
        'QuotaCheckErrorReason' => 'Google::Ads::AdWords::v201109::QuotaCheckError::Reason',
        'QuotaErrorReason' => 'Google::Ads::AdWords::v201109::QuotaError::Reason',
        'RangeErrorReason' => 'Google::Ads::AdWords::v201109::RangeError::Reason',
        'RateExceededErrorReason' => 'Google::Ads::AdWords::v201109::RateExceededError::Reason',
        'ReadOnlyErrorReason' => 'Google::Ads::AdWords::v201109::ReadOnlyError::Reason',
        'RegionCodeErrorReason' => 'Google::Ads::AdWords::v201109::RegionCodeError::Reason',
        'RejectedErrorReason' => 'Google::Ads::AdWords::v201109::RejectedError::Reason',
        'RequestErrorReason' => 'Google::Ads::AdWords::v201109::RequestError::Reason',
        'RequiredErrorReason' => 'Google::Ads::AdWords::v201109::RequiredError::Reason',
        'SelectorErrorReason' => 'Google::Ads::AdWords::v201109::SelectorError::Reason',
        'SettingErrorReason' => 'Google::Ads::AdWords::v201109::SettingError::Reason',
        'SizeLimitErrorReason' => 'Google::Ads::AdWords::v201109::SizeLimitError::Reason',
        'StatsQueryErrorReason' => 'Google::Ads::AdWords::v201109::StatsQueryError::Reason',
        'StringLengthErrorReason' => 'Google::Ads::AdWords::v201109::StringLengthError::Reason',
        'TargetErrorReason' => 'Google::Ads::AdWords::v201109::TargetError::Reason',
    },
    {

        'AdErrorReason' => 'AdErrorReason',
        'AdExtensionErrorReason' => 'AdExtensionErrorReason',
        'AdExtensionOverrideErrorReason' => 'AdExtensionOverrideErrorReason',
        'AdGroupAdErrorReason' => 'AdGroupAdErrorReason',
        'AdGroupCriterionErrorReason' => 'AdGroupCriterionErrorReason',
        'AdGroupServiceErrorReason' => 'AdGroupServiceErrorReason',
        'AuthenticationErrorReason' => 'AuthenticationErrorReason',
        'AuthorizationErrorReason' => 'AuthorizationErrorReason',
        'BiddingErrorReason' => 'BiddingErrorReason',
        'BiddingTransitionErrorReason' => 'BiddingTransitionErrorReason',
        'BudgetErrorReason' => 'BudgetErrorReason',
        'BulkMutateJobErrorReason' => 'BulkMutateJobErrorReason',
        'CampaignAdExtensionErrorReason' => 'CampaignAdExtensionErrorReason',
        'CampaignCriterionErrorReason' => 'CampaignCriterionErrorReason',
        'CampaignErrorReason' => 'CampaignErrorReason',
        'ClientTermsErrorReason' => 'ClientTermsErrorReason',
        'CriterionErrorReason' => 'CriterionErrorReason',
        'DatabaseErrorReason' => 'DatabaseErrorReason',
        'DateErrorReason' => 'DateErrorReason',
        'DistinctErrorReason' => 'DistinctErrorReason',
        'EntityAccessDeniedReason' => 'EntityAccessDeniedReason',
        'EntityCountLimitExceededReason' => 'EntityCountLimitExceededReason',
        'EntityNotFoundReason' => 'EntityNotFoundReason',
        'IdErrorReason' => 'IdErrorReason',
        'ImageErrorReason' => 'ImageErrorReason',
        'InternalApiErrorReason' => 'InternalApiErrorReason',
        'JobErrorReason' => 'JobErrorReason',
        'MediaErrorReason' => 'MediaErrorReason',
        'NewEntityCreationErrorReason' => 'NewEntityCreationErrorReason',
        'NotEmptyErrorReason' => 'NotEmptyErrorReason',
        'NotWhitelistedErrorReason' => 'NotWhitelistedErrorReason',
        'NullErrorReason' => 'NullErrorReason',
        'OperationAccessDeniedReason' => 'OperationAccessDeniedReason',
        'OperatorErrorReason' => 'OperatorErrorReason',
        'PagingErrorReason' => 'PagingErrorReason',
        'PolicyViolationErrorReason' => 'PolicyViolationErrorReason',
        'QuotaCheckErrorReason' => 'QuotaCheckErrorReason',
        'QuotaErrorReason' => 'QuotaErrorReason',
        'RangeErrorReason' => 'RangeErrorReason',
        'RateExceededErrorReason' => 'RateExceededErrorReason',
        'ReadOnlyErrorReason' => 'ReadOnlyErrorReason',
        'RegionCodeErrorReason' => 'RegionCodeErrorReason',
        'RejectedErrorReason' => 'RejectedErrorReason',
        'RequestErrorReason' => 'RequestErrorReason',
        'RequiredErrorReason' => 'RequiredErrorReason',
        'SelectorErrorReason' => 'SelectorErrorReason',
        'SettingErrorReason' => 'SettingErrorReason',
        'SizeLimitErrorReason' => 'SizeLimitErrorReason',
        'StatsQueryErrorReason' => 'StatsQueryErrorReason',
        'StringLengthErrorReason' => 'StringLengthErrorReason',
        'TargetErrorReason' => 'TargetErrorReason',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201109::ApiErrorReason

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
ApiErrorReason from the namespace https://adwords.google.com/api/adwords/cm/v201109.

Interface that has a reason return an associated service error. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * AdErrorReason


=item * AdExtensionErrorReason


=item * AdExtensionOverrideErrorReason


=item * AdGroupAdErrorReason


=item * AdGroupCriterionErrorReason


=item * AdGroupServiceErrorReason


=item * AuthenticationErrorReason


=item * AuthorizationErrorReason


=item * BiddingErrorReason


=item * BiddingTransitionErrorReason


=item * BudgetErrorReason


=item * BulkMutateJobErrorReason


=item * CampaignAdExtensionErrorReason


=item * CampaignCriterionErrorReason


=item * CampaignErrorReason


=item * ClientTermsErrorReason


=item * CriterionErrorReason


=item * DatabaseErrorReason


=item * DateErrorReason


=item * DistinctErrorReason


=item * EntityAccessDeniedReason


=item * EntityCountLimitExceededReason


=item * EntityNotFoundReason


=item * IdErrorReason


=item * ImageErrorReason


=item * InternalApiErrorReason


=item * JobErrorReason


=item * MediaErrorReason


=item * NewEntityCreationErrorReason


=item * NotEmptyErrorReason


=item * NotWhitelistedErrorReason


=item * NullErrorReason


=item * OperationAccessDeniedReason


=item * OperatorErrorReason


=item * PagingErrorReason


=item * PolicyViolationErrorReason


=item * QuotaCheckErrorReason


=item * QuotaErrorReason


=item * RangeErrorReason


=item * RateExceededErrorReason


=item * ReadOnlyErrorReason


=item * RegionCodeErrorReason


=item * RejectedErrorReason


=item * RequestErrorReason


=item * RequiredErrorReason


=item * SelectorErrorReason


=item * SettingErrorReason


=item * SizeLimitErrorReason


=item * StatsQueryErrorReason


=item * StringLengthErrorReason


=item * TargetErrorReason




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::v201109::ApiErrorReason
   # One of the following elements.
   # No occurance checks yet, so be sure to pass just one...
   AdErrorReason => $some_value, # AdError.Reason
   AdExtensionErrorReason => $some_value, # AdExtensionError.Reason
   AdExtensionOverrideErrorReason => $some_value, # AdExtensionOverrideError.Reason
   AdGroupAdErrorReason => $some_value, # AdGroupAdError.Reason
   AdGroupCriterionErrorReason => $some_value, # AdGroupCriterionError.Reason
   AdGroupServiceErrorReason => $some_value, # AdGroupServiceError.Reason
   AuthenticationErrorReason => $some_value, # AuthenticationError.Reason
   AuthorizationErrorReason => $some_value, # AuthorizationError.Reason
   BiddingErrorReason => $some_value, # BiddingError.Reason
   BiddingTransitionErrorReason => $some_value, # BiddingTransitionError.Reason
   BudgetErrorReason => $some_value, # BudgetError.Reason
   BulkMutateJobErrorReason => $some_value, # BulkMutateJobError.Reason
   CampaignAdExtensionErrorReason => $some_value, # CampaignAdExtensionError.Reason
   CampaignCriterionErrorReason => $some_value, # CampaignCriterionError.Reason
   CampaignErrorReason => $some_value, # CampaignError.Reason
   ClientTermsErrorReason => $some_value, # ClientTermsError.Reason
   CriterionErrorReason => $some_value, # CriterionError.Reason
   DatabaseErrorReason => $some_value, # DatabaseError.Reason
   DateErrorReason => $some_value, # DateError.Reason
   DistinctErrorReason => $some_value, # DistinctError.Reason
   EntityAccessDeniedReason => $some_value, # EntityAccessDenied.Reason
   EntityCountLimitExceededReason => $some_value, # EntityCountLimitExceeded.Reason
   EntityNotFoundReason => $some_value, # EntityNotFound.Reason
   IdErrorReason => $some_value, # IdError.Reason
   ImageErrorReason => $some_value, # ImageError.Reason
   InternalApiErrorReason => $some_value, # InternalApiError.Reason
   JobErrorReason => $some_value, # JobError.Reason
   MediaErrorReason => $some_value, # MediaError.Reason
   NewEntityCreationErrorReason => $some_value, # NewEntityCreationError.Reason
   NotEmptyErrorReason => $some_value, # NotEmptyError.Reason
   NotWhitelistedErrorReason => $some_value, # NotWhitelistedError.Reason
   NullErrorReason => $some_value, # NullError.Reason
   OperationAccessDeniedReason => $some_value, # OperationAccessDenied.Reason
   OperatorErrorReason => $some_value, # OperatorError.Reason
   PagingErrorReason => $some_value, # PagingError.Reason
   PolicyViolationErrorReason => $some_value, # PolicyViolationError.Reason
   QuotaCheckErrorReason => $some_value, # QuotaCheckError.Reason
   QuotaErrorReason => $some_value, # QuotaError.Reason
   RangeErrorReason => $some_value, # RangeError.Reason
   RateExceededErrorReason => $some_value, # RateExceededError.Reason
   ReadOnlyErrorReason => $some_value, # ReadOnlyError.Reason
   RegionCodeErrorReason => $some_value, # RegionCodeError.Reason
   RejectedErrorReason => $some_value, # RejectedError.Reason
   RequestErrorReason => $some_value, # RequestError.Reason
   RequiredErrorReason => $some_value, # RequiredError.Reason
   SelectorErrorReason => $some_value, # SelectorError.Reason
   SettingErrorReason => $some_value, # SettingError.Reason
   SizeLimitErrorReason => $some_value, # SizeLimitError.Reason
   StatsQueryErrorReason => $some_value, # StatsQueryError.Reason
   StringLengthErrorReason => $some_value, # StringLengthError.Reason
   TargetErrorReason => $some_value, # TargetError.Reason
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

