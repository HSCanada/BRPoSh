<#
.Synopsis
fg_merge - merges multiple auto and override files to a common file
.DESCRIPTION
last updated 20 Oct 21
.INPUTS
*.csv files from JDE 
.OUTPUTS
output=./load
archive=./zArchive
.NOTES
na
#>

# init params

$IN_FILE= '*F5554240*.csv'
$OUT_FILE= '.\load\F5554240_LOAD.csv' 
$ARCHIVE_PATH= '.\zArchive'
$i=1

# do not process if files missing
if (-not (Test-Path $IN_FILE)) {
    return;
}

Write-Output "Processing FG files.  Please wait..."

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
	Select-Object @{n='FILE_NAME'; e={$fileObj.Name }}, FILE_LINE,
        'Key  ----------',
        'Cat Cde ---',
        'Sppl Cde ------',
        '2nd Item Number --------------------',
        'Customer/Supplier Item Number --------------------',
        'Quantity Ordered ---------------',
        'UM  --',
        'Unit Cost ---------------',
        'Cur Cod ---',
        'Extended Cost --------------------',
        'Description  --------------------',
        'Description Line 2 --------------------',
        'BILLTO NUMBER. . . .',
        'BILLTO NAME. . . . .',
        'Ship To Number --------',
        'SHIPTO NAME. . . . .',
        'Order Number --------',
        'Or Ty --',
        'High Sts ----',
        'ORDER DATE . . . . .',
        'Frm Grd ---',
        'Thr Grd ---',
        'Ln Ty --',
        'Invoice Number',
        'Free Goods Contract Number',
        'PROMO DESCRIPTION' |
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


