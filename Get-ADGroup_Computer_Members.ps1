import-mobule ActiveDirectory
#Get the computer name from the user
Write-Host "Input the computer name and press enter"
$ComputerName = Read-Host

$computerDN = Get-ADComputer -Filter { sAMAccountName -eq $env:COMPUTERNAME } | Select-Object DistinguishedName

# Get all groups that the computer is a member of
$allGroups = Get-ADPrincipalGroupMembership -Identity $ComputerDN |
    Select-Object Name, SamAccountName, DistinguishedName

$allGroups | Export-Csv -Path "C:\Temp\$ComputerName-GroupMembership.csv" -NoTypeInformation