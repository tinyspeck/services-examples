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

=head1 NAME

nagios.pl - A nagios/icinga plugin for sending alerts to Slack

=head1 AUTHOR

Tiny Speck, Inc

=head1 SYNOPSIS

B<nagios.pl> [B<--help>] [B<-field slack_SOMETHING=value>]

=head2 -h, --help

This output

=head2 -field

Provide B<slack> related configuration. Possible choices include:

  * slack_channel - Target Slack channel for the message
  * slack_domain  - Slack domain for your team
  * slack_token   - Slack token for this integration

B<NOTE:> Providing the Slack token on the CLI might allow it to be
read from /proc or the like.

=head1 REQUIRES

Perl5.004, L<strict>, L<warnings>, L<HTTP::Request>, L<LWP::UserAgent>

=head1 EXPORTS

Nothing

=head1 DESCRIPTION

A nagios/icinga plugin for sending alerts to Slack. See more documentation on the team services page at:
 L<https://my.slack.com/services/new/nagios>

An example Nagios config:

  define contact {
        contact_name                             slack
        alias                                    Slack
        service_notification_period              24x7
        host_notification_period                 24x7
        service_notification_options             w,u,c,r
        host_notification_options                d,r
        service_notification_commands            notify-service-by-slack
        host_notification_commands               notify-host-by-slack
  }

  define command {
        command_name     notify-service-by-slack
        command_line     /usr/local/bin/slack_nagios.pl -field slack_channel=#alerts -field slack_domain=yourteam.slack.com -field slack_token=Som3th1ngR@nd0m
  }

  define command {
        command_name     notify-host-by-slack
        command_line     /usr/local/bin/slack_nagios.pl -field slack_channel=#ops  -field slack_domain=yourteam.slack.com -field slack_token=Som3th1ngR@nd0m
  }

=cut

use warnings;
use strict;

use Getopt::Long;
use HTTP::Request::Common qw(POST);
use HTTP::Status qw(is_client_error);
use LWP::UserAgent;


#
# Customizable vars. Set these to the information for your team
#

my $opt_domain = "foo.slack.com"; # Your team's domain
my $opt_token = ""; # The token from your Nagios services page


#
# Get command-line opts
#

my %opt_fields;
GetOptions("field=s%" => \%opt_fields)
  or exec( "pod2usage -v 1 $0 1>&2" );

#
# Allow these to be provided via command-line opts (fall back to defaults)
#
$opt_domain = $opt_fields{'slack_domain'} || $opt_domain;
delete($opt_fields{'slack_domain'});

$opt_token = $opt_fields{'slack_token'} || $opt_token;
delete($opt_fields{'slack_token'});

#
# DO THINGS
#

my %event;

# Get all Nagios variables
while ((my $k, my $v) = each %ENV) {
	next unless $k =~ /^(?:NAGIOS|ICINGA)_(.*)$/;
	$event{$1} = $v;
}

# Merge in passed-in variables
%event = (%event, %opt_fields);

$event{"slack_version"} = "1.1";


#
# Make the request
#

my $ua = LWP::UserAgent->new;
$ua->timeout(15);

my $req = POST("https://${opt_domain}/services/hooks/nagios?token=${opt_token}", \%event);

my $s = $req->as_string;
print STDERR "Request:\n$s\n";

my $resp = $ua->request($req);
$s = $resp->as_string;
print STDERR "Response:\n$s\n";
