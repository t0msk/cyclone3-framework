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
# This example gets and downloads a defined report from a report definition.
#
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::Common::ReportUtils;

use Cwd qw(abs_path);
use File::Basename;

# Replace with valid values of your account.
my $report_definition_id = "INSERT_REPORT_DEFINITION_ID_HERE";
my $file_name = "INSERT_OUTPUT_FILE_NAME_HERE";

# Example main subroutine.
sub download_defined_report {
  my $client = shift;
  my $report_definition_id = shift;
  my $file_name = shift;

  my $path = dirname($0) . "/" . $file_name;

  # Download report.
  Google::Ads::Common::ReportUtils::download_report($report_definition_id,
                                                    $client, $path);

  printf("Report with definition id \"%s\" was downloaded to \"%s\".\n",
         $report_definition_id, $path);

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
download_defined_report($client, $report_definition_id, $file_name);
