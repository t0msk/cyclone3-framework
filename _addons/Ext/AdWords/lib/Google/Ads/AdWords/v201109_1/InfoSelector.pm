package Google::Ads::AdWords::v201109_1::InfoSelector;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/info/v201109_1' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %serviceName_of :ATTR(:get<serviceName>);
my %methodName_of :ATTR(:get<methodName>);
my %operator_of :ATTR(:get<operator>);
my %dateRange_of :ATTR(:get<dateRange>);
my %clientEmails_of :ATTR(:get<clientEmails>);
my %clientCustomerIds_of :ATTR(:get<clientCustomerIds>);
my %includeSubAccounts_of :ATTR(:get<includeSubAccounts>);
my %apiUsageType_of :ATTR(:get<apiUsageType>);

__PACKAGE__->_factory(
    [ qw(        serviceName
        methodName
        operator
        dateRange
        clientEmails
        clientCustomerIds
        includeSubAccounts
        apiUsageType

    ) ],
    {
        'serviceName' => \%serviceName_of,
        'methodName' => \%methodName_of,
        'operator' => \%operator_of,
        'dateRange' => \%dateRange_of,
        'clientEmails' => \%clientEmails_of,
        'clientCustomerIds' => \%clientCustomerIds_of,
        'includeSubAccounts' => \%includeSubAccounts_of,
        'apiUsageType' => \%apiUsageType_of,
    },
    {
        'serviceName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'methodName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'operator' => 'Google::Ads::AdWords::v201109_1::Operator',
        'dateRange' => 'Google::Ads::AdWords::v201109_1::DateRange',
        'clientEmails' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'clientCustomerIds' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'includeSubAccounts' => 'SOAP::WSDL::XSD::Typelib::Builtin::boolean',
        'apiUsageType' => 'Google::Ads::AdWords::v201109_1::ApiUsageType',
    },
    {

        'serviceName' => 'serviceName',
        'methodName' => 'methodName',
        'operator' => 'operator',
        'dateRange' => 'dateRange',
        'clientEmails' => 'clientEmails',
        'clientCustomerIds' => 'clientCustomerIds',
        'includeSubAccounts' => 'includeSubAccounts',
        'apiUsageType' => 'apiUsageType',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201109_1::InfoSelector

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
InfoSelector from the namespace https://adwords.google.com/api/adwords/info/v201109_1.

Specifies the type of API usage information to be returned. API usage information returned is based on the {@link #apiUsageType API usage type} specified. All returned values are specific to the developer token being used to call <code>InfoService.get</code>. <p>For each of the <code>apiUsageType</code> values, other <code>InfoSelector</code> fields must also be set as described below:</p> <ul> <li><code>FREE_USAGE_API_UNITS_PER_MONTH</code> : Returns the number of allocated <a href="http://www.google.com/support/adwordsapi/bin/answer.py?answer=45891"> free API units</a> for this entire month. Specify only the apiUsageType parameter.</li> <li><code>TOTAL_USAGE_API_UNITS_PER_MONTH</code> : Returns the total number of allocated API units for this entire month. Includes both free and paid API units. Specify only the apiUsageType parameter.</li> <li><code>OPERATION_COUNT</code> : Returns the number of operations recorded over the given date range. The given dates are inclusive; to get the operation count for a single day, supply it as both the start and end date. Specify the apiUsageType and dateRange parameters. </li> <li><code>UNIT_COUNT</code> : Returns the number of API units recorded. <ul> <li>Specify the apiUsageType and dateRange parameters to retrieve the units recorded over the given date range.</li> <li>Specify the apiUsageType, serviceName, methodName and dateRange to retrieve the units recorded over the given date range for a specified method.</li> </ul> </li> <li><code>UNIT_COUNT_FOR_CLIENTS</code> : Returns the number of API units recorded for a subset of clients over the given date range. The given dates are inclusive; to get the unit count for a single day, supply it as both the start and end date. Specify the apiUsageType, dateRange and clientEmails parameters.</li> <li><code>METHOD_COST</code> : Returns the cost, in API units per operation, of the given method on a specific date. Methods default to a cost of 1. Specify the apiUsageType, dateRange (start date and end date should be the same), serviceName, methodName, operator parameters.</li> </ul> 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * serviceName


=item * methodName


=item * operator


=item * dateRange


=item * clientEmails


=item * clientCustomerIds


=item * includeSubAccounts


=item * apiUsageType




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::v201109_1::InfoSelector
   serviceName =>  $some_value, # string
   methodName =>  $some_value, # string
   operator => $some_value, # Operator
   dateRange =>  $a_reference_to, # see Google::Ads::AdWords::v201109_1::DateRange
   clientEmails =>  $some_value, # string
   clientCustomerIds =>  $some_value, # long
   includeSubAccounts =>  $some_value, # boolean
   apiUsageType => $some_value, # ApiUsageType
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

