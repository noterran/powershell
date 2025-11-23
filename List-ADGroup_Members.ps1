#populate variables
Write-Host "This script will create a csv file containing a list of all ENABLED members of an AD group. You can select from 1 to 20 attributes for each member"

Write-Host "Input the group name and press enter"
	$grpname = Read-Host
	Clear-Host

Write-Host "Input the amount of variables and press enter (the script will terminate if you input a value other than a number from 1 to 20)"
	$attributenr = Read-Host
	Clear-Host
	
#check for valid input
if($attributenr -gt 20){
	Write-Host "This is not a valid input" -ForegroundColor Red
    return
}

if($attributenr -eq 0){
	Write-Host "This is not a valid input" -ForegroundColor Red
    return
}

Write-Host "Input whether you want a list of enabled or disabled users"
	$enabledstatus = Read-Host
	Clear-Host

#initialize arrays
$attributearray = New-Object string[] $attributenr
$i = 0

#populate $attributearray with user inputs
for ($i=0
$i -lt $attributenr
$i++) 
{ 
$j = $i+1
Write-Host "Enter name of attribute $j"
$attributearray[$i] = Read-Host
}

#get the filepath where the CSV file will be saved
Write-Host "Input a valid filepath where you want the csv file to be exported to"
	$filepath = Read-Host
	Clear-Host

#indicate progress
$activity = "Exporting to CSV"
$task     = "Generating CSV file"
Write-Progress -Activity $activity -Status $task

#generate and export file
$grp = get-adgroup "$grpname" -properties members
$grp.members | Get-ADUser -Properties $attributearray | Where-Object{$_.$enabledstatus} | Select-Object $attributearray | Export-Csv -path "$filepath" -notypeinformation

#notify host that the process has completed
Clear-Host
Write-Host "The csv file for $grpname has been saved to $filepath"