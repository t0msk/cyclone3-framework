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
# This example helps you map your accounts client emails to its client customer
# ids. We recommend to use this script as a one off to convert from email to
# client customer id and store them for future use.
#
# Tags: InfoService.get
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201206::InfoSelector;

use Cwd qw(abs_path);

# Replace with valid values of your account.
# Email addresses separated by comma.
my $client_emails = "INSERT_EMAIL_ADDRESSES_HERE";

# Example main subroutine.
sub get_client_customer_id {
  my $client = shift;
  my $client_emails = shift;
  $client_emails =~ s/\s+//g;
  my @emails_arr = split(/,/, $client_emails);

  # Force to use the MCC credentials.
  $client->set_client_id(undef);

  # Create selector.
  my (undef, undef, undef, $mday, $mon, $year) = localtime(time);
  my $today = sprintf("%d%02d%02d", ($year + 1900), ($mon + 1), $mday);
  my $selector = Google::Ads::AdWords::v201206::InfoSelector->new({
    apiUsageType => "UNIT_COUNT_FOR_CLIENTS",
    clientEmails => \@emails_arr,
    # Set to true to navigate your entire accounts tree.
    includeSubAccounts => 1,
    # Need to specify a date range, but it is not relevant since we only
    # care about the associated client customer ids.
    dateRange => new Google::Ads::AdWords::v201206::DateRange({
      min => $today,
      max => $today
    })
  });

  # Get api usage info.
  my $api_info = $client->InfoService()->get({selector => $selector});

  # Display api usage info.
  if ($api_info) {
    foreach my $record (@{$api_info->get_apiUsageRecords()}) {
      print "Found record with client email '", $record->get_clientEmail(),
            "' and ID ", $record->get_clientCustomerId(), ".\n";
    }
  } else {
    print "No api info match was returned.\n";
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
my $client = Google::Ads::AdWords::Client->new({version => "v201206"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
get_client_customer_id($client, $client_emails);
