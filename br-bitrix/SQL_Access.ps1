$SQLServer = "cahsionnlsql1"
$SQLDBName = "DEV_BRSales"
#$uid ="john"
#$pwd = "pwd123"

$SqlQuery = "SELECT * from dbo.BRS_Customer where shipto=1520908;"

$SqlConnection = New-Object System.Data.SqlClient.SqlConnection

$SqlConnection.ConnectionString = "Server = $SQLServer; Database = $SQLDBName; Integrated Security = True;"

$SqlCmd = New-Object System.Data.SqlClient.SqlCommand

$SqlCmd.CommandText = $SqlQuery

$SqlCmd.Connection = $SqlConnection

$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter

$SqlAdapter.SelectCommand = $SqlCmd

$DataSet = New-Object System.Data.DataSet

$SqlAdapter.Fill($DataSet)

$DataSet.Tables[0] |out-file "S:\BR\Jennifer\Project\RestAPI\DEV_BRSales.Customer.csv" 

$groupname =$DataSet.Tables[0].practivename + " - " +$DataSet.Tables[0].shipto

$url= "https://team-qa.hsa.ca/rest/1/2v21zmqf6rtcp2f2/sonet_group.create.json?NAME="+$groupname+" - "+(Get-Date).ToString("d",$dede)

$url =$url +"&DESCRIPTION=Test%20desr&VISIBLE=Y&OPENED=N&INITIATE_PERMS=K&PROJECT=Y&PROJECT_DATE_FINISH="+'2040-12-30'+"&PROJECT_DATE_START="+(Get-Date).ToString("d",$dede)
   
 curl  $url
