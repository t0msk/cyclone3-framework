package Google::Ads::AdWords::v201109_1::ReportDefinitionService::ReportDefinitionServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201109_1::TypeMaps::ReportDefinitionService
    if not Google::Ads::AdWords::v201109_1::TypeMaps::ReportDefinitionService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/cm/v201109_1/ReportDefinitionService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201109_1::TypeMaps::ReportDefinitionService')
        if not $_[2]->{class_resolver};

    $_[0]->set_prefix($_[2]->{use_prefix}) if exists $_[2]->{use_prefix};
}

sub get {
    my ($self, $body, $header) = @_;
    die "get must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'get',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201109_1::ReportDefinitionService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201109_1::ReportDefinitionService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub getReportFields {
    my ($self, $body, $header) = @_;
    die "getReportFields must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'getReportFields',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201109_1::ReportDefinitionService::getReportFields )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201109_1::ReportDefinitionService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201109_1::ReportDefinitionService::ReportDefinitionServiceInterfacePort - SOAP Interface for the ReportDefinitionService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201109_1::ReportDefinitionService::ReportDefinitionServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201109_1::ReportDefinitionService::ReportDefinitionServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->getReportFields();



=head1 DESCRIPTION

SOAP Interface for the ReportDefinitionService web service
located at https://adwords.google.com/api/adwords/cm/v201109_1/ReportDefinitionService.

=head1 SERVICE ReportDefinitionService



=head2 Port ReportDefinitionServiceInterfacePort



=head1 METHODS

=head2 General methods

=head3 new

Constructor.

All arguments are forwarded to L<SOAP::WSDL::Client|SOAP::WSDL::Client>.

=head2 SOAP Service methods

Method synopsis is displayed with hash refs as parameters.

The commented class names in the method's parameters denote that objects
of the corresponding class can be passed instead of the marked hash ref.

You may pass any combination of objects, hash and list refs to these
methods, as long as you meet the structure.

List items (i.e. multiple occurences) are not displayed in the synopsis.
You may generally pass a list ref of hash refs (or objects) instead of a hash
ref - this may result in invalid XML if used improperly, though. Note that
SOAP::WSDL always expects list references at maximum depth position.

XML attributes are not displayed in this synopsis and cannot be set using
hash refs. See the respective class' documentation for additional information.



=head3 get

Returns the list of report definitions that meet the selector criteria. @param selector Determines which report definitions to return. If empty, all report definitions will be returned. @return A list of report definitions. @throws ApiException if problems occurred while fetching report definitions information. 

Returns a L<Google::Ads::AdWords::v201109_1::ReportDefinitionService::getResponse|Google::Ads::AdWords::v201109_1::ReportDefinitionService::getResponse> object.

 $response = $interface->get( {
    selector =>  $a_reference_to, # see Google::Ads::AdWords::v201109_1::ReportDefinitionSelector
  },,
 );

=head3 getReportFields

Returns the available report fields for a given report type. @param reportType The type of report. @return The list of available report fields. Each {@link ReportDefinitionField} encapsulates the field name, the field data type, and the enum values (if the field's type is {@code enum}). @throws ApiException if a problem occurred while fetching the ReportDefinitionField information. 

Returns a L<Google::Ads::AdWords::v201109_1::ReportDefinitionService::getReportFieldsResponse|Google::Ads::AdWords::v201109_1::ReportDefinitionService::getReportFieldsResponse> object.

 $response = $interface->getReportFields( {
    reportType => $some_value, # ReportDefinition.ReportType
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Tue Aug 28 17:13:16 2012

=cut
