<#
.Synopsis
Remove-Item-Old - deletes file prior to x days from path p
.DESCRIPTION
last updated 31 Mar 23
.INPUTS
.env file (local)
last_created_days={int}
src_path={str}

.OUTPUTS
none
.NOTES
based on code from https://stackoverflow.com/questions/17829785/delete-files-older-than-15-days-using-powershell
#>

# read params from .env file
switch -File .env {
  default {
    $name, $value = $_.Trim() -split '=', 2
    if ($name -and $name[0] -ne '#') { # ignore blank and comment lines.
      Set-Item "Env:$name" $value
    }
  }
}

if($env:BRS_MODE -eq "PROD") {
    $last_created_days = $env:last_created_days
    $src_path = $env:src_path
    $active_ind = $true
} 
else {
    $last_created_days = $env:last_created_days
    $src_path = $env:src_path
    $active_ind = $false
}

$limit = (Get-Date).AddDays(-$last_created_days)

# test
if($env:BRS_MODE -ne "PROD") {
    Write-Host $env:BRS_MODE
    Write-Host ".env params:"
    Write-Host $last_created_days
    Write-Host $src_path
    Write-Host $active_ind
    Write-Host $limit

}

Read-Host -Prompt "Press Enter to Delete old SQL: backup files..."

if($env:BRS_MODE -eq "PROD") {
    Get-ChildItem -Path $src_path  -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } | Remove-Item -Force 
} 
else {
    Get-ChildItem -Path $src_path  -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } | Remove-Item -Force -WhatIf 
}

# keep this so that we can see any errors before exit
Read-Host -Prompt "Done.  Press Enter to exit"

# Delete files older than the $limit.
#Get-ChildItem -Path $src_path -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } | Remove-Item -Force -WhatIf
#Get-ChildItem -Path $src_path  -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } | Measure-Object -Line
