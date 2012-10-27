#!/usr/bin/perl -w
#
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
#
# This example gets all report definitions. To add a report definition, run
# add_keywords_performance_report_definition.pl.
#
# Tags: ReportDefinitionService.get
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201109::ReportDefinition;
use Google::Ads::AdWords::v201109::ReportDefinitionSelector;

use Cwd qw(abs_path);

# Example main subroutine.
sub get_defined_reports {
  my $client = shift;

  # Create selector.
  my $selector = Google::Ads::AdWords::v201109::ReportDefinitionSelector->new();

  # Get all report definitions.
  my $page = $client->ReportDefinitionService()->get({
    selector => $selector
  });

  # Display report definitions.
  if ($page->get_entries()) {
    foreach my $report_definition (@{$page->get_entries()}) {
       printf "ReportDefinition with name \"%s\" and id \"%s\" was found.\n",
              $report_definition->get_reportName(),
              $report_definition->get_id();
    }
  } else {
    print "No report definitions were found.\n";
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
my $client = Google::Ads::AdWords::Client->new({version => "v201109"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
get_defined_reports($client);
