package Google::Ads::AdWords::v201109_1::BulkMutateJobService::BulkMutateJobServiceInterfacePort;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Google::Ads::AdWords::v201109_1::TypeMaps::BulkMutateJobService
    if not Google::Ads::AdWords::v201109_1::TypeMaps::BulkMutateJobService->can('get_class');

sub START {
    $_[0]->set_proxy('https://adwords.google.com/api/adwords/job/v201109_1/BulkMutateJobService') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Google::Ads::AdWords::v201109_1::TypeMaps::BulkMutateJobService')
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
            parts           =>  [qw( Google::Ads::AdWords::v201109_1::BulkMutateJobService::get )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201109_1::BulkMutateJobService::RequestHeader )],
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
            parts           =>  [qw( Google::Ads::AdWords::v201109_1::BulkMutateJobService::mutate )],
        },
        header => {
            


           'use' => 'literal',
            namespace => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle => '',
            parts => [qw( Google::Ads::AdWords::v201109_1::BulkMutateJobService::RequestHeader )],
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

Google::Ads::AdWords::v201109_1::BulkMutateJobService::BulkMutateJobServiceInterfacePort - SOAP Interface for the BulkMutateJobService Web Service

=head1 SYNOPSIS

 use Google::Ads::AdWords::v201109_1::BulkMutateJobService::BulkMutateJobServiceInterfacePort;
 my $interface = Google::Ads::AdWords::v201109_1::BulkMutateJobService::BulkMutateJobServiceInterfacePort->new();

 my $response;
 $response = $interface->get();
 $response = $interface->mutate();



=head1 DESCRIPTION

SOAP Interface for the BulkMutateJobService web service
located at https://adwords.google.com/api/adwords/job/v201109_1/BulkMutateJobService.

=head1 SERVICE BulkMutateJobService



=head2 Port BulkMutateJobServiceInterfacePort



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

Returns a list of bulk mutate jobs. @param selector Specifies which jobs to return. If the selector is empty, all jobs are returned. @return List of bulk mutate jobs meeting the {@code selector} criteria. @throws ApiException if problems occurred while fetching the jobs 

Returns a L<Google::Ads::AdWords::v201109_1::BulkMutateJobService::getResponse|Google::Ads::AdWords::v201109_1::BulkMutateJobService::getResponse> object.

 $response = $interface->get( {
    selector =>  $a_reference_to, # see Google::Ads::AdWords::v201109_1::BulkMutateJobSelector
  },,
 );

=head3 mutate

Adds or updates a bulk mutate job. <p>Use the &laquo;ADD&raquo; operator to submit a new job, and the &laquo;SET&raquo; operator to add additional {@linkplain BulkMutateRequest request parts} to an existing job. The &laquo;DELETE&raquo; operator is not supported. From v201008 and later, use the &laquo;REMOVE&raquo; operator to cancel a job. Only jobs that still have pending additions of request parts may be canceled.</p> <p class="note"><b>Note:</b> In the current implementation, the check for duplicate job keys is only "best effort", and may not prevent jobs with the same keys from being accepted if they are submitted around the same instant.</p> @param operation The operation to perform. @throws ApiException if problems occurred while creating or updating jobs @return The added or updated bulk mutate job. 

Returns a L<Google::Ads::AdWords::v201109_1::BulkMutateJobService::mutateResponse|Google::Ads::AdWords::v201109_1::BulkMutateJobService::mutateResponse> object.

 $response = $interface->mutate( {
    operation =>  $a_reference_to, # see Google::Ads::AdWords::v201109_1::JobOperation
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Tue Aug 28 17:15:16 2012

=cut
