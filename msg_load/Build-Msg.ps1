﻿<#
.Synopsis
Build-Msg - saves prior week of MSG files to a zip package
.DESCRIPTION
item, customer, transaction
last updated 27 Sep 22
.INPUTS
none
.OUTPUTS
file=./yyyymmdd_camsg.zip
.NOTES
based on code from Jen Li
#>

Import-Module -Force -Name \\cahsionnlfp04\groups\BR\zDev\BR_Scripts\BRPoSh\BR_Util\InvokeSQL.psm1 
# Import-Module -Force -Name ..\BR_Util\InvokeSQL.psm1 

if($env:BRS_MODE -eq "PROD") {
    $bx_server = $env:BRS_SQLSERVER
    $bx_database = $env:bx_database
} 
else {
    $bx_server = $env:BRS_SQLSERVER
    $bx_database = $env:bx_database_DEV
}

# read params from .env file
switch -File .env {
  default {
    $name, $value = $_.Trim() -split '=', 2
    if ($name -and $name[0] -ne '#') { # ignore blank and comment lines.
      Set-Item "Env:$name" $value
    }
  }
}

# get last Friday
# from https://stackoverflow.com/questions/16785241/powershell-find-the-next-friday
[datetime] $date_trx_end =  get-date
[DayOfWeek] $NextDayOfWeek = 'Friday'
$date_trx_end=$date_trx_end.AddDays(((7-[int]$date_trx_end.DayOfWeek+[int]$NextDayOfWeek)%7)-7)

# SQL file params
$msg_path = $env:msg_path.Trim().Trim('"')
$msg_prefix = $date_trx_end.ToString("yyyyMMdd")

# SQL templates

$cmd_item        = "SELECT * from msg.item"
$cmd_customer    = "SELECT * from msg.customer"
$cmd_transaction = "SELECT * FROM msg.[Transaction] where POSTED_DATE BETWEEN '" + $date_trx_end.AddDays(-$env:date_trx_days).ToString("yyyy-MM-dd") + "' and '" +  $date_trx_end.AddDays(0).ToString("yyyy-MM-dd") + "'"


<#
$cmd_item        = "SELECT top 10 * from msg.item"
$cmd_customer    = "SELECT top 10 * from msg.customer"
$cmd_transaction = "SELECT top 10 * FROM msg.[Transaction] where POSTED_DATE BETWEEN '" + $date_trx_end.AddDays(-$env:date_trx_days).ToString("yyyy-MM-dd") + "' and '" +  $date_trx_end.AddDays(0).ToString("yyyy-MM-dd") + "'"
#>


# SQL file names {root path} + {date prefix} + {filename.TXT}
$msgItem_name =        $msg_prefix.tostring() + '_camsg_item.txt'
$msgcustomer_name =    $msg_prefix.tostring() + '_camsg_customer.txt'
$msgtransaction_name = $msg_prefix.tostring() + '_camsg_transaction.txt'
$zip_file_name =       $msg_prefix.tostring() + '_camsg.zip'

<# test
Write-Host $date_trx_end
Write-Host $env:date_trx_days
Write-Host $env:msg_path
Write-Host $cmd_transaction
Write-Host $msgItem_name
Write-Host $msgcustomer_name
Write-Host $msgtransaction_name
Write-Host $zip_file_name
#>

#item
$DataRows = Invoke-MSSQL -Server $bx_server -database $bx_database -SQLCommand $cmd_item  -ConvertFromDataRow:$false
#write-output $DataRows 
$DataRows | export-csv -delimiter "`t" -path ($msg_path + $msgItem_name) -notype 

#customer
$DataRows = Invoke-MSSQL -Server $bx_server -database $bx_database -SQLCommand $cmd_customer  -ConvertFromDataRow:$false
#write-output $DataRows 
$DataRows | export-csv -delimiter "`t" -path ($msg_path + $msgcustomer_name) -notype

#transaction
$DataRows = Invoke-MSSQL -Server $bx_server -database $bx_database -SQLCommand $cmd_transaction  -ConvertFromDataRow:$false
#write-output $DataRows 
$DataRows | export-csv -delimiter "`t" -path ($msg_path + $msgtransaction_name) -notype

# remove any prior zip files.  this is to allow the SFTP logic to use *.zip
Remove-Item ($msg_path + '*.zip')
     
# zip files
$compress = @{
  Path = $msg_path + $msg_prefix + '*.txt'
  CompressionLevel = "Fastest"
  DestinationPath = ($msg_path + $zip_file_name)
  #update = true
}

Compress-Archive @compress -Update

# keep this so that we can see any errors before exit
Read-Host -Prompt "Press Enter to exit"  