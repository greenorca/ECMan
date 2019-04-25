# copy local Desktop folder remote directory
# first, map network share to drive x:, then copy from x to Desktop
# actual network resource replaces $dst$ (triggered by python) 
# see full help: https://ss64.com/ps/copy-item.html

$src="$src$"
$dst="$dst$"

$server_user = "$server_user$"
$server_pwd = "$server_pwd$"
$domain = "$domain$"

$dst=$dst.replace('#', '\')
$dst=$dst.replace('smb:','')
$dst=$dst.replace('/','\').trim()

$maxFilesize = $maxFilesize$

echo $dst

Try{
	net use * /del /y
	$Error.Clear()
	
	$pwd = ConvertTo-SecureString -String $server_pwd -AsPlainText -Force
	if (! $domain -eq "") { $server_user = $domain + "\" + $server_user }; Write-Host $server_user 
    $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $server_user, $pwd

    New-PSDrive -Name x -PSProvider FileSystem -Root $dst -Credential $cred

    if ($Error[0].Exception.Message)
    {
        throw [System.IO.FileNotFoundException]::new("Cannot map network (copy back to server): "+$Error[0].Exception.Message)
    }
	    
	New-Item -Path x:\$module$ -ItemType directory -ErrorAction SilentlyContinue
	New-Item -Path x:\$module$\$candidateName$ -ItemType directory -ErrorAction SilentlyContinue
	
	Compress-Archive -DestinationPath x:\$module$\$candidateName$\desktop_$candidateName$.zip -Force -Path $src -ErrorAction Ignore
	#Copy-Item -Path $src -Destination x:\$module$\$candidateName$ -Recurse -Force
	
	if ($Error[0].Exception.Messsage){ 
	    	throw [System.IO.FileNotFoundException]::new("Crashed copying files back to server: "+$Error[0].Exception.Message)
	    }
	    
	net use * /delete /y
	
	$file = 'c:\Users\winrm\ecman.json';
	if (Get-Item $file 2> $null) { Write-Host "File found, OK" } 
	else { Write-Host "Status file not found"; exit; }
	
	$regex='(^last_update: .* ?)';
	$d = date;
	
	$content = Get-Content $file
	if (($content -match $regex).Length -eq 0){
	    Add-Content -Path $file -Value ('last_update: ' + $d+';')
	} else {
	    $content -replace $regex, ('last_update: '+$d+';') | Set-Content $file
	}
	
	$regex='(^lb_dst: .* ?)';
	$content = Get-Content $file
	if (($content -match $regex).Length -eq 0){
	    Add-Content -Path $file -Value ("lb_dst: " + $dst+";")
	} else {
	    $content -replace $regex, ('lb_dst: '+$dst+';') | Set-Content $file
	}
	
	$regex='(^client_state: .* ?)';
	$content = Get-Content $file
	if (($content -match $regex).Length -eq 0){
	    Add-Content -Path $file -Value "client_state: STATE_FINISHED;"
	} else {
	    $content -replace $regex, "client_state: STATE_FINISHED;" | Set-Content $file
	}
	
	Write-Host "SUCCESS"
}
catch {
	Write-Host $_.Exception.Message
}