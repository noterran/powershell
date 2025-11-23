Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

Get-SPSite | Select-Object URL,`
@{Name="Site Owner"; Expression={$_.Owner.Email}},`
@{Name="Quota Assigned"; Expression={"{0:N2} MB" -f ($_.Quota.StorageMaximumLevel/1MB)} } ,`
@{Name="Storage Used"; Expression={"{0:N2} MB" -f ($_.Usage.Storage/1MB)}},`
@{Name="Percentage Used"; Expression={"{0:P2}" -f (   ($_.Usage.Storage/1MB) / ($_.Quota.StorageMaximumLevel/1MB ))}}`| Out-GridView -Title " Quota Report" | Export-Csv  -NoTypeInformation -Delimiter "`t" -Path "C:\Users\admoleher\Sharepoint-Quota-Report.csv"