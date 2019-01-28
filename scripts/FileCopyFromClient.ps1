# copy local Desktop folder remote directory
# first, map network share to drive x:, then copy from x to Desktop
# actual network resource replaces $dst$ (triggered by python) 
# see full help: https://ss64.com/ps/copy-item.html

$src="$src$"
$dst="$dst$"

$dst=$dst.replace('#', '\').trim()
echo $dst

net use x: $dst /user:$server_user$

# Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path x:\$module$ -ItemType directory
New-Item -Path x:\$module$\$candidateName$ -ItemType directory
Copy-Item -Path $src -Destination x:\$module$\$candidateName$ -Recurse -Force

net use x: /delete
