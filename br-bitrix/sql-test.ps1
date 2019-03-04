Import-Module -Force -Name .\InvokeSQL.psm1 
#Import-Module -Force -Name .\InvokeSQL.psm1 -Verbose

$DataRows = Invoke-MSSQL -Server win2019 -database master -SQLCommand "select * from sys.databases" -ConvertFromDataRow:$false

write-output $DataRows 
#$DataRows | Select-object name,database_id
