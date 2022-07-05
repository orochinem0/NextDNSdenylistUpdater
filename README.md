# NextDNS denylist Updater

## What is this?

Adds a batch of URIs from a text file to your NextDNS.io denylist

## How to use

Make a file named `config.ps1` and include the following information (available on your NextDNS.io account):

```
# user variables
$DNSprofile = ''
$APIkey     = ''
```

Save this in the same directory as `run.ps1`
