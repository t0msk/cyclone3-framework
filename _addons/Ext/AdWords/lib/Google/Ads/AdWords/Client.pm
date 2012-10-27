# Copyright 2011, Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package Google::Ads::AdWords::Client;

use strict;
use version;
our $VERSION = qv("2.7.2");

# Warn if this module is not loaded before any other Google::Ads module.
BEGIN {
  if (my @modules = grep {
      m|^Google/Ads/(?!AdWords/Client\.pm\|!AdWords::Constants)| } keys %INC) {
    my $modules = join "\n", map { s|/|::|g; s/\.pm$//; $_ } @modules;
    require Carp;
    Carp::cluck(<<"END");
Google::Ads::AdWords::Client should be loaded before other Google::Ads::
modules. The following modules were found in %INC first:

$modules
END
  }
}

use Google::Ads::AdWords::AuthTokenHandler;
use Google::Ads::AdWords::Constants;
use Google::Ads::AdWords::Deserializer;
use Google::Ads::AdWords::OAuth2Handler;
use Google::Ads::AdWords::OAuth1_0aHandler;
use Google::Ads::AdWords::Serializer;
use Google::Ads::Common::HTTPTransport;
use Google::Ads::ThirdParty::SOAPWSDLPatches;

use CHI;
use Class::Std::Fast;
use SOAP::WSDL qv("2.00.10");

use constant OAUTH_2_HANDLER => "OAUTH_2_HANDLER";
use constant OAUTH_1_0A_HANDLER => "OAUTH_1_0A_HANDLER";
use constant AUTH_TOKEN_HANDLER => "AUTH_TOKEN_HANDLER";
use constant AUTH_HANDLERS_ORDER =>
    (OAUTH_2_HANDLER, OAUTH_1_0A_HANDLER, AUTH_TOKEN_HANDLER);

# Class::Std-style attributes. Most values read from adwords.properties file.
my %client_id_of : ATTR(:name<client_id> :default<>);
my %user_agent_of : ATTR(:name<user_agent> :default<>);
my %developer_token_of : ATTR(:name<developer_token> :default<>);
my %version_of : ATTR(:name<version> :default<>);
my %alternate_url_of : ATTR(:name<alternate_url> :default<>);
my %die_on_faults_of : ATTR(:name<die_on_faults> :default<0>);
my %validate_only_of : ATTR(:name<validate_only> :default<0>);
my %partial_failure_of : ATTR(:name<partial_failure> :default<0>);

my %properties_file_of : ATTR(:init_arg<properties_file> :default<>);
my %services_of : ATTR(:name<services> :default<{}>);
my %transport_of : ATTR(:name<transport> :default<0>);
my %auth_handlers_of : ATTR(:name<auth_handlers> :default<0>);

# All these auth related properties are now considered deprecated, to be
# removed in a later release.
my %email_of : ATTR(:init_arg<email> :get<email> :default<>);
my %password_of : ATTR(:init_arg<password> :get<password> :default<>);
my %auth_server_of : ATTR(:init_arg<auth_server> :get<auth_server> :default<0>);
my %auth_token_of : ATTR(:init_arg<auth_token> :get<auth_token> :default<>);
my %use_auth_token_cache_of : ATTR(:init_arg<use_auth_token_cache>
                                   :get<use_auth_token_cache> :default<>);
my %oauth_consumer_key_of : ATTR(:init_arg<oauth_consumer_key>
                                 :get<oauth_consumer_key> :default<>);
my %oauth_consumer_secret_of : ATTR(:init_arg<oauth_consumer_secret>
                                    :get<oauth_consumer_secret> :default<>);
my %oauth_token_of : ATTR(:init_arg<oauth_token> :get<oauth_token> :default<>);
my %oauth_token_secret_of : ATTR(:init_arg<oauth_token_secret>
                                 :get<oauth_token_secret> :default<>);
my %oauth_display_name_of : ATTR(:init_arg<oauth_display_name>
                                 :get<oauth_display_name> :default<>);

# Runtime statistics.
my %requests_count_of : ATTR(:name<requests_count> :default<0>);
my %failed_requests_count_of : ATTR(:name<failed_requests_count> :default<0>);
my %units_count_of : ATTR(:name<units_count> :default<0>);
my %operations_count_of : ATTR(:name<operations_count> :default<0>);
my %last_request_stats_of : ATTR(:name<last_request_stats> :default<>);
my %last_soap_request_of : ATTR(:name<last_soap_request> :default<>);
my %last_soap_response_of : ATTR(:name<last_soap_response> :default<>);

# Static module-level variables.

# Automatically called by Class::Std after the values for all the attributes
# have been populated but before the constuctor returns the new object.
sub START {
  my ($self, $ident) = @_;

  my $default_properties_file = Google::Ads::AdWords::Constants::DEFAULT_PROPERTIES_FILE;
  if (not $properties_file_of{$ident} and -e $default_properties_file) {
    $properties_file_of{$ident} = $default_properties_file;
  }

  my %properties = ();
  if ($properties_file_of{$ident}) {
    # If there's a valid properties file to read from, parse it and use the
    # config values to fill in any missing attributes.
    %properties = __parse_properties_file($properties_file_of{$ident});
    $client_id_of{$ident} ||= $properties{clientId};
    $user_agent_of{$ident} ||= $properties{useragent} || $properties{userAgent};
    $developer_token_of{$ident} ||= $properties{developerToken};
    $version_of{$ident} ||= $properties{version};
    $alternate_url_of{$ident} ||= $properties{alternateUrl};
    $validate_only_of{$ident} ||= $properties{validateOnly};
    $partial_failure_of{$ident} ||= $properties{partialFailure};

    # Deprecated: To be removed in a later release.
    $email_of{$ident} ||= $properties{email};
    $password_of{$ident} ||= $properties{password};
    $auth_server_of{$ident} ||= $properties{authServer};
    $auth_token_of{$ident} ||= $properties{authToken};
    $use_auth_token_cache_of{$ident} ||= $properties{useAuthTokenCache};
    $oauth_consumer_key_of{$ident} ||= $properties{oAuthConsumerKey};
    $oauth_consumer_secret_of{$ident} ||= $properties{oAuthConsumerSecret};
    $oauth_token_of{$ident} ||= $properties{oAuthToken};
    $oauth_token_secret_of{$ident} ||= $properties{oAuthTokenSecret};
    $oauth_display_name_of{$ident} ||= $properties{oAuthDisplayName};

    # SSL Peer validation setup.
    $self->__setup_SSL($properties{CAPath}, $properties{CAFile});
  }

  # We want to provide default values for these  attributes if they weren't
  # set by parameters to new() or the properties file.
  $alternate_url_of{$ident} ||=
      Google::Ads::AdWords::Constants::DEFAULT_ALTERNATE_URL;
  $validate_only_of{$ident} ||=
      Google::Ads::AdWords::Constants::DEFAULT_VALIDATE_ONLY;
  $version_of{$ident} ||= Google::Ads::AdWords::Constants::DEFAULT_VERSION;
  $partial_failure_of{$ident} ||= 0;

  # Always prepend the module identifier to the user agent.
  $user_agent_of{$ident} =
      sprintf("%s (AwApi-Perl/%s, Common-Perl/%s, SOAP-WSDL/%s, ".
              "libwww-perl/%s, perl/%s)", $user_agent_of{$ident} || $0,
              ${Google::Ads::AdWords::Constants::VERSION},
              ${Google::Ads::Common::Constants::VERSION},
              ${SOAP::WSDL::VERSION}, ${LWP::UserAgent::VERSION}, $]);

  # Setup of auth handlers
  my %auth_handlers = ();

  my $auth_handler = Google::Ads::AdWords::OAuth2Handler->new();
  $auth_handler->initialize($self, \%properties);
  $auth_handlers{OAUTH_2_HANDLER} = $auth_handler;

  $auth_handler = Google::Ads::AdWords::OAuth1_0aHandler->new();
  $auth_handler->initialize($self, {
    oAuthConsumerKey => $oauth_consumer_key_of{$ident},
    oAuthConsumerSecret => $oauth_consumer_secret_of{$ident},
    oAuthDisplayName => $oauth_display_name_of{$ident},
    oAuthToken => $oauth_token_of{$ident},
    oAuthTokenSecret => $oauth_token_secret_of{$ident}
  });
  $auth_handlers{OAUTH_1_0A_HANDLER} = $auth_handler;

  $auth_handler = Google::Ads::AdWords::AuthTokenHandler->new();
  $auth_handler->initialize($self, {
    email => $email_of{$ident},
    password => $password_of{$ident},
    authServer => $auth_server_of{$ident},
    authToken => $auth_token_of{$ident},
  });
  $auth_handlers{AUTH_TOKEN_HANDLER} = $auth_handler;

  $auth_handlers_of{$ident} = \%auth_handlers;

  # Setups the HTTP transport and OAuthHandler this client will use.
  $transport_of{$ident} = Google::Ads::Common::HTTPTransport->new();
  $transport_of{$ident}->client($self);
}

# Automatically called by Class::Std when an unknown method is invoked on an
# instance of this class. It is used to handle creating singletons (local to
# each Google::Ads::AdWords::Client instance) of all the SOAP services. The
# names of the services may change and shouldn't be hardcoded.
sub AUTOMETHOD {
  my ($self, $ident) = @_;
  my $method_name = $_;

  # All SOAP services should end in "Service"; fail early if the requested
  # method doesn't.
  if ($method_name =~ /^\w+Service$/) {
    if ($self->get_services()->{$method_name}) {
      # To emulate a singleton, return the existing instance of the service if
      # we already have it. The return value of AUTOMETHOD must be a sub
      # reference which is then invoked, so wrap the service in sub { }.
      return sub {
        return $self->get_services()->{$method_name};
      };
    } else {
      my $version = $self->get_version();

      # Check to see if there is a module with that name under
      # Google::Ads::AdWords::$version if not we warn and return nothing.
      my $module_name = "Google::Ads::AdWords::${version}::${method_name}"
          . "::${method_name}InterfacePort";
      eval("require $module_name");
      if ($@) {
        warn("Module $module_name was not found.");
        return;
      } else {
        # Generating the service endpoint url of the form
        # https://{server_url}/{group_name(cm/job/info/o)}/{version}/{service}.
        my $server_url = $self->get_alternate_url() =~ /\/$/ ?
            substr($self->get_alternate_url(), 0, -1) :
            $self->get_alternate_url();
        my $service_to_group_name =
            $Google::Ads::AdWords::Constants::SERVICE_TO_GROUP{$method_name};
        my $endpoint_url =
            sprintf(Google::Ads::AdWords::Constants::PROXY_FORMAT_STRING,
                    $server_url, $service_to_group_name, $self->get_version(),
                    $method_name);

        # If a suitable module is found, instantiate it and store it in
        # instance-specific storage to emulate a singleton.
        my $service_port =
            $module_name->new({
              # Setting the server endpoint of the service.
              proxy => [$endpoint_url],
              # Associating our custom serializer.
              serializer =>
                  Google::Ads::AdWords::Serializer->new({client => $self}),
              # Associating our custom deserializer.
              deserializer =>
                  Google::Ads::AdWords::Deserializer->new({client => $self})
            });

        # Injecting our own transport.
        $service_port->set_transport($self->get_transport());

        if ($ENV{HTTP_PROXY}) {
          $service_port->get_transport()->proxy(['http'], $ENV{HTTP_PROXY});
        }
        if ($ENV{HTTPS_PROXY}) {
          $service_port->get_transport()->proxy(['https'], $ENV{HTTPS_PROXY});
        }

        $self->get_services()->{$method_name} = $service_port;
        return sub {
          return $self->get_services()->{$method_name};
        };
      }
    }
  }
}

# Protected method to retrieve the proper enabled authorization handler.
sub _get_auth_handler {
  my $self = shift;

  my $auth_handlers = $self->get_auth_handlers();

  foreach my $handler_id (AUTH_HANDLERS_ORDER) {
    if ($auth_handlers->{$handler_id}->is_auth_enabled()) {
      return $auth_handlers->{$handler_id};
    }
  }

  return undef;
}

# Private method to setup IO::Socket::SSL and Crypt::SSLeay variables
# for certificate and hostname validation.
sub __setup_SSL {
  my ($self, $ca_path, $ca_file) = @_;
  if($ca_path || $ca_file) {
    $ENV{HTTPS_CA_DIR} = $ca_path;
    $ENV{HTTPS_CA_FILE} = $ca_file;
    eval {
      require IO::Socket::SSL;
      require Net::SSLeay;
      IO::Socket::SSL::set_ctx_defaults(
          verify_mode => Net::SSLeay->VERIFY_PEER(),
          SSL_verifycn_scheme => "www",
          ca_file => $ca_file,
          ca_path => $ca_path
      );
    }
  }
}

# Private method to parse values in a properties file.
sub __parse_properties_file {
  my ($properties_file) = @_;
  my %properties;

  # glob() to expand any metacharacters.
  ($properties_file) = glob($properties_file);

  if (open(PROP_FILE, $properties_file)) {
    # The data in the file should be in the following format:
    #   key1=value1
    #   key2=value2
    while (my $line = <PROP_FILE>) {
      chomp($line);

      # Skip comments.
      next if ($line =~ /^#/ || $line =~ /^\s*$/);
      my ($key, $value) = split(/=/, $line, 2);
      $properties{$key} = $value;
    }
    close(PROP_FILE);
  } else {
    die("Couldn't open properties file $properties_file for reading: $!\n");
  }
  return %properties;
}

# Protected method to generate the appropriate SOAP request header.
sub _get_header {
  my ($self) = @_;
  my $headers = {
    userAgent => $self->get_user_agent(),
    developerToken => $self->get_developer_token(),
    validateOnly => $self->get_validate_only(),
    partialFailure => $self->get_partial_failure()
  };
  my $clientId = $self->get_client_id();

  # $clientId may not be set, in which case we're operating on the account
  # specified in the email header.
  if ($clientId) {
    # Not the most sophisticated check, but it should do the trick.
    if ($clientId =~ /@/) {
      $headers->{clientEmail} = $clientId;
    } else {
      $headers->{clientCustomerId} = $clientId;
    }
  }

  return $headers;
}

sub get_auth_token_handler {
  my ($self) = @_;

  return $self->get_auth_handlers()->{AUTH_TOKEN_HANDLER};
}

sub get_oauth_1_0a_handler {
  my ($self) = @_;

  return $self->get_auth_handlers()->{OAUTH_1_0A_HANDLER};
}

sub get_oauth_2_handler {
  my ($self) = @_;

  return $self->get_auth_handlers()->{OAUTH_2_HANDLER};
}

# Adds a new RequestStats object to the client and updates the aggregated
# stats. It also checks against the MAX_NUM_OF_REQUEST_STATS constant to
# not make the array of lastest stats grow infinitely.
sub _push_new_request_stats {
  my ($self, $request_stats) = @_;

  $self->set_last_request_stats($request_stats);
  $self->set_requests_count($self->get_requests_count() + 1);
  $request_stats->get_is_fault() and
      $self->set_failed_requests_count($self->get_failed_requests_count() + 1);
  $self->set_operations_count($self->get_operations_count() +
      $request_stats->get_operations());
  $self->set_units_count($self->get_units_count() +
      $request_stats->get_units());
}

# Deprecated methods. These can be removed in a later release.

## Forces a refresh of the auth token even if it's cached already or if it was
## manually set via the auth_token property.
## This method is deprecated, consider using
## $client->get_auth_token_handler()->refresh_auth_token() instead.
sub refresh_auth_token {
  my ($self) = @_;

  my $auth_token_handler = $self->get_auth_token_handler();
  my $error = $auth_token_handler->refresh_auth_token();
  if ($error) {
    $self->get_die_on_faults() ? die($error) : warn($error);
  }

  return $auth_token_handler->get_auth_token();
}

## Retrieves an authorization URL that can be presented to the user for
## granting permissions to this client.
sub get_oauth_authorization_url {
  my ($self, $callback) = @_;

  my $oauth_handler = $self->get_oauth_1_0a_handler();
  $oauth_handler->set_consumer_key($self->get_oauth_consumer_key());
  $oauth_handler->set_consumer_secret($self->get_oauth_consumer_secret());
  $oauth_handler->set_display_name($self->get_oauth_display_name());
  my $url = $oauth_handler->get_authorization_url($callback);
  $self->set_oauth_token($oauth_handler->get_token());
  $self->set_oauth_token_secret($oauth_handler->get_token_secret());

  return $url;
}

## Upgrades an authorized request token generated by the
## get_oauth_authorization_url method.
sub upgrade_oauth_token {
  my ($self, $verification_code) = @_;

  my $oauth_handler = $self->get_oauth_1_0a_handler();
  $oauth_handler->issue_access_token($verification_code);
  $self->set_oauth_token($oauth_handler->get_token());
  $self->set_oauth_token_secret($oauth_handler->get_token_secret());
}

# Overriding default setter to also set underlying auth handlers.

sub set_email {
  my ($self, $email) = @_;

  $email_of{ident $self} = $email;
  $self->get_auth_token_handler()->set_email($email);
}

sub set_password {
  my ($self, $password) = @_;

  $password_of{ident $self} = $password;
  $self->get_auth_token_handler()->set_password($password);
}

sub set_auth_server {
  my ($self, $auth_server) = @_;

  $auth_server_of{ident $self} = $auth_server;
  $self->get_auth_token_handler()->set_auth_server($auth_server);
}

sub set_auth_token {
  my ($self, $auth_token) = @_;

  $auth_token_of{ident $self} = $auth_token;
  $self->get_auth_token_handler()->set_auth_token($auth_token);
}

sub set_oauth_consumer_key {
  my ($self, $consumer_key) = @_;

  $oauth_consumer_key_of{ident $self} = $consumer_key;
  $self->get_oauth_1_0a_handler()->set_consumer_key($consumer_key);
}

sub set_oauth_consumer_secret {
  my ($self, $consumer_secret) = @_;

  $oauth_consumer_secret_of{ident $self} = $consumer_secret;
  $self->get_oauth_1_0a_handler()->set_consumer_secret($consumer_secret);
}

sub set_oauth_token {
  my ($self, $oauth_token) = @_;

  $oauth_token_of{ident $self} = $oauth_token;
  $self->get_oauth_1_0a_handler()->set_token($oauth_token);
}

sub set_oauth_token_secret {
  my ($self, $oauth_token_secret) = @_;

  $oauth_token_secret_of{ident $self} = $oauth_token_secret;
  $self->get_oauth_1_0a_handler()->set_token_secret($oauth_token_secret);
}

sub set_oauth_display_name {
  my ($self, $oauth_display_name) = @_;

  $oauth_display_name_of{ident $self} = $oauth_display_name;
  $self->get_oauth_1_0a_handler()->set_display_name($oauth_display_name);
}

1;

=pod

=head1 NAME

Google::Ads::AdWords::Client

=head1 SYNOPSIS

  use Google::Ads::AdWords::Client;

  my $client = Google::Ads::AdWords::Client->new();

  my $adGroupId = "12345678";

  my $adgroupad_selector =
      Google::Ads::AdWords::v201109::Types::AdGroupAdSelector->new({
        adGroupIds => [$adGroupId]
      });

  my $page =
      $client->AdGroupAdService()->get({selector => $adgroupad_selector});

  if ($page->get_totalNumEntries() > 0) {
    foreach my $entry (@{$page->get_entries()}) {
      #Do something with the results
    }
  } else {
    print "No AdGroupAds found.\n";
  }

=head1 DESCRIPTION

Google::Ads::AdWords::Client is the main interface to the AdWords API. It takes
care of handling your API credentials, and exposes all of the underlying
services that make up the AdWords API.

Due to internal patching of the C<SOAP::WSDL> module, the
C<Google::Ads::AdWords::Client> module should be loaded before other
C<Google::Ads::> modules. A warning will occur if modules are loaded in the
wrong order.

=head1 ATTRIBUTES

Each of these attributes can be set via Google::Ads::AdWords::Client->new().
Alternatively, there is a get_ and set_ method associated with each attribute
for retrieving or setting them dynamically. For example, the set_client_id()
allows you to change the value of the client_id attribute and get_client_id()
returns the current value of the attribute.

=head2 email

The email address of a Google Account. This account could correspond to either
an AdWords MCC account or a normal AdWords account.

B<This property is demeed deprecated and should not be referenced>. Instead use
$client->get_auth_token_handler()->get_email().

=head2 password

The password associated with the Google Account given in L</email>.

B<This property is demeed deprecated and should not be referenced>. Instead use
$client->get_auth_token_handler()->get_password().

=head2 client_id

If the Google Account given in L</email> is an MCC account, you can specify the
AdWords account underneath that MCC account to act upon using client_id. The
value could be either a login email address or a 10 digit client id.

=head2 user_agent

A user-generated string used to identify your application. If nothing is
specified, the name of your script (i.e. $0) will be used instead.

=head2 developer_token

A string used to tie usage of the AdWords API to a specific MCC account.

In the Sandbox environment, the value should be

 email++CUR

i.e. the L</email> value, two plus signs, and then a currency code like C<USD>.

In the Production environment, the value should be a character string
assigned to you by Google. This string will tie AdWords API usage to your MCC
account for billing purposes. You can apply for a Developer Token at

https://adwords.google.com/select/ApiWelcome

=head2 version

The version of the AdWords API to use. Currently C<v201109> is the default and
only supported version.

=head2 alternate_url

The URL of an alternate AdWords API server to use. The most common use case
would be to specify the address of the Sandbox server.

The default value is C<https://adwords.google.com>

To access the Sandbox, use C<https://adwords-sandbox.google.com>

=head2 validate_only

If is set to "true" calls to services will only perform validation, the results
will be either empty response or a SOAP fault with the API error causing the
fault.

The default is "false".

=head2 partial_failure

If true, API will try to commit as many error free operations as possible and
report the other operations' errors. This flag is currently only supported by
the AdGroupCriterionService.

The default is "false".

=head2 auth_server

The server to use when making ClientLogin or OAuth requests. This normally
doesn't need to be changed from the default value.

The default is "https://www.google.com".

=head2 auth_token

Use to manually set an existing AuthToken. If not set the client will use the
auth_server to generate a token for you based on the email and password
provided.

B<This property is demeed deprecated and should not be referenced>. Instead use
$client->get_auth_token_handler()->get_auth_token().

=head2 use_auth_token_cache

By default the client keeps generated auth tokens for 23 hours in a local cache,
if this property is set to false then is your responsability to manually refresh
tokens either setting the auth_token property or calling refresh_auth_token to
auto generate a new one.

B<This property is demeed deprecated and should not be referenced>. There is no
replacement for this property since the auth token caching is now managed
differently.

=head2 die_on_faults

By default the client returns a L<SOAP::WSDL::SOAP::Typelib::Fault11> object
if an error has ocurred at the server side, however if this flag is set to true,
then the client will issue a die command on received SOAP faults.

The default is "false".

=head2 oauth_consumer_key & oauth_consumer_secret

The OAuth consumer key and secret pair to use when your client is OAuth enabled.
Refer to
http://code.google.com/apis/accounts/docs/RegistrationForWebAppsAuto.html on how
to obtain these values.

B<This property is demeed deprecated and should not be referenced>. Instead use
$client->get_oauth_1_0a_handler()->get_consumer_[key|secret]().

=head2 oauth_token & oauth_token_secret

The OAuth access token and secret pair to use when your client is OAuth enabled.
Refer to the methods L<get_oauth_authorization_url> & L<upgrade_oauth_token> to
generate these pair of keys.

B<This property is demeed deprecated and should not be referenced>. Instead use
$client->get_oauth_1_0a_handler()->get_token[_secret]().

=head2 oauth_display_name

Used to identify your application when requesting access to the user to use
his account via OAuth, refer to L<get_oauth_authorization_url> for more
information.

B<This property is demeed deprecated and should not be referenced>. Instead use
$client->get_oauth_1_0a_handler()->get_display_name().

=head2 oauth_handler

Implementation of L<Google::Ads::Common::OAuthHandler> to handle all
the required logic to access AdWords API authorized via OAuth. This attribute
can be overriden to use your own implementation, it defaults to
L<Google::Ads::AdWords::OAuthHandler>.

=head2 requests_count

Number of requests performed with this client so far.

=head2 failed_requests_count

Number of failed requests performed with this client so far.

=head2 units_count

Number of API units consumed by requests made with this client so far.

=head2 operations_count

Number of operations made with this client so far.

=head2 requests_stats

An array of L<Google::Ads::AdWords::RequestStats> containing the statistics of
the last L<Google::Ads::AdWords::Constants:MAX_NUM_OF_REQUEST_STATS> requests.

=head2 last_request_stats

A L<Google::Ads::AdWords::RequestStats> containing the statistics the last
request performed by this client.

=head2 last_soap_request

A string containing the last SOAP request XML sent by this client.

=head2 last_soap_response

A string containing the last SOAP response XML sent by this client.

=head1 METHODS

=head2 new

Initializes a new Google::Ads::AdWords::Client object.

=head3 Parameters

new() takes parameters as a hash reference.
The attributes of this object can be populated in a number of ways:

=over

=item *

If the properties_file parameter is given, then properties are read from the
file at that path and the corresponding attributes are populated.

=item *

If no properties_file parameter is given, then the code checks to see if there
is a file named "adwords.properties" in the home directory of the current user.
If there is, then properties are read from there.

=item *

Any of the L</ATTRIBUTES> can be passed in as keys in the parameters hash
reference. If any attribute is explicitly passed in then it will override any
value for that attribute that might be in a properties file.

=back

=head3 Returns

A new Google::Ads::AdWords::Client object with the appropriate attributes set.

=head3 Exceptions

If a properties_file is passed in but the file cannot be read, the code will
die() with an error message describing the failure.

=head3 Example

 # Basic use case. Attributes will be read from ~/adwords.properties file.
 my $client = Google::Ads::AdWords::Client->new();

 # Most attributes from a custom properties file, but override email.
 eval {
   my $client = Google::Ads::AdWords::Client->new({
     properties_file => "/path/to/adwords.properties",
     email => "user\@domain.com",
   });
 };
 if ($@) {
   # The properties file couldn't be read; handle error as appropriate.
 }

 # Specify all attributes explicitly. The properties file will not override.
 my $client = Google::Ads::AdWords::Client->new({
   email => "user\@domain.com",
   password => "my_password",
   client_id => "client_1+user\@domain.com",
   developer_token => "user\@domain.com++USD",
   user_agent => "My Sample Program",
 });

=head2 {ServiceName}

The client object contains a method for every service provided by the API.
So for example it can invoked as $client->AdGroupService() and it will return
an object of type
L<Google::Ads::AdWords::v201109::AdGroupService::AdGroupServiceInterfacePort>
when using version v201109 of the API.
For a list of all available services please refer to
http://code.google.com/apis/adwords/docs/ and for examples on
how to invoke the services please refer to scripts in the examples folder.

=head2 __setup_SSL (Private)

Setups IO::Socket::SSL and Crypt::SSLeay enviroment variables to work with
SSL certificate validation.

=head3 Parameters

The path to the certificate authorites folder and the path to the certificate
authorites file. Either can be null.

=head3 Returns

Nothing.

=head2 __parse_properties_file (Private)

=head3 Parameters

The path to a properties file on disk. The data in the file should be in the
following format:

 key1=value1
 key2=value2

=head3 Returns

A hash corresponding to the keys and values in the properties file.

=head3 Exceptions

die()s with an error message if the properties file could not be read.

=head2 set_die_on_faults

This module supports two approaches to handling SOAP faults (i.e. errors
returned by the underlying SOAP service).

One approach is to issue a die() with a description of the error when a SOAP
fault occurs. This die() would ideally be contained within an eval { }; block,
thereby emulating try { } / catch { } exception functionality in other
languages.

A different approach is to require developers to explicitly check for SOAP
faults being returned after each AdWords API method. This approach requires a
bit more work, but has the advantage of exposing the full details of the SOAP
fault, like the fault code.

Refer to the object L<SOAP::WSDL::SOAP::Typelib::Fault11> for more detail on
how faults get returned.

The default value is false, i.e. you must explicitly check for faults.

=head3 Parameters

A true value will cause this module to die() when a SOAP fault occurs.

A false value will supress this die(). This is the default behavior.

=head3 Returns

The input parameter is returned.

=head3 Example

 # $client is a Google::Ads::AdWords::Client object.

 # Enable die()ing on faults.
 $client->set_die_on_faults(1);
 eval {
   my $response = $client->AdGroupAdService->mutate($mutate_params);
 };
 if ($@) {
   # Do something with the error information in $@.
 }

 # Default behavior.
 $client->set_die_on_faults(0);
 my $response = $client->AdGroupAdService->mutate($mutate_params);
 if ($response->isa("SOAP::WSDL::SOAP::Typelib::Fault11")) {
   my $code = $response->get_faultcode() || '';
   my $description = $response->get_faultstring() || '';
   my $actor = $response->get_faultactor() || '';
   my $detail = $response->get_faultdetail() || '';

   # Do something with this error information.
 }

=head2 get_die_on_faults

=head3 Returns

A true or false value indicating whether the Google::Ads::AdWords::Client
instance is set to die() on SOAP faults.

=head2 _get_header (Protected)

Used by the L<Google::Ads::AdWords::Serializer> class to get a valid request
header corresponding to the current credentials in this
Google::Ads::AdWords::Client instance.

=head3 Returns

A hash reference with credentials corresponding to the values needed to be
included in the request header.

=head2 _auth_handler (Protected)

Retrieves the active AuthHandler. All handlers are checked in the order
OAuth2 -> OAuth1_0a -> AuthToken, given preference of OAuth2 over OAuth1_0a and
OAuth1_0a over AuthToken.

=head3 Returns

An implementation of L<Google::Ads::Common::AuthHandlerInterface>.

=head2 get_oauth_authorization_url

Used to generate a request token and return an authorization URL that should be
presented to the user to authorize the token.

B<This method is demeed deprecated and should not be used>. Instead use
$client->get_oauth_1_0a_handler()->get_authorization_url().

=head3 Parameters

A callback URL to which the user will be redirect after granting access. A value
"oob" out-of-band can be passed to have the server print out the verification
code in screen.

=head3 Returns

The URL that should be presented to the user to grant access to the application.

=head2 upgrade_oauth_token

Used to upgrade a request token (generated by the
L<get_oauth_authorization_url>)
to an access token, that can then be used to access the API via OAuth.

B<This method is demeed deprecated and should not be used>. Instead use
$client->get_oauth_1_0a_handler()->issue_access_token().

=head3 Parameters

A verification code returned by the server.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Google Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 AUTHOR

Jeffrey Posnick E<lt>api.jeffy at gmail.comE<gt>

David Torres E<lt>david.t at google.comE<gt>

=head1 REPOSITORY INFORMATION

 $Rev: $
 $LastChangedBy: $
 $Id: $

=cut
