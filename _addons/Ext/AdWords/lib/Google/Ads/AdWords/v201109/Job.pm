package Google::Ads::AdWords::v201109::Job;
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

my %customerJobKey_of :ATTR(:get<customerJobKey>);
my %failureReason_of :ATTR(:get<failureReason>);
my %stats_of :ATTR(:get<stats>);
my %billingSummary_of :ATTR(:get<billingSummary>);
my %Job__Type_of :ATTR(:get<Job__Type>);

__PACKAGE__->_factory(
    [ qw(        customerJobKey
        failureReason
        stats
        billingSummary
        Job__Type

    ) ],
    {
        'customerJobKey' => \%customerJobKey_of,
        'failureReason' => \%failureReason_of,
        'stats' => \%stats_of,
        'billingSummary' => \%billingSummary_of,
        'Job__Type' => \%Job__Type_of,
    },
    {
        'customerJobKey' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'failureReason' => 'Google::Ads::AdWords::v201109::ApiErrorReason',
        'stats' => 'Google::Ads::AdWords::v201109::JobStats',
        'billingSummary' => 'Google::Ads::AdWords::v201109::BillingSummary',
        'Job__Type' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    },
    {

        'customerJobKey' => 'customerJobKey',
        'failureReason' => 'failureReason',
        'stats' => 'stats',
        'billingSummary' => 'billingSummary',
        'Job__Type' => 'Job.Type',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201109::Job

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
Job from the namespace https://adwords.google.com/api/adwords/cm/v201109.

Represents an asynchronous macro unit of work. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * customerJobKey


=item * failureReason


=item * stats


=item * billingSummary


=item * Job__Type

Note: The name of this property has been altered, because it didn't match
perl's notion of variable/subroutine names. The altered name is used in
perl code only, XML output uses the original name:

 Job.Type




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::v201109::Job
   customerJobKey =>  $some_value, # string
   failureReason =>  $a_reference_to, # see Google::Ads::AdWords::v201109::ApiErrorReason
   stats =>  $a_reference_to, # see Google::Ads::AdWords::v201109::JobStats
   billingSummary =>  $a_reference_to, # see Google::Ads::AdWords::v201109::BillingSummary
   Job__Type =>  $some_value, # string
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut
