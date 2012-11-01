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
# This example adds campaigns.
#
# Tags: CampaignService.mutate
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201206::Budget;
use Google::Ads::AdWords::v201206::BudgetOptimizer;
use Google::Ads::AdWords::v201206::Campaign;
use Google::Ads::AdWords::v201206::CampaignOperation;
use Google::Ads::AdWords::v201206::FrequencyCap;
use Google::Ads::AdWords::v201206::GeoTargetTypeSetting;
use Google::Ads::AdWords::v201206::KeywordMatchSetting;
use Google::Ads::AdWords::v201206::ManualCPC;
use Google::Ads::AdWords::v201206::Money;
use Google::Ads::AdWords::v201206::NetworkSetting;
use Google::Ads::AdWords::v201206::TargetRestrictSetting;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

sub add_campaigns {
  my $client = shift;

  my $num_campaigns = 2;
  my @operations = ();
  for (my $i = 0; $i < $num_campaigns; $i++) {
    # Create campaign.
    my (undef, undef, undef, $mday, $mon, $year) = localtime(time);
    my $today = sprintf("%d%02d%02d", ($year + 1900), ($mon + 1), $mday);
    (undef, undef, undef, $mday, $mon, $year) = localtime(time + 60 * 60 * 24);
    my $tomorrow = sprintf("%d%02d%02d", ($year + 1900), ($mon + 1), $mday);
    my $campaign = Google::Ads::AdWords::v201206::Campaign->new({
      name =>  "Interplanetary Cruise #" . uniqid(),
      # Bidding strategy (required).
      biddingStrategy => Google::Ads::AdWords::v201206::ManualCPC->new(),
      # Budget (required).
      budget => Google::Ads::AdWords::v201206::Budget->new({
        amount => Google::Ads::AdWords::v201206::Money->new({
          microAmount => 5000000
        }),
        deliveryMethod => "STANDARD",
        period => "DAILY",
      }),
      # Network targeting (recommended).
      networkSetting => Google::Ads::AdWords::v201206::NetworkSetting->new({
        targetGoogleSearch => 1,
        targetSearchNetwork => 1,
        targetContentNetwork => 1,
        targetPartnerSearchNetwork => 0
      }),
      # Frecuency cap (non-required).
      frequencyCap => Google::Ads::AdWords::v201206::FrequencyCap->new({
        impressions => 5,
        timeUnit => "DAY",
        level => "ADGROUP"
      }),
      settings => [
          # Display network targeting settings (non-required).
          # It can only be enabled, shown only for demonstration purposes.
          # If not set this setting is enabled by default on ADD operations.
          Google::Ads::AdWords::v201206::TargetRestrictSetting->new({
            useAdGroup => 1
          }),
          # Advanced location targeting settings (non-required).
          Google::Ads::AdWords::v201206::GeoTargetTypeSetting->new({
            positiveGeoTargetType => "DONT_CARE",
            negativeGeoTargetType => "DONT_CARE"
          }),
          # Keyword match setting (non-required).
          Google::Ads::AdWords::v201206::KeywordMatchSetting->new({
            optIn => 0
          })
      ],
      # Additional properties (non-required).
      startDate => $today,
      endDate => $tomorrow,
      status => "PAUSED",
      adServingOptimizationStatus => "ROTATE"
    });

    # Create operation.
    my $campaign_operation =
        Google::Ads::AdWords::v201206::CampaignOperation->new({
          operator => "ADD",
          operand => $campaign
        });
    push @operations, $campaign_operation;
  }

  # Add campaigns.
  my $result = $client->CampaignService()->mutate({
    operations => \@operations
  });

  # Display campaigns.
  foreach my $campaign (@{$result->get_value()}) {
    printf "Campaign with name \"%s\" and id \"%s\" was added.\n",
           $campaign->get_name(), $campaign->get_id();
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
add_campaigns($client);