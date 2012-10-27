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

package Google::Ads::AdWords::OAuth1_0aHandler;

use strict;
use version;
use base qw(Google::Ads::Common::OAuth1_0aHandler);

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::AdWords::Constants; our $VERSION = ${Google::Ads::AdWords::Constants::VERSION};

use Class::Std::Fast;

my %server_of : ATTR(:name<server> :default<"https://adwords.google.com">);

# Retrieves the XOAuth scope required for AdWords API.
sub _scope {
  my $self = shift;

  return $self->get_server() . "/api/adwords/";
}

1;

=pod

=head1 NAME

Google::Ads::AdWords::OAuth1_0aHandler

=head1 DESCRIPTION

A concrete implementation of L<Google::Ads::Common::OAuth1_0aHandler> that
defines the scope required to access AdWords API servers using
OAuth1_0a, see
L<https://developers.google.com/accounts/docs/OAuthForInstalledApps> for details
of the protocol.

Refer to the base object L<Google::Ads::Common::OAuth1_0aHandler>
for a complete documentation of all the methods supported by this handler class.

=head1 ATTRIBUTES

Each of these attributes can be set via the constructor as a hash.
Alternatively, there is a get_ and set_ method associated with each attribute
for retrieving or setting them dynamically.

=head2 server

The server URI base used to generate the scope.

=head1 METHODS

=head2 _scope

Method defined by L<Google::Ads::Common::OAuth1_0aHandler> and implemented
in this class as a requirement for the OAuth1_0a protocol.

=head3 Returns

Returns the AdWords API scope used to generate access tokens.

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
