$file = 'C:\Users\winrm\ecman.json';

Get-WMIObject Win32_Logicaldisk -filter "deviceid='$($os.systemdrive)'" -ComputerName $env:COMPUTERNAME |
Select PSComputername,DeviceID,
@{Name="SizeGB";Expression={$_.Size/1GB -as [int]}},
@{Name="FreeGB";Expression={[math]::Round($_.Freespace/1GB,2)}}

$file = 'c:\Users\winrm\ecman.json';
$regex='(^candidate_name: (?<name>[\w ]+)?)';
$content = Get-Content $file;
if ($content -match $regex){ write-host $Matches.name }
}