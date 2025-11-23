<#Should be performed from the server where Azure AD Connect is installed.
Step 1: Import the ADSync Module
Run the following command:
#>

Import-Module ADSync

<#
Step 2: Run the Sync Command. For a Delta Sync (most common, and used for most situations):
#>

Start-ADSyncSyncCycle -PolicyType Delta

#For a Full Sync (only necessary in some situations):

#Start-ADSyncSyncCycle -PolicyType Initial