# 
# cleans all non-system files in users home
# except those whitelisted
# created by Sven Schirmer

$whitelist="Desktop","zeal-portable","eclipse"

$user="$candidate$"

$path="C:\Users\"+$user+"\"

if ( $path -eq "C:\Users\" ){
	exit -1
}

# cleanup folder contents (only for visible folders)
foreach ($folder in Get-ChildItem -Path $path | Where { ($_.Name -notmatch "^\."  -AND $_.Name -notin $whitelist) } ){
    Write-Host "Cleaning up "$folder.name 
    Remove-Item $folder\* -Recurse -Force -ErrorAction SilentlyContinue;
}

# clean additional non-system files in users home directory
Get-ChildItem -Path $path | Where { Test-Path $_ -PathType Leaf } | Remove-Item;

# remove all items from desktop that are no links /* Test-Path $_ -PathType Leaf ) -AND */ 
Get-Item -Path $path"Desktop\*" | Where { ($_.Name -notmatch ".lnk") } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue;