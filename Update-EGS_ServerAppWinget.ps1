try {
    $wingetVersion = winget --version 2>&1
    Write-Host "WinGet is installed. Version: $wingetVersion"
}

catch {
    Write-Host "WinGet is not installed or not recognized."
    $progressPreference = 'silentlyContinue'
    Write-Host "Installing WinGet PowerShell module from PSGallery..."
    Install-PackageProvider -Name NuGet -Force | Out-Null
    Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
    Write-Host "Using Repair-WinGetPackageManager cmdlet to bootstrap WinGet..."
    Repair-WinGetPackageManager -AllUsers
    Write-Host "Done."
}

$sourceName = "Update-EGS_ServerAppWinget"
$logName = "Application"

# Check if the source exists
if (![System.Diagnostics.EventLog]::SourceExists($sourceName)) {
    # If not, create it. Requires administrative privileges.
    New-EventLog -LogName $logName -Source $sourceName
    Write-Host "Created new event log source: $sourceName"
} else {
    Write-Host "Event log source already exists: $sourceName"
}

$appList = @("WinSCP.WinSCP")

foreach ($app in $appList) {
    try {
        winget upgrade --id=$app --source=winget --silent --accept-package-agreements --accept-source-agreements --force
        Write-EventLog -LogName $logName -Source $sourceName -EventId 3001 -EntryType Information -Message "Winget ran successfully for $app" -Category 1 -RawData 10,20
    }
    catch {
        Write-EventLog -LogName $logName -Source $sourceName -EventID 3002 -EntryType Information -Message "Winget failed to upgrade $app" -Category 1 -RawData 10,20
    }      
 }