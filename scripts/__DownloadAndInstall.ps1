# download software and install it
$src = "https://imagemagick.org/download/binaries/ImageMagick-7.0.8-32-Q16-x64-dll.exe"
$dst = "C:\tmp"

Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $dst -Force -ItemType directory

$dst = "C:\tmp\imagemagick.exe"

#$client = new-object System.Net.WebClient
#$cli.Headers['User-Agent'] = 'myUserAgentString';
#$client.DownloadFile($src,$dst)
#$client.DownloadFile($src,$dst)

Invoke-WebRequest $src -OutFile $dst

#Write-Host "waiting for download to finish " -NoNewLine
#while ($client.IsBusy){

#    Write-Host "." -NoNewLine    
#    Start-Sleep -s 1
#}

[System.Diagnostics.Process]::Start($dst, "/VERYSILENT")