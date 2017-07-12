#!/usr/bin/perl


# Copyright 2013 Tiny Speck, Inc
# Contributions by Dalton Scavassa @ Universidade Federal da Fronteira Sul
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
# An SVN post-commit handler for posting to Slack. Setup the channel and get the token
# from your team's services page. Change the options below to reflect your team's settings.
#
# Requires these perl modules:
# HTTP::Request
# LWP::UserAgent
# JSON
# Encode

# Submits the following post to the slack servers

# POST https: //foo.slack.com/services/hooks/subversion?token=xxxxxx
# Content-Type: application/x-www-form-urlencoded
# Host: foo.slack.com
# Content-Length: 101
#
# payload=%7B%22revision%22%3A1%2C%22url%22%3A%22http%3A%2F%2Fsvnserver%22%2C%22author%22%3A%22digiguru%22%2C%22log%22%3A%22Log%20info%22%7D

use warnings;
use strict;

use HTTP::Request::Common qw(POST);
use HTTP::Status qw(is_client_error);
use LWP::UserAgent;
use JSON;
use Encode qw(decode_utf8);

#
# Customizable vars. Set these to the information for your team
#

my $opt_domain = "MY_SUBDOMAIN.slack.com"; # Your team's Slack domain
my $opt_token = "MY_TOKEN"; # The token from your Slack SVN services page

# Optionally set this to the url of your internal commit browser. Ex: http://svnserver/wsvn/main/?op=revision&rev=$ARGV[1]
my $url = "https://MY_REDMINE/projects/MY_PROJECT/repository/revisions/$ARGV[1]";

# this script gets called by the SVN post-commit handler
# with these args:
#
# [0] path to repo
# [1] revision committed
#
# we need to find out what happened in that revision and then act on it
#

# Character encoding fix - Change LC_ALL value to to your own locale if necessary. Inspired by https://stackoverflow.com/a/33233430
my $log = qx|export LC_ALL="pt_BR.UTF-8"; /usr/bin/svnlook log -r $ARGV[1] $ARGV[0]|;
$log = decode_utf8($log);

my $who = `/usr/bin/svnlook author -r $ARGV[1] $ARGV[0]`;
chomp $who;

my $payload = {
	'revision'	=> $ARGV[1],
	'url'		=> $url,
	'author'	=> $who,
	'log'		=> $log,
};

my $ua = LWP::UserAgent->new;
$ua->timeout(15);

my $req = POST( "https://${opt_domain}/services/hooks/subversion?token=${opt_token}", ['payload' => encode_json($payload)] );
my $s = $req->as_string;
print STDERR "Request:\n$s\n";

my $resp = $ua->request($req);
$s = $resp->as_string;
print STDERR "Response:\n$s\n";
