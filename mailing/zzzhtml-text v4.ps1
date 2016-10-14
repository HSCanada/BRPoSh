

$smtp=$env:BR_Mailing_Server

$path=$env:br_mailing_path  #(get-location) 


Clear-Host
if (!(test-path ` HKLM:\SYSTEM\CurrentControlSet\Services\Eventlog\Application\TOP15FSC )) `
{new-eventlog -Logname Application -source TOP15FSC `
-ErrorAction SilentlyContinue}



$list=import-csv ($path + "mailing list.csv")

$startTime = Get-date
$startLog = 'Top15 FSC reports started at ' +$startTime+ ' local time' 

Write-Eventlog -Logname Application -Message $startLog -Source 'TOP15FSC ` -id 1 -entrytype Information -Category  0

foreach ($i in $list)
{	
	if($i.count -gt 0) {
		
		 
if($i.attach1 ){
	$attachments=@()
  		$attachments +="$path" + "\attach\" + $i.attach1 }
if($i.attach2){
$attachments=@()
		$attachments += "$path" + "\attach\" +$i.attach1 
		$attachments += "$path" + "\attach\" + $i.attach2 }

		
if($i.attach3){

		
		$attachments=@()
		$attachments += "$path" + "\attach\" +$i.attach1 
		$attachments += "$path" + "\attach\" + $i.attach2 
		$attachments += "$path" + "\attach\" + $i.attach3 }


	echo $attachments

	$params = @{}
	
	$params['Attachments'] = $attachments	
try{
		
	send-mailmessage -smtpserver $smtp -to $i.email -from "businessreporting.canada@henryschein.ca" -subject $i.subject -body $i.msg -bodyashtml -priority  high @params #-attachments "S:\Business Reporting\Jennifer\Project\script\attach\201602_AZ1CI_Top15.pdf" 
LogWrite ($attachments  + " sent to " + $i.email + " on success")
##echo $i.msg + "sent to" + $i.email
}
catch
{
    echo "sending message failed"
}
 #@params
	}
else {
try{
send-mailmessage -smtpserver $smtp -to $i.email -from "businessreporting.canada@henryschein.ca" -subject $i.subject -body $i.msg -bodyashtml -priority high
LogWrite ($attachments + "sent to" + $i.email)
#echo $i.msg + "sent to" + $i.email
}
catch{
echo "sending message failed"
}
}

}


