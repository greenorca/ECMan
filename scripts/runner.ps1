# sample LB deployment script
# unzips all zip files in this directory to users HOME directory 
# and removes these ZIP files after extraction
# creates a Desktop shortcut 
# removes itself
# USAGE: dump this file (or your own custom script with the same name!) 
# in the exam directory
# will be executed automatically on each client as part of the deployment process 

$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path

Set-Location -Path $ScriptDir

Write-Host $ScriptDir

foreach ($zipfile in (Get-ChildItem -Path $ScriptDir | Where { $_.Name -match "zip" })){ 
    Write-Host $zipfile 
    Expand-Archive $zipfile (Get-Item -Path $ScriptDir ).Parent.Parent.FullName -Force
    Remove-Item $zipfile -Force
    }
    
# create a shortcut to eclipse
$objShell = New-Object -ComObject ("WScript.Shell")
$objShortCut = $objShell.CreateShortcut("C:\Users\student\Desktop\" + "\Eclipse.lnk")
$objShortCut.TargetPath="C:\Users\student\eclipse\eclipse.exe"
$objShortCut.Save()
    
# remove this very script
Remove-Item $MyInvocation.InvocationName