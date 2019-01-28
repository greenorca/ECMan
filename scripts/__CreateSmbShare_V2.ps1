New-SmbShare -Name lb-data -Path C:\Users\Sven\Desktop\LBX -FullAccess winrm

# using it (mount share)
New-PSDrive -Name x -PSProvider FileSystem -Root \\odroid\lb_share\ -Credential winrm