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

package Google::Ads::Common::MapUtils;

use strict;
use version;

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::Common::Constants; our $VERSION = ${Google::Ads::Common::Constants::VERSION};


# Gets a map (associative array) from an array of map entries. A map entry is
# any object that has a key and value field.
sub get_map($) {
  my $map_entries = $_[0];
  my %result = ();
  foreach my $map_entry (@{$map_entries}) {
    $result{$map_entry->get_key()} = $map_entry->get_value();
  }
  return \%result;
}

return 1;

=pod

=head1 NAME

Google::Ads::Common::MapUtils

=head1 SYNOPSIS

 use Google::Ads::Common::MapUtils;

 my $map_entries = Google::Ads::Common::MapUtils::get_map($map_xml);
 # Make use of $map_entries.

=head1 DESCRIPTION

A collection of utility methods for working with maps (associative arrays).

=head1 SUBROUTINES

=head2 get_map

Gets a map (associative array) from an array of map entries. A map entry is any
object that has a key and value field.

=head3 Parameters

An array of map entries.

=head3 Returns

A map built from the keys and values of the map entries.

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

David Torres E<lt>api.davidtorres at gmail.comE<gt>

=head1 REPOSITORY INFORMATION

 $Rev: $
 $LastChangedBy: $
 $Id: $

=cut
