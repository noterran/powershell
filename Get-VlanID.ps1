# This script retrieves and displays the VLAN ID of all network adapters on the system.
# Usage: Run the script in a PowerShell environment with appropriate permissions.
# Output: The VLAN ID(s) of the network adapters will be printed to the console.
# Note: Ensure that the system has network adapters configured with VLANs for this script to return meaningful results.

Get-NetAdapter | Format-List -Property VlanID