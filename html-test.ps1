
$smtp = "usnymexhub1.us.hsi.local"

$to = "trevor.crowley@henryschein.ca"

$from = "jennifer.li@henryschein.ca"

$subject = "This is a Test of HTML Email" 

$body=get-content ("c:\script\output.txt")

send-MailMessage -SmtpServer $smtp -To $to -From $from -Subject $subject -Body $body -BodyAsHtml -Priority high -Attachments “C:\script\201602_AZ1CI_Top15.pdf”, “C:\script\201602_AZ1CI_Top15.xlsx”
