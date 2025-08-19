$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$username = ((Get-CIMInstance -class Win32_ComputerSystem | Select-Object -ExpandProperty username ) -split '\\' )[1]
$psfolderpath = "C:\Users\$username\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine"
if (Test-Path -Path $psfolderpath -PathType Container) {
    $files = Get-ChildItem -Path $psfolderpath
    if ($files.Count -gt 0) {
        Remove-Item -Path "$psfolderpath\*" -Force
    }
}
