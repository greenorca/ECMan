Get-ChildItem "Desktop" | Foreach-Object { 
  Write-Host $_.FullName 
  
 }
 
 Get-ChildItem "Desktop" | Foreach-Object { 
    
    Write-Host $_.FullName "::"  $_.PSIContainer
    
} 


# create random dummy files (requires admin rights)

for /l %x in (1, 1, 100) do (
echo %x
fsutil file createnew filename_%x 10000
)