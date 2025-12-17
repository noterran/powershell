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
$apps = winget upgrade
foreach ($app in $apps) {
    if ($app -match "example_id") {
        winget install --id=example_id --source=winget --silent --accept-package-agreements --accept-source-agreements --override "/S"
    }
}