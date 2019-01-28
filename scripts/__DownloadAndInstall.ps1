# download software and install it

$src = "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=de"
$dst = "C:\tmp\"

Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $dst -Force -ItemType directory

$client = new-object System.Net.WebClient
$client.DownloadFile($src,$dst+"Firefox.exe")

Write-Host "waiting for download to finish " -NoNewLine
while ($client.IsBusy){

    Write-Host "." -NoNewLine    
    Start-Sleep -s 1
}

dir $dst