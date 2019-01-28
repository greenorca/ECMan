
# observe firewall rules (omg):
Get-NetFirewallRule | Where-Object {$_.Name -like '*http*'}


# conditional...
$r = Get-NetFirewallRule -DisplayName 'Block Http' 2> $null; 
if ($r) { write-host "found it"; } 
else { write-host "did not find it" }

#https://sid-500.com/2017/12/11/configuring-windows-firewall-with-powershell/

New-NetFirewallRule -Name "AllowWinRM" -DisplayName "AllowWinRM" -Enabled 1 -Direction Inbound -Action Allow -LocalPort 5985 -Protocol TCP
New-NetFirewallRule -Name "AllowWinRM_Secure" -DisplayName "AllowWinRM_Secure" -Enabled 1 -Direction Inbound -Action Allow -LocalPort 5986 -Protocol TCP

# Problem is, that local administrators can easily disable firewall. possible solution: demote student to power-user

New-NetFirewallRule -Name "Block HTTP" -DisplayName "Block HTTP" -Enabled 1 -Direction Outbound -Action Block -RemotePort 80 -Protocol TCP
New-NetFirewallRule -Name "Block HTTPS" -DisplayName "Block HTTPS" -Enabled 1 -Direction Outbound -Action Block -RemotePort 443 -Protocol TCP
New-NetFirewallRule -Name "Block DNS" -DisplayName "Block DNS" -Enabled 1 -Direction Outbound -Action Block -RemotePort 53 -Protocol UDP

Remove-NetFirewallRule -DisplayName "Block HTTP" 
Remove-NetFirewallRule -DisplayName "Block HTTPS"
Remove-NetFirewallRule -DisplayName "Block DNS" 
 

Set-NetFirewallRule -DisplayName "World Wide Web Services (HTTP Traffic-In)" -Enabled false

Set-NetFirewallRule -DisplayName "Block HTTP" -Enabled false
Set-NetFirewallRule -DisplayName "Block HTTPS" -Enabled false

Set-NetFirewallRule -DisplayName "Block HTTP" -Action Block
Set-NetFirewallRule -DisplayName "Block HTTPS" -Action Block


/* doing the same with cmd:

netsh advfirewall firewall add rule name="BlockHTTP" protocol=TCP dir=OUT remoteport=80 action=block
netsh advfirewall firewall add rule name="BlockHTTPS" protocol=TCP dir=OUT remoteport=443 action=block
netsh advfirewall firewall add rule name="BlockDNS" protocol=UDP dir=OUT remoteport=53 action=block

netsh advfirewall firewall reset


# doesn't work at all:
# netsh advfirewall firewall add rule name="BlockAllTcp" protocol=TCP dir=OUT localport=1-50000 action=block
# netsh advfirewall firewall add rule name="BlockAllUdp" protocol=UDP dir=OUT localport=1-50000 action=block

# netsh advfirewall firewall delete rule name="BlockAllTcp"
# netsh advfirewall firewall delete rule name="BlockAllUdp"

*/