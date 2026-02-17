import-mobule ActiveDirectory
#Get the computer name from the user
Write-Host "Input the computer name and press enter"
$ComputerName = Read-Host

# Get all groups that the computer is a member of
$allGroups = Get-ADPrincipalGroupMembership -Identity $ComputerName |
    Select-Object Name, SamAccountName, DistinguishedName

$allGroups | Export-Csv -Path "C:\Temp\$ComputerName-GroupMembership.csv" -NoTypeInformation