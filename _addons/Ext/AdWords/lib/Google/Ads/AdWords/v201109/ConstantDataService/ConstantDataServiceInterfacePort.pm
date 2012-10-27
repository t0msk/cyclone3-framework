package Google::Ads::AdWords::v201109::ConstantDataService::ConstantDataServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201109::TypeMaps::ConstantDataService
    if not Google::Ads::AdWords::v201109::TypeMaps::ConstantDataService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/cm/v201109/ConstantDataService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201109::TypeMaps::ConstantDataService')
        if not $_[2]->{class_resolver};

    $_[0]->set_prefix($_[2]->{use_prefix}) if exists $_[2]->{use_prefix};
}

sub getCarrierCriterion {
    my ($self, $body, $header) = @_;
    die "getCarrierCriterion must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'getCarrierCriterion',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201109::ConstantDataService::getCarrierCriterion )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201109::ConstantDataService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub getLanguageCriterion {
    my ($self, $body, $header) = @_;
    die "getLanguageCriterion must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'getLanguageCriterion',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201109::ConstantDataService::getLanguageCriterion )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201109::ConstantDataService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201109::ConstantDataService::ConstantDataServiceInterfacePort - SOAP Interface for the ConstantDataService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201109::ConstantDataService::ConstantDataServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201109::ConstantDataService::ConstantDataServiceInterfacePort->new();

 my $response;
 $response = $interface->getCarrierCriterion();
 $response = $interface->getLanguageCriterion();



=head1 DESCRIPTION

SOAP Interface for the ConstantDataService web service
located at https://adwords.google.com/api/adwords/cm/v201109/ConstantDataService.

=head1 SERVICE ConstantDataService



=head2 Port ConstantDataServiceInterfacePort



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



=head3 getCarrierCriterion

Returns a list of all carrier criteria. @return A list of carriers. @throws ApiException when there is at least one error with the request. 

Returns a L<Google::Ads::AdWords::v201109::ConstantDataService::getCarrierCriterionResponse|Google::Ads::AdWords::v201109::ConstantDataService::getCarrierCriterionResponse> object.

 $response = $interface->getCarrierCriterion( {
  },,
 );

=head3 getLanguageCriterion

Returns a list of all language criteria. @return A list of languages. @throws ApiException when there is at least one error with the request. 

Returns a L<Google::Ads::AdWords::v201109::ConstantDataService::getLanguageCriterionResponse|Google::Ads::AdWords::v201109::ConstantDataService::getLanguageCriterionResponse> object.

 $response = $interface->getLanguageCriterion( {
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Tue Aug 28 17:16:18 2012

=cut
