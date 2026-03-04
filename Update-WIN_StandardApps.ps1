#Set up the log directory if necessary
if (!(Test-Path "C:/log")) {
    New-Item -ItemType Directory -Path "C:/log" | Out-Null
}

#Install winget if necessary
try {
    $wingetVersion = winget --version 2>&1
    "WinGet is installed. Version: $wingetVersion" | out-file -filepath "C:/log/WinGetVersion.log" -Append
}
catch {
    "WinGet is not installed or not recognized." | out-file -filepath "C:/log/WinGetVersion.log" -Append
    $progressPreference = 'silentlyContinue'
    "Installing WinGet PowerShell module from PSGallery..." | out-file -filepath "C:/log/WinGetVersion.log" -Append
    Install-PackageProvider -Name NuGet -Force | Out-Null
    Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
    "Using Repair-WinGetPackageManager cmdlet to bootstrap WinGet..." | out-file -filepath "C:/log/WinGetVersion.log" -Append
    Repair-WinGetPackageManager -AllUsers
    "Done." | out-file -filepath "C:/log/WinGetVersion.log" -Append
}

#List of all apps to be installed or upgraded
$appList = @("Notepad++.Notepad++")

#stopping the apps
foreach ($app in $appList) {
    $appToStop = $app.Substring(0, $app.IndexOf("."))
    #$appToStop
    $task = Get-Process | Where {$_.Name -like $appToStop} | Select-Object -ExpandProperty ProcessName
    $taskToKill = $task + ".exe"
    c:\windows\system32\taskkill /f /im $tasktokill
 }

#Update the apps
foreach ($app in $appList) {
    try {
        winget upgrade --id=$app --source=winget --silent --accept-package-agreements --accept-source-agreements --force
        "Successfully ran Winget for $app" | out-file -filepath "C:/log/WinGetVersion.log" -Append
    }
    catch {
        "Failed to run Winget for $app" | out-file -filepath "C:/log/WinGetVersion.log" -Append
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

$csv = Get-Content "C:/log/updateavailable.csv" 
$csv = $csv[1..($csv.count - 1)]
$csv | Set-Content -Path "C:/log/updateavailable.csv"