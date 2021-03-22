<#
.Synopsis
gsp_merge - merges B and S GSP files to a common file
.DESCRIPTION
Long description
.INPUTS
*.csv files from GSP
.OUTPUTS
output=./load
archive=./zArchive
.NOTES
date on S and B files are different yyyymmdd vs yyyy-mm-dd
will handle conversion downstream from file
#>

# init params

$IN_FILE= 'CN-SCHN*.csv'
$OUT_FILE= '.\load\CN-SCHN_LOAD.csv' 
$ARCHIVE_PATH= '.\zArchive'
$i=1

try
{
	# clear output file
    if (Test-Path $OUT_FILE) {
      Remove-Item -Path $OUT_FILE
    }
    # Remove-Item -Path $OUT_FILE

	# build output file
	# add filename and line number to merged source files
	#
	Get-ChildItem -Filter $IN_FILE -PipelineVariable fileObj | 
	Select-Object -ExpandProperty FullName |
	Import-Csv | 
	ForEach-Object {
	Add-Member -InputObject $PSItem -MemberType NoteProperty -Name 'FILE_LINE' -Value ($i++) -PassThru; } | 
	Select-Object @{n='FILE_NAME'; e={$fileObj.Name }},
		FILE_LINE, ORDERNO, REFERENCE, ITEMNO, ITEMDESC,
		UPC,QTY,PRICE,FREEGDS,DATE,ACCOUNT,
		COMPANY,FIRSTLAST,ADDRESS1,ADDRESS2,ADDRESS3,
		CITY,ST,POSTALCODE,PHONE,COUNTRY,PROGRAMCODE,PROMOCODE | 
	Export-Csv $OUT_FILE -NoTypeInformation -Append
	
	# archive inputs, if no error
	Move-Item -Path $IN_FILE -DESTINATION $ARCHIVE_PATH
}
catch
{
    # pwd | Format-Table
	write-output 'Error:  unable to prepare load file!!'
    # test
    Read-Host -Prompt "Press Enter to exit"


}

