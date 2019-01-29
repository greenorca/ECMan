from winrm.protocol import Protocol
from winrm import Session
from base64 import b64encode
import time, re
#import socket, shutil
from enum import Enum

#from base64 import *

'''
Created on Dec 25, 2018

@author: sven
'''
class File:
    def __init__(self, name: str, isDir: bool, size=None, date=""):
        '''
        create a new file
        '''
        self.name = name.replace("\\","/")
        self.size = size
        self.date = date
        self.isDirectory = isDir
        if self.isDirectory:
            self.children=[]
        
    def addChild(self, child):
        if not(self.isDirectory):
            raise Exception("cannot add children to regular file")
        if type(child) == File: 
            self.children.append(child)
            
    def getSubFolder(self,name: str):
        '''
        finds and returns subfolder for give name
        '''
        subfolders = [f for f in self.children if f.isDirectory]
        result = [f for f in subfolders if f.name.split("/")[-1]==name]
        if len(result)>0 and result[0]!=[]:
            return result[0]
        result = [f.getSubFolder(name) for f in subfolders]
        return result

class Computer(object):
    '''
    class to administer instances of computers
    '''
    class State(Enum):
        '''
        enumeration of various computer states
        '''
        STATE_INIT = 0
        STATE_DEPLOYED = 1
        STATE_FINISHED = 2
        STATE_IN_PROGRESS = 3
        STATE_UNKNOWN = -1
        STATE_COPY_FAIL = -2
        STATE_RETRIVAL_FAIL = -3
        
        
    
    def __init__(self, ipAddress, user, passwd, fetchHostname=False):
        '''
        Constructor
        '''
        self.debug=True
        self.ip = ipAddress
        self.user = user
        self.passwd = passwd
        self.state = Computer.State.STATE_INIT
        self.hostname = "--unknown--"
        self.STATUS_OK = 0
        
        self.lb_dataDirectory = ""
        self.lb_files = None
        self.remoteFileListing = ""
        self.last_sync = time.time()
        self.minSynTime = 5
        self.filepath=""
        self.candidateName = ""
        self.defaultLogin = "Sven" # assuming one standard login for all client pcs (usually student/student)
        
        self.__usbBlocked = "unbekannt"
        self.__internetBlocked = "unbekannt"
        
        if fetchHostname==True:
            try:
                self.hostname = self.getHostName()
            except Exception as ex:
                print("Couldn't get hostname: %s".format(str(ex)))
            pass
    
    def __runRemoteCommand(self,command="ipconfig", params=['/all']):
        '''
        try to run a regular cmd program with given parameters on given winrm-host (ip)
        just prints std_out, std_err and status
        '''
        print(command+", "+str(params))
        p = Protocol(
            endpoint='https://' + self.ip + ':5986/wsman',
            transport='basic',
            username=self.user,
            password=self.passwd,
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
        return status_code
     
    def sendMessage(self, message = ""):
        '''
        opens a little popup window on client computer
        '''
        if message == "" or type(message) != str:
            message="Verbindungstest Kandidat: "+self.getCandidateName()
        else:
            message = self.candidateName + ":: "+message
            
        p = Protocol(
            endpoint='https://' + self.ip + ':5986/wsman',
            transport='basic',
            username=self.user,
            password=self.passwd,
            server_cert_validation='ignore')
        
        shell_id = p.open_shell()
        
        command_id = p.run_command(shell_id, "msg", [r"*", message])
        std_out, std_err, status_code = p.get_command_output(shell_id, command_id)
        
        if self.debug:
            print(std_out)
            print(std_err)
            
        return status_code
            
    def getRemoteFileListing(self):
        '''
        reads remote LB-Daten directory
        returns nicely formatted HTML list
        '''
        if self.state != Computer.State.STATE_DEPLOYED and self.state != Computer.State.STATE_FINISHED:
            return "Not yet deployed: "+self.state.name
        
        if time.time() - self.last_sync > self.minSynTime or self.remoteFileListing=="":
            p = Protocol(
                endpoint='https://' + self.ip + ':5986/wsman',
                transport='basic',
                username=self.user,
                password=self.passwd,
                server_cert_validation='ignore')
            
            shell_id = p.open_shell()
            lbFileRoot = r"C:\Users\\"+self.defaultLogin +r"\Desktop\LB_Daten" 
            command_id = p.run_command(shell_id, "dir", [lbFileRoot, "/S"])
            std_out, std_err, status_code = p.get_command_output(shell_id, command_id)
            
            p.cleanup_command(shell_id, command_id)
            p.close_shell(shell_id)
            
            print(std_out)
            self.lb_files = File(lbFileRoot, True)
            currentDir = self.lb_files
            
            if status_code == self.STATUS_OK:
                self.last_sync = time.time()
                remoteFiles = std_out.decode("850") # important codepage, utf8 doesn't work for umlauts
                remoteFiles = remoteFiles[remoteFiles.find("Verzeichnis"):] # cut the first few lines
                lines = remoteFiles.split("\r\n")
                self.remoteFileListing = "<h4>Dateien</h4><ul>\n"
                for line in lines[:-4]:
                    file=None
                    if len(line)>0 and not(line.endswith(".")):
                        file = self.parseFile(line)
                        if type(file) == File:
                            file.name = currentDir.name+"/"+file.name
                            currentDir.addChild(file)
                        elif type(file) == str and not(currentDir.name.endswith(file)):
                            currentDir = currentDir.getSubFolder(file)
                            if currentDir==[]:
                                currentDir = self.lb_files.getSubFolder(file)
                                if type(currentDir)==list and len(currentDir)>0:
                                    currentDir = [x for x in currentDir if x != []]
                                    currentDir = currentDir[0]
                            
                        if line.find("<DIR>") < 0:       
                            self.remoteFileListing+="<li>"+line.replace("Verzeichnis von ","")+"</li>\n"
                        
                self.remoteFileListing+="</ul>"    
            else:
                return std_err
            
        return self.remoteFileListing
    
    def parseFile(self, line):
        '''
        turn a line (like this one: 07.01.2019 15:59 23 local_client_test.txt)
        from windows-dir command into a file object
        returns String for subdirectories (that should have been created before) e.g. "Verzeichnis von C:\\Users\\Sven\\Desktop\<<<\\\LB_Daten\\M104\\sub2"
        or None if a line did not matter ()e.g.  " 1 Datei(en), 28 Bytes"
        '''
        match=re.match("^(?P<date>[0-9]{2}\.[0-9]{2}\.[0-9]{4})\s+(?P<time>[0-9]{2}:[0-9]{2})\s+(?P<size>[0-9]+)\s+(?P<name>\S+)",line)
        if match and match.group("name")!="":
            file = File(match.group("name"), isDir=False, size=match.group("size"), date=match.group("date")+" "+match.group("time"))
            return file
        if line.find("<DIR>")>-1 and not(line.endswith(".")):
            name=line.split(" ")[-1] # directory name is last thing in line, e.g. "13.01.2019  18:44    <DIR>          sub1"
            file = File(name, isDir=True)
            return file
        if line.find("Verzeichnis von")>-1:
            return line.split("\\")[-1] 
        
        return None
    
    def disableUsbAccess(self, block=True):
        '''
        block or unblock usb access for usbsticks etc
        PARAM block =True blocks, block=False reenables access
        https://redmondmag.com/articles/2017/06/27/prevent-the-use-of-usb-media-in-windows-10.aspx
        set HKLM:\\SYSTEM\CurrentControlSet\\Services\\USBSTOR\\Start
        4: blocks; 3 unblocks
        '''
        psCommand = 'Set-ItemProperty -Path "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\USBSTOR\\" -Name Start -Value '+ str(4 if block==True else 3) 
        std_out, std_err, status = self.runPowerShellCommand(psCommand) 
        
        if status != self.STATUS_OK:
            print("Error: "+std_err)
            return False
        
        self.__usbBlocked = True if std_out.rstrip()=="4" else False
        return True
        
    
    def isUsbBlocked(self):
        '''
        reads blocking status of this client (from registry)
        and returns USB-ENABLED or USB-BLOCKED
        '''
        psCommand = 'Get-ItemPropertyValue -Path "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\USBSTOR\\" -Name Start'
        std_out, std_err, status = self.runPowerShellCommand(psCommand)
        
        if status != self.STATUS_OK:
            print("Error: "+std_err)
            self.__internetBlocked = "unbekannt"
            return self.__internetBlocked
        
        self.__usbBlocked = True if std_out.rstrip()=="4" else False
                        
        return self.__usbBlocked
     
    def allowInternetAccess(self):
        return self.blockInternetAccess(block=False)
     
    def blockInternetAccess(self, block = True):
        '''
        blocks or unblocks web access on client machine,
        returns True if commands were successful, False in case of errors
        '''
        blockList = [
            {"name":"Block Http", "port": 80, "protocol": "TCP"},
            {"name":"Block Https", "port": 443, "protocol": "TCP"},
            {"name":"Block Dns", "port": 53, "protocol": "UDP"},
            ]
        
        script = []
        if block==False:
            for entry in blockList:
                command='$r = Get-NetFirewallRule -DisplayName "{0}" 2> $null; if ($r) { Remove-NetFirewallRule -DisplayName "{0}" } else { write-host "Rule exists, noting to do" }'
                command = command.replace("{0}",entry['name'])
                script.append(command)
                
        else:            
            for entry in blockList:
                command='$r = Get-NetFirewallRule -DisplayName "{0}" 2> $null; if ($r) { write-host "Rule exists, noting to do" } else { New-NetFirewallRule -Name "{0}" -DisplayName "{0}" -Enabled 1 -Direction Outbound -Action Block -RemotePort {1} -Protocol {2} }'
                command = command.replace("{0}",entry['name'])
                command = command.replace("{1}", str(entry['port']))
                command = command.replace("{2}", entry['protocol'])
                script.append(command)
            
        p = Protocol(
            endpoint='https://' + self.ip + ':5986/wsman',
            transport='basic',
            username=self.user,
            password=self.passwd,
            server_cert_validation='ignore')
    
        shell_id = p.open_shell()
        
        for line in script:
            print("running: "+line)
            encoded_ps = b64encode(line.encode('utf_16_le')).decode('ascii')
            command_id = p.run_command(shell_id, 'powershell -encodedcommand {0}'.format(encoded_ps), [])
            std_out, std_err, status_code = p.get_command_output(shell_id, command_id)
            if status_code!=self.STATUS_OK:
                break
        
        p.cleanup_command(shell_id, command_id)
        p.close_shell(shell_id)
        
        if self.debug:
            print("std_out:")
            for line in str(std_out).split(r"\r\n"):
                print(line)
            
        if status_code!=self.STATUS_OK:            
            print("status_code: " + str(status_code))
            print("error_code: " + str(std_err))
            self.__internetBlocked = "unbekannt"
            return False
        
        self.__internetBlocked = block
        return True
     
    def isInternetBlocked(self):
        return self.__internetBlocked
     
    def isFirewallServiceEnabled(self):
        '''
        tests if windows defender firewall service is enabled for all network profiles
        '''
        testCommand = 'Get-NetFirewallProfile | Where-Object {$_.Enabled -ne "true"}'
        std_out, std_err, status = self.runPowerShellCommand(command=testCommand)
        
        if status == self.STATUS_OK and std_out.rstrip() != "":
            print("following firewalls are not active: "+ std_out)
            return False
        
        return True
    
    def configureFirewallService(self, enable=True):
        '''
        enable or disable windows defender firewall service for all network profiles
        '''
        testCommand = 'Set-NetFirewallProfile -Enabled {}'.format(enable)
        std_out, std_err, status = self.runPowerShellCommand(command=testCommand)
        
        if status != self.STATUS_OK:
            print("error activating/deactivating firewalls: "+ std_err)
            return False
        
        return True     
            
    def testInternetBlocked(self):        
        '''
        testing web connectivity
        '''
            
        testWebConnectivityHost = "www.wiss.ch"
        textCommandPing = 'try { if (Test-Connection "$1$" -Quiet -Count 1 )  { Write-Host PING_OK } else { Write-Host PING_NOK } } catch { Write-host DNS_FAIL }'.replace('$1$', testWebConnectivityHost) 
        testCommandHttp = 'try { $client = New-Object System.Net.WebClient; $res=$client.DownloadString("http://$1$"); write-host 1} catch{ write-host -1}'.replace("$1$", testWebConnectivityHost)
        
        std_out, std_err, status = self.runPowerShellCommand(command=textCommandPing)
        if status == self.STATUS_OK and std_out.rstrip() in ["PING_NOK", "DNS_FAIL"]:
            self.__internetBlocked = True
            print("DNS is blocked")
        else:
            self.__internetBlocked = False
            print("DNS unblocked, PING ok")
    
        std_out, std_err, status = self.runPowerShellCommand(command=testCommandHttp)
        if status == self.STATUS_OK:
            if std_out == "-1":
                self.__internetBlocked = True
                print("HTTP is blocked")
            elif std_out == "1":
                self.__internetBlocked = False
                print("HTTP is unblocked")                
            
        return self.__internetBlocked        
        
        
    def setCandidateName(self,candidateName):
        '''
        sets given candidate name on remote machine 
        by writing it to a file on the users home directory
        '''
        p = Protocol(
            endpoint='https://' + self.ip + ':5986/wsman',
            transport='basic',
            username=self.user,
            password=self.passwd,
            server_cert_validation='ignore')
        shell_id = p.open_shell()
        command_id = p.run_command(shell_id, 'echo', ["["+candidateName + r"] > C:\Users\\"+self.defaultLogin +r"\candidate.md"])
        std_out, std_err, status_code = p.get_command_output(shell_id, command_id)
        
        p.cleanup_command(shell_id, command_id)
        p.close_shell(shell_id)
        
        if status_code != self.STATUS_OK:
            print("Error: "+std_err.decode("850"))
        
        self.candidateName = candidateName
        return status_code
    
    def getCandidateName(self):
        '''
        returns candidate name sitting on this client
        '''        
        p = Protocol(
            endpoint='https://' + self.ip + ':5986/wsman',
            transport='basic',
            username=self.user,
            password=self.passwd,
            server_cert_validation='ignore')
        shell_id = p.open_shell()
        command_id = p.run_command(shell_id, 'more', [r"C:\Users\\"+self.defaultLogin +r"\candidate.md"])
        std_out, std_err, status_code = p.get_command_output(shell_id, command_id)
        
        p.cleanup_command(shell_id, command_id)
        p.close_shell(shell_id)
        
        if status_code != self.STATUS_OK:
            print("Error: "+std_err.decode("850"))
            return None
        
        self.candidateName = std_out.decode("850").replace("\r\n","").replace("[","").replace("]","").rstrip()
        return self.candidateName
      
    def getHostName(self):
        '''
        returns hostname for given ip
        '''
        p = Protocol(
            endpoint='https://' + self.ip + ':5986/wsman',
            transport='basic',
            username=self.user,
            password=self.passwd,
            server_cert_validation='ignore')
        
        shell_id = p.open_shell()
        command_id = p.run_command(shell_id, 'hostname', [])
        std_out, std_err, status_code = p.get_command_output(shell_id, command_id)
        
        p.cleanup_command(shell_id, command_id)
        p.close_shell(shell_id)
        
        if status_code != self.STATUS_OK:
            print("Error: "+std_err.decode("850"))
            return None
        
        return std_out.decode("utf-8").replace("\r\n","")
        
    def runPowerShellCommand(self,command=""):
        '''
        run a powershell command remotely on given ip,
        just prints std_out, std_err and status
        returns std_out, std_err and status (0 == good) instead of True and False  
        '''
        #=======================================================================
        # s = Session(self.ip, auth=(self.user, self.passwd))
        # r = s.run_ps(command)
        # print("std_out:")
        # for line in str(r.std_out).split(r"\r\n"):
        #     print(line)
        # print("status_code: " + str(r.status_code))
        #=======================================================================
        p = Protocol(
            endpoint='https://' + self.ip + ':5986/wsman',
            transport='basic',
            username=self.user,
            password=self.passwd,
            server_cert_validation='ignore')
        
        encoded_ps = b64encode(command.encode('utf_16_le')).decode('ascii')
        shell_id = p.open_shell()
        command_id = p.run_command(shell_id, 'powershell -encodedcommand {0}'.format(encoded_ps), [])
        std_out, std_err, status_code = p.get_command_output(shell_id, command_id)
        p.cleanup_command(shell_id, command_id)
        p.close_shell(shell_id)
        return std_out.decode("850").rstrip(), std_err.decode("850").rstrip(), status_code
    
    def __copyFile2Client(self, filepath):
        '''
        doesn't work well as long as network shares are not mounted locally (and file permissions fit)
        '''
        #self.runPowerShellCommand(r'Remove-SmbShare -Name LB-DATA -Force -ErrorAction SilentlyContinue')
        #self.runPowerShellCommand(r'New-SmbShare -Name LB-DATA -PATH C:\Users\sven\Desktop\LBX -FullAccess winrm')
        #shutil.copytree(filepath, '//'+self.ip+'/LB-DATA/'+filepath.split('/')[-1])
        
        '''
        net use works, but only until session is closed...
        '''
        #self.runRemoteCommand(command="net use",params=["x:", filepath, r"/user:winrm lalelu", "/persistent:yes"])
        #self.runRemoteCommand("dir",["x:"])
        #self.runRemoteCommand(command="robocopy", params=["x:/", r"C:/Users/Sven/Desktop/LBX"])
        #self.runRemoteCommand(command=r"net use x: /delete",params=[])
        pass
        
    def deployClientFiles(self, filepath, empty=True):
        '''
        copy the content of filepath (recursively) to this client machine 
        prints std_out, std_err and status
        returns True on success, False otherwise
        '''
        if self.state == Computer.State.STATE_DEPLOYED:
            raise Exception("Client already in STATE_DEPLOYED: "+self.state.name)
            
        script=""  
        try:
            with open("scripts/FileCopy.ps1") as file:
                script = file.read()
        except Exception as ex:
            with open("../scripts/FileCopy.ps1") as file:
                script = file.read()
        
        # replace script parameters     
        script=script.replace("$src$",filepath.format('utf_16_le'))
        script=script.replace('$dst$','C:\\Users\\$user$\\Desktop\\LB_Daten\\')
        script=script.replace('$user$', self.defaultLogin)
        script=script.replace('$server_user$',r'odroid\winrm lalelu')
        
        
        # clean previous data in LB_Daten?
        if empty==False:
            script = script.replace(r"Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue","")
            script = script.replace(r"New-Item -Path $dst -Force -ItemType directory","")
        
        if self.debug:
            print("***********************************")
            print(script)
            print("***********************************")
        
        status, error = self.runCopyScript(script)

        if status == self.STATUS_OK:        
            self.lb_dataDirectory = filepath.split("\\")[-1]
            self.lb_dataDirectory = self.lb_dataDirectory.split("#")[-1]
            self.filepath = filepath
            self.state = Computer.State.STATE_DEPLOYED
            return True, "" 
        else:
            self.state = Computer.State.STATE_COPY_FAIL
            return False, error.decode("850")

    def retrieveClientFiles(self, filepath):
        '''
        copy LB-data files from this machine to destination (which has to be a writable SMB share) 
        within a folder with the candidates name that will be created on destination; 
        breaks if Computer state is not deployed or candidate name is empty
        returns True on success, False otherwise
        '''
        
        if self.candidateName=="":
            if self.getCandidateName()=="":
                raise Exception("Candidate name not set")
            
        #if self.lb_dataDirectory == "" or self.lb_dataDirectory == None:
        #    raise Exception("lb_data path invalid")
            
        script=""  
        try:
            with open("scripts/FileCopyFromClient.ps1") as file:
                script = file.read()
        except Exception:
            with open("../scripts/FileCopyFromClient.ps1") as file:
                script = file.read()
        
        # replace script parameters     
        script=script.replace("$dst$",filepath.format('utf_16_le'))
        script = script.replace("$module$", self.lb_dataDirectory)
        script=script.replace('$src$','C:\\Users\\$user$\\Desktop\\LB_Daten\\'+self.lb_dataDirectory+'\\*')
        script=script.replace('$user$', self.defaultLogin)
        script=script.replace('$candidateName$', self.candidateName.replace(" ", "_"))
        script=script.replace('$server_user$',r'odroid\winrm lalelu')
                
        if self.debug:
            print("***********************************")
            print(script)
            print("***********************************")
        
        status, error = self.runCopyScript(script)
        
        if status == self.STATUS_OK:
            self.state = Computer.State.STATE_FINISHED
            return True, ""
        else:
            self.state = Computer.State.STATE_RETRIVAL_FAIL            
            return False, error.decode("850")
            
            
    def runCopyScript(self,script):
            
        #s = Session(self.ip, auth=(self.user, self.passwd)) #, transport="ssl") --> ssl option doesn't work here...
        #r = s.run_ps(script)
        
        p = Protocol(
            endpoint='https://' + self.ip + ':5986/wsman',
            transport='basic',
            username=self.user,
            password=self.passwd,
            server_cert_validation='ignore')
        
        shell_id = p.open_shell()
        encoded_ps = b64encode(script.encode('utf_16_le')).decode('ascii')
        command_id = p.run_command(shell_id, 'powershell -encodedcommand {0}'.format(encoded_ps), [])
        std_out, std_err, status_code = p.get_command_output(shell_id, command_id)
        
        p.cleanup_command(shell_id, command_id)
        p.close_shell(shell_id)
        
        if self.debug:
            print("std_out:")
            for line in str(std_out).split(r"\r\n"):
                print(line)
            
        if status_code!=self.STATUS_OK:            
            print("status_code: " + str(status_code))
            print("error_code: " + str(std_err))
            
                        
        return status_code, std_err
                
    def __runPowerShellScript(self, scriptfile="FileCopy.ps1", isFile=True):
        '''
        run the content of a powershell script given in scriptfile
        if isFile=True, scriptFile must contain path to Powershell script,
        if isFile==False, scriptFile is treaded as scripting string 
        prints std_out, std_err and status
        returns std_out
        '''
        script=""
        if isFile==True:  
            with open(scriptfile) as file:
                script = file.read()
        else:
            script = scriptfile
            
        s = Session(self.ip, auth=(self.user, self.passwd))
        r = s.run_ps(script)
        if self.debug:
            print("std_out:")
            for line in str(r.std_out).split(r"\r\n"):
                print(line)
        if r.status_code != self.STATUS_OK:        
            print("status_code: " + str(r.status_code))
            print("error: "+str(r.std_err))
        
        return r.std_out.decode("utf-8").rstrip()

if __name__=="__main__":
    compi = Computer('192.168.0.67', 'winrm', 'lalelu', True)
    print("Testing firewall status")
    status = compi.isFirewallServiceEnabled()
    print("result: "+str(status))
    #compi.getCandidateName()
    #blocked = False
    #compi.sendMessage("Internet is blocked: {}".format(str(blocked)))
    #compi.blockInternetAccess(blocked)
    #print("Hopefully blocked now: "+compi.isUsbBlocked())
    #compi.disableUsbAccess(False)
    #print("Hopefully enabled now: "+compi.isUsbBlocked())
    
    #filepath=r"\\odroid\lb_share\M104"
    #compi.state = Computer.State.STATE_DEPLOYED
    #print(compi.getRemoteFileListing())
    #print(compi.lb_files) 
    #print(compi.getCandidateName())
    
    exit()
    #filepath=r"\\odroid\lb_share\Ergebnisse"
    #x = compi.retrieveClientFiles(filepath)
    #print(x)
    
    
    
    #===========================================================================
    # print("**********************************")
    # print("running tree command:")
    # compi.__runRemoteCommand("tree", [r"C:\Users\Sven\Desktop\LB_Daten", "/F"])
    # print("**********************************")
    # print("running dir command:")
    # compi.__runRemoteCommand("dir", [r"C:\Users\Sven\Desktop\LB_Daten", "/S"])
    # print("**********************************")
    # print("running powershell Get-ChildItem command:")
    # compi.runPowerShellCommand(command="Get-ChildItem -Path C:\\Users\\Sven\\Desktop\\LB_Daten\\ -Recurse")
    #===========================================================================
    #compi.runRemoteCommand(command="robocopy", params=[filepath.replace("#","\\"), r"C:\Users\Sven\Desktop\LBX"])