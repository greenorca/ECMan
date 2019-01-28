#!/usr/bin/python3

from winrm.protocol import Protocol
from winrm import Session
from threading import Thread
import socket

user = "winrm"
passwd = "Remote0815"

class ScannerThread(Thread):
    '''
    scanning thread; see https://stackoverflow.com/questions/26174743/making-a-fast-port-scanner
    '''
    def __init__(self, ip, port, timeout=5):
        Thread.__init__(self)
        self.ip = ip
        self.port=port
        self.done=-1
        self.timeout=timeout
    
    def run(self):
        TCPsock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        TCPsock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        TCPsock.settimeout(self.timeout)
        try:
            #sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            #print("scanning "+self.ip)
            TCPsock.connect((self.ip, self.port))
            print("done scanning "+self.ip)         
            self.done=1
        except Exception as ex:
            #print("crashed scanning IP {} because of {}".format(self.ip, ex))
            pass

def scanIpRange(ipRange="192.168.0.*", port=5986):
    '''
    scans all ips in range (e.g. 192.168.0.*) if port 5986 is open,
    returns array of tupels (ip,status) for each successful connection        
    '''        
    result = []
    threads = []
    for i in range(254):       
        remote_ip = ipRange.replace("*",str(i+1))
        tScanner = ScannerThread(remote_ip, port)
        tScanner.start()
        threads.append(tScanner)
        #Thread.sleep(10)
    
    for t in threads:
        t.join()
        print(".", end="", flush=True)
        result.append((t.ip, t.done))
    
    return result

def runRemoteCommand(ip="192.168.0.111", command="ipconfig", params=['/all']):
    '''
    try to run a regular cmd program with given parameters on given winrm-host (ip)
    just prints std_out, std_err and status
    '''
    p = Protocol(
        endpoint='https://' + ip + ':5986/wsman',
        transport='basic',
        username=user,
        password=passwd,
        server_cert_validation='ignore')
    shell_id = p.open_shell()
    command_id = p.run_command(shell_id, command, params)
    std_out, std_err, status_code = p.get_command_output(shell_id, command_id)
    print("message: ")
    for line in str(std_out).split(r"\r\n"):
        print(line)
    print("std_err: " + str(std_err))
    print("status: " + str(status_code))
    p.cleanup_command(shell_id, command_id)
    p.close_shell(shell_id)
  
def getHostName(ip="192.168.0.111"):
    '''
    returns hostname for given ip
    '''
    p = Protocol(
        endpoint='https://' + ip + ':5986/wsman',
        transport='basic',
        username=user,
        password=passwd,
        server_cert_validation='ignore')
    shell_id = p.open_shell()
    command_id = p.run_command(shell_id, 'hostname', [])
    std_out, std_err, status_code = p.get_command_output(shell_id, command_id)
    if status_code != 0:
        print("Error: "+std_err)
        return None
    
    return std_out.decode("utf-8").replace("\r\n","")
    
def runPowerShellCommand(ip="192.168.0.111",command=""):
    '''
    run a powershell command remotely on given ip,
    just prints std_out, std_err and status  
    '''
    s = Session(ip, auth=(user, passwd))
    r = s.run_ps(command)
    print("std_out:")
    for line in str(r.std_out).split(r"\r\n"):
        print(line)
    print("status_code: " + str(r.status_code))

    
def runPowerShellScript(ip="192.168.0.111", scriptfile="FileCopy.ps1"):
    '''
    run the content of a powershell script given in scriptfile 
    remotely on ip 
    just prints std_out, std_err and status
    '''
    script=""  
    with open(scriptfile) as file:
        script = file.read()
     
    script.replace("$src$",r"\\VBOXSVR\Nextcloud\Photos\Squirrel.jpg")   
    s = Session(ip, auth=(user, passwd))
    r = s.run_ps(script)
    print("std_out:")
    for line in str(r.std_out).split(r"\r\n"):
        print(line)
    print("status_code: " + str(r.status_code))
    print("status_code: " + str(r.std_err))

  
if __name__ == "__main__":
    #===========================================================================
    # ips = scanIpRange("192.168.0.*")
    # for ip, code in ips:
    #     if code > -1:
    #         print("WinRemote open on: "+str(ip)+", code: "+str(code))
    #===========================================================================
    #runPowerShellScript(ip="192.168.0.111", scriptfile="ShowDialog.ps1")
    ip = "192.168.0.113"
    print(ip+": "+getHostName(ip))
    runPowerShellCommand(ip=ip,command="msg * 'Hoi Schnüggel'")
    runPowerShellScript(ip,"FileCopy.ps1")
    #runRemoteCommand(command="dir", params=['C:\\Users\\Sven\\Desktop\\*.jpg'])
