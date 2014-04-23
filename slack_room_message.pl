#!/usr/bin/perl

# Copyright 2013 Tiny Speck, Inc
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
# Completely generic shell-style script for sending messages to Slack. 
# Derived from https://github.com/tinyspeck/services-examples/blob/master/nagios.pl
#
# Requires these perl modules:
# HTTP::Request
# LWP::UserAgent
#

use warnings;
use strict;

use Getopt::Long;
use HTTP::Request::Common qw(POST);
use HTTP::Status qw(is_client_error);
use LWP::UserAgent;
use JSON;


#
# Customizable vars. Set these to the information for your team
#

my $opt_domain = "foo.slack.com"; # Your team's domain
my $opt_token = ""; # The token from your Incoming Webhook services page


#
# Get command-line opts
#

my $text;
my $username;
my $channel;
GetOptions("text=s" => \$text,
           "username=s" => \$username,
           "channel=s" => \$channel);

die ("Usage: $0 -text=TEXT -username=USER -channel=CHANNEL") unless ($text and $username and $channel);


my $payload = {
  'text' => $text,
  'username' => $username,
  'channel' => $channel
};

#
# Make the request
#

my $ua = LWP::UserAgent->new;
$ua->timeout(15);

my $req = POST("https://${opt_domain}/services/hooks/incoming-webhook?token=${opt_token}", ['payload' => encode_json($payload)] );

my $s = $req->as_string;
print STDERR "Request:\n$s\n";

my $resp = $ua->request($req);
$s = $resp->as_string;
print STDERR "Response:\n$s\n";
