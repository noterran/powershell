#Set up the log directory if necessary
if (!(Test-Path "C:\Program Files\Marcello\WinGetAppsUpdates\")) {
    New-Item -ItemType Directory -Path "C:\Program Files\Marcello\WinGetAppsUpdates\" | Out-Null
}

#Indicate new run of Update-Win_Standardapps
$timestamp = Get-Date
$timestamp | out-file -filepath "C:\Program Files\Marcello\WinGetAppsUpdates\WinGetVersion.log" -Append -NoNewline

#Install winget if necessary
try {
    $wingetVersion = winget --version 2>&1
    "`nWinGet is installed. Version: $wingetVersion" | out-file -filepath "C:\Program Files\Marcello\WinGetAppsUpdates\WinGetVersion.log" -Append
}
catch {
    "`nWinGet is not installed or not recognized." | out-file -filepath "C:\Program Files\Marcello\WinGetAppsUpdates\WinGetVersion.log" -Append
    $progressPreference = 'silentlyContinue'
    "Installing WinGet PowerShell module from PSGallery..." | out-file -filepath "C:\Program Files\Marcello\WinGetAppsUpdates\WinGetVersion.log" -Append
    Install-PackageProvider -Name NuGet -Force | Out-Null
    Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
    "Using Repair-WinGetPackageManager cmdlet to bootstrap WinGet..." | out-file -filepath "C:\Program Files\Marcello\WinGetAppsUpdates\WinGetVersion.log" -Append
    Repair-WinGetPackageManager -AllUsers
    "Done." | out-file -filepath "C:\Program Files\Marcello\WinGetAppsUpdates\WinGetVersion.log" -Append
}

#List of all apps to be installed or upgraded
$appList = @("WinSCP.WinSCP", "Microsoft.AppInstaller")

#stopping the apps
foreach ($app in $appList) {
    $appToStop = $app.Substring(0, $app.IndexOf("."))
    $process = Get-Process | Where-Object {$_.Name -like $appToStop} | Select-Object -ExpandProperty ProcessName
    $processToKill = $process + ".exe"
    if ($processToKill) { c:\windows\system32\taskkill /f /im $processtokill
    }
    else {"No process like $appToStop exists" | out-file -filepath "C:\Program Files\Marcello\WinGetAppsUpdates\WinGetVersion.log" -Append
    }
}

#Update the apps
foreach ($app in $appList) {
    try {
        winget upgrade --id=$app --source=winget --silent --accept-package-agreements --accept-source-agreements --force
        "Successfully ran Winget for $app" | out-file -filepath "C:\Program Files\Marcello\WinGetAppsUpdates\WinGetVersion.log" -Append
    }
    catch {
        "Failed to run Winget for $app" | out-file -filepath "C:\Program Files\Marcello\WinGetAppsUpdates\WinGetVersion.log" -Append
    }
 }

 #install WingetClient module if necessary
if (!(Get-Module -ListAvailable -Name Microsoft.WinGet.Client)) {
    Install-Module -Name Microsoft.WinGet.Client -Repository PSGallery -Force -ErrorAction SilentlyContinue
} 

#Check for applications where update has failed and is still available
$i = 0
foreach ($app in $appList){
    $installed = Get-WinGetPackage -Source winget -id $app
    $updateable = $installed | Where-Object IsUpdateAvailable | Select-Object -ExpandProperty Id
    if ($updateable){
        $i++
    }
}

#Write result of previous check to registry
$path = "HKLM:\SOFTWARE\Marcello\WinGetAppsUpdates"
$value = "WinGetAppsUpdatesAvailable"
if (!(Test-Path $path)) {
    New-Item -Path "$path" | Out-Null
    New-ItemProperty -Path "$path" -Name "$value" | Out-Null
}

Set-ItemProperty -Path $path -Name $value -Value $i -Type DWord