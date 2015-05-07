# Requires Powershell 3.0
#
# An SVN post-commit handler for posting to Slack. Setup the channel and get the token
# from your team's services page. Change the options below to reflect your team's settings.

Param(
  [string]$svnPath,
  [string]$revision,
  [string]$repoName
)

$domain = "YOUR_DOMAIN.slack.com"
$token = "TOKEN"
$endpoint = "https://${domain}/services/hooks/subversion?token=${token}"
#$revisionUrlBase = "WEB_VIEW_BASE URL" #if any

$log = (svnlook log -r $revision $svnPath)
$who = (svnlook author -r $revision $svnPath)
$changes = (svnlook changed -r $revision $svnPath)

$payload = @{   
    attachments = @(@{
        pretext = "Commit completed: $repoName rev. $revision"
        text = "Message: $log"
        fallback = "Commit completed: $repoName rev. $revision"
        title = "Commit details"
        # title_link = "$revisionUrlBase$revision"
        color = '#439FE0'
        fields = @(@{
            title = "Changes"
            value = $changes
            short = $false
        }, @{
            title = "Author"
            value = $who
            short = $true
        })
    })
}

$json = (ConvertTo-Json $payload -Depth 99)
Invoke-RestMethod -Uri $endpoint -Method Post -ContentType "application/json" -Body $json