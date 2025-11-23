# Variables
$portName = "IP_10.57.143.60" # Printer port name
$printerName = "Smartlegen Printer Uranienborg HP M479fdw" # Printer display name
# Do not modify these variables
$portExists = Get-Printerport -Name $portname -ErrorAction SilentlyContinue
$printerExists = Get-Printer -Name $printerName -ErrorAction SilentlyContinue
######################
#   REMOVE SCRIPT   #
######################
# Remove Printer Port
if ($portExists) {
  Remove-PrinterPort -Name $portName -ComputerName $env:computername
}
# Remove Printer
if ($printerExists) {
Remove-Printer -Name $printerName
}
