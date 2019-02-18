# copy remote directory into local Desktop folder
# first, map network share to drive x:, then copy from x to Desktop
# actual network resource replaces $src$ (triggered by python) 
# TODO: adapt user 
# see full help: https://ss64.com/ps/copy-item.html

$src="$src$"
$dst="$dst$"
$server_user = "$server_user$"
$server_pwd = "$server_pwd$"

$src=$src.replace('#', '\')
$src=$src.replace('/', '\')
$src=$src.replace('smb:','').trim()

echo $src

Try {
    $Error.Clear()
	Remove-PSDrive -Name x
    $Error.Clear()
    #net use x: $src /user:$server_user $server_pwd

    $pwd = ConvertTo-SecureString -String $server_pwd -AsPlainText -Force
    $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $server_user, $pwd

    New-PSDrive -Name x -PSProvider FileSystem -Root $src -Credential $cred

    if ($Error[0].Exception.Message)
    {
        throw [System.IO.FileNotFoundException]::new("Cannot map network: "+$Error[0].Exception.Message)
    }
    
    # check if base directory (LB_Daten) exists
    $baseDir = $dst.substring(0,$dst.lastIndexOf("\"))
    Write-Host "BaseDir: " $baseDir
    if (![System.IO.File]::Exists($baseDir)){
	    New-Item -Path $baseDir -Force -ItemType directory
    }

    Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -Path $dst -Force -ItemType directory
    Write-Host "Source: " $src
    Write-Host "Dest: " $dst
    $Error.Clear()

    Copy-Item -Path "x:\" -Destination $dst -Recurse -Force
    
    if ($Error[0].Exception.Message)
    {
        throw [System.IO.FileNotFoundException]::new("Cannot copy: "+$Error[0].Exception.Message)
    }
    
    Remove-PSDrive -Name x
	
    # update status file
    $file = 'c:\Users\winrm\ecman.json';

    $regex='(^last_update: .* ?)';
    $d = date;
    $content = Get-Content $file
    if (!($content -match $regex)){
        Add-Content -Path $file -Value ('last_update: ' + $d+';')
    } else {
        $content -replace $regex, ('last_update: '+$d+';') | Set-Content $file
    }

    $regex='(^lb_src: .* ?)';
    $content = Get-Content $file
    if (!($content -match $regex)){
        Add-Content -Path $file -Value ("lb_src: " + $src+";")
    } else {
        $content -replace $regex, ('lb_src: '+$src+';') | Set-Content $file
    }

    $regex='(^client_state: .* ?)';
    $content = Get-Content $file
    if (!($content -match $regex)){
        Add-Content -Path $file -Value "client_state: STATE_DEPLOYED;"
    } else {
        $content -replace $regex, "client_state: STATE_DEPLOYED;" | Set-Content $file
    }

    Write-Host "SUCCESS"
}
Catch {
    Write-Host "ERROR copying files from network share to client: " $_.Exception.Message
    break;
}
