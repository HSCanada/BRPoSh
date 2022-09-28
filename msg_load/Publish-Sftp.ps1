<#
.Synopsis
Publish-Sftp - put file to SFTP site
.DESCRIPTION
see .env file for params
last updated 27 Sep 22
.INPUTS
none
.OUTPUTS
copy source file to sftp site
.NOTES
based on code from Jen Li
#>

Import-Module Posh-SSH

# read params from .env file
switch -File .env {
  default {
    $name, $value = $_.Trim() -split '=', 2
    if ($name -and $name[0] -ne '#') { # ignore blank and comment lines.
      Set-Item "Env:$name" $value
    }
  }
}

<# test
Write-Host $env:sftp_host
Write-Host $env:sftp_user
Write-Host $env:sftp_password_file
Write-Host $env:sftp_local
Write-Host $env:sftp_remote
#>

# save password (from prior)
# (get-credential).password | ConvertFrom-SecureString | set-content "password.txt"
$password = Get-Content $env:sftp_password_file | ConvertTo-SecureString
$credential = New-Object System.Management.Automation.PsCredential($env:sftp_user,$password)


# SFTP
try
{
    $Session = New-SFTPSession -Computername $env:sftp_host -credential $credential 
    $transferResult = Set-SFTPItem -SessionId $session.SessionID -Path $env:sftp_local -Destination $env:sftp_remote
    $transferResult.Check()

}
catch
{
    write-output 'Error:  unable to publish file!!'
}
finally
{
    # Disconnect, clean up
    $session.Disconnect()
}  

