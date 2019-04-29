# 
# cleans all non-system files in users home
# created by Sven Schirmer

$user="$candidate$"

$path="C:\Users\"+$user+"\*"

if ( $path -eq "C:\Users\*" ){
	exit -1
}

# cleanup folder contents (only for visible folders)
foreach ($folder in get-item -Path $path | Where { ($_.Name -notmatch "^\."  -AND $_.Name -notmatch "^zeal-portable"  -AND $_.Name -notmatch "^eclipse") } ){
    Write-Host "Cleaning up "$folder.name 
    Remove-Item $folder\* -Recurse -Force -ErrorAction SilentlyContinue;
}

# clean additional non-system files in users home directory
Get-Item -Path $path | Where { Test-Path $_ -PathType Leaf } | Remove-Item;