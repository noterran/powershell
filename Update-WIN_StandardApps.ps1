#Set up the log directory if necessary
if (!(Test-Path "C:/log")) {
    New-Item -ItemType Directory -Path "C:/log" | Out-Null
}

#Install winget if necessary
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

#List of all apps to be installed or upgraded
$appList = @("WinSCP.WinSCP")

foreach ($app in $appList) {
    try {
        winget upgrade --id=$app --source=winget --silent --accept-package-agreements --accept-source-agreements --force
        "Successfully ran Winget for $app" | out-file -path "C:/log/WinGetVersion.log" -Append
    }
    catch {
        "Failed to run Winget for $app" | out-file -path "C:/log/WinGetVersion.log" -Append
    }
 }

Remove-Item -Path "C:/log/updateavailable.csv" -ErrorAction SilentlyContinue

#install WingetClient module if necessary
if (!(Get-Module -ListAvailable -Name Microsoft.WinGet.Client)) {
    Install-Module -Name Microsoft.WinGet.Client -Repository PSGallery -Force -ErrorAction SilentlyContinue
} 

#check if apps need update
$installed = Get-WinGetPackage -Source winget
$updatable = $installed | Where-Object IsUpdateAvailable | Select-Object -ExpandProperty Id
$updatable | Out-file -FilePath "C:/log/updateavailable.csv" -Encoding utf8

#Append status column and trim file
$file = Import-Csv "C:/log/updateavailable.csv" -Header "column1"
$file | select-object column1,@{Name="column2";Expression={'2'}} | Export-Csv -path "C:/log/updateavailable.csv" -NoTypeInformation