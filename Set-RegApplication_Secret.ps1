# Connect to Microsoft Graph with the required permissions
Connect-MgGraph -Scopes "Application.ReadWrite.All"
#Variables
$appId = "0f7a0cdf-5fd3-4e12-8e54-ef30fdc0f436"
$oldAppCredentialId = Get-AzADAppCredential -ApplicationId $appId
$startDate = Get-Date
$endDate = $startDate.AddMonths(3)
# Export the old application credentials to a CSV file with a timestamped filename
$oldAppCredentialId | Export-Csv -Path C:\temp\OldAppCredentials.csv -NoTypeInformation
$filepath = "C:\temp\OldAppCredentials.csv"
$basename = (Get-Item $filepath).BaseName
$extension = (Get-Item $filepath).Extension
$newName = "$basename-$(Get-Date -Format 'yyyyMMddHHmmss')$extension"
Rename-Item -Path $filepath -NewName $newName
# Create a new application secret
Get-AzADApplication -ApplicationId $appId | New-AzADAppCredential -StartDate $startDate -EndDate $endDate
# Remove the old application secret
Get-AzADApplication -ApplicationId $appId | Remove-AzADAppCredential -ObjectId $oldAppCredentialId.Id
# Disconnect from Microsoft Graph
Disconnect-MgGraph