Import-Module ExchangeOnlineManagement

$username = Read-Host -Prompt "Enter your admin UPN:"
$dynamicGroup = Read-Host -Prompt "Enter the Dynamic Distribution Group email address:"

Connect-ExchangeOnline -UserPrincipalName $username -ShowProgress $true

Set-DynamicDistributionGroup -Identity $dynamicGroup -ForceMembershipRefresh

Disconnect-ExchangeOnline -Confirm:$false