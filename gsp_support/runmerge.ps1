Get-ChildItem -Filter *.csv | Import-Csv | Export-Csv .\merged\merged.csv -NoTypeInformation -Append
