#!/usr/bin/perl
# From 
#	https://raw.githubusercontent.com/tinyspeck/services-examples/master/subversion.pl

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
# An SVN post-commit handler for posting to Slack. Setup the channel and get the token
# from your team's services page. Change the options below to reflect your team's settings.
#
# Requires these perl modules:
# HTTP::Request
# LWP::UserAgent
# JSON


# Submits the following post to the slack servers

# POST https: //foo.slack.com/services/hooks/subversion?token=xxxxxx
# Content-Type: application/x-www-form-urlencoded
# Host: foo.slack.com
# Content-Length: 101
#
# payload=%7B%22revision%22%3A1%2C%22url%22%3A%22http%3A%2F%2Fsvnserver%22%2C%22author%22%3A%22digiguru%22%2C%22log%22%3A%22Log%20info%22%7D

#
# I am not a perl programmer. Beware.
#


# This script should be installed in
#	/path/to/SVN/RepoName/hooks
# as in
#	/var/www/svn/projects/FooBar/hooks
#
# It will look for a configuration file in 
#	/path/to/SVN/RepoName/conf/svn-to-slack.conf
# that will contain
#############
#	$opt_domain = "foo.slack.com"; # Your team's domain
#	$opt_token = ""; # The token from your SVN services page
#############
# note that the conf file, if present, must be valid perl syntax.

use warnings;
use strict;

use HTTP::Request::Common qw(POST);
use HTTP::Status qw(is_client_error);
use LWP::UserAgent;
use JSON;
use File::Spec;
use File::Basename;	# for dirname()

sub LongestCommonPrefix {
	# from:
	#	http://stackoverflow.com/questions/499967/how-do-i-determine-the-longest-similar-portion-of-several-strings
	# longest_common_prefix( $|@ ): returns $
   	# URLref: http://linux.seindal.dk/2005/09/09/longest-common-prefix-in-perl
 	# find longest common prefix of scalar list
	my $prefix = shift;
	for (@_) {
		chop $prefix while (! /^\Q$prefix\E/);
	}
	return $prefix;
}



my $opt_domain;
my $opt_token;
my $url = ""; # optionally set this to the url of your internal commit browser. Ex: http://svnserver/wsvn/main/?op=revision&rev=$ARGV[1]


# Is there a conf file? Look for it in dirname($0)/../conf, but Do NOT dereference symlinks!
#
# This allows us to have one executable, with symlinks from multiple
# SVN project repos, and to have individual config files per-repo, as in:
#
#	ln -s /usr/local/bin/svn-to-slack_post-commit.pl  /var/www/svn/projects/Proj1/hooks/post-commit
#	printf '$opt_domain="foobar";\n$opt_token="bizzbop";\n$url="https://my.url";\n' > /var/www/svn/projects/Proj1/conf/svn-to-slack.conf
#	ln -s /usr/local/bin/svn-to-slack_post-commit.pl  /var/www/svn/projects/Proj2/hooks/post-commit
#	printf '$opt_domain="jakslfjaslkf";\n$opt_token="123456790";\n" > /var/www/svn/projects/Proj2/conf/svn-to-slack.conf
#	ln -s /usr/local/bin/svn-to-slack_post-commit.pl  /var/www/svn/projects/Proj3/hooks/post-commit
#	printf '$opt_domain="ebcdic";\n$opt_token="3.1415927";\n" > /var/www/svn/projects/Proj3/conf/svn-to-slack.conf

my $repodir;
$repodir=dirname($0);
$repodir = File::Spec->rel2abs( $repodir );
$repodir=~s,/hooks/*$,,;

if ( -f "$repodir/conf/svn-to-slack.conf" ) {
	my $config=$repodir . "/conf/svn-to-slack.conf";
	open(CONFIG,"<",$config) or die "Error: Could not open($config) for reading: $!";
	while ( <CONFIG> )
	{
		my $valid="YES";

		chomp($_);
		# remove comments & blank lines & whitespace
		next if ( $_ =~ /^#/ );
		next if ( $_ =~ /^\s*$/ );
		$_=~s/\#.*//;
		$_=~s/^\s*//;
		$_=~s/[;\s]*$/;/;
		$_=~s/\s*=\s*/=/;

		# is the line in the form:
		# 	$variable\s*=\s*something;
		# 	^        ^         ^
		die("Error: $config line \<$_\> is not a variable assignment") if ( $_ !~ /^\$.*=.*;$/ );
		
		# are there any bad characters?
		# 	 (parens) and `backticks` as they can be used to launch commands and sub-shells
		# 	 multiple semicolons could cause the eval() of commands serially
		$valid="NO" if ( $_ =~ /[()`]/);
		$valid="NO" if ( $_ =~ /;.*;/);

		die("Error: $config line \"$_\" is not a valid variable assignment") if ( $valid eq "NO");

		eval($_);
	}
	close(CONFIG) or die "Error: Could not close($config): $!";
} else {
	# use hard-coded values

	#
	# Customizable vars. Set these to the information for your team
	#
	$opt_domain = "foo.slack.com"; # Your team's domain
	$opt_token = ""; # The token from your SVN services page
	$url = "http://svn-server/websvn/wsvn/project";
}

# Sanity checks
if ( $opt_token eq "" ) {
	printf STDERR "Missing required token, \$opt_token=\"$opt_token\" Bailing out.\n";
	exit(1);
}
if ( $opt_domain eq "" ) {
	printf STDERR "Missing required domain, \$opt_domain=\"$opt_domain\". Bailing out.\n";
	exit(1);
}

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

if ( $url ne "" ) {
	# we've got a URL... try to make it point to the individual file or the most specific subdirectory within the repo that
	# contains all the changes
	#
	# Strategy:
	# 	get a list of all changed files in the last rev
	# 	convert full paths to deleted files to just the dir name
	#	find the longest common initial substring among all the changed objects in the last commit
	#	use that path appended to the URL

	my @changedpaths;
	my $changedfile;
	my $lcp;	# longest common prefix
	my $action;	# What action was reported for the changed file listed in svnlook?

	open(CHANGELIST,"-|","/usr/bin/svnlook changed -r $ARGV[1] $ARGV[0]") or die "Could not get change list: $!";
	while(<CHANGELIST>)
	{
		$changedfile=$_;
		chomp($changedfile);

		# If the SVN action is "D" (the object was deleted), then add the parent directory path to 
		# @changedpaths, to avoid having $url point to an object in the repo that no longer exists
		($action,$changedfile)=m/^([^\s])\s*(.*)/;
		if ( $action eq "D" ) {
			$changedfile=dirname($changedfile);
		}

		push(@changedpaths,$changedfile);
	}
	close(CHANGELIST) or die "Could not close input from piped command: $!\n";
	
	# the array has all the filenames... call LongestCommonPrefix 
	
	# if there's just one entry in @changedpaths, then use that verbatim
	if ( @changedpaths == 1 ) 
	{
		$lcp=$changedpaths[0];
	} else {
		# otherwise, find the longest common prefix
		$lcp=LongestCommonPrefix(@changedpaths);
	}

	# make sure the URL doesn't have a trailing '/', then append the $longestLCP
	$url=~s,/$,,;

	$url=$url . "/" . $lcp;
}
		

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
