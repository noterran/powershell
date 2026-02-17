#Get the computer name from the user
Write-Host "Input the computer name and press enter"
$ComputerName = Read-Host

# Get all groups that the computer is a member of
$allGroups = Get-ADPrincipalGroupMembership -Identity $ComputerName |
    Select-Object Name, SamAccountName, DistinguishedName

$allGroups | Export-Csv -Path "C:\Temp\$ComputerName-GroupMembership.csv" -NoTypeInformation



# Set the computer name (SAMAccountName)
$ComputerName = "COMPUTER1$"

# Create DirectorySearcher
$Searcher = New-Object System.DirectoryServices.DirectorySearcher
$Searcher.Filter = "(&(objectClass=computer)(sAMAccountName=$ComputerName))"
$Searcher.PropertiesToLoad.Add("memberOf") | Out-Null

# Run the query
$Result = $Searcher.FindOne()

if ($Result -ne $null) {
    $Groups = $Result.Properties["memberOf"]

    Write-Host "Groups for $ComputerName:`n"
    foreach ($g in $Groups) {
        Write-Host $g
    }
} else {
    Write-Host "Computer not found in Active Directory."
}
