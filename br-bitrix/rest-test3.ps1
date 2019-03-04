.\sql-test.ps1 | Select-Object database_id,name | foreach { $_ 
| ConvertTo-HashTable | .\rest-test2.ps1 }


