#Connects to exchange online and sets customattribute1 for users in a CSV file
#Connect-ExchangeOnline

#Creates arrays to hold users that were skipped or failed
$SkippedUsers = @()
$FailedUsers = @()

#Edits customattribute1 for users in a CSV file
#CSV file should have a header with UserPrincipalName and customattribute1
$CSVrecords = Import-Csv "C:\Users\Ole.Anders.Herland\OneDrive - Marcello Consulting AS\Skrivebord\test.csv" -Delimiter ","
foreach($CSVrecord in $CSVrecords ){
    $upn = $CSVrecord.UserPrincipalName
    $user = Get-Mailbox -Filter "userPrincipalName -eq '$upn'"  
    if ($user) {
        try{
        $user | Set-Mailbox -customattribute1 $CSVrecord.customattribute1
        
        } catch {
        $FailedUsers += $upn
        Write-Warning "$upn user found, but FAILED to update customattribute1."
        }
    }
    else {
        Write-Warning "$upn not found, skipped updating customattribute1"
        $SkippedUsers += $upn
    }
}

foreach($CSVrecord in $CSVrecords ){
    $upn = $CSVrecord.UserPrincipalName
    $user = Get-Mailbox -Filter "userPrincipalName -eq '$upn'"  
    if ($user) {
        try{
        $user | Set-User -Department $CSVrecord.department
        
        } catch {
        $FailedUsers += $upn
        Write-Warning "$upn user found, but FAILED to update department."
        }
    }
    else {
        Write-Warning "$upn not found, skipped updating department"
        $SkippedUsers += $upn
    }
}
