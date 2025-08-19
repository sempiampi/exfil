<#Script to cleanup Bashtop 4 windows - a terminal taskmanager.#>
# Variables
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$basepath = "C:\Windows\System32\SecureBootUpdatesMicrosoft"
$btop4winpath = Join-Path -Path $basepath -ChildPath "btop4win"

# Remove the installation folder
if (Test-Path $btop4winpath) {
    Remove-Item -Path $btop4winpath -Recurse -Force -Confirm:$false
    Write-Host "Cleanup completed: removed installation folder."
} else {
    Write-Host "No previous installation found."
}

# Remove the executable path from the system PATH
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
if ($currentPath -like "*$btop4winpath*") {
    $newPath = $currentPath -replace [regex]::Escape(";$btop4winpath"), ''
    [System.Environment]::SetEnvironmentVariable("Path", $newPath, [System.EnvironmentVariableTarget]::Machine)
    Write-Host "btop4win path has been removed from the system PATH."
} else {
    Write-Host "btop4win path is not in the system PATH."
}