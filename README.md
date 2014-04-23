services-examples
=================

Examples of third-party integration scripts for [Slack](https://slack.com/)

* [Nagios](https://github.com/tinyspeck/services-examples/blob/master/nagios.pl)
* [SVN](https://github.com/tinyspeck/services-examples/blob/master/subversion.pl)

[slack_room_message.pl](/slack_room_message.pl) is a simple wrapper for use from the command line, with
minimal dependencies. Use it like so:

    slack_room_message.pl -text="some event happened" -channel="#events" -username='a_bot'
