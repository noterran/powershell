Connect-MgGraph -Scopes "Application.ReadWrite.All"
$appId = "0f7a0cdf-5fd3-4e12-8e54-ef30fdc0f436"
$oldAppCredentialId = Get-AzADAppCredential -ApplicationId $appId
$startDate = Get-Date
$endDate = $startDate.AddMonths(3)
# ApplicationId is AppId of Application object which is different from directory id in Azure AD.
Get-AzADApplication -ApplicationId $appId | New-AzADAppCredential -StartDate $startDate -EndDate $endDate
