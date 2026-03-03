try {
    $wingetVersion = winget --version 2>&1
    "WinGet is installed. Version: $wingetVersion" | out-file -path "C:/log/WinGetVersion.log" -Append
}

catch {
    "WinGet is not installed or not recognized." | out-file -path "C:/log/WinGetVersion.log" -Append
    $progressPreference = 'silentlyContinue'
    "Installing WinGet PowerShell module from PSGallery..." | out-file -path "C:/log/WinGetVersion.log" -Append
    Install-PackageProvider -Name NuGet -Force | Out-Null
    Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
    "Using Repair-WinGetPackageManager cmdlet to bootstrap WinGet..." | out-file -path "C:/log/WinGetVersion.log" -Append
    Repair-WinGetPackageManager -AllUsers
    "Done." | out-file -path "C:/log/WinGetVersion.log" -Append
}

$sourceName = "Update-EGS_ServerAppWinget"
$logName = "Application"

# Check if the source exists
if (![System.Diagnostics.EventLog]::SourceExists($sourceName)) {
    # If not, create it. Requires administrative privileges.
    New-EventLog -LogName $logName -Source $sourceName
    "Created new event log source: $sourceName" | out-file -path "C:/log/WinGetVersion.log" -Append
} else {
    "Event log source already exists: $sourceName" | out-file -path "C:/log/WinGetVersion.log" -Append
}

$appList = @("WinSCP.WinSCP")

foreach ($app in $appList) {
    try {
        winget upgrade --id=$app --source=winget --silent --accept-package-agreements --accept-source-agreements --force
        Write-EventLog -LogName $logName -Source $sourceName -EventId 30001 -EntryType Information -Message "Winget ran successfully for $app" -Category 1 -RawData 10,20
    }
    catch {
        Write-EventLog -LogName $logName -Source $sourceName -EventID 30002 -EntryType Information -Message "Winget failed to upgrade $app" -Category 1 -RawData 10,20
    }      
 }