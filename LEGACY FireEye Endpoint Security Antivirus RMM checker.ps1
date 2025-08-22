    <# .SYNOPSIS
         Script ""
    .DESCRIPTION
         This script will run various functions on the computer to check that the services Marcello is providing is up to date and running
         - this script will not remediate any misconfigurations

    .NOTES
         Author     : Kenneth Jøleid-Skari
         Date       : 26.12.2019
         Revised    : 08.02.2021
         Version    : 1.02

         Comments   : 
    .LINK
         
    #>
    [cmdletbinding()]
    param(
    )

function Write-DeviceMonitorAlert {
    <# .SYNOPSIS
         Function "Write-DeviceMonitorAlert"
    .DESCRIPTION
         This Function will write output that supports being captured by Datto RMM Device Monitor
         - the AlertInfo message must be a single line string
         - the DiagnosticInfo message can be multiple lines in array
         - "-ExitWithError" is to control the exit code "Exit 0" or "Exit 1"

         The Datto RMM Device Monitor Policy must look at output variable to caputer the result correctly
         - the script defaults to "RMM_Monitor_Result" if OutputVariable not specified
         - output itself will look like "OutputVariable:"

    .NOTES
         Author     : Kenneth Jøleid-Skari
         Date       : 29.04.2019
    .LINK
         https://help.aem.autotask.net/en/Content/4WEBPORTAL/Monitor/CustomComponentMonitor.htm
    #>
    [cmdletbinding()]
    param(
        [parameter(position=0)]
        [string]$AlertInfo,
        [parameter(position=1)]
        $DiagnosticInfo,
        [parameter(position=3)]
        $OutputVariable,
        [parameter(position=4)]
        [ValidateSet($true,$false)]
        $ExitWithError
    )
    if (!($OutputVariable)){
        $OutputVariable = "RMM_Monitor_Result"
    }
    Write-Verbose "AlertInfo is..: $AlertInfo"
    Write-Verbose "OutputVariable is..: $OutputVariable"
	Write-Host "<-Start Result->"
    Write-Host "$OutputVariable=$AlertInfo"
    Write-Host "<-End Result->"
    if ($DiagnosticInfo){
        Write-Verbose "DiagnosticInfo is..: $DiagnosticInfo"
        # if $Diagnostics is present create output for Diagnostics information
        Write-Host "<-Start Diagnostic->"
        ForEach ($line in $DiagnosticInfo){
            Write-Host "$line"
        }
        Write-Host "<-End Diagnostic->"
    }
    if ($ExitWithError -eq $true){
        Write-Verbose "ExitWithError is set to 'TRUE'"
        exit 1
    }
    elseif ($ExitWithError -eq $false){
        Write-Verbose "ExitWithError is set to 'FALSE'"
        exit 0
    }
    else {
        Write-Verbose "ExitWithError is not defined - will use 'TRUE'"
        exit 1
    }
}

function Start-DS-StateCheck {
    $State = New-Object PSObject -Property @{
        State = [string]::Empty;
        DiagnosticInfo = [string]::Empty;
    }
    $StateInfo = @()
    $StateInfo += $StateInfo = Set-DattoRMMAntivirusStatus
    if (!($StateInfo)){
        $State.State = "ok"
    }
    else {
        $State.State = "not ok"
        $State.DiagnosticInfo = $StateInfo
    }
    return $State
}

Function Get-FireEyeAntivirusStatus {
    <# 
	    .Synopsis
        
	    .Notes
	    Version   	..: 1.0.3
	    Created   	..: 05.02.2021
	    Created by	..: Kenneth Jøleid-Skari, Marcello Consulting AS.

	    Change log	..:
            10.02.2021 - 1.0.3 - Updated diagnostic data
            09.02.2021 - 1.0.2 - Updated with check for file not exist on version file
            05.02.2021 - 1.0.0 - Initial Release

	    .Description

	    .Example
    
        .Link
        https://help.aem.autotask.net/en/Content/4WEBPORTAL/AntivirusDetection.htm?Highlight=antivirus%20json
        
    #>

    #region Variables for function
        $FunctionName = "Get-FireEyeAntivirusStatus"
        $StateDescription = New-Object PSObject -Property @{
            State = [string]::Empty;
            DiagnosticInfo = [string]::Empty;
            Value = [string]::Empty;
        }
    #endregion

    #region variables for function
        $ValidHourSpan = 64 # from RMM 'NOTE  Updates older than three days are considered out of date.'
            
    #endregion

    #region folder containing antivirus info
        $AVrootFolder = "C:\ProgramData\FireEye\xagt\exts\MalwareProtection\sandbox\content\av"
        $AVsubFolders = (Get-ChildItem $AVrootFolder).Name | where {(!($_ -like "temp"))}
        $AVstatusFilePath = "$AVrootFolder\$AVsubFolders"
        $AVstatusFile = (Get-Item "$AVstatusFilePath\versions.id.*").Name
    #endregion

    #region test that pattern files exist - this could indicate problems with installation
        if (!($AVstatusFile)){
            $upToDate = "false"
            $DiagnosticInfo = "AV Pattern file is missing: expected file is versions.id.*" # further checks should not be perfomed
            #region update output
                $StateDescription.DiagnosticInfo = $DiagnosticInfo
                $StateDescription.Value = $upToDate
                $StateDescription.State = switch ($upToDate){true {'ok'}false {'not ok'}}
            #endregion
            return $StateDescription
        }
    #endregion

    #region comparison
        [xml]$AVstatusXMLFile = Get-Content "$AVrootFolder\$AVsubFolders\$AVstatusFile"
        $AVLastUpdateTimestamp = Get-Date ($AVstatusXMLFile.info.time).'#text'
        $TimeStampNow = Get-Date
        $TimeDiff = New-TimeSpan -Start $AVLastUpdateTimestamp -End $TimeStampNow
        if ($TimeDiff.Hours -lt $ValidHourSpan) {
            $upToDate = "true"
        }
        else{
            $upToDate = "false"
            $DiagnosticInfo = "The AV pattern file is outdated"
        }
    #region update output
        $StateDescription.DiagnosticInfo = $DiagnosticInfo
        $StateDescription.Value = $upToDate
        $StateDescription.State = switch ($upToDate){true {'ok'}false {'not ok'}}
    #endregion
    return $StateDescription
}

Function Get-FireEyeRunningStatus {
    <# 
	    .Synopsis
        
	    .Notes
	    Version   	..: 1.0.4
	    Created   	..: 05.02.2021
	    Created by	..: Kenneth Jøleid-Skari, Marcello Consulting AS.

	    Change log	..:
            10.02.2021 - 1.0.4 - Updated diagnostic data
            09.02.2021 - 1.0.3 - Filtered out "events.db" for servers as this probably will be in memory
            05.02.2021 - 1.0.2 - Added StateDescription
            05.02.2021 - 1.0.0 - Initial Release

	    .Description

	    .Example
    
        .Link
        https://help.aem.autotask.net/en/Content/4WEBPORTAL/AntivirusDetection.htm?Highlight=antivirus%20json
        
    #>
    #region Variables for function
        $FunctionName = "Get-FireEyeRunningStatus"
        $StateDescription = New-Object PSObject -Property @{
            State = [string]::Empty;
            DiagnosticInfo = [string]::Empty;
            Value = [string]::Empty;
        }
        $OSVersionRegistry = "REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        $OSVersion = Get-ItemProperty $OSVersionRegistry
    #endregion

    #region FireEye files
        $Path = "C:\ProgramData\FireEye\xagt"
        $RequiredFiles =@(
            "events.db",
            "main.db",
            "xlog.db"
        )
        if ($OSVersion.ProductName -like "*Server*"){
            $RequiredFiles =@(
                "main.db",
                "xlog.db"
            )
        }
    #endregion

    #region test that key-files exist - this could indicate problems with installation
        ForEach ($file in $RequiredFiles){
            if ((Test-Path "$Path\$file") -eq $false){
                $Running = "false"
                $DiagnosticInfo = "One or more key FireEye files are missing: $file" # further checks should not be perfomed
            }
        }
    #endregion
    #region check time stamp on required files
        if (!($Running -eq "false")){
            $TimeStampNow = Get-Date
            $ValidMinuteSpan = "60"
            ForEach ($file in $RequiredFiles){
                #Check dates and compare to timespan
                # - should not differ with more than 15 min
                $TimeDiff = ""
                $TimeDiff = New-TimeSpan -Start (Get-Item $Path\$file).LastWriteTime -End $TimeStampNow
                if ($TimeDiff.Minutes -lt $ValidMinuteSpan) {
                    $Running = "true"
                }
                else {
                    $Running = "false"
                    $DiagnosticInfo = "One of the required file are out of date: $file"
                } 
            }
        }
    #endregion
    #region check service state
        if (!($Running -eq "false")){
            if (!((Get-Service xagt).status -like "running")) {
                $Running = "false"
                $DiagnosticInfo = "The 'xagt' service is not running"
            }
            else {
                if (!($Running -eq "false")){ #if previous checks NOT indicating failed running state
                    $Running = "true"
                }
            }
        }
    #endregion
    #check system startup time
    #grant som slack to status check if system has just restarted
    
    #region update output
        $StateDescription.DiagnosticInfo = $DiagnosticInfo
        $StateDescription.Value = $Running
        $StateDescription.State = switch ($Running){true {'ok'}false {'not ok'}}
    #endregion
    return $StateDescription
}

Function Get-FireEyeDefenderExclutions {
    <# 
	    .Synopsis
        
	    .Notes
	    Version   	..: 1.0.0
	    Created   	..: 08.02.2021
	    Created by	..: Kenneth Jøleid-Skari, Marcello Consulting AS.

	    Change log	..:
            05.02.2021 - 1.0.0 - Initial Release

	    .Description

	    .Example
    
        .Link
            https://docs.microsoft.com/en-us/windows/security/threat-protection/microsoft-defender-atp/switch-to-microsoft-defender-setup#enable-microsoft-defender-antivirus-and-confirm-its-in-passive-mode
            https://docs.microsoft.com/en-us/windows/security/threat-protection/microsoft-defender-antivirus/microsoft-defender-antivirus-on-windows-server-2016#need-to-set-microsoft-defender-antivirus-to-passive-mode
    #>
    #region Variables for function
        $FunctionName = "Get-FireEyeDefenderExclutions"
        $StateDescription = New-Object PSObject -Property @{
            State = [string]::Empty;
            DiagnosticInfo = [string]::Empty;
            Value = [string]::Empty;
        }
        $OSVersionRegistry = "REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        $OSVersion = Get-ItemProperty $OSVersionRegistry
    #endregion

    #region check if defender is present
        $DefenderCommand = Get-Command "Get-MpPreference" -ErrorAction SilentlyContinue  # powershell module for defender is present if defender is installed
        if ($DefenderCommand){ #defender is probably installed as PS commands are present
            if ($OSVersion.ProductName -like "*Server 2016*"){
                #region for server 2016
                    $DefenderState = Get-WindowsFeature -Name "Windows-Defender"
                    if ($DefenderState.Installed -eq $true){
                        #region update output
                            $StateDescription.DiagnosticInfo = "Windows Defender is installed - Uninstall Windows Defender according to Microsoft Recommendations"
                            $StateDescription.State = "not ok"
                        #endregion
                        return $StateDescription
                    }
                #endregion
            }
            else {
                #region compare exclutions
                    $DefenderExclutions = (Get-MpPreference).ExclusionPath
                    if ($DefenderExclutions){
                        # reguired exceptions for FireEye
                        $ExcludeFolder = @(
                            "$env:ALLUSERSPROFILE\Application Data\FireEye\xagt",
                            "$env:ProgramData\FireEye\xagt",
                            "$env:SystemRoot\FireEye",
                            "C:\Program Files\FireEye",
                            "C:\Program Files (x86)\FireEye",
                            "$env:SystemRoot\System32\drivers\FeKern.sys"
                        )
                        $Results = Compare-Object -ReferenceObject $ExcludeFolder -DifferenceObject $DefenderExclutions -PassThru -IncludeEqual
                        #region creation of arrays in case of export-csv is needed for log purpose
                            $Missing = $Results | where {$_.sideindicator -eq "<="} #only present in ReferenceObject
                            $Additional = $Results | where {$_.sideindicator -eq "=>"} #only present in DifferenceObject
                            $AlreadyPresent = $Results | where {$_.sideindicator -eq "=="} #only present both in ReferenceObject and DifferenceObject
                        #endregion
                        if ($Missing){
                            #region update output
                                $StateDescription.DiagnosticInfo = "FireEye exceptions list for Windows Defender is not present - Update Windows Defender exclution list"
                                $StateDescription.State = "not ok"
                            #endregion
                            return $StateDescription
                        }
                        else {
                            # do nothing as all exceptions are present
                        }
                    }
                    else {
                        #region update output
                            $StateDescription.DiagnosticInfo = "FireEye exceptions list for Windows Defender is not present - Update Windows Defender exclution list"
                            $StateDescription.State = "not ok"
                        #endregion
                        return $StateDescription
                    }
                #endregion
            }
        }

        if (!($DefenderCommand)){ #defender is not installed as PS commands are missing
            if ($OSVersion.ProductName -like "*Server 2016*"){
                #region for server 2016
                    $DefenderState = Get-WindowsFeature -Name "Windows-Defender"
                    if ($DefenderState.Installed -eq $true){
                        #region update output
                            #$StateDescription.DiagnosticInfo = "Windows Defender is uninstalled according to Microsoft Recommendations"
                            $StateDescription.State = "ok"
                        #endregion
                        return $StateDescription
                    }
                #endregion
            }
            if ($OSVersion.ProductName -like "*Server 2019*"){
                #region for server 2019
                    $DefenderState = Get-WindowsFeature -Name "Windows-Defender"
                    if ($DefenderState.Installed -eq $false){
                        #region update output
                            $StateDescription.DiagnosticInfo = "Windows Defender is not installed - Install Windows Defender"
                            $StateDescription.State = "not ok"
                        #endregion
                        return $StateDescription
                    }
                #endregion
            }
            else { #for all other OS than above specified
                if ($OSVersion.ProductName -like "*server*"){
                    #do nothing as defender is not expected to be installed
                }
                else {
                    #region update output
                        $StateDescription.DiagnosticInfo = "Windows Defender is not installed - Install Windows Defender"
                        $StateDescription.State = "not ok"
                    #endregion
                    return $StateDescription                    
                }
            }
        }
    #endregion

    #region check that defender is configured for passive mode
        <#
            Windows Defender is the default antivirus program for endpoints running Windows 10. On Windows Desktop OSs, Windows Defender is automatically disabled when you enable the malware protection feature on your host endpoints
            On Windows Server OSs, if Windows Defender is enabled, FireEye Malware Protection and Windows Defender will run simultaneously. 
            This could cause performance issues and unpredictable behavior. An administrator can uninstall Windows Defender, disable it by using a Group Policy setting, or set Defender to "Passive mode" (for Server 2019). 
            If you want to run both Windows Defender and FireEye Malware Protection, FireEye recommends that you have the two agents exclude each other.
        #>
        if ($DefenderCommand){
            if ($OSVersion.ProductName -like "*Server 2019*"){
                $PassiveModeRegistry = "REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Advanced Threat Protection"
                $PassiveMode = Get-ItemProperty $PassiveModeRegistry
                if ($PassiveMode){
                    if ($PassiveMode.ForceDefenderPassiveMode -like "0"){
                        #region update output
                            $StateDescription.DiagnosticInfo = "Windows Defender is not configured for Passive mode - Configre Registry Key for Passive Mode"
                            $StateDescription.State = "not ok"
                        #endregion
                        return $StateDescription
                    }
                }
                else {
                    #region update output
                        $StateDescription.DiagnosticInfo = "Windows Defender is not configured for Passive mode - Configre Registry Key for Passive Mode"
                        $StateDescription.State = "not ok"
                    #endregion
                    return $StateDescription
                }

            }
            else {
                # nothing to do as FireEye integrates with Security Center

            }
        }
    #endregion
    #region update output
        $StateDescription.State = "ok"
    #endregion
    return $StateDescription
}

Function Set-DattoRMMAntivirusStatus {
    <# 
	    .Synopsis
        
	    .Notes
	    Version   	..: 1.0.0
	    Created   	..: 05.02.2021
	    Created by	..: Kenneth Jøleid-Skari, Marcello Consulting AS.

	    Change log	..:
            05.02.2021 - 1.0.0 - Initial Release

	    .Description

	    .Example
    
        .Link
        https://help.aem.autotask.net/en/Content/4WEBPORTAL/AntivirusDetection.htm?Highlight=antivirus%20json
        
    #>

    #region Variables for function
        $FunctionName = "Set-DattoRMMAntivirusStatus"
        $StateDescription = @()
    #endregion

    #region Collect FireEye status
        $RunningStatus = Get-FireEyeRunningStatus
        $AntivirusStatus = Get-FireEyeAntivirusStatus
        $DefenderStatus = Get-FireEyeDefenderExclutions
    #endregion

    #region create JSON file
        <#
            {"product":"Override Antivirus","running":true,"upToDate":true}
            %ProgramData%\CentraStage\AEMAgent\antivirus.json
        #>
        $AntivirusJSON = @{
            "product"  = "FireEye Endpoint Security"
            "running"  = "$($RunningStatus.Value)"
            "upToDate" = "$($AntivirusStatus.Value)"
        }
        $AntivirusJSON | ConvertTo-Json | Out-File "$env:ProgramData\CentraStage\AEMAgent\antivirus.json"
    #endregion
    if ($RunningStatus.Value -eq "false" -or $AntivirusStatus.Value -eq "false"){
        #$StateDescription = [string]($AntivirusJSON.GetEnumerator() | % { "$($_.Key)=$($_.Value)" }) + "`r`n" + $RunningStatus.DiagnosticInfo
        $RunningInfo = ("Running State: $($RunningStatus.State). $($RunningStatus.DiagnosticInfo)").Trim()
        $AVInfo = ("Pattern State: $($AntivirusStatus.State). $($AntivirusStatus.DiagnosticInfo)").Trim()
        $Defender = ("Defender State: $($DefenderStatus.State). $($DefenderStatus.DiagnosticInfo)").Trim()
        $StateDescription = $RunningInfo + "`r`n" + $AVInfo + "`r`n" + $Defender
    }
    return $StateDescription
}

Try {
    #region Trigger Routine
        $State = Start-DS-StateCheck
        #region Sort information for Monitor Alert
            # Place correct information into AlertInfo
            $AlertInfo = $State.State
            # Create a multiline output for use in DiagnosticInfo
            $DiagnosticInfo = @(
                $State.DiagnosticInfo
            )
            # Handle the correct ExitCode
            if ($AlertInfo -like "ok"){
                $ExitWithError = $false
            }
            else {
                $ExitWithError = $true
            }
        #endregion
        #region Trigger Monitor Alert
            Write-DeviceMonitorAlert -AlertInfo $AlertInfo -DiagnosticInfo $DiagnosticInfo -OutputVariable "State" -ExitWithError $ExitWithError
        #endregion
    #endregion
}
Catch {
    #region Catch routine for Monitor
    $ErrorArray = $_.Exception
    $ErrorRecord = $ErrorArray.ErrorRecord | Out-String
    $ExitWithError = $true
        #region Trigger Monitor Alert
            Write-DeviceMonitorAlert -AlertInfo "Script Error" -DiagnosticInfo $ErrorRecord -OutputVariable "State" -ExitWithError $ExitWithError
        #endregion
    #endregion
}