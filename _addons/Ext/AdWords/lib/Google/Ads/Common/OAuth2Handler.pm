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

package Google::Ads::Common::OAuth2Handler;

use strict;
use version;
use base qw(Google::Ads::Common::OAuthHandlerInterface);

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::Common::Constants; our $VERSION = ${Google::Ads::Common::Constants::VERSION};

use Class::Std::Fast;
use HTTP::Request::Common;
use LWP::UserAgent;
use URI::Escape;

use constant OAUTH2_BASE_URL => "https://accounts.google.com/o/oauth2";
use constant OAUTH2_TOKEN_INFO_URL =>
    "https://www.googleapis.com/oauth2/v1/tokeninfo";
use constant OAUTH2_SCOPE => "https://adwords.google.com/api/adwords/";

# Class::Std-style attributes. Need to be kept in the same line.
my %api_client_of : ATTR(:name<api_client> :default<>);
my %client_id_of : ATTR(:name<client_id> :default<>);
my %client_secret_of : ATTR(:name<client_secret> :default<>);
my %access_type_of : ATTR(:name<access_type> :default<offline>);
my %approval_prompt_of : ATTR(:name<approval_prompt> :default<auto>);
my %access_token_of : ATTR(:init_arg<access_token> :default<>);
my %access_token_expires_of : ATTR(:name<access_token_expires> :default<>);
my %refresh_token_of : ATTR(:name<refresh_token> :default<>);
my %redirect_uri_of : ATTR(:name<redirect_uri>
    :default<urn:ietf:wg:oauth:2.0:oob>);
my %__user_agent_of : ATTR(:name<__user_agent> :default<>);

# Constructor
sub START {
    my ($self, $ident) = @_;

  $__user_agent_of{$ident} ||= LWP::UserAgent->new();
}

# Methods from Google::Ads::Common::AuthHandlerInterface
sub initialize {
  my ($self, $api_client, $properties) = @_;
  my $ident = ident $self;

  $api_client_of{$ident} = $api_client;
  $client_id_of{$ident} = $properties->{oAuth2ClientId} || $client_id_of{$ident};
  $client_secret_of{$ident} = $properties->{oAuth2ClientSecret} ||
      $client_secret_of{$ident};
  $access_type_of{$ident} = $properties->{oAuth2AccessType} ||
      $access_type_of{$ident};
  $approval_prompt_of{$ident} = $properties->{oAuth2ApprovalPrompt} ||
      $approval_prompt_of{$ident};
  $access_token_of{$ident} = $properties->{oAuth2AccessToken} ||
      $access_token_of{$ident};
  $refresh_token_of{$ident} = $properties->{oAuth2RefreshToken} ||
      $refresh_token_of{$ident};
  $redirect_uri_of{$ident} = $properties->{oAuth2RedirectUri} ||
      $redirect_uri_of{$ident};
}

sub prepare_request {
  my ($self, $endpoint, $http_headers, $envelope) = @_;

  my $access_token = $self->get_access_token();

  if (!$access_token) {
    my $api_client = $self->get_api_client();
    my $err_msg = "Unable to prepare a request, authorization info is incomplete or invalid.";
    $api_client->get_die_on_faults() ? die($err_msg) : warn($err_msg);
    return;
  }

  push @{$http_headers}, ("Authorization", "Bearer ${access_token}");

  return HTTP::Request->new('POST', $endpoint, $http_headers, $envelope);
}

sub is_auth_enabled {
  my ($self) = @_;

  return $self->get_access_token();
}


# Methods from Google::Ads::Common::OAuthHandlerInterface
sub get_authorization_url {
  my ($self, $state) = @_;

  $state ||= "";
  my ($client_id, $redirect_uri, $access_type, $approval_prompt) =
      ($self->get_client_id(), $self->get_redirect_uri(),
       $self->get_access_type(), $self->get_approval_prompt());

  return OAUTH2_BASE_URL . "/auth?response_type=code" .
      "&client_id=" . uri_escape($client_id) .
      "&redirect_uri=" . $redirect_uri .
      "&scope=" . uri_escape($self->_scope()) .
      "&access_type=" . $access_type .
      "&approval_prompt=" . $approval_prompt .
      "&state=" . uri_escape($state);
}

sub issue_access_token {
  my ($self, $authorization_code) = @_;

  my $body = "code=" . uri_escape($authorization_code) .
      "&client_id=" . uri_escape($self->get_client_id()) .
      "&client_secret=" . uri_escape($self->get_client_secret()) .
      "&redirect_uri=" . uri_escape($self->get_redirect_uri()) .
      "&grant_type=authorization_code";

  push my @headers, "Content-Type" => "application/x-www-form-urlencoded";
  my $request = HTTP::Request->new("POST", OAUTH2_BASE_URL . "/token",
                                   \@headers, $body);
  my $res = $self->get___user_agent()->request($request);

  if (!$res->is_success()) {
    return $res->decoded_content();
  }

  my $content_hash = __parse_auth_response($res->decoded_content());

  $self->set_access_token($content_hash->{access_token});
  $self->set_refresh_token($content_hash->{refresh_token});
  $self->set_access_token_expires(time + $content_hash->{expires_in});

  return undef;
}

# Custom getters and setters for the access token with logic to auto-refresh.
sub get_access_token {
  my $self = shift;

  my $access_token = $access_token_of{ident $self};
  if (!$access_token && !$self->get_refresh_token()) {
    return undef;
  }

  if (!$self->_is_access_token_valid()) {
    if (!$self->_refresh_access_token()) {
      return undef;
    }

    return $access_token_of{ident $self};
  }

  return $access_token;
}

sub set_access_token {
  my ($self, $token) = @_;

  $access_token_of{ident $self} = $token;
  $access_token_expires_of{ident $self} = undef;
}

# Internal methods

sub _refresh_access_token {
  my $self = shift;

  if (!$self->get_refresh_token()) {
    return 0;
  }

  my $body = "refresh_token=" . uri_escape($self->get_refresh_token()) .
      "&client_id=" . uri_escape($self->get_client_id()) .
      "&client_secret=" . uri_escape($self->get_client_secret()) .
      "&grant_type=refresh_token";

  push my @headers, "Content-Type" => "application/x-www-form-urlencoded";
  my $request = HTTP::Request->new("POST", OAUTH2_BASE_URL . "/token",
                                   \@headers, $body);
  my $res = $self->get___user_agent()->request($request);

  if (!$res->is_success()) {
    return 0;
  }

  my $content_hash = __parse_auth_response($res->decoded_content());

  $self->set_access_token($content_hash->{access_token});
  $self->set_access_token_expires(time + $content_hash->{expires_in});

  return 1;
}

# Checks if:
#   - the access token is set
#   - if the token has no expiration set then assumes it was manually set and:
#       - checks the token info, if it is valid then set its expiration
#       - checks the token scopes
#   - checks the token has not expired
sub _is_access_token_valid {
  my $self = shift;

  my $access_token = $access_token_of{ident $self};
  if (!$access_token) {
    return 0;
  }

  if (!$self->get_access_token_expires()) {
    my $url = OAUTH2_TOKEN_INFO_URL .
        "?access_token=" . uri_escape($access_token);
    my $res = $self->get___user_agent()->request(GET $url);
    if (!$res->is_success()) {
      return 0;
    }
    my $content_hash = __parse_auth_response($res->decoded_content());
    my %token_scopes = map { $_ => 1 } split(" ", $content_hash->{scope});

    foreach my $required_scope ($self->_scope()) {
      if (!exists($token_scopes{$required_scope})) {
        return 0;
      }
    }
    $self->set_access_token_expires(time + $content_hash->{expires_in});
  }

  return time < $self->get_access_token_expires() - 10;
}

sub __parse_auth_response {
  my $response_content = shift;

  my %content_hash = ();
  while ($response_content =~ m/([^"]+)"\s*:\s*"([^"]+)|([^"]+)"\s*:\s*([0-9]+)/g) {
    if ($1 && $2) {
      $content_hash{$1} = $2;
    } else {
      $content_hash{$3} = $4;
    }
  }

  return \%content_hash;
}

sub _scope {
  my $self = shift;
  die "Need to be implemented by subclass";
}

1;

=pod

=head1 NAME

Google::Ads::Common::OAuth2Handler

=head1 DESCRIPTION

A partial implementation of L<Google::Ads::Common::OAuthHandlerInterface> that
defines most of the logic required to use OAuth2 against Google APIs.

It is meant to be specialized and its L<_scope> method be properly implemented.

=head1 ATTRIBUTES

Each of these attributes can be set via
Google::Ads::Common::OAuth2Handler->new().

Alternatively, there is a get_ and set_ method associated with each attribute
for retrieving or setting them dynamically.

=head2 api_client

A reference to the API client used to send requests.

=head2 client_id

OAuth2 client id obtained from the Google APIs Console.

=head2 client_secret

OAuth2 client secret obtained from the Google APIs Console.

=head2 access_type

OAuth2 access type to be requested when following the authorization flow. It
defaults to offline but it can be set to online.

=head2 approval_prompt

OAuth2 approval_prompt to be used when following the authorization flow. It
defaults to auto but it can be set to always - to force the user to always
authorize.

=head2 redirect_uri

Redirect URI as set for you in the Google APIs console, to which the
authorization flow will callback with the verification code. Defaults to
urn:ietf:wg:oauth:2.0:oob for the installed applications flow.

=head2 access_token

Stores an OAuth2 access token after the authorization flow is followed or for
you to manually set it in case you had it previously stored.
If this is manually set this handler will verify its validity before preparing
a request.

=head2 refresh_token

Stores an OAuth2 refresh token in case of an offline L<access_type> is
requested. It is automatically used by the handler to request new access tokens
i.e. when they expire or found invalid.

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
  # Refer to the documentation of the L<client_id> property.
  oAuth2ClientId => "consumer key",
  # Refer to the documentation of the L<client_secret> property.
  oAuth2ClientSecret => "consumer secret",
  # Refer to the documentation of the L<access_type> property.
  oAuth2AccessType => "name",
  # Refer to the documentation of the L<approval_prompt> property.
  oAuth2ApprovalPrompt => "token",
  # Refer to the documentation of the L<access_token> property.
  oAuth2AccessToken => "secret",
  # Refer to the documentation of the L<refresh_token> property.
  oAuth2RefreshToken => "secret",
  # Refer to the documentation of the L<redirect_uri> property.
  oAuth2RedirectUri => "secret",
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
