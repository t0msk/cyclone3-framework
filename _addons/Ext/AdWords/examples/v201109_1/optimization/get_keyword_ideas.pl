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
# This example gets keywords related to a seed keyword.
#
# Tags: TargetingIdeaService.get
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201109_1::Keyword;
use Google::Ads::AdWords::v201109_1::KeywordMatchTypeSearchParameter;
use Google::Ads::AdWords::v201109_1::Paging;
use Google::Ads::AdWords::v201109_1::RelatedToKeywordSearchParameter;
use Google::Ads::AdWords::v201109_1::TargetingIdeaSelector;
use Google::Ads::Common::MapUtils;

use Cwd qw(abs_path);

# Example main subroutine.
sub get_keyword_ideas {
  my $client = shift;

  # Create seed keyword.
  my $seed_keyword = Google::Ads::AdWords::v201109_1::Keyword->new({
    text => "mars cruise",
    matchType => "BROAD"
  });

  # Create selector.
  my $selector = Google::Ads::AdWords::v201109_1::TargetingIdeaSelector->new({
    requestType => "IDEAS",
    ideaType => "KEYWORD",
    requestedAttributeTypes => ["CRITERION",
                                "AVERAGE_TARGETED_MONTHLY_SEARCHES",
                                "CATEGORY_PRODUCTS_AND_SERVICES"],
  });

  # Set selector paging (required for targeting idea service).
  my $paging = Google::Ads::AdWords::v201109_1::Paging->new({
    startIndex => 0,
    numberResults => 10
  });
  $selector->set_paging($paging);

  # Create related to keyword search parameter.
  my $keyword_search_parameter =
      Google::Ads::AdWords::v201109_1::RelatedToKeywordSearchParameter->new({
        keywords => [$seed_keyword]
      });

  # Create keyword match type search parameter to ensure unique results.
  my $keyword_match_type =
      Google::Ads::AdWords::v201109_1::KeywordMatchTypeSearchParameter->new({
        keywordMatchTypes => ["BROAD"]
      });
  $selector->set_searchParameters([$keyword_search_parameter,
                                   $keyword_match_type]);

  # Get related keywords.
  my $page = $client->TargetingIdeaService()->get({selector => $selector});

  # Display related keywords.
  if ($page->get_entries()) {
    foreach my $targeting_idea (@{$page->get_entries()}) {
      my $data =
          Google::Ads::Common::MapUtils::get_map($targeting_idea->get_data());
      my $keyword = $data->{"CRITERION"}->get_value();
      my $average_monthly_searches =
          $data->{"AVERAGE_TARGETED_MONTHLY_SEARCHES"}->get_value()?
          $data->{"AVERAGE_TARGETED_MONTHLY_SEARCHES"}->get_value():0;
      my $categories =
          $data->{"CATEGORY_PRODUCTS_AND_SERVICES"}->get_value()?
          $data->{"CATEGORY_PRODUCTS_AND_SERVICES"}->get_value():[];
      printf "Keyword with text \"%s\", match type \"%s\", average " .
             "monthly search volume \"%s\" and categories \"%s\" was found.\n",
             $keyword->get_text(), $keyword->get_matchType(),
             $average_monthly_searches, join(", ", @{$categories});
    }
  } else {
    print "No related keywords were found.\n";
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
get_keyword_ideas($client);
