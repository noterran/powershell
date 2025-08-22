# Variables
$driverDownloadPath = "https://ftp.hp.com/pub/softlib/software13/printers/UPD/upd-pcl6-x64-7.6.0.26178.zip"
$portName = "IP_192.168.141.251" # Printer port name
$portAddress = "192.168.141.251" # Printer IP
$printerName = "Smartlegen Printer Kantarellen HP M479fdw" # Printer display name
$driverName = "HP Universal Printing PCL 6" # Must be exact! Install driver on your computer and copy its name and paste here!
# Do not modify these variables
$driverDownloaded = "C:\support\PrinterDriver.zip"
$extractPath = "C:\support\PrinterDriver"
$portExists = Get-Printerport -Name $portname -ErrorAction SilentlyContinue
$printerExists = Get-Printer -Name $printerName -ErrorAction SilentlyContinue
######################
#   REMOVE SCRIPT   #
######################
# Remove Printer Port
if ($portExists) {
  Remove-PrinterPort -Name $portName -PrinterHostAddress $portAddress
}
# Install Printer
if ($printerExists) {
Remove-Printer -Name $printerName -PortName $portName -DriverName $driverName
}