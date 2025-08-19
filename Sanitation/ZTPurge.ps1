<# Script to remove zerotier #>
# variables.
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$nugetProvider = Get-PackageProvider -ListAvailable -Name NuGet
$username = ( ( Get-CIMInstance -class Win32_ComputerSystem | Select-Object -ExpandProperty username ) -split '\\' )[1]
$ztservice = "ZeroTierOneService"
$fwruleset = ("ZeroTier One", "ZeroTier x64 Binary In", "ZeroTier UDP/9993 In")
$ztdatadir = "C:\Users\$username\AppData\Local\ZeroTier"
$ztsystemdatadir = "C:\ProgramData\ZeroTier\"

# registry fix for join network side panel popup.
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff" -ItemType Directory -Force | Out-Null

# Removal of old installation incase it exists.
Stop-Service -Name $ztservice | Out-Null
if (-not $nugetProvider) {
    Install-PackageProvider -Name NuGet -Force | Out-Null
}
Uninstall-Package -Name "ZeroTier One" -Force | Out-Null

# manual removal
sc.exe delete $ztservice | Out-Null
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

# directory removal
if (Test-Path $ztdatadir) {
    Remove-Item -Path $ztdatadir -Recurse -Force -Confirm:$false | Out-Null
}

if (Test-Path $ztsystemdatadir) {
    Remove-Item -Path $ztsystemdatadir -Recurse -Force -Confirm:$false | Out-Null
}