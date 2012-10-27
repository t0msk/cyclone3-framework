# Copyright 2012, Google Inc. All Rights Reserved.
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

package Google::Ads::Common::OAuth1_0aHandler;

use strict;
use version;
use base qw(Google::Ads::Common::OAuthHandlerInterface);

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::Common::Constants; our $VERSION = ${Google::Ads::Common::Constants::VERSION};

use Class::Std::Fast;
use HTTP::Request::Common;
use LWP::UserAgent;
use Net::OAuth;

# OAuth 1.0a properties. Refer to
# https://developers.google.com/accounts/docs/OAuthForInstalledApps for
# more information on these.
use constant DEFAULT_OAUTH_REQUEST_TOKEN_URL =>
    "https://www.google.com/accounts/OAuthGetRequestToken";
use constant DEFAULT_OAUTH_AUTHORIZE_TOKEN_URL =>
    "https://www.google.com/accounts/OAuthAuthorizeToken";
use constant DEFAULT_OAUTH_ACCESS_TOKEN_URL =>
    "https://www.google.com/accounts/OAuthGetAccessToken";
use constant DEFAULT_OAUTH_CONSUMER_KEY => "anonymous";
use constant DEFAULT_OAUTH_CONSUMER_SECRET => "anonymous";

# Loading Math::Random::MT as a more secure implementation to generate random
# numbers to be used when generating the nonce.
BEGIN {
  eval { require Math::Random::MT };
  unless ($@) {
    Math::Random::MT->import(qw(srand rand));
  }
}

# Using OAuth 1.0A
$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;

# Class::Std-style attributes. Need to be kept in the same line.
my %request_token_url_of : ATTR(:name<request_token_url>
    :default<Google::Ads::Common::OAuth1_0aHandler::DEFAULT_OAUTH_REQUEST_TOKEN_URL>);
my %authorize_token_url_of : ATTR(:name<authorize_token_url>
    :default<Google::Ads::Common::OAuth1_0aHandler::DEFAULT_OAUTH_AUTHORIZE_TOKEN_URL>);
my %access_token_url_of : ATTR(:name<access_token_url>
    :default<Google::Ads::Common::OAuth1_0aHandler::DEFAULT_OAUTH_ACCESS_TOKEN_URL>);
my %consumer_key_of : ATTR(:name<consumer_key>
    :default<Google::Ads::Common::OAuth1_0aHandler::DEFAULT_OAUTH_CONSUMER_KEY>);
my %consumer_secret_of : ATTR(:name<consumer_secret>
    :default<Google::Ads::Common::OAuth1_0aHandler::DEFAULT_OAUTH_CONSUMER_SECRET>);
my %token_of : ATTR(:name<token> :default<>);
my %token_secret_of : ATTR(:name<token_secret> :default<>);
my %display_name_of : ATTR(:name<display_name> :default<>);
my %__user_agent_of : ATTR(:name<__user_agent> :default<>);

# Constructor. Setups the standard LWP::UserAgent is none is passed.
sub START {
  my ($self, $ident) = @_;

  $__user_agent_of{$ident} ||= LWP::UserAgent->new();
}

# From Google::Ads::Common::AuthHandlerInterface.
sub initialize {
  my ($self, $api_client, $properties) = @_;

  my $ident = ident $self;

  $consumer_key_of{$ident} = $properties->{oAuthConsumerKey} ||
      $consumer_key_of{$ident};
  $consumer_secret_of{$ident} = $properties->{oAuthConsumerSecret} ||
      $consumer_secret_of{$ident};
  $display_name_of{$ident} = $properties->{oAuthDisplayName} ||
      $display_name_of{$ident};
  $token_of{$ident} = $properties->{oAuthToken} || $token_of{$ident};
  $token_secret_of{$ident} = $properties->{oAuthTokenSecret} ||
      $token_secret_of{$ident};
}

sub is_auth_enabled {
  my $self = shift;

  return $self->get_consumer_key() && $self->get_consumer_secret() &&
      $self->get_token() && $self->get_token_secret();
}

sub prepare_request {
  my ($self, $endpoint, $http_headers, $envelope) = @_;

  $endpoint = $self->_get_protected_resource_url($endpoint);

  return HTTP::Request->new('POST', $endpoint, $http_headers, $envelope);
}

# From Google::Ads::Common::OAuth1_0aHandlerInterface.
sub get_authorization_url {
  my ($self, $callback) = @_;

  my $request = Net::OAuth->request("request token")->new(
    consumer_key => $self->get_consumer_key(),
    consumer_secret => $self->get_consumer_secret(),
    request_url => $self->get_request_token_url(),
    request_method => "POST",
    signature_method => "HMAC-SHA1",
    timestamp => $self->_timestamp(),
    nonce => $self->_nonce(),
    callback => $callback,
    extra_params => {
      scope => $self->_scope(),
      xoauth_displayname => $self->get_display_name()
    }
  );
  $request->sign;

  my $ua = LWP::UserAgent->new();
  my $res = $ua->request(POST $request->to_url());

  if (!$res->is_success()) {
    die "Unable to obtain authorization URL.";
  }

  my $response =
      Net::OAuth->response("request token")->from_post_body($res->content);

  $self->set_token($response->token);
  $self->set_token_secret($response->token_secret);

  return $self->get_authorize_token_url() . "?oauth_token=" .
      $self->get_token();
}

sub issue_access_token {
  my ($self, $verifier) = @_;

  if (!$self->get_token() || !$self->get_token_secret()) {
     return "No request token is available to upgrade.";
  }

  my $request = Net::OAuth->request("access token")->new(
    consumer_key => $self->get_consumer_key(),
    consumer_secret => $self->get_consumer_secret(),
    token => $self->get_token(),
    token_secret => $self->get_token_secret(),
    request_url => $self->get_access_token_url(),
    request_method => "POST",
    signature_method => "HMAC-SHA1",
    timestamp => $self->_timestamp(),
    nonce => $self->_nonce(),
    verifier => $verifier
  );

  $request->sign;

  my $ua = LWP::UserAgent->new();
  my $res = $ua->request(POST $request->to_url);

  if (!$res->is_success()) {
    return "Something went wrong obtaining access token";
  }

  my $response =
      Net::OAuth->response("access token")->from_post_body($res->content);

  $self->set_token($response->token);
  $self->set_token_secret($response->token_secret);
}

# Internal methods.
sub _get_protected_resource_url {
  my ($self, $url) = @_;

  my $request = Net::OAuth->request("protected resource")->new(
    consumer_key => $self->get_consumer_key(),
    consumer_secret => $self->get_consumer_secret(),
    token => $self->get_token(),
    token_secret => $self->get_token_secret(),
    request_url => $url,
    signature_method => "HMAC-SHA1",
    request_method => "POST",
    timestamp => $self->_timestamp(),
    nonce => $self->_nonce()
  );

  $request->sign;

  return $request->to_url;
}

# Get the timestamp to include in requests.
sub _timestamp {
  return time;
}

# Get the nonce to include in requests.
sub _nonce {
  return int(rand(2**32));
}

sub _scope {
  my $self = shift;
  die "Need to be implemented by subclass";
}

1;

=pod

=head1 NAME

Google::Ads::Common::OAuth1_0aHandler

=head1 DESCRIPTION

A partial implementation of L<Google::Ads::Common::OAuth1_0aHandlerInterface>
that defines most of the logic required to use OAuth against Google Ads
endpoints.

It is meant to be specialized and its L<_scope> method be properly implemented.

=head1 ATTRIBUTES

Each of these attributes can be set via
Google::Ads::Common::OAuth1_0aHandler->new().
Alternatively, there is a get_ and set_ method associated with each attribute
for retrieving or setting them dynamically.

=head2 request_token_url

Request token URL used to retrieve a request token meant to be later authorized
and upgraded to an access token. Defaults to
L<Google::Ads::Common::Constants::DEFAULT_OAUTH_REQUEST_TOKEN_URL>.

=head2 authorize_token_url

Authorize token URL used to generate the location the user has to use to
a valid request token. Defaults to
L<Google::Ads::Common::Constants::DEFAULT_OAUTH_AUTHORIZE_TOKEN_URL>.

=head2 access_token_url

Access token URL used to upgrade an authorized request token. Defaults to
L<Google::Ads::Common::Constants::DEFAULT_OAUTH_ACCESS_TOKEN_URL>.

=head2 consumer_key

OAuth consumer key used include in requests, refer to
http://code.google.com/apis/accounts/docs/RegistrationForWebAppsAuto.html
for more information how to request this key. Defaults to
L<Google::Ads::Common::Constants::DEFAULT_OAUTH_CONSUMER_KEY> which is meant
to be used only during tests.

=head2 consumer_secret

OAuth consumer secret used to sign requests, refer to
http://code.google.com/apis/accounts/docs/RegistrationForWebAppsAuto.html
for more information how to request this key. Defaults to
L<Google::Ads::Common::Constants::DEFAULT_OAUTH_CONSUMER_KEY> which is meant
to be used only during tests.

=head2 token

OAuth token included in every request, this attribute will hold either a request
token while in the process of requesting permission to the user to access his
account or an upgraded access token, that can then be kept as foverer unless
the user revokes its access, and used to access restricted resources as for
example Ads API endpoints. For more information about this process refer to
http://code.google.com/apis/accounts/docs/RegistrationForWebAppsAuto.html

=head2 token_secret

OAuth token secret used to sign every request, this attribute will hold either a
request token secret while in the process of requesting permission to the user
to access his account or an upgraded access token secret, that can then be kept
foverer unless the user revokes its access, and used to access restricted
resources as for example Ads API endpoints. For more information about this
process refer to
http://code.google.com/apis/accounts/docs/RegistrationForWebAppsAuto.html

=head2 display_name

OAuth display name include as part of a request token and displayed to the
user when authorizing access to your application.

=head1 METHODS

=head2 initialize

Initializes the handler with properties such as the consumer_key and
consumer_secret to use for generating authorization requests.

=head3 Parameters

=over

=item *

A required I<api_client> with a reference to the API client object handling the
requests against the API.

=item *

A hash reference with the following keys:
{
  # A consumer key generated from the API console.
  oAuthConsumerKey => "consumer key",
  # A consumer secret generated from the API console.
  oAuthConsumerSecret => "consumer secret",
  # Display name shown to the user when requesting authorization.
  oAuthDisplayName => "name",
  # Optionally an access token and secret can be manually set if authorization
  # was previosly requested.
  oAuthToken => "token",
  oAuthTokenSecret => "secret",
}

=head2 is_auth_enabled

Refer to L<Google::Ads::Common::AuthHandlerInterface> documentation of this
method.

=head2 prepare_request

Refer to L<Google::Ads::Common::AuthHandlerInterface> documentation of this
method.

=head2 get_authorization_url

Refer to L<Google::Ads::Common::OAuthHandlerInterface> documentation of this
method.

=head2 issue_access_token

Refer to L<Google::Ads::Common::OAuthHandlerInterface> documentation of this
method.

=head2 _timestamp

Returns a valid OAuth timestamp to be included in every request. The timestamp
is expressed in the number of seconds since January 1, 1970 00:00:00 GMT.

=head2 _nonce

Returns a valid OAuth nonce to be included in every request. A nonce is a random
string, uniquely generated for each request. Which is generated using
the more secure Math::Random::MT subroutines with a fallback to the language
subroutines if the module can't be loaded.

=head2 _scope

Meant to be implemented by subclasses to define the valid XOAuth scope to be
included in every request.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Google Inc.

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

David Torres E<lt>david.t at google.comE<gt>

=head1 REPOSITORY INFORMATION

 $Rev: $
 $LastChangedBy: $
 $Id: $

=cut
