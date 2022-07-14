. .\config.ps1 # import your own authentication details (see README)

# API config
$url        = 'https://api.nextdns.io/profiles/'+$DNSprofile+'/denylist'
$headers    = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("X-API-KEY", $APIkey)

# application variables
$logpath    = ".\errors.log"
$inputpath  = ".\blacklist_domains_test.txt" # text list of hosts
$inputfile  = Get-Content $inputpath # dump hosts from file
$count      = 0 # iterators for progress bar
$skipped    = 0
$total      = $inputfile.Length # read total length of host list for accurate progress bar
$sleeptime  = 1 # in seconds - NextDNS will rate limit less than 1 second between API calls

Clear-Host # make the terminal neat and pretty before we get on with the show

$inputfile | ForEach-Object { # main loop
    $domain = @{ # build JSON out of host entry
        "id"     = $_
        "active" = $true
    }
    $json = $domain | ConvertTo-Json

    try { # POST the JSON to NextDNS and handle errors
        $response = Invoke-RestMethod $url -Headers $headers -Method Post -Body $json -ContentType 'application/json'
    }
    catch { # capture Powershell errors and the URL that failed
        Write-Error $error[0].Exception.Message
        Write-Host $domain.id
        $errormessage = 'connection exception,'+$domain.id
        Add-Content -Path $logpath -Value $errormessage
        $skipped++
    }
    if ($response.errors.code) { # capture NextDNS.io errors
        $errormessage = $response.errors.code+','+$domain.id
        if ($response.errors.code -eq "duplicate") {
            # do nothing, we can simply count them towards the skipped total
        }
        else { # if something other than a duplicate, write to error log
            Write-Host $errormessage
            Add-Content -Path $logpath -Value $errormessage
        }
        $skipped++
    }

    $count++ # update quantities for the progress bar
    $processed = $count - $skipped
    $percent = [math]::Round(($count / $total)*100,2)

    Write-Progress -Activity "Processed $processed of $total hosts ($skipped skipped)" -Status "$percent%" -PercentComplete $percent
    Start-Sleep -Seconds $sleeptime # pause so we don't hit the rate limiter
}

Write-Progress -Activity "Processed $processed of $total hosts ($skipped skipped)" -Complete
Write-Host "Processed $processed of $total hosts ($skipped skipped) and added to the NextDNS.io Denylist on profile $DNSprofile"