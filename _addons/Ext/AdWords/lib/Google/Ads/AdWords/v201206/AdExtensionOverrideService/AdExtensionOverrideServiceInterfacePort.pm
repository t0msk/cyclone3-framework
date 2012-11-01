package Google::Ads::AdWords::v201206::AdExtensionOverrideService::AdExtensionOverrideServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201206::TypeMaps::AdExtensionOverrideService
    if not Google::Ads::AdWords::v201206::TypeMaps::AdExtensionOverrideService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/cm/v201206/AdExtensionOverrideService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201206::TypeMaps::AdExtensionOverrideService')
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
            parts           =>  [qw( Google::Ads::AdWords::v201206::AdExtensionOverrideService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201206::AdExtensionOverrideService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub mutate {
    my ($self, $body, $header) = @_;
    die "mutate must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'mutate',
        soap_action => '',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Google::Ads::AdWords::v201206::AdExtensionOverrideService::mutate )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201206::AdExtensionOverrideService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201206::AdExtensionOverrideService::AdExtensionOverrideServiceInterfacePort - SOAP Interface for the AdExtensionOverrideService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201206::AdExtensionOverrideService::AdExtensionOverrideServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201206::AdExtensionOverrideService::AdExtensionOverrideServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->mutate();



=head1 DESCRIPTION

SOAP Interface for the AdExtensionOverrideService web service
located at https://adwords.google.com/api/adwords/cm/v201206/AdExtensionOverrideService.

=head1 SERVICE AdExtensionOverrideService



=head2 Port AdExtensionOverrideServiceInterfacePort



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

Returns a list of AdExtensionOverrides based on an AdExtensionOverrideSelector. @param selector the selector specifying the query @return the page containing the AdExtensionOverride which meet the criteria specified by the selector 

Returns a L<Google::Ads::AdWords::v201206::AdExtensionOverrideService::getResponse|Google::Ads::AdWords::v201206::AdExtensionOverrideService::getResponse> object.

 $response = $interface->get( {
    selector =>  $a_reference_to, # see Google::Ads::AdWords::v201206::AdExtensionOverrideSelector
  },,
 );

=head3 mutate

Applies the list of mutate operations. Conditions for adding an ad-level AdExtension override using an AdExtension under the Ad's campaign: 1) If the text ad has never been overridden, an AdExtension override may be set on the creative using an extension under the campaign, along with any override info. 2) If the text ad has been overriden before, the latitude/longitude of the new extension override must be the same as the previous override and no override info can be specified (ie. the override info will inherit from the previous override info). @param operations the operations to apply. The same ad extension override cannot be specified in more than one operation. @return the applied ad extension overrides 

Returns a L<Google::Ads::AdWords::v201206::AdExtensionOverrideService::mutateResponse|Google::Ads::AdWords::v201206::AdExtensionOverrideService::mutateResponse> object.

 $response = $interface->mutate( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201206::AdExtensionOverrideOperation
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Tue Aug 28 17:06:59 2012

=cut