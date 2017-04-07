
$smtp=$env:BR_Mailing_Server

$path=$env:br_mailing_path  #(get-location) 


$Logfile = "$path" + "\log\mailing.log" #attach\" #"D:\Apps\Logs\$(gc env:computername).log"



Function LogWrite
{
   Param ([heltring]$logstring)

   Add-content $Logfile -value $logstring
}

#$body=get-content ($path +"J051_TOP15_FSC\ETU_MSG_FSC_Top_15_ASCII.htm") -Raw

$body=get-content ($path +"J051_TOP15_FSC\ETU_MSG_FSC_Top_15_ASCII.htm") | out-string

#$body=get-content ($path +"J051_TOP15_FSC\ETU_MSG_FSC_Top_15.htm") | out-string



#$body=get-content ($path +"J051_TOP15_FSC\ETU_MSG_FSC_Top_15.htm") -Encoding Unicode 

Clear-Host
if (!(test-path HKLM:\SYSTEM\CurrentControlSet\Services\Eventlog\Application\BRC))`
    {new-eventlog -Logname Application -source BRC `
    -ErrorAction SilentlyContinue}

#$list=import-csv ($path + "mailing list v6.csv")


$list=import-csv ($path + "J051_TOP15_FSC\"+"mailing list - Top15 - test.csv")

#$list=import-csv ($path + "mailing list v6 - ME.csv")
#$list=import-csv ($path + "mailing list FSC comm.csv")
#$list=import-csv ($path + "mailing list FSC comm - test.csv")
#$list=import-csv ($path + "mailing list EST comm - test.csv")
#$list=import-csv ($path + "mailing list EST comm.csv")

$startTime = Get-date
#$startLog = 'Top15 FSC -' +$startTime
$startLog = 'Branch Daily Sales -' +$startTime

#'Write-Eventlog -Logname Application -Message $startLog -Source 'TOP15FSC'
write-eventlog -logname Application -message $startlog -source BRC -ENTRYTYPE information -EventId 1 -category 0 

foreach ($i in $list)
{	
	if($i.flag -eq 1 -and $i.count -gt 0) {
		
		 
        if($i.attach1 ){
	        $attachments=@()
            $attach=@()
  		   # $attachments +="$path" + "attach\" + $i.attach1 
            $attachments += $i.attach1 

            $attach +=$i.attach1

           echo $attachments
          }
        if($i.attach2){
            $attachments=@()
            $attach=@()
		    #$attachments += "$path" + "attach\" +$i.attach1 
            $attachments += $i.attach1 
            $attach +=$i.attach1
            #$attachments += "$path" + "attach\" +$i.attach2
            $attachments += $i.attach2 
            $attach +=$i.attach2
             echo $attachments

        }
		
        if($i.attach3){

		
		    $attachments=@()
            $attach=@()

	       # $attachments += "$path" + "attach\" +$i.attach1 
            $attachments += $i.attach1 
            $attach +=$i.attach1
		    #$attachments += "$path" + "attach\" + $i.attach2 
            $attachments += $i.attach2 
            $attach +=$i.attach2
		    #$attachments += "$path" + "attach\" + $i.attach3
            $attachments += $i.attach3 
            $attach +=$i.attach3
            echo $attachments
         
        }                                           
        echo $attachments	

	    $params = @{}
	
	    $params['Attachments'] = $attachments
	
        $emailarray  = $I.EMAIL -split ','

        try{

       # Add-Type -AssemblyName System.Web
        #[System.Web.HttpUtility]::HtmlDecode
		
	       send-mailmessage -smtpserver $smtp -to $emailarray -from "businessreporting.canada@henryschein.ca" -subject $i.subject -body $body -bodyashtml -priority  high @params 

            #send-mailmessage -smtpserver $smtp -to $emailarray -from "businessreporting.canada@henryschein.ca" -subject $i.subject  -bodyashtml S:\Business Reporting\ZDEV_BR_Scripts\BRPoSh\BR_Mailer\ETU_MSG_FSC_Top_15.htm -priority  high @params 

            #send-mailmessage -smtpserver $smtp -to $emailarray -from "businessreporting.canada@henryschein.ca" -subject $i.subject -body $i.msg -bodyashtml -priority  high @params 
            #write-eventlog -logname Application -message ( 'Top15 FSC -' +$startTime+ '  to  '  + $i.email + "    " + $attach ) -source BRC -ENTRYTYPE information -EventId 1 -category 0
            write-eventlog -logname Application -message ( 'Branch Daily Sales -' +$startTime+ '  to  '  + $i.email + "    " + $attach ) -source BRC -ENTRYTYPE information -EventId 1 -category 0
            #LogWrite ($attachments  + " sent to " + $i.email + " on success")
            #echo $i.msg + "sent to" + $i.email
         }
        catch
         {
             echo "sending message failed"
            # write-eventlog -logname Application -message ('Top15 FSC -' +$startTime+ '  to  '  + $i.email + "   - Fail to send") -source BRC -ENTRYTYPe FailureAudit -EventId 2 -category 1
             write-eventlog -logname Application -message ('Branch Daily Sales -' +$startTime+ '  to  '  + $i.email + "   - Fail to send") -source BRC -ENTRYTYPe FailureAudit -EventId 2 -category 1

        }
 
    }

    elseif($i.flag -eq 1) {
    
        $emailarray  = $I.EMAIL -split ','
            try{
                send-mailmessage -smtpserver $smtp -to $emailarray  -from "businessreporting.canada@henryschein.ca" -subject $i.subject -body $i.msg -bodyashtml -priority  high 
                #write-eventlog -logname Application -message ( 'Top15 FSC -' +$startTime+ '  to  '  + $i.email ) -source BRC -ENTRYTYPE information -EventId 1 -category 0
                write-eventlog -logname Application -message ( 'Branch Daily Sales -' +$startTime+ '  to  '  + $i.email ) -source BRC -ENTRYTYPE information -EventId 1 -category 0
                #LogWrite ($attachments + "sent to" + $i.email)
                #echo $i.msg + "sent to" + $i.email
            }
            catch{
                    echo "sending message failed"
                    #write-eventlog -logname Application -message ('Top15 FSC -' +$startTime+ '  to  '  + $i.email + "   - Fail to send") -source BRC -ENTRYTYPe FailureAudit -EventId 2 -category 1
                    write-eventlog -logname Application -message ('Branch Daily Sales -' +$startTime+ '  to  '  + $i.email + "   - Fail to send") -source BRC -ENTRYTYPe FailureAudit -EventId 2 -category 1
            }
      }
      else
       
      {
            echo "flag set to 0, no message sent"
      }
    

}

<#
.SYNOPSIS
Gets file encoding.
.DESCRIPTION
The Get-FileEncoding function determines encoding by looking at Byte Order Mark (BOM).
Based on port of C# code from http://www.west-wind.com/Weblog/posts/197245.aspx
.EXAMPLE
Get-ChildItem  *.ps1 | select FullName, @{n='Encoding';e={Get-FileEncoding $_.FullName}} | where {$_.Encoding -ne 'ASCII'}
This command gets ps1 files in current directory where encoding is not ASCII
.EXAMPLE
Get-ChildItem  *.ps1 | select FullName, @{n='Encoding';e={Get-FileEncoding $_.FullName}} | where {$_.Encoding -ne 'ASCII'} | foreach {(get-content $_.FullName) | set-content $_.FullName -Encoding ASCII}
Same as previous example but fixes encoding using set-content
#>
function Get-FileEncoding
{
    [CmdletBinding()] Param (
     [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)] [string]$Path
    )
 
    [byte[]]$byte = get-content -Encoding byte -ReadCount 4 -TotalCount 4 -Path $Path
 
    if ( $byte[0] -eq 0xef -and $byte[1] -eq 0xbb -and $byte[2] -eq 0xbf )
    { Write-Output 'UTF8' }
    elseif ($byte[0] -eq 0xfe -and $byte[1] -eq 0xff)
    { Write-Output 'Unicode' }
    elseif ($byte[0] -eq 0 -and $byte[1] -eq 0 -and $byte[2] -eq 0xfe -and $byte[3] -eq 0xff)
    { Write-Output 'UTF32' }
    elseif ($byte[0] -eq 0x2b -and $byte[1] -eq 0x2f -and $byte[2] -eq 0x76)
    { Write-Output 'UTF7'}
    else
    { Write-Output 'ASCII' }
}

