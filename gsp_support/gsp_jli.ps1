
Import-Module -Force -Name .\InvokeSQL.psm1 

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

$date_trx_start = Read-Host -Prompt "Enter transaction_start date: yyyy-mm-dd"
$date_trx_end = Read-Host -Prompt "Enter transaction_start date: yyyy-mm-dd"


$cmd_item = "select * from msg.item"
$cmd_customer = "select * from msg.customer"
$cmd_transaction="SELECT * FROM msg.[Transaction] where POSTED_DATE BETWEEN " + $date_trx_start.tostring() + " and " +  $date_trx_end.tostring() 


        #INTO OUTFILE '/tmp/orders.csv',FIELDS TERMINATED BY ','ENCLOSED BY '"',LINES TERMINATED BY '\n'
 $msg_path ="S:\BR\RegularReports\Weekly\EPS_Salesforce_Load (MSG)\"

        #$msgItem_name =$msg_path.tosting + "_camsg_item_jli" +  ".txt"

$file_date = Read-Host -Prompt "Enter file date: yyyymmdd"

$msgItem_name =$msg_path.tostring() +  $file_date.tostring() + "_camsg_item_jli" +  ".txt"
$msgcustomer_name =$msg_path.tostring() +  $file_date.tostring() + "_camsg_customer_jli"  + ".txt"
$msgtransaction_name = $msg_path.tostring() + $file_date.tostring() + "_camsg_transaction_jli"  + ".txt"

$zip_file_name =$msg_path.tostring() + $file_date.tostring() + "_jli.zip"


 Invoke-Sqlcmd -ServerInstance $bx_server -Database $bx_database -Query $cmd_item | Out-File -FilePath $msgItem_name
 Invoke-Sqlcmd -ServerInstance $bx_server -Database $bx_database -Query $cmd_customer | Out-File -FilePath $msgcustomer_name
 Invoke-Sqlcmd -ServerInstance $bx_server -Database $bx_database -Query $cmd_transaction | Out-File -FilePath $msgtransaction_name


        #write-output $DataRows 

$compress = @{
  Path = $msgItem_name, $msgcustomer_name,$msgtransaction_name    
  CompressionLevel = "Fastest"
  DestinationPath = $zip_file_name 
}

Compress-Archive @compress
