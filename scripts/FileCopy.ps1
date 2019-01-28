# copy remote directory into local Desktop folder
# first, map network share to drive x:, then copy from x to Desktop
# actual network resource replaces $src$ (triggered by python) 
# TODO: adapt user 
# see full help: https://ss64.com/ps/copy-item.html

$src="$src$"
$dst="$dst$"

$src=$src.replace('#', '\').trim()
echo $src

net use x: $src /user:$server_user$

# check if base directory (LB_Daten) exists
$baseDir = $dst.substring(0,$file.lastIndexOf("\")) 
if (![System.IO.File]::Exists($baseDir)){
	New-Item -Path $baseDir -Force -ItemType directory
}

Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $dst -Force -ItemType directory
Copy-Item -Path $src -Destination $dst -Recurse -Force

net use x: /delete
