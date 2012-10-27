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
# This example gets the account hierarchy under the current account.
#
# Tags: ServicedAccountService.get
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201109_1::ServicedAccountSelector;

use Cwd qw(abs_path);

sub display_account_tree;

# Example main subroutine.
sub get_account_hierarchy {
  my $client = shift;

  # Force to use the MCC credentials.
  $client->set_client_id(undef);

  # Create selector.
  my $selector = Google::Ads::AdWords::v201109_1::ServicedAccountSelector->new({
    # To get the links, paging must be disabled.
    enablePaging => 0
  });

  # Get account graph.
  my $graph = $client->ServicedAccountService()->get({
    selector => $selector
  });

  # Display Serviced account graph.
  if ($graph->get_accounts()) {
    # Create map from customerId to parent and child links.
    my $child_links = {};
    my $parent_links = {};
    if ($graph->get_links()) {
      foreach my $link (@{$graph->get_links()}) {
        if (!$child_links->{$link->get_managerId()->get_id()}) {
          $child_links->{$link->get_managerId()->get_id()} = [];
        }
        push @{$child_links->{$link->get_managerId()->get_id()}}, $link;
        if (!$parent_links->{$link->get_clientId()->get_id()}) {
          $parent_links->{$link->get_clientId()->get_id()} = [];
        }
        push @{$parent_links->{$link->get_clientId()->get_id()}}, $link;
      }
    }
    # Create map from customerID to account, and find root account.
    my $accounts = {};
    my $root_account;
    foreach my $account (@{$graph->get_accounts()}) {
      $accounts->{$account->get_customerId()} = $account;
      if (!$parent_links->{$account->get_customerId()}) {
        $root_account = $account;
      }
    }
    # Sandbox doesn't handle parent links properly, so use a fake account.
    if (!$root_account && scalar(keys %{$child_links}) > 0) {
      $root_account = new Google::Ads::AdWords::v201109_1::Account({
        customerId => (keys %{$child_links}),
        login      => "Root"
      });
    }
    # Display account tree.
    print "Login, CustomerId (Status, Description)\n";
    display_account_tree($root_account, undef, $accounts, $child_links, 0);
  } else {
    print "No serviced accounts were found.\n";
  }

  return 1;
}

# Displays an account tree, starting at the account and link provided, and
# recursing to all child accounts.
sub display_account_tree {
  my ($account, $link, $accounts, $links, $depth) = @_;
  print "-" x ($depth * 2);
  print " ";
  if ($account->get_login() ne "") {
    print $account->get_login() . ", ";
  }
  print $account->get_customerId();
  if ($link) {
    print " (" . $link->get_typeOfLink();
    if ($link->get_descriptiveName() ne "") {
      print ", " . $link->get_descriptiveName();
    }
    print ")";
  }
  print "\n";
  if ($links->{$account->get_customerId()}) {
    foreach my $child_link (@{$links->{$account->get_customerId()}}) {
      my $child_account = $accounts->{$child_link->get_clientId()->get_id()};
      display_account_tree($child_account, $child_link, $accounts, $links,
          $depth + 1);
    }
  }
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
get_account_hierarchy($client);
