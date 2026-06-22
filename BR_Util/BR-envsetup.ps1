# setup env for Genpact team, tmc, 19 Jun 26

$HostsPath = "$env:windir\System32\drivers\etc\hosts"

$NewEntry = "10.10.200.117`thub.br.hsa.ca draw.br.hsa.ca wiki.br.hsa.ca forgejo.br.hsa.ca vw.br.hsa.ca .br.hsa.ca"
#$NewEntry = "192.168.1.50`tmyserver.local"

# Read the file and search for the entry
if ((Get-Content $HostsPath) -notcontains $NewEntry) {
    Add-Content -Path $HostsPath -Value "`n$NewEntry" -Force
    Write-Host "Entry added successfully!" -ForegroundColor Green
} else {
    Write-Host "Entry already exists." -ForegroundColor Yellow
}

# Setting a user-level persistent environment variable
[Environment]::SetEnvironmentVariable('BR_Mailing_Path', 'S:\BR\zDev\BR_Scripts\BRPoSh\BR_Mailer\', 'User')
[Environment]::SetEnvironmentVariable('BR_Mailing_Server', 'usnymexhub1.us.hsi.local', 'User')
[Environment]::SetEnvironmentVariable('BRS_MODE', 'DEV', 'User')
[Environment]::SetEnvironmentVariable('BRS_SQLSERVER', 'CAHSIONNLSQL1.ca.hsi.local', 'User')

Write-Host "SetEnvironmentVariable Done" -ForegroundColor Green


