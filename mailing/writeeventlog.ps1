Clear-Host
if (!(test-path ` HKLM:\SYSTEM\CurrentControlSet\Services\Eventlog\Application\TOP15FSC )) `
{new-eventlog -Logname Application -source TOP15FSC `
-ErrorAction SilentlyContinue}

## Step 2 - Create a 'Job start' entry in your event log
$startTime = Get-date
$startLog = 'Top15 FSC reports started at ' +$startTime+ ' local time' 
Write-Eventlog -Logname Application -Message $startLog -Source 'TOP15FSC `-id 1 -entrytype Information -Category  0

## Step 3 - A production script would have a payload here.

## Step 4 - Write errors during processing (typically part of a if statement)
Write-Eventlog -Logname Application -Message "TOP15 report sent" #'Message content' `
-Source TOP15FSC -id 100 -entrytype Information -category 0

## Step 5 - Write end of process entry in your event log
$endTime = Get-date
$endLog = 'Top15 FSC reports sent complete at ' +$endTime+ ' local time'
Write-Eventlog -Logname Application -Message $endLog -Source 'TOP15FSC `
-id 9 -entrytype Information -category 0

Clear-Host
Get-WinEvent Application | Where {$_.ProviderName -Match "TOP15FSC"}