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
# A nagios/icinga plugin for sending alerts to [redacted]. See more documentation on the team services page.
#
# Requires these perl modules:
# HTTP::Request
# LWP::UserAgent
#
# I am not a perl programmer. Beware.
#
# An example Nagios config:
#
# define contact {
#       contact_name                             redacted
#       alias                                    Redacted
#       service_notification_period              24x7
#       host_notification_period                 24x7
#       service_notification_options             w,u,c,r
#       host_notification_options                d,r
#       service_notification_commands            notify-service-by-redacted
#       host_notification_commands               notify-host-by-redacted
# }
#
# define command {
#       command_name     notify-service-by-redacted
#       command_line     /usr/local/bin/redacted_nagios.pl
# }
#
#define command {
#       command_name     notify-host-by-redacted
#       command_line     /usr/local/bin/redacted_nagios.pl
# }
#

use warnings;
use strict;

use HTTP::Request::Common qw(POST);
use HTTP::Status qw(is_client_error);
use LWP::UserAgent;


#
# Customizable vars. Set these to the information for your team
#

my $opt_domain = "foo.chatly.io";
my $opt_token = "";


#
# DO THINGS
#

my %event;

# Scoop all the Nagios related stuff out of the environment.
while ((my $k, my $v) = each %ENV) {
	next unless $k =~ /^ICINGA_(.*)$/;
	$event{$1} = $v;
}

$event{"slack_version"} = "1.0";


#
# Make the request
#

my $ua = LWP::UserAgent->new;
$ua->timeout(15);

my $req = POST("https://${$opt_domain}/services/hooks/nagios?token=${$opt_token}", \%event);

my $s = $req->as_string;
print STDERR "Request:\n$s\n";

my $resp = $ua->request($req);
$s = $resp->as_string;
print STDERR "Response:\n$s\n";