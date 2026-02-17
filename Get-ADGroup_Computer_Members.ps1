import-module ActiveDirectory
# Get the computer name from the user
Write-Host "Input the computer name and press enter"
$ComputerName = Read-Host

$ComputerDN = Get-ADComputer -Identity "$ComputerName" | Select-Object DistinguishedName

$originalString = "$computerDN"
$charsFromStart = 20 
$charsFromEnd = 1

$newLength = $originalString.Length - $charsFromStart - $charsFromEnd

$cleanComputerDN = $originalString.Substring($charsFromStart, $newLength)

# Get all groups that the computer is a member of
$allGroups = Get-ADPrincipalGroupMembership -Identity "$cleanComputerDN" |
    Select-Object Name

$allGroups | Export-Csv -Path "C:\temp\$computerName-GroupMembership.csv" -NoTypeInformation
write-host Result can be found in "C:\temp\$computerName-GroupMembership.csv"