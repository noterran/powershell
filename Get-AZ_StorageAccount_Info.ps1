$subscription = Read-Host -Prompt "Enter your Azure Subscription Name or ID:"
Set-AzContext -Subscription $subscription
$storageAccounts = Get-AzStorageAccount
$storageAccounts | Select-Object ResourceGroupName, StorageAccountName, MinimumTlsVersion | Format-Table -AutoSize