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
# This example demonstrates how to authenticate using OAuth.  This example
# is meant to be run from the command line and requires user input.
#
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201109::OrderBy;
use Google::Ads::AdWords::v201109::Predicate;
use Google::Ads::AdWords::v201109::Selector;

use Cwd qw(abs_path);

# Example main subroutine.
sub use_oauth {
  my $client = shift;

  # Set the OAuth consumer key and secret. Anonymous values can be used for
  # testing, and real values can be obtained by registering your application:
  # http://code.google.com/apis/accounts/docs/RegistrationForWebAppsAuto.html
  $client->set_oauth_consumer_key("anonymous");
  $client->set_oauth_consumer_secret("anonymous");
  # Optionally you can set your test application display name which will
  # appear to the user when granting you access.
  $client->set_oauth_display_name("Test application");

  # In a web application you would redirect the user to the authorization URL
  # and after approving the token they would be redirected back to the
  # callbackUrl. For desktop application spawn a browser to the URL and
  # then have the user enter the generated verification code.
  # Using "oob" special destination URL to get the verification code printed in
  # the page.
  print "Log in to your AdWords account and open the following URL: ",
        $client->get_oauth_authorization_url("oob"), "\n";
  print "Grant access to the applications and enter the verifier code " .
        "display in the page then hit ENTER.\n";
  my $verifier = <STDIN>;
  # Trimming the value.
  $verifier =~ s/^\s*(.*)\s*$/$1/;

  # Upgrading the authorized token, so it can be used to access the API.
  $client->upgrade_oauth_token($verifier);

  # After the oauth token is upgraded to an access token, you should store the
  # token and the secret and re-use them for future calls, by either changing
  # your adwords.properties file or passing them in the constructor of the
  # client:
  # Google::Ads::AdWords::Client->new({
  #   version => "v201109",
  #   oauth_token => $my_token
  #   oauth_token_secret => $my_token_secret
  # });
  print "OAuth Token: ", $client->get_oauth_token(), "\n",
        "OAuth Token Secret: ", $client->get_oauth_token_secret(), "%s\n\n";

  # Create selector.
  my $selector = Google::Ads::AdWords::v201109::Selector->new({
    fields => ["Id", "Name"],
    ordering => [Google::Ads::AdWords::v201109::OrderBy->new({
      field => "Name",
      sortOrder => "ASCENDING"
    })]
  });

  # Get all campaigns.
  my $page = $client->CampaignService()->get({serviceSelector => $selector});

  # Display campaigns.
  if ($page->get_entries()) {
    foreach my $campaign (@{$page->get_entries()}) {
      print "Campaign with name '", $campaign->get_name(), "' and id '",
            $campaign->get_id(), "' was found.\n";
    }
  } else {
    print "No campaigns were found.\n";
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
use_oauth($client);
