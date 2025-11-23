$serverName = Read-Host -Prompt "Enter the server name or IP address"
$portNumber = Read-Host -Prompt "Enter the port number to test"
New-Object System.Net.Sockets.TCPClient -ArgumentList $serverName,$portNumber>
$null
#If the port is open, you will see no output. If the port is closed, you will see an error message.
if ($?) {
    Write-Host "Port $portNumber on $serverName is open."
} else {
    Write-Host "Port $portNumber on $serverName is closed or unreachable."
}
