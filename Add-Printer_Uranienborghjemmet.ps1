# Variables
$driverDownloadPath = "https://ftp.hp.com/pub/softlib/software13/UPD/upd-pcl6-x64-7.8.0.26261.zip"
$portName = "IP_10.6.102.10" # Printer port name
$portAddress = "10.6.102.10" # Printer IP
$printerName = "Smartlegen Printer Uranienborg HP M479fdw" # Printer display name
$driverName = "HP Universal Printing PCL 6" # Must be exact! Install driver on your computer and copy its name and paste here!
# Do not modify these variables
$driverDownloaded = "C:\support\PrinterDriver.zip"
$extractPath = "C:\support\PrinterDriver"
$portExists = Get-Printerport -Name $portname -ErrorAction SilentlyContinue
$printerExists = Get-Printer -Name $printerName -ErrorAction SilentlyContinue
######################
#   INSTALL SCRIPT   #
######################
if (-not $printerExists) {
New-Item -ItemType Directory -Force -Path C:\support # Create local storage folder
Invoke-WebRequest $driverDownloadPath -OutFile $driverDownloaded # Download HP driver
Expand-Archive -Path $driverDownloaded -DestinationPath $extractPath -Force # Extract HP driver
Get-ChildItem $extractPath -Recurse -Filter "*.inf" -Force | ForEach-Object { PNPUtil.exe /add-driver $_.FullName /install } # Add to Windows Driver Store
Add-PrinterDriver -Name $driverName # Add Driver
# Add Printer Port
if (-not $portExists) {
  Add-PrinterPort -Name $portName -PrinterHostAddress $portAddress
}
# Install Printer
if (-not $printerExists) {
Add-Printer -Name $printerName -PortName $portName -DriverName $driverName
}
Set-PrintConfiguration -PrinterName $printerName -Color $true # Set Default to Color print
#(Get-WmiObject -ClassName Win32_Printer | Where-Object -Property Name -EQ $printerName).SetDefaultPrinter() # Set as default printer
# Cleanup
Remove-Item -Path $driverDownloaded -Force
Remove-Item -Path $extractPath -Force -Recurse
}