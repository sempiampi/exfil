# Prompt user for Wi-Fi SSID and password
#$wifiSSID = Read-Host "Enter the Wi-Fi SSID (in quotation marks, e.g., `"wifi ssid`")"
#$wifiPassword = Read-Host "Enter the Wi-Fi password"

#for automated addition
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$wifiSSID = "Hotspot 2.0"
$wifiPassword = "012301230"
# Remove quotation marks from SSID
$wifiSSID = $wifiSSID.Trim('"')
# XML content for the network profile
$xmlContent = @"
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>$wifiSSID</name>
    <SSIDConfig>
        <SSID>
            <name>$wifiSSID</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>auto</connectionMode>
    <MSM>
        <security>
            <authEncryption>
                <authentication>WPA2PSK</authentication>
                <encryption>AES</encryption>
                <useOneX>false</useOneX>
            </authEncryption>
            <sharedKey>
                <keyType>passPhrase</keyType>
                <protected>false</protected>
                <keyMaterial>$wifiPassword</keyMaterial>
            </sharedKey>
        </security>
    </MSM>
</WLANProfile>
"@
# Save the XML content to a temporary file
$tempFilePath = [System.IO.Path]::GetTempFileName()
Set-Content -Path $tempFilePath -Value $xmlContent
# Add the network profile
netsh wlan add profile filename="$tempFilePath"
# Clean up temporary file
Remove-Item -Path $tempFilePath -Force
