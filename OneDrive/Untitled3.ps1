Start-Process -Path "https://login.microsoftonline.com"
[System.Diagnostics.Process]::Start("https://login.microsoftonline.com")
(New-Object -Com Shell.Application).Open("https://login.microsoftonline.com")

****
$credentials = Get-Credential
Connect-SPOService -Url https://henryschein.ca-admin.sharepoint.com –credential $credentials
Get-SPOSite


(Invoke-WebRequest -uri "https:///henryscheininc.my-sharepoint.com/_api/web") |gm -MemberType Properties

Invoke-RestSPO -Url "https://henryschein.sharepoint.com/_api/web"

Invoke-RestSPO -Url "https://accounts.google.com/"

invoke-webrequest -uri "https://accounts.google.com/"