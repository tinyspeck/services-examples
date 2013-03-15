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
# An SVN post-commit handler for posting to [redacted]. Setup the channel and get the token
# from your team's services page. Change the options below to reflect your team's settings.
#
# Requires these perl modules:
# HTTP::Request
# LWP::UserAgent
# JSON
#
# I am not a perl programmer. Beware.
#

use warnings;
use strict;

use HTTP::Request::Common qw(POST);
use HTTP::Status qw(is_client_error);
use LWP::UserAgent;
use JSON;


#
# Customizable vars. Set these to the information for your team
#

my $opt_domain = "foo.chatly.io"; # Your team's domain
my $opt_token = ""; # The token from your SVN services page


#
# this script gets called by the SVN post-commit handler
# with these args:
#
# [0] path to repo
# [1] revision committed
#
# we need to find out what happened in that revision and then act on it
#

my $log = `/usr/bin/svnlook log -r $ARGV[1] $ARGV[0]`;
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

my $req = POST( "https://${$opt_domain}/services/hooks/subversion?token=${$opt_token}", ['payload' => encode_json($payload)] );
my $s = $req->as_string;
print STDERR "Request:\n$s\n";

my $resp = $ua->request($req);
$s = $resp->as_string;
print STDERR "Response:\n$s\n";