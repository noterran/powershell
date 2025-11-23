Import-Module ExchangeOnlineManagement

$username = Read-Host -Prompt "Enter your admin UPN:"
$dynamicGroup = Read-Host -Prompt "Enter the name for your newDynamic Distribution Group:"
$recipients = Read-Host -Prompt "Enter the recipient qualifiers (e.g., 'MailboxUsers'):"
$conditions = Read-Host -Prompt "Enter the conditions for the group (e.g., 'Department' values separated by commas):"

Connect-ExchangeOnline -UserPrincipalName $username -ShowProgress $true

New-DynamicDistributionGroup -Name "$dynamicGroup" -IncludedRecipients "$recipients" -ConditionalDepartment "$conditions"

Disconnect-ExchangeOnline -Confirm:$false