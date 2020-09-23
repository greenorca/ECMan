# copy local Desktop folder remote directory
# first, map network share to drive x:, then copy from x to Desktop

$src="$src$"
$dst="$dst$"

$server_user = "$server_user$"
$server_pwd = "$server_pwd$"
$candidate = "$candidateName$"
$module ="$module$"
$domain = "$domain$"

$dst=$dst.replace('#', '\').replace('smb:','').replace('/','\').trim()

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
        $message = "Cannot map network (copy back to server): "
        $message += $Error[0].Exception.Message
        throw [System.IO.FileNotFoundException]::new($message)
    }
	$dirPath = "x:\"+$module+"\"
	New-Item -Path $dirPath -ItemType directory -ErrorAction SilentlyContinue
	$destDirectory = $dirPath+$candidate
	New-Item -Path $destDirectory -ItemType directory -ErrorAction SilentlyContinue
	
	# use 7Zip if installed because it is faster and POSIX compatible
	if (Test-Path 'C:\Programme\7-Zip\7z.exe'){
		$env:Path = "C:\Programme\7-Zip;$env:Path"
		$zipFile = "C:\desktop_"+$candidate+".zip"
		7z a -tzip $zipFile $src
		if ( $LASTEXITCODE -ne 0 ) {
		    $message =  "Crashed compressing result files"
			throw [System.IO.FileNotFoundException]::new($message)
		}
		$destDirectory += "\"
		Move-Item -Path $zipFile -Destination $destDirectory -Force
	}

	else {
	    $message = "Crashed retrieving result files. Please install 7Zip";
		throw [System.IO.FileNotFoundException]::new($message)
	}

	if ($Error[0].Exception.Messsage){
	    $message = "Crashed copying files back to server: "+$Error[0].Exception.Message
        throw [System.IO.FileNotFoundException]::new($message)
    }
	    
	net use * /delete /y
	
	$file = 'c:\Users\winrm\ecman.json';
	if (Get-Item $file 2> $null) { Write-Host "File found, OK" } 
	else { Write-Host "Status file not found"; exit; }
	$json=ConvertFrom-Json -InputObject (Gc $file -Raw) 

	$d = date;
	if ($json.PSObject.Properties.Name -notcontains "last_update") { 
		$json | Add-Member NoteProperty -Name "last_update" -Value "$d" } 
	else  { $json.last_update="$d" }

    if ($json.PSObject.Properties.Name -notcontains "lb_dst") { 
		$json | Add-Member NoteProperty -Name "lb_dst" -Value "$dst" } 
	else  { $json.lb_dst="$dst" }

    if ($json.PSObject.Properties.Name -notcontains "client_state") { 
		$json | Add-Member NoteProperty -Name "client_state" -Value "STATE_FINISHED" } 
	else  { $json.client_state="STATE_FINISHED" }
    
    $json | ConvertTo-Json | Out-File $file
    	
	Write-Host "SUCCESS"
}
catch {
	Write-Host $_.Exception.Message
}