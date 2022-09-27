
Import-Module -Force -Name ..\BR_Util\InvokeSQL.psm1 

if($env:BRS_MODE -eq "PROD") {
    $bx_server = $env:BRS_SQLSERVER
    $bx_database = $env:bx_database
    $bx_webhook_url = $env:bx_webhook_url
} 
else {
    $bx_server = $env:BRS_SQLSERVER
    $bx_database = $env:bx_database_DEV
    $bx_webhook_url = $env:bx_webhook_url_DEV
}


#$cmd = "SELECT * FROM br.nes.bx_group_load"
#$cmd = "SELECT * FROM nes.bx_group_load where bx_shipto in (3966556, 1661316, 1670574, 1667252, 3933776, 3930089)"
#$cmd = "SELECT * FROM nes.bx_group_load where bx_shipto in (2247344)"

#$cmd = "SELECT * FROM dbo.brs_customer"

# Get Params


#$cmd = "SELECT top 10 * from BRS_Item"


#$date_trx_start = Read-Host -Prompt "Enter transaction_start date: yyyy-mm-dd"
#$date_trx_end = Read-Host -Prompt "Enter transaction_start date: yyyy-mm-dd"

#$date_trx_start_text = '06-Sep-22'
$date_trx_start_text = Read-Host -Prompt "Enter transaction_start date: dd-mmm-yy"
$date_trx_start =[datetime]::parseexact($date_trx_start_text, 'dd-MMM-yy', $null)
$days = 2




# SQL templates
$cmd_item = "select * from msg.item"
$cmd_customer = "select * from msg.customer"

#$cmd_transaction="SELECT * FROM msg.[Transaction] where POSTED_DATE BETWEEN " + $date_trx_start.tostring() + " and " +  $date_trx_end.tostring() 
$cmd_transaction="SELECT * FROM msg.[Transaction] where POSTED_DATE BETWEEN '" + $date_trx_start.AddDays(-$days).ToString("yyyy-MM-dd") + "' and '" +  $date_trx_start.AddDays(0).ToString("yyyy-MM-dd") + "'"



# set const
        #INTO OUTFILE '/tmp/orders.csv',FIELDS TERMINATED BY ','ENCLOSED BY '"',LINES TERMINATED BY '\n'
 #$msg_path ="S:\BR\RegularReports\Weekly\EPS_Salesforce_Load (MSG)\"
 $msg_path = $env:msg_path_weekly
 # "S:\BR\RegularReports\Weekly\EPS_Salesforce_Load (MSG)\"

#$msgItem_name =$msg_path.tosting + "_camsg_item_jli" +  ".txt"

# get more params
#$file_date = Read-Host -Prompt "Enter file date: yyyymmdd"
$file_date = $date_trx_start.AddDays(0).ToString("yyyyMMdd")

# set constants
$msgItem_name =$msg_path.tostring() +  $file_date.tostring() + "_camsg_item_jli" +  ".txt"
$msgcustomer_name =$msg_path.tostring() +  $file_date.tostring() + "_camsg_customer_jli"  + ".txt"
$msgtransaction_name = $msg_path.tostring() + $file_date.tostring() + "_camsg_transaction_jli"  + ".txt"

$zip_file_name =$msg_path.tostring() + $file_date.tostring() + "_jli.zip"


# get sql to files
 Invoke-Sqlcmd -ServerInstance $bx_server -Database $bx_database -Query $cmd_item | Out-File -FilePath $msgItem_name
 Invoke-Sqlcmd -ServerInstance $bx_server -Database $bx_database -Query $cmd_customer | Out-File -FilePath $msgcustomer_name
 Invoke-Sqlcmd -ServerInstance $bx_server -Database $bx_database -Query $cmd_transaction | Out-File -FilePath $msgtransaction_name


      
# zip files
$compress = @{
  Path = $msgItem_name, $msgcustomer_name,$msgtransaction_name    
  CompressionLevel = "Fastest"
  DestinationPath = $zip_file_name 
  #update = true
}

Compress-Archive @compress -Update

# SFTP

# this needed?----------------------------
$assemblyPath ="C:\Program Files (x86)\WinSCP\"
Add-Type -Path (Join-Path $assemblyPath "WinSCPnet.dll")
#

# adding secrets to scrips ???
$sessionOptions = New-Object WinSCP.SessionOptions -Property @{
    Protocol = [WinSCP.Protocol]::SFtp
    #FtpMode = [WinSCP.FtpMode]::Passive
    HostName = "BR.HSA.CA"
    UserName = "user"
    Password = "password"
    SshHostKeyFingerprint = "ssh-ed25519 255 ljY2GOloVklxoVqB6szZLffDesRaE9bNPOFIhiLM0Ag"
}

$session = New-Object WinSCP.Session

# SFTP
try
{
    # Connect
    $session.Open($sessionOptions)

    # Download files
   # $session.GetFiles("/home/user/*.xlsx", "C:\temp\").Check()
    $session.putfiles("c:\temp\*.csv","/home/user/").Check()
}
finally
{
    # Disconnect, clean up
    $session.Dispose()
}  



  