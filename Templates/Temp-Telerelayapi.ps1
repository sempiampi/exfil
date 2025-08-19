# to send a file
$finaloutput = "C:\Users\Admin\Desktop\test.txt"
$apiurl = "https://hook.eu2.make.com/pgvj9kxtwo4pcrhxwn1kg9p9agp129bl"
$boundary = [System.Guid]::NewGuid().ToString()
$fileBytes = [System.IO.File]::ReadAllBytes($finaloutput)
$fileName = [System.IO.Path]::GetFileName($finaloutput)
$LF = "`r`n"
$body = (
    "--$boundary$LF" +
    "Content-Disposition: form-data; name=`"file`"; filename=`"$fileName`"$LF" +
    "Content-Type: application/octet-stream$LF$LF" +
    [System.Text.Encoding]::Default.GetString($fileBytes) + $LF +
    "--$boundary--$LF"
)
$bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
Invoke-WebRequest -Uri $apiurl -Method Post -ContentType "multipart/form-data; boundary=`"$boundary`"" -Body $bodyBytes -UseBasicParsing | Out-Null

# to send a message.
$apiurl = "https://hook.eu2.make.com/pgvj9kxtwo4pcrhxwn1kg9p9agp129bl"
Invoke-WebRequest -Uri $apiurl -Method Post -ContentType "text/plain" -Body $message -UseBasicParsing | Out-Null