# we might as well create a share (this obviously requires administrative rights)
# http://ilovepowershell.com/2012/09/19/create-network-share-with-powershell-3/

$directory = "C:\Users\Sven\Desktop\LB"
Remove-Item $directory -Force -Recurse -ErrorAction SilentlyContinue
New-Item $directory -type directory
Remove-SmbShare -Name "LB" -Force -ErrorAction SilentlyContinue
New-SmbShare -Name "LB" -Path $directory `
    -FullAccess sven