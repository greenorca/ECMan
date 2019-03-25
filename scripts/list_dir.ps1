Get-ChildItem "Desktop" | Foreach-Object { 
  Write-Host $_.FullName 
  
 }
 
 Get-ChildItem "Desktop" | Foreach-Object { 
    
    Write-Host $_.FullName "::"  $_.PSIContainer
    
} 
 