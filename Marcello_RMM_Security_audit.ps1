<# 
	.Synopsis
    The purpose of this script is to create security audit on all RMM managed devices based on 'known' factors
        
	.Notes
	Version   	..: 3.2.3
	Created   	..: 14.09.2020
	Created by	..: Kenneth Jøleid-Skari, Marcello Consulting AS.

	Change log	..:
    21.03.2022 - 3.2.3 - corrected erroraction on regquery for printnightmare
    21.03.2022 - 3.2.2 - added check for "disable inbound printing" as approved workaround for print nightmare
    04.01.2022 - 3.2.1 - added more eventIDs into 60003 logging
    10.12.2021 - 3.2.0 - updated commenting for easier LM parsing
    02.12.2021 - 3.1.9 - corrected RmmCapable for Hardening Kitty
    19.11.2021 - 3.1.8 - improved logging and fixed eventID 60003
    15.11.2021 - 3.1.7 - autoformatted code with VScode
    15.11.2021 - 3.1.6 - standarized variable DisplayOutput, IsDattoRmm and RmmCapable
    14.09.2020 - 1.0.0 - Initial Release

	.Description
	This script is a copy of Datto RMM Security Audit, however, it is adopted into "Marcello mindset".
        Areases marked as '#region Datto RMM original - ' will have modified output to comply with a better output for reading purpose

	.Example
    
    .Link
    Source files...:
        https://help.aem.autotask.net/en/Content/2SETUP/BestPractices/Best_Practices_Security_Audit.htm
#>
[CmdletBinding()]
Param (
    [Parameter(Mandatory = $false)]
    [bool]$DisplayOutput,
    [bool]$RmmCapable,
    [bool]$IsDattoRmm
)

#region Marcello Adoption - Datto RMM boilerplaten
[int]$varBuildString = 49
#region Marcello Adoption
$varCustomBuildString = "3.2.3"
$varMarcelloBuildString = "$varBuildString-$varCustomBuildString"
#endregion
#region main variables for script
[int]$varKernel = ([System.Diagnostics.FileVersionInfo]::GetVersionInfo("C:\Windows\system32\kernel32.dll")).FileBuildPart
$ErrorActionPreference = "Stop"
$varTimeZone = (Get-Itemproperty 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' -Name TimeZoneKeyName).TimeZoneKeyName -replace '[^a-zA-Z:()\s]', "-"
$varPSVersion = "PowerShell version: " + $PSVersionTable.PSVersion.Major + '.' + $PSVersionTable.PSVersion.Minor
$varPartOfDomain = (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain
[int]$varDomainRole = (Get-WmiObject -Class Win32_ComputerSystem).DomainRole
[int]$varWarnings = 0
[int]$varAlerts = 0
#endregion
#region create eventlog source
if (!([System.Diagnostics.EventLog]::SourceExists("Marcello RMM Security Audit"))) {
    New-EventLog -LogName 'Application' -Source 'Marcello RMM Security Audit'
}
#endregion
#region main variables for functions
#region correct DisplayOutput according to RMM variable
if ($env:DisplayOutput -like "false") {
    $DisplayOutput = $false
}
if ($env:DisplayOutput -like "true") {
    $DisplayOutput = $true
}
if ($env:RmmCapable -like "true") {
    $RmmCapable = $true
}
if ($env:IsDattoRmm -like "true") {
    $IsDattoRmm = $true
}
#endregion
$EventLog = "Application"
$EventSource = "Marcello RMM Security Audit"
$EventIDsLogging = ""
$StartLine = "======================"
$LineBreak = "===================================================================="
$NewLine = "`r`n"
#endregion

#region write-host output for RMM jobs
if ($DisplayOutput) {
    #region Datto RMM original - preliminary pabulum
    Write-Host "`r`nMarcello RMM Security Audit: build $varMarcelloBuildString`r`n"
    Write-Host "Local Time:        " (Get-Date)
    Write-Host "Local Timezone:    " $varTimeZone
    Write-Host "Windows Version:    Build $varKernel`:" (Get-WmiObject -computername $env:computername -Class win32_operatingSystem).caption
    Write-Host $varPSVersion
    #endregion
    #region Datto RMM original - workgroup/domain
    if (!(Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain) {
        if ((Get-WmiObject -Class Win32_ComputerSystem).Workgroup -match 'WORKGROUP') {
            Write-Host "Workgroup:          Default Workgroup Setting `(`'WORKGROUP`'`)"
        }
        else {
            Write-Host "Workgroup:         "(Get-WmiObject -Class Win32_ComputerSystem).Workgroup
        }
    }
    else {
        Write-Host "Domain:            "(Get-WmiObject -Class Win32_ComputerSystem).Domain
    }
    #endregion
}
#endregion

#region Marcello RMM adoption - timer for logging
$ScriptTime = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
$EventID = "60001"
$EventType = "Information"
$EventMessage = "Marcello RMM Security Audit Alert:`rAudit started."
            
#region write-host output for RMM jobs
if ($DisplayOutput) {
    Write-Host $LineBreak $NewLine
    Write-Host ": START: $ScriptTime" $NewLine
}
#endregion
#region write to eventlog
Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
#endregion
#endregion
#endregion


function Check-AccountSecurityAudit {
    <# 
        .SYNOPSIS
        Function "Check-AccountSecurityAudit"
        .DESCRIPTION
        This function will 

        .NOTES
        Version   	..: 1.1.2
        Created   	..: 11.11.2021
        Created by	..: Kenneth Jøleid-Skari, Marcello Consulting AS.

        Change log	..:
        12.11.2021 - 1.1.1 - replaced UsedForRmm_job with DisplayOutput
        11.11.2021 - 1.1.0 - Corrected "UsedForRmm_job" if checks and added Domain Check to alert on where LAPS is not installed
                      1.03 - Added check for default administator account and corrected warning message reflecting LAPS "protection"
        .LINK
            https://4sysops.com/archives/monitoring-laps-with-configuration-manager
    #>

    #region Variables for function
    $FunctionName = "Account Security Audit"
    #endregion

    #region write-host output for RMM jobs
    if ($DisplayOutput) {
        # sum total characters should be the same as for $LineBreak. By having same start and end, text will be line centrated.
        Write-Host "$($LineBreak[0..20] -join('')) ($FunctionName) $($LineBreak[0..20] -join(''))"
    }
    #endregion

    #region check: Marcello RMM adoption - LAPS and local account password age
    #check registry for AdmPwdEnabled for LAPS existance or not
    try {
        #region eventID variable
        $EventID = "60101"
        $EventType = "Warning"
        $EventMessage = "Marcello RMM Security Audit Alert:`rLAPS is installed but not running.`rThis poses a security risk as management of Local `'Adminstrator`' is not being handled."

        $AlertMessage = "- ALERT: LAPS is installed but not running."
        $WarningMessage = "- WARNING: 'Insert text here'"
        $InfoMessage = "+ LAPS is installed and running."
        #endregion

        $varLAPSenabled = (Get-Itemproperty 'HKLM:\SOFTWARE\Policies\Microsoft Services\AdmPwd').AdmPwdEnabled
        if ($varLAPSenabled -ne 1) {
            #region write to eventlog
            Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
            #endregion
            #region update UDF
            $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
            #endregion
            #region write-host output for RMM jobs
            if ($DisplayOutput) {
                Write-Host $AlertMessage
                $script:varAlerts++
            }
            #endregion
        }
        else {
            #region write-host output for RMM jobs
            if ($DisplayOutput) {
                Write-Host $InfoMessage
            }
            #endregion
        }
    }
    catch [System.Exception] {
        if ($varPartOfDomain) {
            #region eventID variable
            $EventID = "60102"
            $EventType = "Warning"
            $EventMessage = "Marcello RMM Security Audit Alert:`rLAPS is not installed.`rThis poses a security risk as management of Local `'Adminstrator`' is not being handled."

            $AlertMessage = "- ALERT: LAPS is not installed."
            #endregion
            #region write to eventlog
            Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
            #endregion
            #region update UDF
            $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
            #endregion
            #region write-host output for RMM jobs
            if ($DisplayOutput) {
                Write-Host $AlertMessage
                $script:varAlerts++
            }
            #endregion
        }
        else {
            #do nothing as LAPS is only for Domain Members
        }
    }
    #region function to identify local account password age
    $Passwordage = 31 # this value is the same value, +1 day, as configured in LAPS policy 'PasswordAgeDays'
    function Get-SWLocalPasswordLastSet {
        $acc = Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount='True' And Sid like '%-500'"
        $user = ([adsi]"WinNT://./$($acc.Name),user")
        $pwAge = $user.PasswordAge.Value
        return (Get-Date).AddSeconds(-$pwAge)
    }
    if ($varLAPSenabled) {
        $strDate = Get-SWLocalPasswordLastSet
        $StrDays = (New-TimeSpan $StrDate $(Get-Date)).Days
        $pwdChangeCompliance = ($StrDays -le $Passwordage)
    }
    else {
        $strDate = Get-SWLocalPasswordLastSet
        $StrDays = (New-TimeSpan $StrDate $(Get-Date)).Days
        $pwdChangeCompliance = ($StrDays -le $Passwordage)        
    }
    #region eventID variable
    $EventID = "60103"
    $EventType = "Warning"
    $EventMessage = "Marcello RMM Security Audit Alert:`rLocal `'Administrator`' account has not changed password for $($StrDays)days.`rThis poses a security risk.`rRemediation of this would be easily managed by implementing LAPS."
        
    $AlertMessage = "- ALERT: Local `'Administrator`' account has not changed password for $($StrDays)days."
    $WarningMessage = "- WARNING: 'Insert text here'"
    $InfoMessage = "+ Local `'Administrator`' account has changed password $($StrDays) days ago (within last $($Passwordage) days)."
    #endregion
    if ($pwdChangeCompliance) {
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host $InfoMessage
        }
        #endregion
    }
    else {
        #region write to eventlog
        Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
        #endregion
        #region update UDF
        $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
        #endregion
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host $AlertMessage
            $script:varAlerts++
        }
        #endregion
    }
    #endregion
    #endregion
    #region check: Marcello RMM adoption - is admin account disabled
    $localAccountExists = Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount='$true'"
    if ( -not $localAccountExists ) {
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host "+ No Local Accounts (Admin, Guest) exist on this device."
        }
        #endregion
    }
    else {
        #region Datto RMM original - is guest account disabled
        #region eventID variable
        $EventID = "60104"
        $EventType = "Warning"
        $EventMessage = "Marcello RMM Security Audit Alert:`rLocal `'Guest`' account is enabled on this device.`rThis unprotected user account can be used as a vantage point by malware and should be disabled."

        $AlertMessage = "- ALERT: Local `'Guest`' account is enabled on this device."
        $WarningMessage = "- WARNING: 'Insert text here'"
        $InfoMessage = "+ Local `'Guest`' account is disabled on this device."
        #endregion
        if ((Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount='$true' AND SID LIKE '%-501'").disabled) {
            #region write-host output for RMM jobs
            if ($DisplayOutput) {
                Write-Host $InfoMessage
            }
            #endregion
        }
        else {
            #region write to eventlog
            Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
            #endregion
            #region update UDF
            $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
            #endregion
            #region write-host output for RMM jobs
            if ($DisplayOutput) {
                Write-Host $AlertMessage
                $script:varAlerts++
            }
            #endregion
        }
        #endregion
    }
    #region Marcello RMM adoption - is admin account disabled
    #region eventID variable
    $EventID = "60105"
    $EventType = "Warning"
    $EventMessage = "Marcello RMM Security Audit Alert:`rLocal `'Administrator`' account is enabled on this device.`rThis can be used as a vantage point by malware and should be disabled."

    $AlertMessage = "- ALERT: Local `'Administrator`' account is enabled on this device."
    $WarningMessage = "- WARNING: 'Insert text here'"
    $InfoMessage = "+ Local `'Administrator`' account is disabled on this device."
    #endregion
    if ((Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount='$true' AND SID LIKE '%-500'").disabled) {
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host $InfoMessage
        }
        #endregion
    }
    else {
        if ($varPartOfDomain -and $varLAPSenabled -eq 1) {
            #region write-host output for RMM jobs
            $InfoMessage = "+ Local `'Administrator`' account is managed by LAPS as the device is domain joined."
            if ($DisplayOutput) {
                Write-Host $InfoMessage
            }
            #endregion
        }
        else {
            #region write to eventlog
            Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
            #endregion
            #region update UDF
            $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
            #endregion
            #region write-host output for RMM jobs
            if ($DisplayOutput) {
                Write-Host $AlertMessage
                $script:varAlerts++
            }
            #endregion
        }
    }
    #endregion
    #region Datto RMM original -  are all accounts in the administrators group disabled? v2: ps2 compat
    #region eventID variable
    $EventID = "60106"
    $EventType = "Warning"

    $AlertMessage = "- ALERT: 'Insert text here'"
    $WarningMessage = "- WARNING: The following local users are members of the `'Administrators`' group:"
    $InfoMessage = "+ No members of the `'Administrators`' group have local access."
    #endregion
    $arrLocalAdmins = @()
            (Get-WmiObject -Class Win32_Group -Filter "LocalAccount=TRUE and SID='S-1-5-32-544'").GetRelated("Win32_Account", "", "", "", "PartComponent", "GroupComponent", $FALSE, $NULL) | where-object { $_.Domain -match $env:COMPUTERNAME } | ForEach-Object {
        $varCurrentName = $_.Name
        if (!(Get-WmiObject -Class Win32_UserAccount -filter "Name like '$varCurrentName' AND LocalAccount=TRUE" | % { $_.disabled })) {
            $arrLocalAdmins += ($varCurrentName -as [string])
        }
    }

    $arrLocalAdmins = $arrLocalAdmins | where { $_ -match "\w" }
    if ($arrLocalAdmins) {
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host $WarningMessage
            $script:varWarnings++
        }
        #endregion
        foreach ($iteration in $arrLocalAdmins) {
            if ((Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain) {
                #check if $iteration is default administrator account - if so skip EventID creation as account is expected to controlled by LAPS
                if (!(Get-WmiObject -Class Win32_UserAccount -filter "LocalAccount=TRUE AND Name like '$iteration' AND SID like 'S-1-5-21-%500'")) {
                    $EventMessage = "Marcello RMM Security Audit Alert:`rLocal `'$iteration`' account is a member of the `'Administrators`' group.`rLocal users should not have device-level administrative privileges.`rDevices should be governed by the network or domain administrator."
                    #region write to eventlog
                    Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
                    #endregion
                    #region update UDF
                    $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
                    #endregion
                    #region write-host output for RMM jobs
                    if ($DisplayOutput) {
                        Write-Host "    `'$iteration`'"
                    }
                    #endregion
                }
                else {
                    #region write-host output for RMM jobs
                    if ($DisplayOutput) {
                        Write-Host "    `'$iteration`' (This is the default, system created Administrator account. It's not considered to be a security risk, as this device is expected to be governed by a LAPS installation)."
                        $script:varWarnings++
                    }
                    #endregion
                }
            }
            else {
                $EventMessage = "Marcello RMM Security Audit Alert:`rLocal `'$iteration`' account is a member of the `'Administrators`' group.`rLocal users should not have device-level administrative privileges.`rDevices should be governed by the network or domain administrator."
                #region write-host output for RMM jobs
                if ($DisplayOutput) {
                    Write-Host "    `'$iteration`'"
                }
                #endregion
                #region write to eventlog
                Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
                #endregion
                #region update UDF
                $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
                #endregion
                #region write-host output for RMM jobs
                if ($DisplayOutput) {
                    Write-Host $WarningMessage
                    $script:varWarnings++
                }
                #endregion
            }
        }
    }
    else {
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host $InfoMessage
        }
        #endregion
    }
    #endregion
    #endregion

    #region end of function
    #region write-host output for RMM jobs
    if ($DisplayOutput) {
        Write-Host $LineBreak $NewLine
    }
    #endregion
    #endregion
}

function Check-PasswordPolicyAudit {
    <# 
        .SYNOPSIS
        Function "Check-PasswordPolicyAudit"
        .DESCRIPTION
        This function will 

        .NOTES
        Version   	..: 1.1.2
        Created   	..: 11.11.2021
        Created by	..: Kenneth Jøleid-Skari, Marcello Consulting AS.

        Change log	..:
        12.11.2021 - 1.1.2 - replaced UsedForRmm_job with DisplayOutput
        11.11.2021 - 1.1.1 - correction in code for "UsedForRmm_job"

        .LINK
    #>

    #region Variables for function
    $FunctionName = "Password Policy Audit"
    #endregion

    #region write-host output for RMM jobs
    if ($DisplayOutput) {
        # sum total characters should be the same as for $LineBreak. By having same start and end, text will be line centrated.
        Write-Host "$($LineBreak[0..20] -join('')) ($FunctionName) $($LineBreak[0..21] -join(''))"
    }
    #endregion

    #region check: Datto RMM original -  net accounts, since we're not doing anything with the data besides displaying it
    if (!(Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain) {
        foreach ($iteration in (net accounts | where { $_ -match "\w" })) {
            if ($iteration -match ":") {
                #region write-host output for RMM jobs
                if ($DisplayOutput) {
                    Write-Host : $iteration
                }
                #endregion
            }
        }
    }
    else {
        # Skipping local password policy audit as device will use domain-enforced policy settings.
    }
    #endregion
    #region check: Marcello RMM adoption - default password for automatic logon
    <#
            Changed $varDefaultPassLength -le 7 to 15 as 15 is according to Marcello default password policy
        #>
    try {
        #region check registry for information
        $varDefaultPassLength = ((Get-Itemproperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name defaultPassword).defaultPassword).length
        $varDefaultPass = (Get-Itemproperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name defaultPassword).defaultPassword
        # $varDefaultUser = "undefined"
        $varDefaultUser = (Get-Itemproperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name defaultUserName).defaultUserName
        #endregion
        #region eventID variable
        $EventID = "60201"
        $EventType = "Warning"
        $EventMessage = "Marcello RMM Security Audit Alert:`rAccount password for user `'$varDefaultUser`' is stored in plaintext in Registry.`rThe user appears to have configured their device to log into their user account automatically via the Registry.`rThe password is stored in plaintext at HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon under value `'DefaultPassword`' and should be removed ASAP."
            
        $AlertMessage = "- ALERT: Account password for user `'$varDefaultUser`' is stored in plaintext in Registry `($varDefaultPassLength characters`)."
        $WarningMessage = "- WARNING: 'Insert text here'" 
        #endregion
        #region write to eventlog
        Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
        #endregion
        #region update UDF
        $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
        #endregion
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host $AlertMessage
            $script:varAlerts++
        }
        #endregion
            
        #since we have the password, may as well analyse it
        # -- length
        if ($varDefaultPassLength -le 15) {
            #region eventID variable
            $EventID = "60202"
            $EventType = "Warning"
            $EventMessage = "Marcello RMM Security Audit Alert:`rSince the password for user `'$varDefaultUser`' is stored in plaintext in the Registry, it's been analysed for length.`rThe password contains less than 8 characters.`rImplement a stronger password or stronger password policy settings."
                        
            $AlertMessage = "- ALERT: As the password for user `'$varDefaultUser`' is stored in plaintext in the Registry, it's been analysed for length.`r    The password contains less than 8 characters."
            #endregion
            #region write to eventlog
            Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
            #endregion
            #region update UDF
            $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
            #endregion
            #region write-host output for RMM jobs
            if ($DisplayOutput) {
                Write-Host $AlertMessage
                $script:varAlerts++
            }
            #endregion
        }
        # -- strength
        if ($varDefaultPass -match 'password' -or $varDefaultPass -match 'p4ssw0rd' -or $varDefaultPass -match '12345' -or $varDefaultPass -match 'qwerty' -or $varDefaultPass -match 'letmein') {
            #region eventID variable
            $EventID = "60203"
            $EventType = "Warning"
            $EventMessage = "Marcello RMM Security Audit Alert:`rSince the password for user `'$varDefaultUser`' is stored in plaintext in the Registry, it's been analysed for strength.`rThe password is one of many well-known common passwords.`rImplement a more unique password or stronger password policy settings."

            $AlertMessage = "- ALERT: As the password for user `'$varDefaultUser`' is stored in plaintext in the Registry, it's been analysed for strength.`r    The password is one of many well-known common passwords."
            #endregion
            #region write to eventlog
            Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
            #endregion
            #region update UDF
            $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
            #endregion
            #region write-host output for RMM jobs
            if ($DisplayOutput) {
                Write-Host $AlertMessage
                $script:varAlerts++
            }
            #endregion
        }
    }
    catch [System.Exception] {
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            $InfoMessage = "+ No account credentials are stored in the Registry."
            Write-Host $InfoMessage
        }
        #endregion
    }
    #endregion
    #region end of function
    #region write-host output for RMM jobs
    if ($DisplayOutput) {
        Write-Host $LineBreak $NewLine
    }
    #endregion
    #endregion
}

function Check-NetworkSecurityAudit {
    <# 
        .SYNOPSIS
             Function "Check-Network Security Audit"
        .DESCRIPTION
             This function will 

        .NOTES
        Version   	..: 1.1.1
        Created   	..: 11.11.2021
        Created by	..: Kenneth Jøleid-Skari, Marcello Consulting AS.

        Change log	..:
        12.11.2021 - 1.1.1 - replaced UsedForRmm_job with DisplayOutput
        11.11.2021 - 1.1.0 - Corrected "UsedForRmm_job" if checks
        22.03.2021 - 1.02  - added UDF update for Firewall Profiles
        .LINK
            https://support.microsoft.com/en-us/help/2696547/how-to-detect-enable-and-disable-smbv1-smbv2-and-smbv3-in-windows-and
    #>

    #region Variables for function
    $FunctionName = "Network Security Audit"
    #endregion

    #region write-host output for RMM jobs
    if ($DisplayOutput) {
        # sum total characters should be the same as for $LineBreak. By having same start and end, text will be line centrated.
        Write-Host "$($LineBreak[0..20] -join('')) ($FunctionName) $($LineBreak[0..20] -join(''))"
    }
    #endregion

    #region check: Datto RMM original - Restrict Null Session Access Value in Registry (shares that are accessible anonymously)
    #region eventID variable
    $EventID = "60301"
    $EventType = "Warning"
    $EventMessage = "Marcello RMM Security Audit Alert:`rAccess to anonymous shares is permitted and should be disabled.`rThe setting is stored in the Registry at HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters under value `'RestrictNullSessAccess`'."
            
    $AlertMessage = "- ALERT: Device does not restrict access to anonymous shares. This poses a security risk."
    $WarningMessage = "- WARNING: Unable to determine whether this device restricts access to anonymous shares."
    $InfoMessage = "+ Device restricts access to anonymous shares."
    #endregion
    try {
        $varNullSession = (Get-Itemproperty 'HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters').restrictnullsessaccess
        if ($varNullSession -ne 1) {
            #region write to eventlog
            Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
            #endregion
            #region update UDF
            $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
            #endregion
            #region write-host output for RMM jobs
            if ($DisplayOutput) {
                Write-Host $AlertMessage
                $script:varAlerts++
            }
            #endregion
        }
        else {
            #region write-host output for RMM jobs
            if ($DisplayOutput) {
                Write-Host $InfoMessage
            }
            #endregion
        }
    }
    catch [System.Exception] {
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host $WarningMessage
            $script:varWarnings++
        }
        #endregion
    }
    #endregion

    #region check: Datto RMM original - is telnet server enabled
    #region eventID variable            
    $EventID = "60302"
    $EventType = "Warning"
    $EventMessage = "Marcello RMM Security Audit Alert:`rTelnet Server is running and should be replaced by a more secure alternative."
            
    $AlertMessage = "- ALERT: Telnet Server is active."
    $InfoMessage = "+ Telnet Server is not installed."
    #endregion
    Get-Process tlntsvr -ErrorAction silentlycontinue | out-null
    if ($?) {
        #region write to eventlog
        Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
        #endregion
        #region update UDF
        $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
        #endregion
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host $AlertMessage
            $script:varAlerts++
        }
        #endregion
    }
    else {
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host $InfoMessage
        }
        #endregion
    }
    #endregion
    
    #region check: Marcello RMM adoption - is SMBv1 permitted?
    #region SMBv1 - registry
    #region eventID variable
    $EventID = "60303"
    $EventType = "Warning"
    $EventMessage = "Marcello RMM Security Audit Alert:`rDevice has the actively-exploited SMBv1 protocol enabled in registry.`rMicrosoft advisory: https://blogs.technet.microsoft.com/filecab/2016/09/16/stop-using-smb1/"
            
    $AlertMessage = "- ALERT: Device has the SMBv1 protocol enabled in registry."
    $InfoMessage = "+ Device has the SMBv1 protocol disabled in registry."
    #endregion
    $varSMBCheck = (Get-Itemproperty 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters').SMB1
    #edit default value of SMB to adopt to legacy OS (Pre 2019 Server)
    if ($varSMBCheck -like "") {
        if ($varKernel -lt 17763) {
            #OS probably has SMBv1 enabled by default
            $varSMBCheck = "1"
        }
        else {
            #OS probably has SMBv1 disabled by default
            $varSMBCheck = "0"
        }
    }
    if ($varSMBCheck -eq 1) {
        #region write to eventlog
        Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
        #endregion
        #region update UDF
        $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
        #endregion
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host $AlertMessage
            $script:varAlerts++
        }
        #endregion
    }
    else {
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host $InfoMessage
        }
        #endregion
    }
    #endregion
    #region SMBv1 - server
    #region eventID variable
    $EventID = "60304"
    $EventType = "Warning"
    $EventMessage = "Marcello RMM Security Audit Alert:`rDevice is configured as a server for the vulnerable and actively-exploited SMBv1 protocol.`rMicrosoft advisory: https://blogs.technet.microsoft.com/filecab/2016/09/16/stop-using-smb1/"

    $AlertMessage = "- ALERT: Device is configured as an SMBv1 server due to exposed SMBv1 on 'Server Service'."
    $InfoMessage = "+ Device is not configured as an SMBv1 server as SMBv1 is not exposed on 'Server Service'."
    #endregion
    $varServerSMB1 = (Get-Service lanmanserver).requiredservices | where-object { $_.DisplayName -match '1.xxx' }
    if ($varServerSMB1) {
        #region write to eventlog
        Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
        #endregion
        #region update UDF
        $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
        #endregion
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host $AlertMessage
            $script:varAlerts++
        }
        #endregion
    }
    else {
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host $InfoMessage
        }
        #endregion
    }
    #endregion
    #region SMBv1 - client
    #region eventID variable
    $EventID = "60305"
    $EventType = "Warning"
    $EventMessage = "Marcello RMM Security Audit Alert:`rDevice is configured as a client for the vulnerable and actively-exploited SMBv1 protocol.`rMicrosoft advisory: https://blogs.technet.microsoft.com/filecab/2016/09/16/stop-using-smb1/"
            
    $AlertMessage = "- ALERT: Device is configured as an SMBv1 client due to exposed SMBv1 on 'Workstation Service'."
    $InfoMessage = "+ Device is not configured as an SMBv1 client as SMBv1 is not exposed on 'Workstation Service'."
    #endregion
    $varClientSMB1 = (Get-Service lanmanworkstation).requiredservices | where-object { $_.DisplayName -match '1.x' }
    if ($varClientSMB1) {
        #region write to eventlog
        Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
        #endregion
        #region update UDF
        $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
        #endregion
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host $AlertMessage
            $script:varAlerts++
        }
        #endregion
    }
    else {
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host $InfoMessage
        }
        #endregion
    }
    #endregion
    #endregion

    #region check: Datto RMM original - windows firewall
    #region firewall status
    #region eventID variable
    $EventID = "60306"
    $EventType = "Warning"
    $EventMessage = "Marcello RMM Security Audit Alert:`rWindows Firewall is not running.`rIf this was unintentional, please revert the setting.`rIf this was intentional, please ensure the replacement solution is operational and configured."
            
    $AlertMessage = "- ALERT: Windows Firewall is not running."
    $InfoMessage = "+ Windows Firewall is running."
    #endregion
    if (((Get-WmiObject win32_service  -Filter "name like '%mpssvc%'").state) -match 'Running') {
        $varFirewallRunning = $true
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host $InfoMessage
        }
        #endregion
    }
    else {
        #region write to eventlog
        Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
        #endregion
        #region update UDF
        $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
        #endregion
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host $AlertMessage
            $script:varAlerts++
        }
        #endregion
    }
    #endregion
    #region firewall enabled for private networks?
    #region eventID variable
    $EventID = "60307"
    $EventType = "Warning"
    $EventMessage = "Marcello RMM Security Audit Alert:`rWindows Firewall is disabled for Private networks.`rIf this was unintentional, please revert the setting.`rIf this was intentional, please ensure the replacement solution is operational and configured."
            
    $AlertMessage = "- ALERT: Windows Firewall is disabled for Private networks."
    $WarningMessage = "- WARNING: 'Insert text here'"
    $InfoMessage = "+ Windows Firewall is enabled for Private networks."
    #endregion
    try {
        $varSMBCheck = (Get-Itemproperty 'HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile').EnableFirewall
        if ($varSMBCheck -ne 1) {
            #region write to eventlog
            Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
            #endregion
            #region update UDF
            $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
            #endregion
            #region write-host output for RMM jobs
            if ($DisplayOutput) {
                Write-Host $AlertMessage
                $script:varAlerts++
            }
            #endregion
        }
        else {
            #region write-host output for RMM jobs
            if ($DisplayOutput) {
                Write-Host $InfoMessage
            }
            #endregion
        }
    }
    catch [System.Exception] {
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host "- ALERT: Unable to ascertain Windows Firewall state for Private networks."
            $script:varAlerts++
        }
        #endregion
    }
    #endregion
    #region firewall enabled for public networks?
    #region eventID variable
    $EventID = "60308"
    $EventType = "Warning"
    $EventMessage = "Marcello RMM Security Audit Alert:`rWindows Firewall is disabled for Public networks.`rIf this was unintentional, please revert the setting.`rIf this was intentional, please ensure the replacement solution is operational and configured."
            
    $AlertMessage = "- ALERT: Windows Firewall is disabled for Public networks."
    $WarningMessage = "- WARNING: 'Insert text here'"
    $InfoMessage = "+ Windows Firewall is enabled for Public networks."
    #endregion
    try {
        $varSMBCheck = (Get-Itemproperty 'HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\PublicProfile').EnableFirewall
        if ($varSMBCheck -ne 1) {
            #region write to eventlog
            Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
            #endregion
            #region update UDF
            $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
            #endregion
            #region write-host output for RMM jobs
            if ($DisplayOutput) {
                Write-Host $AlertMessage
                $script:varAlerts++
            }
            #endregion
        }
        else {
            #region write-host output for RMM jobs
            if ($DisplayOutput) {
                Write-Host $InfoMessage
            }
            #endregion 
        }
    }
    catch [System.Exception] {
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host "- ALERT: Unable to ascertain Windows Firewall state for Public networks."
            $script:varAlerts++
        }
        #endregion
    }
    #endregion
    #region firewall is enabled when connected to a domain?
    #region eventID variable
    $EventID = "60309"
    $EventType = "Warning"
    $EventMessage = "Marcello RMM Security Audit Alert:`rWindows Firewall is disabled for Domain networks.`rIf this was unintentional, please revert the setting.`rIf this was intentional, please ensure the replacement solution is operational and configured."
            
    $AlertMessage = "- ALERT: Windows Firewall is disabled for Domain networks."
    $WarningMessage = "- WARNING: 'Insert text here'"
    $InfoMessage = "+ Windows Firewall is enabled for Domain networks."
    #endregion
    if ((Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain) {
        try {
            $varSMBCheck = (Get-Itemproperty 'HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile').EnableFirewall
            if ($varSMBCheck -ne 1) {
                #region write to eventlog
                Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
                #endregion
                #region update UDF
                $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
                #endregion                        
                #region write-host output for RMM jobs
                if ($DisplayOutput) {
                    Write-Host $AlertMessage
                    $script:varAlerts++
                }
                #endregion
            }
            else {
                #region write-host output for RMM jobs
                if ($DisplayOutput) {
                    Write-Host $InfoMessage
                }
                #endregion 
            }
        }
        catch [System.Exception] {
            #region write-host output for RMM jobs
            if ($DisplayOutput) {
                Write-Host "- ALERT: Unable to ascertain Windows Firewall state for Domain networks."
                $script:varAlerts++
            }
            #endregion
        }
    }
    else {
        # Device is not part of a domain; checks for domain-level firewall compliance skipped."
    }
    #endregion
    #region firewall show active profiles. this will read strangely but it's the only way to do it without butchering the i18n
    #region eventID variable
    $EventID = "60310"
    $EventType = "Warning"
    $EventMessage = "Marcello RMM Security Audit Alert:`rUnable to detect active Windows Firewall Profile as Windows Firewall is not running."
            
    $AlertMessage = "- ALERT: Unable to detect active Windows Firewall Profile as Windows Firewall is not running."
    $WarningMessage = "- WARNING: 'Insert text here'"
    $InfoMessage = "+ Windows Firewall Profile detected successfully."
    #endregion
    if ($varFirewallRunning) {
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host $InfoMessage
            foreach ($iteration in (netsh advfirewall show currentprofile | select-string ":" | select-string " ")) {
                $varActiveProfile = $iteration -as [string]
                Write-Host "   "$varActiveProfile.substring(0, $varActiveProfile.Length - 2)
            }
        }
        #endregion
    }
    else {
        #region write to eventlog
        Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
        #endregion
        #region update UDF
        $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
        #endregion
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host $AlertMessage
            $script:varAlerts++
        }
        #endregion
    }
    #endregion
    #endregion

    #region check: Datto RMM original - teamviewer
    #region eventID variable
    $EventID = "60311"
    $EventType = "Warning"
    $EventMessage = "Marcello RMM Security Audit Alert:`rTeamViewer detected on this device."
            
    $InfoMessage = "+ TeamViewer not detected on this device."
    #endregion
    Get-ChildItem "C:\Users" | ? { $_.PSIsContainer } | % { 
        if (Test-Path "C:\Users\$_\AppData\Roaming\TeamViewer\Connections.txt") {
            $WarningMessage = "- WARNING: TeamViewer detected on this device.$NewLine    User `'$_`' has used TeamViewer software."
            $varTeamViewer = $true
            #region write to eventlog
            Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
            #endregion
            #region update UDF
            $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
            #endregion
            #region write-host output for RMM jobs
            if ($DisplayOutput) {
                Write-Host $WarningMessage
                $script:varWarnings++
            }
            #endregion
        }
    }
    if (!$varTeamViewer) {
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host $InfoMessage
        }
        #endregion
    }
    #endregion
    
    #region end of function
    #region write-host output for RMM jobs
    if ($DisplayOutput) {
        Write-Host $LineBreak $NewLine
    }
    #endregion
    #endregion
}

function Check-DeviceSecurityAudit {
    <# 
        .SYNOPSIS
        Function "Check-DeviceSecurityAudit"
        .DESCRIPTION
        This function will 

        .NOTES
        Version   	..: 1.1.1
        Created   	..: 11.11.2021
        Created by	..: Kenneth Jøleid-Skari, Marcello Consulting AS.

        Change log	..:
        12.11.2021 - 1.1.1 - replaced UsedForRmm_job with DisplayOutput
        11.11.2021 - 1.1.0 - Corrected "UsedForRmm_job" if checks
        .LINK
            https://docs.microsoft.com/en-us/windows/security/threat-protection/microsoft-defender-atp/enable-exploit-protection
    #>

    #region Variables for function
    $FunctionName = "Device Security Audit"
    #endregion
    #region write-host output for RMM jobs
    if ($DisplayOutput) {
        # sum total characters should be the same as for $LineBreak. By having same start and end, text will be line centrated.
        Write-Host "$($LineBreak[0..20] -join('')) ($FunctionName) $($LineBreak[0..21] -join(''))"
    }
    #endregion
    #region check: Datto RMM original - device security audit
    #region uefi secure boot
    #region eventID variable
    $EventID = "60401"
    $EventType = "Warning"
    $EventMessage = "Marcello RMM Security Audit Alert:`rUEFI Secure Boot is supported on this device but has not been enabled.`rThis may have been configured deliberately to facilitate installation of other Operating Systems that do not have a Microsoft Secure Boot shim available; however, the setting still leaves a device vulnerable and should be changed."

    $AlertMessage = "- ALERT: UEFI Secure Boot is supported but not enabled on this device."
    $WarningMessage = "- WARNING: UEFI Secure Boot is not supported on this device."
    $InfoMessage = "+ UEFI Secure Boot is supported and enabled on this device."
    #endregion
    if ($varKernel -ge 9200) {
        try {
            $varSecureBoot = Confirm-SecureBootUEFI
            if ($varSecureBoot) {
                #region write-host output for RMM jobs
                if ($DisplayOutput) {
                    Write-Host $InfoMessage
                }
                #endregion
            }
            else {
                #region write to eventlog
                Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
                #endregion
                #region update UDF
                $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
                #endregion
                #region write-host output for RMM jobs
                if ($DisplayOutput) {
                    Write-Host $AlertMessage
                    $script:varAlerts++
                }
                #endregion
            }
        }
        catch [PlatformNotSupportedException] {
            #region write-host output for RMM jobs
            if ($DisplayOutput) {
                Write-Host $WarningMessage
                Write-Host "    The device may use the legacy BIOS platform instead of UEFI or it may be a virtual machine."
                $script:varWarnings++
            }
            #endregion
        }
    }
    else {
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host $WarningMessage
            Write-Host "    UEFI Secure Boot is not supported on Windows 7."
            $script:varWarnings++
        }
        #endregion
    }
    #endregion
    #region Exploit Protection settings
    #region eventID variable
    $EventID = "60402"
    $EventType = "Warning"
    $EventMessage = "Marcello RMM Security Audit Alert:`rWindows 10 Exploit Protection settings have been altered from the default.`rThis is generally done deliberately by the end-user or administrator in order to mitigate against a specific compatibility or performance issue.`rRegardless, it is bad practice to deviate from Microsoft's standards.`rPlease scrutinise the mitigation steps below and ensure you have a strong justification for dismissing each.`r$varExploitFlaws"
                
    $AlertMessage = "- ALERT: System Exploit Protection configuration differs from Windows 10 Exploit Protection Settings."
    $WarningMessage = "- WARNING: Windows 10 Exploit Protection is only available from Windows 10 build 1709 onward."
    $InfoMessage = "+ Main Windows 10 Exploit Protection Settings have not been altered from default recommendations."
    #endregion
    if ($varKernel -ge 16299) {
        $varExploitProtection = Get-ProcessMitigation -System
        if ($varExploitProtection.DEP.Enable -match 'OFF') { $varExploitFlaws += "Enable DEP / " }
        if ($varExploitProtection.CFG.Enable -match 'OFF') { $varExploitFlaws += "Enable Control Flow Guard / " }
        if ($varExploitProtection.ASLR.BottomUp -match 'OFF') { $varExploitFlaws += "Enable Bottom-up ASLR / " }
        if ($varExploitProtection.ASLR.HighEntropy -match 'OFF') { $varExploitFlaws += "Enable High-Entropy ASLR / " }
        if ($varExploitProtection.SEHOP.Enable -match 'OFF') { $varExploitFlaws += "Enable Exception Chain Validation (SEHOP) / " }
        if ($varExploitProtection.Heap.TerminateOnError -match 'OFF') { $varExploitFlaws += "Enable Heap Integrity Validation" }
        if ($varExploitFlaws) {
            #region write to eventlog
            Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
            #endregion
            #region update UDF
            $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
            #endregion
            #region write-host output for RMM jobs
            if ($DisplayOutput) {
                Write-Host $AlertMessage
                $script:varAlerts++
            }
            #endregion
        }
        else {
            #region write-host output for RMM jobs
            if ($DisplayOutput) {
                Write-Host $InfoMessage
            }
            #endregion
        }
    }
    else {
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host $WarningMessage
            $script:varWarnings++
        }
        #endregion
    }
    #endregion
    #endregion
    #region check: Datto RMM original - security policy
    #region is there a security policy
    #region eventID variable
    $EventID = "60403"
    $EventType = "Warning"
    $EventMessage = "Marcello RMM Security Audit Alert:`rThe Windows Security Policy is not configured to block files with dangerous extensions from executing.`rThese file types are: $varFileRisks`.`rIn addition, the right-to-left unicode character should also be blocked to mitigate against extension masquerade attacks.`rMore information: https://www.ipa.go.jp/security/english/virus/press/201110/E_PR201110.html"

    $AlertMessage = "- ALERT: The Windows Security Policy is not configured to block files with dangerous extensions from executing."
    $WarningMessage = "- WARNING: 'Insert text here'"
    $InfoMessage = "+ The Windows Security Policy is configured to block files with dangerous extensions from executing."
    #endregion
    [array]$arrSecurityPolicies = @()
    try {
        Get-ChildItem -Recurse 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Safer\codeidentifiers\0\Paths' | % {
            [array]$arrSecurityPolicies += (Get-ItemProperty registry::$_).ItemData
        }
    }
    catch [System.Exception] {
        $varNoSecPols = $true
        #region write to eventlog
        Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
        #endregion
        #region update UDF
        $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
        #endregion
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host $AlertMessage
            $script:varAlerts++
        }
        #endregion
    }
    if (!$varNoSecPols) {
        if ($arrSecurityPolicies -match '.VBS') {
            #do nothing
        }
        else {
            $varFileRisks += "VBS, "
        }
        if ($arrSecurityPolicies -match '.CPL') {
            #do nothing
        }
        else {
            $varFileRisks += "CPL, "
        }
        if ($arrSecurityPolicies -match '.SCR') {
            #do nothing
        }
        else {
            $varFileRisks += "SCR, "
        }
        if ($arrSecurityPolicies -match "\u202E") {
            #do nothing
        }
        else {
            $varFileRisks += "Right-to-Left override"
        }
    }
    #endregion
    #region is there any file type risks
    #region eventID variable
    $EventID = "60404"
    $EventType = "Warning"
    $EventMessage = "Marcello RMM Security Audit Alert:`rThe Windows Security Policy is not configured to block files with dangerous extensions from executing.`rThese file types are: $varFileRisks`.`rIn addition, the right-to-left unicode character should also be blocked to mitigate against extension masquerade attacks.`rMore information: https://www.ipa.go.jp/security/english/virus/press/201110/E_PR201110.html"

    $AlertMessage = "- ALERT: The Windows Security Policy does not prohibit execution of problematic file types (https://goo.gl/P6ec8q)."
    $WarningMessage = "- WARNING: 'Insert text here'"
    $InfoMessage = "+ The Windows Security Policy prohibits execution of problematic file types (https://goo.gl/P6ec8q)."
    #endregion
    if ($varFileRisks) {
        #region write to eventlog
        Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
        #endregion
        #region update UDF
        $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
        #endregion
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host $AlertMessage
            $script:varAlerts++
        }
        #endregion
    }
    #endregion
    #endregion
    #region check: Marcello RMM adoption - check OS patch status
    try {
        #region check if Windows Update Last Months CU is installed
        $WULastMonthDate = (Get-Date).AddMonths(-1).ToString("yyyy-MM")
        $WuThisMonthDate = (Get-Date).ToString("yyyy-MM")
        $WUListInstalled = Get-WUList -IsInstalled -ErrorAction Stop
        $WUList = Get-WUList -ErrorAction Stop
        $WULastMonth = $WUListInstalled | where { $_.title -like "$WULastMonthDate cumulative update for windows*" -OR $_.title -like "$WULastMonthDate samlet oppdatering for Windows*" -OR $_.Title -like "$WULastMonthDate security monthly quality rollup*" }
        $WUThistMonth = $WUListInstalled | where { $_.title -like "$WuThisMonthDate cumulative update for windows*" -OR $_.title -like "$WuThisMonthDate samlet oppdatering for Windows*" -OR $_.Title -like "$WuThisMonthDate security monthly quality rollup*" }
        $WUFeatureUpdate = $WUList | where { $_.title -like "Feature update to Windows 10* version*" -OR $_.title -like "Funksjonsoppdatering for Windows 10* versjon*" }
        if ($WULastMonth -eq $null) {
            if (!($WUThistMonth -eq $null)) {
                # Do nothing as healt is OK
                $InfoMessage = "+ Windows Update status is GOOD. Cumulative or Quality updates for this month has been applied."
                #region write-host output for RMM jobs
                if ($DisplayOutput) {
                    Write-Host $InfoMessage
                }
                #endregion
            }
            else {
                if ($WUFeatureUpdate) {
                    #region eventID variable
                    $EventID = "60405"
                    $EventType = "Warning"
                    $EventMessage = "Marcello RMM Security Audit Alert:`rWindows Update Feature Update is required - no more Cumulative or Quality rollups will be installed`rThis should be remediated ASAP as this means that the device will no longer receive security updates."
            
                    $AlertMessage = "- ALERT: Windows Update Feature Update is required. No more Cumulative or Quality rollups will be installed."
                    $WarningMessage = "- WARNING: Windows Update Feature Update is required. No more Cumulative or Quality rollups will be installed."
                    #endregion
                    #region write to eventlog
                    Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
                    #endregion
                    #region update UDF
                    $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
                    #endregion
                    #region write-host output for RMM jobs
                    if ($DisplayOutput) {
                        Write-Host $AlertMessage
                        $script:varAlerts++
                    }
                    #endregion
                }
                else {
                    #region eventID variable
                    $EventID = "60406"
                    $EventType = "Warning"
                    $EventMessage = "Marcello RMM Security Audit Alert:`rNo Cumulative or Quality rollup applied for this month ($WuThisMonthDate) or last month ($WULastMonthDate)`rThis should be remediated ASAP as this means that the device probably have missed one or multiple maintenance windows, or other root problems prevents installation of updates"
            
                    $AlertMessage = "- ALERT: No Cumulative or Quality rollup applied for this month ($WuThisMonthDate) or last month ($WULastMonthDate)."
                    $WarningMessage = "- WARNING: No Cumulative or Quality rollup applied for this month ($WuThisMonthDate) or last month ($WULastMonthDate)."
                    $InfoMessage = "+ Cumulative or Quality rollup applied for this month ($WuThisMonthDate) or last month ($WULastMonthDate)."
                    #endregion
                    #region write to eventlog
                    Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
                    #endregion
                    #region update UDF
                    $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
                    #endregion
                    #region write-host output for RMM jobs
                    if ($DisplayOutput) {
                        Write-Host $AlertMessage
                        $script:varAlerts++
                    }
                    #endregion
                }
            }
        }
        else {
            # Do nothing as health is OK
            #region write-host output for RMM jobs
            if ($DisplayOutput) {
                Write-Host "- WARNING: Windows Update status is OK. Cumulative or Quality updates for last month has been applied."
                Write-Host "    We do not calculate maintenance window so no need to panic when `'last month`' patches is installed."
                Write-Host "    Patches are relased from Microsoft the second Tuesday each month."
                $script:varWarnings++
            }
            #endregion
        }
        #endregion
    }
    catch [System.Exception] {
        #region eventID variable
        $EventID = "60407"
        $EventType = "Warning"
        $EventMessage = "Marcello RMM Security Audit Alert:`rUnable to perform check against Windows Update`rThis should be remediated ASAP.`rMake sure that PSWindowsUpdate module is installed and working, and that the device is able to reach Windows Update."
            
        $AlertMessage = "- ALERT: Unable to perform check against Windows Update. Is PSWindowsUpdate module installed and can the device can reach Windows Update?"
        $WarningMessage = "- WARNING: 'Insert text here'"
        $InfoMessage = "+ 'Insert text here'"
        #endregion
        #region write to eventlog
        Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
        #endregion
        #region update UDF
        $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
        #endregion
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host $AlertMessage
            $script:varAlerts++
        }
        #endregion
    }
    #endregion
    
    #region check: Marcello RMM adoption - check for Print Spooler Service
    #region eventID variable
    $EventID = "60408"
    $EventType = "Warning"
    $EventMessage = "Marcello RMM Security Audit Alert:`rPrint Spooler is enabled on a device that should not need it. Print Spooler Service should be disabled."
    $AlertMessage = "- ALERT: Print Spooler is enabled on a device that should not need it. Print Spooler Service should be disabled."
    $WarningMessage = "- WARNING: Print Spooler is probably in use, as this is either a WorkStation, RDS or Print Server - considure alternative actions for remediation"
    $InfoMessage = "+ Print Spooler Service is configured according to recommendations"
    #endregion
    #check spooler service
    $ServiceStartMode = Get-WMIObject win32_service -filter "name='Spooler'" -computer "." | select -expand startMode
    if ($ServiceStartMode) {
        $ServiceStatus = (Get-Service spooler).Status
        <#
            check if remote inbound print is Stopped - if so, change status to "Stopped"
            https://msrc.microsoft.com/update-guide/vulnerability/CVE-2021-34527
        #>
        if ($ServiceStatus -eq "Running") {
            $query = Get-ItemProperty -Path Registry::"HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" -Name "RegisterSpoolerRemoteRpcEndPoint" -ErrorAction SilentlyContinue
            $result = $query.RegisterSpoolerRemoteRpcEndPoint
            if ($result -eq "2") {
                #will override values as this is a supported workaround for remediation of print nightmare
                $ServiceStartMode = "Disabled"
                $ServiceStatus = "Stopped"
                $InfoMessage += " as workaround has been applied"
            }
        }
    }
    else {
        #service does not exist, will manually set value
        $ServiceStartMode = "Disabled"
        $ServiceStatus = "Stopped"
    }
    <#
        determine if this is a workstation or server
        https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-operatingsystem 
    #>
    $osInfo = Get-WmiObject -Class Win32_OperatingSystem
    if (!($osInfo.ProductType -eq "1")) {
        #this is a server OS
        try {
            $InstalledServerRoles = Get-WindowsFeature | where { $_.Installed }
        }
        catch [System.Exception] {
            if (!($InstalledServerRoles)) {
                #failed to detect server roles, probably due to unsupported OS
                #region write-host output for RMM jobs
                if ($DisplayOutput) {
                    $WarningMessage = "- WARNING: Failed to detect any installed server roles. This is probably due to operating system being unsupported"
                    Write-Host $WarningMessage
                    $script:varWarnings++
                }
                #endregion
            }
        }
        if ($InstalledServerRoles.Name -like "RDS-RD-Server" -or $InstalledServerRoles.Name -like "Print-Server") {
            if ($ServiceStartMode -like "Disabled" -and $ServiceStatus -like "Stopped") {
                #region write-host output for RMM jobs
                if ($DisplayOutput) {
                    Write-Host $InfoMessage
                }
                #endregion
            }
            else {
                #region write-host output for RMM jobs
                if ($DisplayOutput) {
                    Write-Host $WarningMessage
                    $script:varWarnings++
                }
                #endregion
                #region query EventLog
                $LogName = 'Microsoft-Windows-PrintService/Operational'
                $EventLogXML = wevtutil.exe gl $LogName /format:XML
                $EventLogStatus = ([xml]$EventLogXML).channel.enabled
                #region eventID variable
                $EventID = "60409"
                $EventType = "Warning"
                $EventMessage = "Marcello RMM Security Audit Alert:`rEvent logging of Spooler is not enabled. This should be enabled to track malicious usage of Spooler service."
                $AlertMessage = "- ALERT: Event logging of Spooler is not enabled. This should be enabled to track malicious usage of Spooler service."
                $WarningMessage = "- WARNING: "
                $InfoMessage = "+ Print Spooler Event logging is enabled according to recommendations"
                #endregion
                if ($EventLogStatus -eq "False") {
                    #region write to eventlog
                    Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
                    #endregion
                    #region update UDF
                    $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
                    #endregion
                    #region write-host output for RMM jobs
                    if ($DisplayOutput) {
                        Write-Host $AlertMessage
                        $script:varAlerts++
                    }
                    #endregion
                }
                else {
                    #region write-host output for RMM jobs
                    if ($DisplayOutput) {
                        Write-Host $InfoMessage
                    }
                    #endregion  
                }
                #endregion
            }
        }
        else {
            #disable spooler
            if ($ServiceStartMode -like "Disabled" -and $ServiceStatus -like "Stopped") {
                #region write-host output for RMM jobs
                if ($DisplayOutput) {
                    Write-Host $InfoMessage
                }
                #endregion
            }
            else {
                #region write to eventlog
                Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
                #endregion
                #region update UDF
                $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
                #endregion
                #region write-host output for RMM jobs
                if ($DisplayOutput) {
                    Write-Host $AlertMessage
                    $script:varAlerts++
                }
                #endregion
            }
        }
    }
    else {
        #this is not a server OS
        if ($ServiceStartMode -like "Disabled" -and $ServiceStatus -like "Stopped") {
            #region write-host output for RMM jobs
            if ($DisplayOutput) {
                Write-Host $InfoMessage
            }
            #endregion
        }
        else {
            #region write-host output for RMM jobs
            if ($DisplayOutput) {
                Write-Host $WarningMessage
                $script:varWarnings++
            }
            #endregion
            #region query EventLog
            $LogName = 'Microsoft-Windows-PrintService/Operational'
            $EventLogXML = wevtutil.exe gl $LogName /format:XML
            $EventLogStatus = ([xml]$EventLogXML).channel.enabled
            #region eventID variable
            $EventID = "60409"
            $EventType = "Warning"
            $EventMessage = "Marcello RMM Security Audit Alert:`rEvent logging of Spooler is not enabled. This should be enabled to track malicious usage of Spooler service."
            $AlertMessage = "- ALERT: Event logging of Spooler is not enabled. This should be enabled to track malicious usage of Spooler service."
            $WarningMessage = "- WARNING: "
            $InfoMessage = "+ Print Spooler Event logging is enabled according to recommendations"
            #endregion
            if ($EventLogStatus -eq "False") {
                #region write to eventlog
                Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
                #endregion
                #region update UDF
                $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
                #endregion
                #region write-host output for RMM jobs
                if ($DisplayOutput) {
                    Write-Host $AlertMessage
                    $script:varAlerts++
                }
                #endregion
            }
            else {
                #region write-host output for RMM jobs
                if ($DisplayOutput) {
                    Write-Host $InfoMessage
                }
                #endregion  
            }
            #endregion
        }
    }
    #endregion
    
    #region end of function
    #region write-host output for RMM jobs
    if ($DisplayOutput) {
        Write-Host $LineBreak $NewLine
    }
    #endregion
    #endregion
}

function Check-SecurityBaseline {
    <# 
        .SYNOPSIS
             Function "Check-SecurityBaseline"
        .DESCRIPTION
             This function will 

        .NOTES
        Version   	..: 1.1.2
        Created   	..: 11.11.2021
        Created by	..: Kenneth Jøleid-Skari, Marcello Consulting AS.

        Change log	..:
        12.11.2021 - 1.1.2 - replaced UsedForRmm_job with DisplayOutput
        11.11.2021 - 1.1.1 - Corrected "UsedForRmm_job" if checks
                      1.06 - stopped the routine from running on unsupported OS (Windows 7)
        Comments    ..:
                    Report score card
                    Score	Rating Casual	Rating Professional
                    6	Excellent	Excellent
                    5	Well done	Good
                    4	Sufficient	Sufficient
                    3	You should do better	Insufficient
                    2	Weak	Insufficient
                    1	Bogus	Insufficient
                Edit the variable $FileFindingList to use other or multiple list for measurements of score

        .LINK
            https://www.scip.ch/en/?labs.20201015
            https://github.com/scipag/HardeningKitty
            https://docs.microsoft.com/en-us/sysinternals/downloads/accesschk
        
    #>

    #region Variables for function
    $FunctionName = "Check-SecurityBaseline"
    $Hostname = $env:COMPUTERNAME.ToLower()
    $FileDate = Get-Date -Format yyyyMMdd-HHmm
    $OSVersionRegistry = "REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    $OSVersion = Get-ItemProperty $OSVersionRegistry
    #endregion
    
    #region write-host output for RMM jobs
    if ($DisplayOutput) {
        # sum total characters should be the same as for $LineBreak. By having same start and end, text will be line centrated.
        #$TestOutPut = "$($LineBreak[0..20] -join('')) ($FunctionName) $($LineBreak[0..20] -join(''))"
        Write-Host "$($LineBreak[0..20] -join('')) ($FunctionName) $($LineBreak[0..20] -join(''))"
    }
    #endregion

    #region terminate if RmmCapable is false
    if (!($RmmCapable)) {
        #region eventID variable
        $EventID = "60505"
        $EventType = "Information"
        $EventMessage = "Marcello RMM Security Audit Alert:`rHardening Score has not been measured as this component has not been executed from an RMM Capable platform"
        #endregion
        #region write to eventlog
        Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
        #endregion
        #region update UDF
        $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
        #endregion
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            $AlertMessage = "- ALERT: Hardening Score has not been measured as this component has not been executed from an RMM Capable platform"
            Write-Host $AlertMessage
            $script:varAlerts++
        }
        #endregion
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host $LineBreak $NewLine
        }
        #endregion
        #terminate function
        return
    }
    #endregion    
    
    #region terminate if OS is unsupported
    if ($OSVersion.CurrentVersion -lt "6.2") {
        #region eventID variable
        $EventID = "60504"
        $EventType = "Warning"
        $EventMessage = "Marcello RMM Security Audit Alert:`rHardening Score has not been measured as this is an unsupported OS"
        #endregion
        #region write to eventlog
        Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
        #endregion
        #region update UDF
        $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
        #endregion
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            $AlertMessage = "- ALERT: Hardening Score has not been measured as this is an unsupported OS"
            Write-Host $AlertMessage
            $script:varAlerts++
        }
        #endregion
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host $LineBreak $NewLine
        }
        #endregion
        #terminate function
        return
    }
    #endregion

    #region Staging of Files and Folders
    $TempFolder = "$env:windir\temp\Marcello RMM Security Audit\$FunctionName"
    if (Test-Path "$TempFolder") {
        Remove-Item -Path $TempFolder -Recurse
    }
    New-Item -Path "$TempFolder" -ItemType Directory -Force | Out-Null
    if (!(Test-Path "HardeningKitty.zip")) {
        # Extract HardeningKitty SourceFiles
        Extract-ZipFileToFolder "$PSScriptRoot\HardeningKitty.zip" "$TempFolder\HardeningKitty"
        # Extract Requirements
        Extract-ZipFileToFolder "$PSScriptRoot\AccessChk.zip" "$TempFolder\SysInternals"
    }
    else {
        # Extract HardeningKitty SourceFiles
        Extract-ZipFileToFolder "$PSScriptRoot\HardeningKitty.zip" "$TempFolder\HardeningKitty"
        # Extract Requirements
        Extract-ZipFileToFolder "$PSScriptRoot\AccessChk.zip" "$TempFolder\SysInternals"
    }
    #endregion
    
    #temp start
    $HardeningKittyReportFileHeader = "$TempFolder\report_$Hostname-$FileDate"
    $HardeningKittyLogFileHeader = "$TempFolder\log_$Hostname-$FileDate"
    
    #region write-host output for RMM jobs
    if ($DisplayOutput) {
        $InfoMessage = "+ Output from HardeningKitty has been removed.`r`n    (If needed, check log file(s) at $TempFolder)"
        Write-Host $InfoMessage
    }
    #endregion
    
    #region initiate hardening kitty check
    Import-Module "$TempFolder\HardeningKitty\Invoke-HardeningKitty.ps1"

    if ($OSVersion.InstallationType -like "*Client*") {
        $AuditListsWorkstation = @{
            KittyProject = "$TempFolder\HardeningKitty\lists\finding_list_0x6d69636b_machine.csv" # Personal Prefrence List from HardeningKittyProject
            CIS          = "$TempFolder\HardeningKitty\lists\finding_list_cis_microsoft_windows_10_enterprise_machine.csv" # CIS - CenterForInternetSecurity
            MSFT         = "$TempFolder\HardeningKitty\lists\finding_list_msft_security_baseline_windows_10_2009_machine.csv" # MSFT is Microsoft Security Baseline
        }
        foreach ($List in $AuditListsWorkstation.Keys) {
            #Write-Host "${list}: $($AuditListsWorkstation.Item($List))"
            Invoke-HardeningKitty -BinaryAccesschk "$TempFolder\SysInternals\accesschk.exe" -Mode Audit -FileFindingList $($AuditListsWorkstation.Item($List)) -Report -ReportFile "$HardeningKittyReportFileHeader`_$List.csv" -Log -LogFile "$HardeningKittyLogFileHeader`_$List.log" > $null 6> $null
            $HardeningScore = (Get-Content "$HardeningKittyLogFileHeader`_$List.log" -Tail 1 ) -match '(Your HardeningKitty score is: )(\d{0,2}\.*\d{1,2})'
            $HardeningScore = ($matches[2]).Trim()
            if ($HardeningScore -lt "4") {
                #region write-host output for RMM jobs
                if ($DisplayOutput) {
                    $AlertMessage = "- ALERT: Hardening Score for verification list:`'$list`' is $HardeningScore. This is less than min. recommended value of 4"
                    Write-Host $AlertMessage
                    $script:varAlerts++
                }
                #endregion
                #region eventID variable
                if ($list -like "MSFT") { $EventID = "60501" }
                if ($list -like "CIS") { $EventID = "60502" }
                if ($list -like "KittyProject") { $EventID = "60503" }
                $EventType = "Warning"
                $EventMessage = "Marcello RMM Security Audit Alert:`rHardening Score for verification list:`'$list`' is $HardeningScore. This is less than min. recommended value of 4.`rRecommended plan of action is to reapply the corresponding Microsoft Security Baseline, re-run the audit and plan on further remediation steps"
                #endregion                        
                #region write to eventlog
                Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
                #endregion
                #region update UDF
                $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
                #endregion
            }
            else {
                #region write-host output for RMM jobs
                if ($DisplayOutput) {
                    $InfoMessage = "+ Hardening Score for verification list:`'$list`' is $HardeningScore. This is higher than min. recommended value of 4, where 6 is max. score"
                    Write-Host $InfoMessage
                }
                #endregion
            }
        }
        
    }
    if ($OSVersion.InstallationType -like "*Server*") {
        $AuditListsServer = @{
            KittyProject = "$TempFolder\HardeningKitty\lists\finding_list_0x6d69636b_machine.csv" # Personal Prefrence List from HardeningKittyProject
            CIS          = "$TempFolder\HardeningKitty\lists\finding_list_cis_microsoft_windows_server_2019_machine.csv" # CIS - CenterForInternetSecurity
            MSFT         = "$TempFolder\HardeningKitty\lists\finding_list_msft_security_baseline_windows_server_2009_member_machine.csv" # MSFT is Microsoft Security Baseline
        }
        foreach ($List in $AuditListsServer.Keys) {
            #Write-Host "${list}: $($AuditListsServer.Item($List))"
            Invoke-HardeningKitty -BinaryAccesschk "$TempFolder\SysInternals\accesschk.exe" -Mode Audit -FileFindingList $($AuditListsServer.Item($List)) -Report -ReportFile "$HardeningKittyReportFileHeader`_$List.csv" -Log -LogFile "$HardeningKittyLogFileHeader`_$List.log" > $null 6> $null
            $HardeningScore = (Get-Content "$HardeningKittyLogFileHeader`_$List.log" -Tail 1 ) -match '(Your HardeningKitty score is: )(\d{0,2}\.*\d{1,2})'
            $HardeningScore = ($matches[2]).Trim()
            if ($HardeningScore -lt "4") {
                #region write-host output for RMM jobs
                if ($DisplayOutput) {
                    $AlertMessage = "- ALERT: Hardening Score for verification list:`'$list`' is $HardeningScore. This is less than min. recommended value of 4"
                    Write-Host $AlertMessage
                    $script:varAlerts++
                }
                #endregion
                #region eventID variable
                if ($list -like "MSFT") { $EventID = "60501" }
                if ($list -like "CIS") { $EventID = "60502" }
                if ($list -like "KittyProject") { $EventID = "60503" }
                $EventType = "Warning"
                $EventMessage = "Marcello RMM Security Audit Alert:`rHardening Score for verification list:`'$list`' is $HardeningScore. This is less than min. recommended value of 4.`rRecommended plan of action is to reapply the corresponding Microsoft Security Baseline, re-run the audit and plan on further remediation steps"
                #endregion                        
                #region write to eventlog
                Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
                #endregion
                #region update UDF
                $script:EventIDsLogging = $script:EventIDsLogging + $EventID + ","
                #endregion
            }
            else {
                #region write-host output for RMM jobs
                if ($DisplayOutput) {
                    $InfoMessage = "+ Hardening Score for verification list:`'$list`' is $HardeningScore. This is higher than min. recommended value of 4, where 6 is max. score"
                    Write-Host $InfoMessage
                }
                #endregion
            }
        }
    }
    #endregion

    #region end of function
    #region write-host output for RMM jobs
    if ($DisplayOutput) {
        Write-Host $LineBreak $NewLine
    }
    #endregion
    #endregion
}

function Extract-ZipFileToFolder {
    <# .SYNOPSIS
        
    .DESCRIPTION
        Extract Zip file to folder by use of .NET - requires version 4.5
            - https://docs.microsoft.com/en-us/dotnet/api/system.io.compression.zipfile?view=netframework-4.7.2
            - no option for overwrite files
            - added removal of existing files that extract files will try to perform
            - added check to write the last exitcode if PsAppDeployToolkit failes

    .NOTES
        Author     : Kenneth Jøleid-Skari
        Date       : 17.06.2019
    .LINK
        https://www.marcello.no
    #>

    param( 
        [string]$SourceZip, 
        [string]$DestinationFolder
    )

    Add-Type -Path "C:\Windows\Microsoft.Net\assembly\GAC_MSIL\System.IO.Compression.FileSystem\v4.0_4.0.0.0__b77a5c561934e089\System.IO.Compression.FileSystem.dll"
    [System.IO.Compression.ZipFile]::ExtractToDirectory($SourceZip, $DestinationFolder)
}

function Set-DattoRMMudf {
    <# .SYNOPSIS
         Function "Set-DattoRMMudf"
    .DESCRIPTION
         This Function is intended to write any variable to a Datto RMM udf field

    .NOTES
         Author     : Kenneth Jøleid-Skari
         Date       : 11.05.2019
    .LINK
         https://www.marcello.no
    #>
    [CmdletBinding()]
    param(
        [parameter(position = 0)]
        [decimal]$UdfNumber,
        [parameter(position = 1)]
        [string]$UdfValue
    )
    New-ItemProperty -Path Registry::HKLM\SOFTWARE\CentraStage -Name "Custom$UdfNumber" -Value $UdfValue -Force -ErrorAction Stop | Out-Null
}

function Get-Summary {
    <# 
        .SYNOPSIS
        Function "Get-Summary"
        .DESCRIPTION
        This function will 

        .NOTES
        Version   	..: 1.1.2
        Created   	..: 11.11.2021
        Created by	..: Kenneth Jøleid-Skari, Marcello Consulting AS.

        Change log	..:
        12.11.2021 - 1.1.1 - replaced UsedForRmm_job with DisplayOutput
        .LINK
        
    #>

    #region Variables for function
    $FunctionName = "Summary"
    #endregion

    #region write-host output for RMM jobs
    if ($DisplayOutput) {
        # sum total characters should be the same as for $LineBreak. By having same start and end, text will be line centrated.
        Write-Host "$($LineBreak[0..27] -join('')) ($FunctionName) $($LineBreak[0..28] -join(''))"
    }
    #endregion
    #region create summary
    $AlertMessage = "- Total alerts:   $varAlerts."
    $WarningMessage = "- Total warnings: $varWarnings."
    $EventIDMessage = "- Reporting EventIDs to RMM:"
    $InfoMessage = "+ Total: nothing to report."

    if ($script:EventIDsLogging) {
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            if ($varWarnings -ge 1) {
                Write-Host $WarningMessage
            }
            if ($varAlerts -ge 1) {
                Write-Host $AlertMessage
            }
            Write-Host $EventIDMessage
            Write-Host "    $($script:EventIDsLogging.TrimEnd(","))"
        }
        #endregion
        $EventID = "60003"
        $EventType = "Information"
        $EventMessage = "$(($script:EventIDsLogging -join ",").TrimEnd(","))"
        #region write to eventlog
        Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
        Start-Sleep -Seconds 1
        #endregion

        if ($IsDattoRmm) {
            $EventID = "60004"
            $EventType = "Information"
            $EventMessage = "Marcello RMM Security Audit Alert:`rRMM UDF updated.`r$($script:EventIDsLogging.TrimEnd(","))"
            #region write to eventlog
            Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
            #endregion
        }
    }

    if ($script:EventIDsLogging -like "") {
        #region write-host output for RMM jobs
        if ($DisplayOutput) {
            Write-Host $InfoMessage
            Write-Host $EventIDMessage
            Write-Host "    No EventID created."
        }
        if ($IsDattoRmm) {
            $EventID = "60005"
            $EventType = "Information"
            $EventMessage = "Marcello RMM Security Audit Alert:`rNo EventID for RMM UDF to updated."
            #region write to eventlog
            Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
            #endregion
        }
        #endregion
        $EventID = "60006"
        $EventType = "Information"
        $EventMessage = "Marcello RMM Security Audit Message:`rThis device did not match any detailing criterias for this routine"
        #region write to eventlog
        Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
        Start-Sleep -Seconds 1
        #endregion
    }
    #endregion

    #region update UDF
    if ($IsDattoRmm) {
        Set-DattoRMMudf -UdfNumber "17" -UdfValue $script:EventIDsLogging.TrimEnd(",")
    }
    #endregion
    #region end of function
    #region write-host output for RMM jobs
    if ($DisplayOutput) {
        Write-Host $LineBreak $NewLine
    }
    #endregion
    #endregion
    #region Marcello RMM adoption - timer for logging
    $ScriptTime = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
    $EventID = "60002"
    $EventType = "Information"
    $EventMessage = "Marcello RMM Security Audit Alert:`rAudit finished."
    #region write-host output for RMM jobs
    if ($DisplayOutput) {
        Write-Host ": END: $ScriptTime"
    }
    #endregion
    #region write to eventlog
    Write-EventLog -LogName $EventLog -Source $EventSource -EntryType $EventType -EventID $EventID -Message $EventMessage
    #endregion
    #endregion
    #region write a default StdOut
    if ($DisplayOutput -eq $false) {
        Write-Host "Marcello RMM Security Audit: build $varMarcelloBuildString Executed Successfully.`r`n    (If you expected more output here run the component with DisplayOutput $true)"
    }
    #endregion
}

Check-AccountSecurityAudit
Check-PasswordPolicyAudit
Check-NetworkSecurityAudit
Check-DeviceSecurityAudit
Check-SecurityBaseline
Get-Summary