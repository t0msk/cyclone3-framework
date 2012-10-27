#!/usr/bin/perl -w
#
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
#
# This code example retrieves the unit usage for a client account for the
# current month.
#
# Tags: InfoService.get
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201109_1::InfoSelector;

use Cwd qw(abs_path);

# Example main subroutine.
sub get_client_unit_usage {
  my $client = shift;

  # Force to use the MCC credentials but report about the specified client id.
  my $client_id = $client->get_client_id();
  $client_id =~ s/-//g;
  $client->set_client_id(undef);

  # Create selector.
  my (undef, undef, undef, $mday, $mon, $year) = localtime(time);
  my $today = sprintf("%d%02d%02d", ($year + 1900), ($mon + 1), $mday);
  my $start_of_the_month = sprintf("%d%02d01", $year, $mon + 1);
  my $selector = Google::Ads::AdWords::v201109_1::InfoSelector->new({
    apiUsageType => "UNIT_COUNT_FOR_CLIENTS",
    clientCustomerIds => $client_id,
    # Set to true to navigate your entire accounts tree.
    includeSubAccounts => 1,
    # From the start of the month until today.
    dateRange => new Google::Ads::AdWords::v201109_1::DateRange({
      min => $start_of_the_month,
      max => $today
    })
  });

  # Get api usage info.
  my $api_info = $client->InfoService()->get({selector => $selector});

  # Display api usage info.
  if ($api_info) {
    foreach my $record (@{$api_info->get_apiUsageRecords()}) {
      print "API usage for customer ID ", $record->get_clientCustomerId(),
            " is ", $record->get_cost(), " units.\n";
    }
  } else {
    print "No API usage records were found.\n";
  }

  return 1;
}

# Don't run the example if the file is being included.
if (abs_path($0) ne abs_path(__FILE__)) {
  return 1;
}

# Log SOAP XML request, response and API errors.
Google::Ads::AdWords::Logging::enable_all_logging();

# Get AdWords Client, credentials will be read from ~/adwords.properties.
my $client = Google::Ads::AdWords::Client->new({version => "v201109_1"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
get_client_unit_usage($client);
