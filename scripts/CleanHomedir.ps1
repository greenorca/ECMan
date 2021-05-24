# cleans all non-system files in users home and removes files and folders from desktop
# except those whitelisted
# created by Sven Schirmer

# make sure to spare Desktop
$whitelist="Desktop","zeal-portable","eclipse","AppData","Documents"

$user="$candidate$"
$passwd = "$passwd$"

$path="C:\Users\"+$user+"\"

if ( $path -eq "C:\Users\" ){
	exit -1
}
# without "cd", script causesa lot of trouble 
cd $path

# cleanup files and folder contents (only for visible folders)
foreach ($folder in Get-ChildItem -Path $path | Where { ($_.Name -notmatch "^\."  -AND $_.Name -notin $whitelist) } ){
    Write-Host "Cleaning up "$folder.FullName 
    if ( Test-Path $folder -PathType leaf){
    	Remove-Item -Path $folder -Force -ErrorAction Continue
    }
    else {
    	Remove-Item -Path $folder\* -Recurse -Force -ErrorAction Continue
    }
}

# remove all files and folders from Desktop that are no links 
Get-Item -Path $path"Desktop\*" | Where { ($_.Name -notmatch ".lnk") } | Remove-Item -Recurse -Force  -ErrorAction Continue

# clean trashbin unfortunately doesnt work remotely
# $pwd = ConvertTo-SecureString -String $passwd -AsPlainText -Force
# $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $pwd
# Start-Process powershell.exe -ArgumentList "-Noninteractive -ExecutionPolicy Bypass Clear-RecycleBin -Force" -Credential $cred

$path = "C:\"
Get-ChildItem $Path | Where{$_.Name -Match "<RegEx Pattern>"} | Remove-Item -recurse