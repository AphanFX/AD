<#
    .NOTES
    ===========================================================================
     Created by:       Alan Callahan
     Assisted by:      ChatGPT / Copilot
     Modified on:       4/15/2023
     Filename:         DomainControllerUtilities.psm1
     Version:          Beta 1.0
    ===========================================================================
    .DESCRIPTION
    This PowerShell module contains functions to retrieve information about domain controllers in a domain and test their connectivity and uptime.

    .NOTES
    ===========================================================================
        Dependencies:
        - Get-AllDomainsInForest function
        - Get-DomainControllersInDomain function
        - Test-DomainNameDNS function
        - Test-DomainControllerConnectivity function
        - Get-DomainControllerUptime function
    
        To use this module, make sure to include the functions in your script.
    ===========================================================================
#>

Export-ModuleMember -Function *-*

<#
.SYNOPSIS
    Retrieves all domains in the current forest.

.DESCRIPTION
    This function uses the System.DirectoryServices.ActiveDirectory namespace to get the current forest object and retrieve all domains within it.

.EXAMPLE
    Get-AllDomainsInForest -Verbose

    Returns all domains in the forest and displays verbose output indicating the actions being performed.
#>
# Function to retrieve all domains in the current forest
function Get-AllDomainsInForest {
    [CmdletBinding()]
    param()

    Process {
        Write-Verbose "Getting forest object..."
        $forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()

        Write-Verbose "Retrieving all domains in the forest..."
        $domains = $forest.Domains

        Write-Verbose "Found $($domains.Count) domain(s) in the forest:"
        return $domains
    }
}


<#
.SYNOPSIS
    Retrieves all domain controllers in a specified domain.

.DESCRIPTION
    This function uses the System.DirectoryServices.ActiveDirectory namespace to find all domain controllers within a specified domain.

.PARAMETER DomainName
    The name of the domain for which to retrieve the domain controllers.

.EXAMPLE
    $domainName = "domain.local"
    Get-DomainControllersInDomain -DomainName $domainName -Verbose

    Returns all domain controllers in the "example.com" domain and displays verbose output indicating the actions being performed.
#>
# Function to retrieve all domain controllers in a specified domain
function Get-DomainControllersInDomain {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, HelpMessage="The name of the domain for which to retrieve the domain controllers.")]
        [string]$DomainName
    )

    Process {
        Write-Verbose "Getting domain context for '$DomainName'..."
        $domainContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("Domain", $DomainName)

        Write-Verbose "Retrieving all domain controllers in the '$DomainName' domain..."
        $domainControllers = [System.DirectoryServices.ActiveDirectory.DomainController]::FindAll($domainContext)

        Write-Verbose "Found $($domainControllers.Count) domain controller(s) in the '$DomainName' domain:"
        return $domainControllers
    }
}


<#
.SYNOPSIS
    Tests the provided domain name against DNS and returns the success status.

.DESCRIPTION
    This function uses the Resolve-DnsName cmdlet to test the provided domain name against DNS and returns the success status.

.PARAMETER DomainName
    The name of the domain to test against DNS.

.EXAMPLE
    $domainName = "domain.local"
    $resolutionStatus = Test-DomainNameDNS -DomainName $domainName

    Tests the "domain.local" domain name against DNS and stores the success status in the $resolutionStatus variable.
#>
# Function to test the provided domain name against DNS and return the success status
function Test-DomainNameDNS {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, HelpMessage="The name of the domain to test against DNS.")]
        [string]$DomainName
    )

    Process {
        $resolutionStatus = $false
        try {
            Write-Verbose "Resolving DNS for '$DomainName'..."
            $dnsResolution = Resolve-DnsName -Name $DomainName -Type A -ErrorAction Stop
            if ($dnsResolution) {
                Write-Verbose "Successfully resolved DNS for '$DomainName'"
                $resolutionStatus = $true
            }
        }
        catch {
            Write-Verbose "Failed to resolve DNS for '$DomainName'"
        }
        return $resolutionStatus
    }
}


<#
.SYNOPSIS
    Tests the connectivity to each domain controller and returns a hashtable with the connectivity status.

.DESCRIPTION
    This function uses the Test-Connection cmdlet to test the connectivity to each domain controller and returns a hashtable with the connectivity status.

.PARAMETER DomainControllers
    An array of domain controllers to test connectivity.

.EXAMPLE
    # First, retrieve the domain controllers using the Get-DomainControllersInDomain function
    $domainName = "domain.local"
    $domainControllers = Get-DomainControllersInDomain -DomainName $domainName

    # Then, test the connectivity to each domain controller
    $connectivityStatus = Test-DomainControllerConnectivity -DomainControllers $domainControllers

    Tests the connectivity to each domain controller in the $domainControllers array and stores the connectivity status in the $connectivityStatus variable.

.NOTES
    Dependencies:
    - Get-DomainControllersInDomain function

    To use this function, make sure to include the Get-DomainControllersInDomain function in your script.
#>
# Function to test the connectivity to each domain controller and return a hashtable with the connectivity status
function Test-DomainControllerConnectivity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, HelpMessage="An array of domain controllers to test connectivity.")]
        [System.DirectoryServices.ActiveDirectory.DomainController[]]$DomainControllers
    )

    Process {
        $connectivityStatus = @{}
        foreach ($domainController in $DomainControllers) {
            Write-Verbose "Testing connectivity to '$($domainController.Name)'..."
            $isReachable = Test-Connection -ComputerName $domainController.Name -Count 1 -Quiet
            if ($isReachable) {
                Write-Verbose "Successfully connected to '$($domainController.Name)'"
                $connectivityStatus[$domainController.Name] = "Success"
            } else {
                Write-Verbose "Failed to connect to '$($domainController.Name)'"
                $connectivityStatus[$domainController.Name] = "Fail"
            }
        }
        return $connectivityStatus
    }
}


<#
.SYNOPSIS
    Retrieves the uptime for each domain controller and returns a hashtable with the uptime in total days.

.DESCRIPTION
    This function uses the Get-WmiObject cmdlet to get the Win32_OperatingSystem class, which contains the LastBootUpTime property, to calculate the uptime for each domain controller.

.PARAMETER DomainControllers
    An array of domain controllers to check uptime.

.EXAMPLE
    $domainName = "domain.local"
    $domainControllers = Get-DomainControllersInDomain -DomainName $domainName
    $upTimeStatus = Get-DomainControllerUpTime -DomainControllers $domainControllers

    Retrieves the uptime for each domain controller in the $domainControllers array and stores the uptime in total days in the $upTimeStatus variable.

.NOTES
    Dependencies:
    - Get-DomainControllersInDomain function

    To use this function, make sure to include the Get-DomainControllersInDomain function in your script.
#>
# Function to get the uptime for each domain controller
function Get-DomainControllerUpTime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, HelpMessage="An array of domain controllers to check uptime.")]
        [System.DirectoryServices.ActiveDirectory.DomainController[]]$DomainControllers
    )

    Process {
        $upTimeStatus = @{}
        foreach ($domainController in $DomainControllers) {
            if (Test-Connection -ComputerName $domainController.Name -Count 1 -Quiet) {
                Write-Verbose "Retrieving uptime for '$($domainController.Name)'..."
                $osInfo = Get-WmiObject -ComputerName $domainController.Name -Class Win32_OperatingSystem
                $lastBootUpTime = $osInfo.ConvertToDateTime($osInfo.LastBootUpTime)
                $upTime = (Get-Date) - $lastBootUpTime
                $upTimeStatus[$domainController.Name] = [math]::Floor($upTime.TotalDays)
                Write-Verbose "Uptime for '$($domainController.Name)': $($upTimeStatus[$domainController.Name]) days"
            } else {
                Write-Warning "Unable to reach '$($domainController.Name)'. Skipping this domain controller."
            }
        }
        return $upTimeStatus
    }
}


<#
.SYNOPSIS
    Retrieves the percentage of free disk space on the drive hosting the DIT file for each domain controller in the specified domain.

.DESCRIPTION
    This function uses the Microsoft.Win32.RegistryKey class to access the Windows Registry key on each remote domain controller to retrieve the path of the DIT file. It then calculates the percentage of free disk space on the drive hosting the DIT file and returns the value as a rounded integer in a hashtable.

.PARAMETER DomainControllers
    An array of domain controllers to check.

.EXAMPLE
    $domainName = "domain.local"
    $domainControllers = Get-DomainControllersInDomain -DomainName $domainName
    $freeDiskSpaceStatus = Get-DITFileDriveSpace -DomainControllers $domainControllers

    Retrieves the percentage of free disk space on the drive hosting the DIT file for each domain controller in the specified domain and stores the result in a hashtable.

#>
# Function retrieves the percentage of free disk space on the drive hosting the DIT file for each domain controller in the specified domain.
function Get-DITFileDriveSpace {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, HelpMessage="An array of domain controllers to check.")]
        [System.DirectoryServices.ActiveDirectory.DomainController[]]$DomainControllers
    )

    Process {
        $freeDiskSpaceStatus = @{}
        foreach ($domainController in $DomainControllers) {
            if (Test-Connection -ComputerName $domainController.Name -Count 1 -Quiet) {
                try {
                    $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $domainController.Name)
                    $regKey = $reg.OpenSubKey("SYSTEM\CurrentControlSet\Services\NTDS\Parameters")
                    
                    if ($regKey -ne $null) {
                        $ditFilePath = $regKey.GetValue("DSA Database file")
                        $driveLetter = $ditFilePath.Substring(0, 2)
                        $reg.Close()

                        $diskInfo = Get-WmiObject -ComputerName $domainController.Name -Class Win32_LogicalDisk -Filter "DeviceID='$driveLetter'"
                        $freeSpacePercentage = [math]::Round(($diskInfo.FreeSpace / $diskInfo.Size) * 100)

                        $freeDiskSpaceStatus[$domainController.Name] = $freeSpacePercentage
                        Write-Verbose "Free disk space on the DIT file drive ($driveLetter) of '$($domainController.Name)': $freeSpacePercentage%"
                    } else {
                        Write-Warning "Registry key not found on '$($domainController.Name)'. Skipping this domain controller."
                    }
                } catch {
                    Write-Error "An error occurred while checking the DIT file drive space on '$($domainController.Name)': $_"
                }
            } else {
                Write-Warning "Unable to reach '$($domainController.Name)'. Skipping this domain controller."
            }
        }
        return $freeDiskSpaceStatus
    }
}


<#
.SYNOPSIS
    Retrieves the status of DNS, NTDS, and Netlogon services on each domain controller in the specified domain.

.DESCRIPTION
    This function checks the status of the DNS, NTDS, and Netlogon services on each domain controller in the specified domain and returns the status in a hashtable.

.PARAMETER DomainControllers
    An array of domain controllers to check.

.EXAMPLE
    $domainName = "example.com"
    $domainControllers = Get-DomainControllersInDomain -DomainName $domainName
    $dcServiceStatus = Get-DCServiceStatus -DomainControllers $domainControllers

    Retrieves the status of the DNS, NTDS, and Netlogon services on each domain controller in the specified domain and stores the result in a hashtable.

#>
# Function retrieves the status of DNS, NTDS, and Netlogon services on each domain controller in the specified domain.
function Get-DCServiceStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, HelpMessage="An array of domain controllers to check.")]
        [System.DirectoryServices.ActiveDirectory.DomainController[]]$DomainControllers
    )

    Process {
        $servicesToCheck = @("DNS", "NTDS", "Netlogon")
        $dcServiceStatus = @{}

        foreach ($domainController in $DomainControllers) {
            $dcServiceStatus[$domainController.Name] = @{}

            foreach ($service in $servicesToCheck) {
                try {
                    $serviceStatus = Get-Service -ComputerName $domainController.Name -Name $service -ErrorAction Stop
                    $dcServiceStatus[$domainController.Name][$service] = $serviceStatus.Status
                    Write-Verbose "Status of '$service' service on '$($domainController.Name)': $($serviceStatus.Status)"
                } catch {
                    Write-Warning "An error occurred while checking the '$service' service on '$($domainController.Name)': $_"
                    $dcServiceStatus[$domainController.Name][$service] = "Error"
                }
            }
        }
        return $dcServiceStatus
    }
}


<#
.SYNOPSIS
    Runs five DCDiag tests on each domain controller in the specified domain and stores the results in a hashtable.

.DESCRIPTION
    This function uses the DCDiag command to run the following tests on each domain controller in the specified domain:
    - Advertising
    - FrsEvent
    - DFSREvent
    - SysVolCheck
    - KccEvent

.PARAMETER DomainControllers
    An array of domain controllers on which to run the DCDiag tests.

.EXAMPLE
    $domainName = "domain.local"
    $domainControllers = Get-DomainControllersInDomain -DomainName $domainName
    $dcDiagStatus = Get-DCDiagStatus -DomainControllers $domainControllers

    Runs the five DCDiag tests on each domain controller in the specified domain and stores the results in a hashtable.

#>
# Function runs five DCDiag tests on each domain controller in the specified domain and stores the results in a hashtable.
function Get-DCDiagStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, HelpMessage="An array of domain controllers on which to run the DCDiag tests.")]
        [System.DirectoryServices.ActiveDirectory.DomainController[]]$DomainControllers
    )

    Process {
        $dcDiagStatus = @{}
        $tests = "Advertising","FrsEvent","DFSREvent","SysVolCheck","KccEvent"

        foreach ($domainController in $DomainControllers) {
            $dcDiagStatus[$domainController.Name] = @{}

            if (Test-Connection -ComputerName $domainController.Name -Count 2 -Quiet) {
                Write-Verbose "Running DCDiag tests on '$($domainController.Name)'..."

                foreach ($test in $tests) {
                    try {
                        $result = & "dcdiag.exe" /s:$($domainController.Name) /test:$test /q
                        if ($LASTEXITCODE -eq 0) {
                            $dcDiagStatus[$domainController.Name][$test] = "Passed"
                        } else {
                            $dcDiagStatus[$domainController.Name][$test] = "Failed"
                        }
                        Write-Verbose "DCDiag '$test' test on '$($domainController.Name)': $($dcDiagStatus[$domainController.Name][$test])"
                    } catch {
                        Write-Warning "An error occurred while running the DCDiag '$test' test on '$($domainController.Name)': $_"
                        $dcDiagStatus[$domainController.Name][$test] = "Error"
                    }
                }
            } else {
                Write-Warning "The server '$($domainController.Name)' is not reachable. Skipping DCDiag tests."
                foreach ($test in $tests) {
                    $dcDiagStatus[$domainController.Name][$test] = "Skipped"
                }
            }
        }
        return $dcDiagStatus
    }
}


<#
.SYNOPSIS
    Displays the results of the Get-DCDiagStatus function on the screen.

.DESCRIPTION
    This function takes the hashtable output from Get-DCDiagStatus and displays the results in a human-readable format on the screen.

.PARAMETER DCDiagStatus
    A hashtable containing the DCDiag test results, typically obtained from the Get-DCDiagStatus function.

.EXAMPLE
    $domainName = "domain.local"
    $domainControllers = Get-DomainControllersInDomain -DomainName $domainName
    $dcDiagStatus = Get-DCDiagStatus -DomainControllers $domainControllers
    Test-DCDiagStatus -DCDiagStatus $dcDiagStatus

    Displays the results of the DCDiag tests on the screen.

#>
# Function displays the results of the Get-DCDiagStatus function on the screen.
function Test-DCDiagStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, HelpMessage="A hashtable containing the DCDiag test results.")]
        [hashtable]$DCDiagStatus
    )

    Process {
        Write-Host "`nDCDiag Test Results:`n" -ForegroundColor Cyan
        foreach ($domainController in $DCDiagStatus.Keys) {
            Write-Host "Domain Controller: $domainController" -ForegroundColor Yellow
            $testResults = $DCDiagStatus[$domainController]
            foreach ($test in $testResults.Keys) {
                $result = $testResults[$test]
                if ($result -eq "Passed") {
                    $color = "Green"
                } elseif ($result -eq "Failed") {
                    $color = "Red"
                } else {
                    $color = "Magenta"
                }
                Write-Host ("  {0}: {1}" -f $test, $result) -ForegroundColor $color
            }
            Write-Host ""
        }
    }
}


<#
.SYNOPSIS
    Retrieves the OS version of the specified computers.

.DESCRIPTION
    This function uses the Get-WmiObject cmdlet to retrieve the OS version of the specified computers.

.PARAMETER ComputerNames
    An array of computer names for which to retrieve the OS version.

.EXAMPLE
    $computerNames = @("DC1", "DC2")
    $osVersions = Get-OSVersion -ComputerNames $computerNames

    Retrieves the OS version for the computers "DC1" and "DC2".

.NOTES
    $domainName = "domain.local"
    $domainControllers = Get-DomainControllersInDomain -DomainName $domainName

    $computerNames = $domainControllers.Name
    $osVersions = Get-OSVersion -ComputerNames $computerNames

    foreach ($computerName in $computerNames) {
        $osCaption = $osVersions[$computerName].Caption
        $osVersion = $osVersions[$computerName].Version
        Write-Host "Computer: $computerName - OS: $osCaption ($osVersion)"
    }

    Retrieves the OS version for all domain controllers in the specified domain.
#>
# Function retrieves the OS version of the specified computers.
function Get-OSVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, HelpMessage="An array of computer names for which to retrieve the OS version.")]
        [string[]]$ComputerNames
    )

    Process {
        $osVersions = @{}

        foreach ($computerName in $ComputerNames) {
            try {
                $osInfo = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $computerName
                $osVersions[$computerName] = @{
                    Caption = $osInfo.Caption;
                    Version = $osInfo.Version;
                }
            } catch {
                Write-Warning "An error occurred while retrieving the OS version for '$computerName': $_"
                $osVersions[$computerName] = @{
                    Caption = "Error";
                    Version = "Error";
                }
            }
        }
        return $osVersions
    }
}


<#
.SYNOPSIS
    Retrieves the percentage of free space on the OS drive of the specified computers.

.DESCRIPTION
    This function uses the Get-WmiObject cmdlet to retrieve the percentage of free space on the OS drive of the specified computers.

.PARAMETER ComputerNames
    An array of computer names for which to retrieve the percentage of free space on the OS drive.

.EXAMPLE
    $computerNames = @("DC1", "DC2")
    $osDriveFreeSpacePercentage = Get-OSDriveFreeSpace -ComputerNames $computerNames

    Retrieves the percentage of free space on the OS drive for the computers "DC1" and "DC2".

.Notes
    $domainName = "domain.local"
    $domainControllers = Get-DomainControllersInDomain -DomainName $domainName

    $computerNames = $domainControllers.Name
    $osDriveFreeSpacePercentage = Get-OSDriveFreeSpace -ComputerNames $computerNames

    foreach ($computerName in $computerNames) {
        $freeSpacePercentage = $osDriveFreeSpacePercentage[$computerName]
        Write-Host "Computer: $computerName - Free Space: $freeSpacePercentage%"
    }

    Retrieves the percentage of free space on the OS drive for all domain controllers in the specified domain.
#>
# Function retrieves the percentage of free space on the OS drive of the specified computers.
function Get-OSDriveFreeSpace {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, HelpMessage="An array of computer names for which to retrieve the percentage of free space on the OS drive.")]
        [string[]]$ComputerNames
    )

    Process {
        $osDriveFreeSpacePercentage = @{}

        foreach ($computerName in $ComputerNames) {
            try {
                $osDrive = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $computerName | Select-Object -ExpandProperty SystemDrive
                $driveInfo = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $computerName | Where-Object { $_.DeviceID -eq $osDrive }
                $freeSpacePercentage = [math]::Round(($driveInfo.FreeSpace / $driveInfo.Size) * 100, 2)

                $osDriveFreeSpacePercentage[$computerName] = $freeSpacePercentage
            } catch {
                Write-Warning "An error occurred while retrieving the percentage of free space on the OS drive for '$computerName': $_"
                $osDriveFreeSpacePercentage[$computerName] = "Error"
            }
        }
        return $osDriveFreeSpacePercentage
    }
}
