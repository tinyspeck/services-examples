#!/bin/env php
<?php
#
# An SVN post-commit handler for posting to Slack. Setup the channel and get the token
# from your team's services page. Change the options below to reflect your team's settings.
#

# Submits the following post to the slack servers

# POST https: //foo.slack.com/services/hooks/subversion?token=xxxxxx
# Content-Type: application/x-www-form-urlencoded
# Host: foo.slack.com
# Content-Length: 101
#
# payload=%7B%22revision%22%3A1%2C%22url%22%3A%22http%3A%2F%2Fsvnserver%22%2C%22author%22%3A%22digiguru%22%2C%22log%22%3A%22Log%20info%22%7D

#
# Customizable vars. Set these to the information for your team
#

$domain = "foo.slack.com"; # Your team's domain
$token = "xxxxxx"; # The token from your SVN services page
$url = "https://example.com/svn/changeset/".$argv[2]."/"; # optionally set this to the url of your internal commit browser. Ex: http://svnserver/wsvn/main/?op=revision&rev=$argv[2]

#print_r($argv);die();
#
# this script gets called by the SVN post-commit handler
# with these args:
#
# [0] path to repo
# [1] revision committed
#
# we need to find out what happened in that revision and then act on it
#

exec("/usr/bin/svnlook log -r ".$argv[2]." ".$argv[1], $log);
exec("/usr/bin/svnlook author -r ".$argv[2]." ".$argv[1], $who);
$payload = array(
	'revision'	=> $argv[2],
	'url'		=> $url,
	'author'	=> $who[0],
	'log'		=> implode("\n",$log),
);

$url2 = "https://${domain}/services/hooks/subversion?token=${token}";
$ch = curl_init($url2);
curl_setopt($ch, CURLOPT_POSTFIELDS, array('payload'=>json_encode($payload)));

curl_exec($ch);
echo "\n";
