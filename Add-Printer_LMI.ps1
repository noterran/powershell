Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
New-Item -Path C:\Temp -ItemType directory -ErrorAction SilentlyContinue

#Variables
$printerName = "Canon imageFORCE C5140" # Printer display name
$portName = "IP_192.168.200.57" # Printer port name
$portAddress = "192.168.200.57" # Printer IP
$driverName = "Canon Generic Plus PCL6"
$url = "https://pdisp01.c-wss.com/gdl/WWUFORedirectTarget.do?id=MDEwMDAwOTQyMzE2&cmp=ACM&lang=JA"
$file = "c:\Temp\canon.exe"
$extractPath = "C:\Temp\CanonPrinterDrivers"
$portExists = Get-Printerport -Name $portname -ErrorAction SilentlyContinue
$printerExists = Get-Printer -Name $printerName -ErrorAction SilentlyContinue

#Install printer
if (-not $printerExists) {
#Download file
$clnt = new-object System.Net.WebClient
$clnt.DownloadFile($url,$file)

#Install 7zip module
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Set-PSRepository -Name 'PSGallery' -SourceLocation "https://www.powershellgallery.com/api/v2" -InstallationPolicy Trusted
Install-Module -Name 7Zip4PowerShell -Force

#Extract 7zip file
Expand-7Zip -ArchiveFileName "c:\temp\canon.exe" -TargetPath $extractPath

#Install Printer driver
Invoke-Command {pnputil.exe -a "C:\Temp\CanonPrinterDrivers\x64\Driver\CNP60MA64.INF" }
Add-PrinterDriver -Name $driverName

#Add printer port
if (-not $portExists) {
  Add-PrinterPort -Name $portName -PrinterHostAddress $portAddress
}

Add-Printer -Name $printerName -PortName $portName -DriverName $driverName
Set-PrintConfiguration -PrinterName $printerName -Color $true # Set Default to Color print
(Get-WmiObject -ClassName Win32_Printer | Where-Object -Property Name -EQ $printerName).SetDefaultPrinter() # Set as default printer
}

# Cleanup
Remove-Item -Path $extractPath -Force -Recurse