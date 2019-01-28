## Windows Remote Management

* requires Windows-Remoteverwaltungsdienst (WinRM) to be started and basic auth to be enabled
* WinRM in Firewall zulassen (wird NEU durchs ConfigureRemoteForAnsibleScript gemacht...)
* network connection must either be *home* or *domain* (*unknown* doesn't work, e.g.if there is no regular internet access)

* Windows configuration:

	PS C:\WINDOWS\system32> Set-ExecutionPolicy -ExecutionPolicy unrestricted
	ConfigureRemotingForAnsible.ps1
	...
    winrm set winrm/config/service/auth @{Basic="true"}
    winrm set winrm/config/service @{AllowUnencrypted="true"}
    winrm set winrm/config/client @{TrustedHosts="RemoteComputerName"}
    PS C:\WINDOWS\system32> Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true
	
* create custom SSL certificate and setup firewall rules: ConfigureRemotingForAnsible.ps1   

### Verbindung testen

* Linux: `nc -z -w1 192.168.0.114 5985;echo $?` sollte 0 ergeben (1 ist nicht gut...)
* Win PowerShell: `Test-WSMan -ComputerName 192.168.0.114` oder  `Test-WSMan -ComputerName 192.168.0.114 -UseSSL`

* siehe [http://www.hurryupandwait.io/blog/understanding-and-troubleshooting-winrm-connection-and-authentication-a-thrill-seekers-guide-to-adventure](http://www.hurryupandwait.io/blog/understanding-and-troubleshooting-winrm-connection-and-authentication-a-thrill-seekers-guide-to-adventure)

### "Nicht identifiziertes Netzwerk" Problem

* kann winrm blockieren, wenn kein internet (und damit die ganze app) 
* regedit: 
	- Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles\
	- aktuelles Netzwerk auswählen
	- Wert für "Managed" auf 1 stellen (sollte funktionieren)
	- Wert für "Category" auf 1 stellen (sollte funktionieren)
	- **macht keinen Unterschied**...


### neuer Eintrag fürs Hostfile:

`echo 192.168.0.50 odroid >> %WINDIR%\System32\Drivers\Etc\Hosts`


## Using Python and WinRM

* https://github.com/diyan/pywinrm
* `pip3 install pywinrm`

```python
import winrm

s = winrm.Session('windows-host.example.com', auth=('john.smith', 'secret'))
r = s.run_cmd('ipconfig', ['/all'])
r.status_code
>>> 0
r.std_out
>>> Windows IP Configuration

   Host Name . . . . . . . . . . . . : WINDOWS-HOST
   Primary Dns Suffix  . . . . . . . :
   Node Type . . . . . . . . . . . . : Hybrid
   IP Routing Enabled. . . . . . . . : No
   WINS Proxy Enabled. . . . . . . . : No
...
>>> r.std_err
```

* another example (that is based on the config stuff below:

```
from winrm.protocol import Protocol

p = Protocol(
    endpoint='http://192.168.0.111:5985/wsman',
#    endpoint='htts://192.168.0.111:5986/wsman',
    transport='basic',
#    transport='ntlm',
    username=r'someuser',
    password='secret',
    server_cert_validation='ignore')
shell_id = p.open_shell()
command_id = p.run_command(shell_id, 'ipconfig', ['/all'])
std_out, std_err, status_code = p.get_command_output(shell_id, command_id)
p.cleanup_command(shell_id, command_id)
p.close_shell(shell_id)

```



## Using ansible for Windows

* [https://docs.ansible.com/ansible/latest/user_guide/windows_winrm.html#what-is-winrm](https://docs.ansible.com/ansible/latest/user_guide/windows_winrm.html#what-is-winrm)
* best install ansible for Python3.x:: pip3 install ansible pywinrm    

* in linux:: /etc/ansible/hosts

```
[windows]
192.168.0.111
192.168.56.102


[windows:vars]
 ansible_user=Sven
 ansible_password=sven
 ansible_connection=winrm
 ansible_port=5985
 ansible_winrm_transport=basic

```

## running some remote command

```
ansible 192.168.0.111 -m setup
ansible 192.168.0.111 -m win_command -a "cmd /c dir c:\\"
```

## my first playbook

* test_win_copy.yaml
```yaml
---
- hosts: windows
  tasks:
  - name: Copy file task
    win_copy:
      src: /home/sven/nextcloud_error_folder_open_2018-11-20_15-46-31.png
      dest: c:\test.png
```

* run with `ansible-playbook Nextcloud/Documents/Projects/WISS_LB_Deploy/test_win_copy.yaml`