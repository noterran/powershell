#Written by: Steve Tibbetts
#Version 1.0
#This script will total all base folder sizes in the $startFolder and export that information to
#a ; delimited file.

#Set this to the target root folder
$startFolder = "D:\Data\lmi_inf_001\LMI\Common\Common\LMI"

#Set the output location and file name
$output = "D:\Data\lmi_inf_001\common_LMI.csv"

$colItems = (Get-ChildItem $startFolder | Where-Object {$_.PSIsContainer -eq $True} | Sort-Object)
$results = @()
foreach ($i in $colItems)
    {
        $i.FullName
        $subFolderItems = (Get-ChildItem $i.FullName -recurse | Measure-Object -property length -sum)
        $results += '"' +$i.FullName + '"' + ";" + "{0:N2}" -f ($subFolderItems.sum / 1MB)
    }
$results > $output