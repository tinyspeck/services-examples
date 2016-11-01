# NAME

nagios.pl - A nagios/icinga plugin for sending alerts to Slack

# AUTHOR

Tiny Speck, Inc

# SYNOPSIS

**nagios.pl** \[**--help**\] \[**-field slack\_SOMETHING=value**\]

## -h, --help

This output

## -field

Provide **slack** related configuration. Possible choices include:

    * slack_channel - Target Slack channel for the message
    * slack_domain  - Slack domain for your team
    * slack_token   - Slack token for this integration

# REQUIRES

Perl5.004, [strict](https://metacpan.org/pod/strict), [warnings](https://metacpan.org/pod/warnings), [HTTP::Request](https://metacpan.org/pod/HTTP::Request), [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent)

# EXPORTS

Nothing

# DESCRIPTION

A nagios/icinga plugin for sending alerts to Slack. See more documentation on the team services page at:
 [https://my.slack.com/services/new/nagios](https://my.slack.com/services/new/nagios)

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
