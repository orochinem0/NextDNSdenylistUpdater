. .\config.ps1

# API config
$url        = 'https://api.nextdns.io/profiles/'+$DNSprofile+'/denylist'
$headers    = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("X-API-KEY", $APIkey)

# application variables
$inputfile  = ".\blacklist_domains.txt" # text list of hosts
$sleeptime  = 1 # in seconds - NextDNS will rate limit less than 1 second between API calls
$count      = 0 # iterator for progress bar
$tcount     = (Get-Content $inputfile).Length # read total length of host list for accurate progress bar

clear-host # make the terminal neat and pretty before we get on with the show

Get-Content $inputfile | ForEach-Object { # main loop
    $domain = @{ # build JSON out of host entry
        "id"     = $_
        "active" = $true
    }
    $json = $domain | ConvertTo-Json

    try { # POST the JSON of the host to NextDNS and handle errors
        $response = Invoke-RestMethod $url -Headers $headers -Method Post -Body $json -ContentType 'application/json'
    }
    catch { # capture error information
        if ($_.Exception.Response -eq $null) { # if no response, return exception message
            Write-Host "At $($_.InvocationInfo.ScriptLineNumbere): $_.Exception.Message" -ForeGroundColor Red
        }
        else { # output detailed error messages
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $respBody = $reader.ReadToEnd() | ConvertFrom-Json
            Write-Host "At line $($_.InvocationInfo.ScriptLineNumber): $_.Exception.Message $($respBody.code): $respBody.message $respBody.causeDetails" -ForegroundColor Red
        }
    }

    Start-Sleep -Seconds $sleeptime # pause so we don't hit the rate limiter

    $count++ # update progress bar
    $complete = [math]::Round($count / $tcount) * 100
    $precise  = [math]::Round($count / $tcount,4) * 100
    Write-Progress -Activity "Adding to NextDNS Denylist:" -Status "Processed $count of $tcount hosts $precise%" -PercentComplete $complete
}
