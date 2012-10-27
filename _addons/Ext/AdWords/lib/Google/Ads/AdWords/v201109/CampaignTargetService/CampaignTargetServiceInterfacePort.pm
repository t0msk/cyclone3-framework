package Google::Ads::AdWords::v201109::CampaignTargetService::CampaignTargetServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201109::TypeMaps::CampaignTargetService
    if not Google::Ads::AdWords::v201109::TypeMaps::CampaignTargetService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/cm/v201109/CampaignTargetService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201109::TypeMaps::CampaignTargetService')
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
            parts           =>  [qw( Google::Ads::AdWords::v201109::CampaignTargetService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201109::CampaignTargetService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201109::CampaignTargetService::mutate )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201109::CampaignTargetService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201109::CampaignTargetService::CampaignTargetServiceInterfacePort - SOAP Interface for the CampaignTargetService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201109::CampaignTargetService::CampaignTargetServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201109::CampaignTargetService::CampaignTargetServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->mutate();



=head1 DESCRIPTION

SOAP Interface for the CampaignTargetService web service
located at https://adwords.google.com/api/adwords/cm/v201109/CampaignTargetService.

=head1 SERVICE CampaignTargetService



=head2 Port CampaignTargetServiceInterfacePort



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

Returns the targets for each of the campaigns identified in the campaign target selector. @param selector a list of campaigns' ids and optional filter of target types. @return page of lists of the requested campaign targets. @throws ApiException if problems occurred while fetching campaign targeting information. 

Returns a L<Google::Ads::AdWords::v201109::CampaignTargetService::getResponse|Google::Ads::AdWords::v201109::CampaignTargetService::getResponse> object.

 $response = $interface->get( {
    selector =>  $a_reference_to, # see Google::Ads::AdWords::v201109::CampaignTargetSelector
  },,
 );

=head3 mutate

Mutates (sets) targets for specified campaign identified in the campaign operations. <p class="note"><b>Note:</b> When a campaign is created, its targeting options are also created. To add or remove targets, call {@code mutate} with the {@code SET} operator to update the target lists accordingly. The {@code ADD} and {@code REMOVE} operators are not supported.</p> @param operations list of operations associating targets with campaign ids. @return the updated campaign targets, not necessarily in the same order in which they came in. @throws ApiException if problems occurred while adding campaign targeting information. 

Returns a L<Google::Ads::AdWords::v201109::CampaignTargetService::mutateResponse|Google::Ads::AdWords::v201109::CampaignTargetService::mutateResponse> object.

 $response = $interface->mutate( {
    operations =>  $a_reference_to, # see Google::Ads::AdWords::v201109::CampaignTargetOperation
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Tue Aug 28 17:16:10 2012

=cut
