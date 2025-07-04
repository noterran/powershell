#Connects to exchange online and sets customattribute1 for users in a CSV file
Connect-ExchangeOnline

#Creates arrays to hold users that were skipped or failed
$SkippedUsers = @()
$FailedUsers = @()

#edits department and customattribute 1 for users in a CSV file
#CSV file should have a header with UserPrincipalName, customattribute1 and department
$CSVrecords = Import-Csv "C:\Users\Ole.Anders.Herland\OneDrive - Marcello Consulting AS\Skrivebord\KantarellenansatteCustom1.csv" -Delimiter ","
foreach($CSVrecord in $CSVrecords ){
    $upn = $CSVrecord.UserPrincipalName
    $user = Get-Mailbox -Filter "userPrincipalName -eq '$upn'"  
    if ($user) {
        try{
        $user | Set-User -Department $CSVrecord.department -Confirm:$false
        
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
Disconnect-ExchangeOnline