# copy remote directory into local Desktop folder
# first, map network share to drive x:, then copy from x to Desktop
# actual network resource replaces $src$ (triggered by python) 
# run runner.ps1 in LB directory if exists

$src="$src$"
$dst="$dst$"
$server_user = "$server_user$"
$server_pwd = "$server_pwd$"
$domain = "$domain$"

$src=$src.replace('#', '\')
$src=$src.replace('/', '\')
$src=$src.replace('smb:','').trim()

echo $src

Try {
    $Error.Clear()
	Remove-PSDrive -Name x -ErrorAction Ignore
    $Error.Clear()
    #net use x: $src /user:$server_user $server_pwd

    $pwd = ConvertTo-SecureString -String $server_pwd -AsPlainText -Force
    if (! $domain -eq "") { $server_user = $domain + "\" + $server_user }; Write-Host $server_user 
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

    Write-Host "Source: " $src
    Write-Host "Dest: " $dst
    $Error.Clear()

    Copy-Item -Path "x:\*" -Destination $dst -Recurse -Force
    
    if ($Error[0].Exception.Message)
    {
        throw [System.IO.FileNotFoundException]::new("Cannot copy: "+$Error[0].Exception.Message)
    }
    $mypath=$dst+$src.split("\")[-1]+"\runner.ps1"
    Write-Host "executing " $mypath
    if (Test-Path $mypath) { Invoke-Expression $mypath }
    
    Remove-PSDrive -Name x -ErrorAction Ignore
	
    # update status file
    $file = 'c:\Users\winrm\ecman.json';
	$json=ConvertFrom-Json -InputObject (Gc $file -Raw) 

	$d = date;
	if ($json.PSObject.Properties.Name -notcontains "last_update") { 
		$json | Add-Member NoteProperty -Name "last_update" -Value "$d" } 
	else  { $json.last_update="$d" }

    if ($json.PSObject.Properties.Name -notcontains "lb_src") { 
		$json | Add-Member NoteProperty -Name "lb_src" -Value "$src" } 
	else  { $json.lb_src="$src" }

    if ($json.PSObject.Properties.Name -notcontains "client_state") { 
		$json | Add-Member NoteProperty -Name "client_state" -Value "STATE_DEPLOYED" } 
	else  { $json.client_state="STATE_DEPLOYED" }
    
    $json | ConvertTo-Json | Out-File $file

    Write-Host "SUCCESS"
}
Catch {
    Write-Host "ERROR copying files from network share to client: " $_.Exception.Message
    break;
}
