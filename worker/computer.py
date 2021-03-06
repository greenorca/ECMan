import datetime
import json
import logging
import re
import socket
import time
from base64 import b64encode
from enum import Enum
from pathlib import Path

from winrm import Session
from winrm.exceptions import InvalidCredentialsError
from winrm.protocol import Protocol

'''
Created on Dec 25, 2018

@author: sven
'''

MAX_PS_LENGTH = 3200

class File:

    def __init__(self, name: str, isDir: bool, size=None, date=""):
        """
        create a new file
        """
        self.name = name.replace("\\", "/")
        self.size = size
        self.date = date
        self.isDirectory = isDir
        if self.isDirectory:
            self.children = []

    def addChild(self, child):
        if not (self.isDirectory):
            raise Exception("cannot add children to regular file")
        if type(child) == File:
            self.children.append(child)

    def getSubFolder(self, name: str):
        """
        finds and returns subfolder for give name
        """
        subfolders = [f for f in self.children if f.isDirectory]
        result = [f for f in subfolders if f.name.split("/")[-1] == name]
        if len(result) > 0 and result[0] != []:
            return result[0]
        result = [f.getSubFolder(name) for f in subfolders]
        return result


class Computer(object):
    """
    class to administer instances of computers
    """

    class State(Enum):
        """
        enumeration of various computer states
        """
        STATE_INIT = 0
        STATE_DEPLOYED = 1
        STATE_FINISHED = 2
        STATE_IN_PROGRESS = 3
        STATE_UNKNOWN = -1
        STATE_COPY_FAIL = -2
        STATE_RETRIVAL_FAIL = -3
        STATE_STUDENT_ACCOUNT_NOT_READY = -4
        STATE_ADMIN_STORAGE_NOT_READY = -5
        STATE_WINRM_LOGIN_FAIL = -6
        STATE_IMAGEMAGICK_MISSING = -7
        STATE_GPO_BGIMAGE_FAIL = -8

    def __init__(self, ipAddress, remoteAdminUser, passwd, candidateLogin, fetchHostname=False):
        '''
        constructor
        :param ipAddress: IP of client machine
        :param remoteAdminUser: remote admin account
        :param passwd:
        :param candidateLogin: student account
        :param fetchHostname: set to True to read hostname during constructor call
        '''
        self.debug = False
        if socket.gethostname() == 'sven-V5-171' or socket.gethostname() == 'sven-N13xWU':
            self.debug = True
        self.ip = ipAddress
        self.remoteAdminUser = remoteAdminUser
        self.passwd = passwd
        self.state = Computer.State.STATE_INIT
        self.__hostName = "--unknown--"
        self.STATUS_OK = 0

        self.lb_dataDirectory = ""
        self.lb_files = None
        self.remoteFileListing = ""
        self.last_sync = time.time()
        self.minSynTime = 5
        self.filepath = ""
        self.candidateName = ""
        self.candidateLogin = candidateLogin  # assuming one standard login for all client pcs (usually student/student)

        self.__usbBlocked = "unbekannt"
        self.__internetBlocked = "unbekannt"

        self.logger = logging.getLogger('ecman-clientlog_{}_{}.log'.format(str(datetime.date.today()), self.ip))
        self.logfile_name = 'logs/client_{}_{}.log'.format(str(datetime.date.today()), self.ip)
        if Path(self.logfile_name).parent.exists() == False:
            Path(self.logfile_name).parent.mkdir()
        hdlr = logging.FileHandler(self.logfile_name)
        formatter = logging.Formatter('%(asctime)s %(levelname)s: %(message)s')
        hdlr.setFormatter(formatter)
        self.logger.addHandler(hdlr)
        self.logger.setLevel(logging.INFO)
        self.logger.info("client pc initialisiert: {}".format(self.ip))

        if fetchHostname == True:
            try:
                if (self.debug):
                    print("scanning information")
                self.__hostName = self.getHostName()
            except Exception as ex:
                self.logger.error("Couldn't get hostname: %s".format(str(ex)))
            pass
        else:
            self.__hostName = "Dummy-Host No {}".format(self.ip.split(".")[-1])
            self.candidateName = "Kandidat No {}".format(self.ip.split(".")[-1])

    def resetStatus(self, resetCandidateName=False):
        '''
        resets remote status file and internal status variables
        by overwriting remote ecman.json file with an empty file
        :param resetCandidateName: if set to false, candidate name is erased remotely
        :return:
        '''

        self.logger.info(
            "PC LB-Status zurücksetzen " + ("inklusive Benutzernamen" if resetCandidateName == True else ""))
        candidateName = self.getCandidateName()

        ecmanFile = "C:\\Users\\" + self.remoteAdminUser + "\\ecman.json"

        # wipe all previous state info
        command = '$file = "' + ecmanFile + '";Set-Content -Path $file "{}";'
        std_out, std_err, status_code = self.runPowerShellCommand(command=command)

        if not (resetCandidateName):
            self.setCandidateName(candidateName)
        else:
            self.candidateName = ""

        self.state = Computer.State.STATE_INIT
        self.lb_dataDirectory = ""

    def resetClientHomeDirectory(self):
        '''
        removes all non-system files within client directories
        :return: nothing
        '''
        self.logger.info("PC Benutzerdaten zurücksetzen")

        script = ""
        try:
            with open("scripts/CleanHomedir.ps1") as file:
                script = file.read()
        except Exception:
            with open("../scripts/CleanHomedir.ps1") as file:
                script = file.read()

        # replace script parameters     
        script = script.replace("$candidate$", self.candidateLogin).replace("$passwd$", "student")

        if self.debug:
            print("***********")
            print(script)
            print("***********")

        state, message = self.runCopyScript(script)
        if state != 0:
            self.logger.error("PC Benutzerdaten zurücksetzen gescheitert: " + str(message))

    def getRemoteConnection(self, timeout=4):
        '''
        create a remote connection
        :return: remote connection
        '''
        p = Protocol(
            endpoint='https://' + self.ip + ':5986/wsman',
            transport='basic',
            username=self.remoteAdminUser,
            password=self.passwd,
            server_cert_validation='ignore',
            read_timeout_sec=timeout+5,
            operation_timeout_sec=timeout)
        shell_id = p.open_shell()

        return p, shell_id

    def __runRemoteCommand(self, command="ipconfig", params=['/all']):
        """
        try to run a regular cmd program with given parameters on given winrm-host (ip)
        just prints std_out, std_err and status
        """
        print(command + ", " + str(params))
        p, shell_id = self.getRemoteConnection()

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

    def sendMessage(self, message=""):
        """
        sends a message in a little popup window on client computer
        """
        if message == "" or type(message) != str:
            message = "Verbindungstest Kandidat: " + str(self.getCandidateName())
        else:
            message = str(self.candidateName) + ":: " + message

        p, shell_id = self.getRemoteConnection()

        command_id = p.run_command(shell_id, "msg", [self.candidateLogin, message])
        std_out, std_err, status_code = p.get_command_output(shell_id, command_id)

        if self.debug:
            print(std_out)
            print(std_err)

        return status_code

    def getRemoteFileListing(self, doLogMe = False):
        """
        reads remote LB-Daten directory
        returns nicely formatted HTML list
        """

        if time.time() - self.last_sync > self.minSynTime or self.remoteFileListing == "":
            p, shell_id = self.getRemoteConnection()

            lbFileRoot = r"C:\Users\\" + self.candidateLogin + r"\Desktop"
            command_id = p.run_command(shell_id, "dir", [lbFileRoot, "/S"])
            std_out, std_err, status_code = p.get_command_output(shell_id, command_id)

            p.cleanup_command(shell_id, command_id)
            p.close_shell(shell_id)

            print(std_out)
            self.lb_files = File(lbFileRoot, True)
            currentDir = self.lb_files

            if status_code == self.STATUS_OK:
                self.last_sync = time.time()
                remoteFiles = std_out.decode("850")  # important codepage, utf8 doesn't work for umlauts
                remoteFiles = remoteFiles[remoteFiles.find("Verzeichnis"):]  # cut the first few lines
                lines = remoteFiles.split("\r\n")
                self.remoteFileListing = "<h4>Dateien</h4><ul>\n"

                try:
                    for line in lines[:-4]:
                         file = None
                         if len(line) > 0 and not (line.endswith(".")):
                             file = self.parseFile(line)
                             if type(file) == File and type(currentDir) == File:
                                 file.name = currentDir.name + "/" + file.name
                                 currentDir.addChild(file)
                             elif type(file) == str and not (type(currentDir) is list) and not (
                             currentDir.name.endswith(file)):
                                 currentDir = currentDir.getSubFolder(file)
                                 if currentDir == []:
                                     currentDir = self.lb_files.getSubFolder(file)
                                     if type(currentDir) == list and len(currentDir) > 0:
                                         currentDir = [x for x in currentDir if x != []]
                                         currentDir = currentDir[0]

                             if line.find("<DIR>") < 0:
                                 self.remoteFileListing += "<li>" + line.replace("Verzeichnis von ", "") + "</li>\n"
                except:
                    self.remoteFileListing += "<li>Fehler beim parsen</li>\n"
                    self.remoteFileListing += remoteFiles
                self.remoteFileListing += "</ul>"
            else:
                return std_err
        if doLogMe:
            self.logger.info(self.remoteFileListing)

        return self.remoteFileListing

    def parseFile(self, line):
        """
        turn a line (like this one: 07.01.2019 15:59 23 local_client_test.txt)
        from windows-dir command into a file object
        returns String for subdirectories (that should have been created before) e.g. "Verzeichnis von C:\\Users\\"+self.candidateLogin+"\\Desktop\<<<\\\LB_Daten\\M104\\sub2"
        or None if a line did not matter ()e.g.  " 1 Datei(en), 28 Bytes"
        """
        match = re.match(
            "^(?P<date>[0-9]{2}\.[0-9]{2}\.[0-9]{4})\s+(?P<time>[0-9]{2}:[0-9]{2})\s+(?P<size>[0-9]+)\s+(?P<name>\S+)",
            line)
        if match and match.group("name") != "":
            file = File(match.group("name"), isDir=False, size=match.group("size"),
                        date=match.group("date") + " " + match.group("time"))
            return file
        if line.find("<DIR>") > -1 and not (line.endswith(".")):
            name = line.split(" ")[
                -1]  # directory name is last thing in line, e.g. "13.01.2019  18:44    <DIR>          sub1"
            file = File(name, isDir=True)
            return file
        if line.find("Verzeichnis von") > -1:
            return line.split("\\")[-1]

        return None

    def disableUsbAccess(self, block=True):
        """
        block or unblock usb access for usbsticks etc
        PARAM block =True blocks, block=False reenables access
        https://redmondmag.com/articles/2017/06/27/prevent-the-use-of-usb-media-in-windows-10.aspx
        set HKLM:\\SYSTEM\CurrentControlSet\\Services\\USBSTOR\\Start
        4: blocks; 3 unblocks
        """
        self.logger.info("blockiere USB-Speicher")

        psCommand = 'Set-ItemProperty -Path "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\USBSTOR\\" -Name Start -Value ' + str(
            4 if block == True else 3)
        std_out, std_err, status = self.runPowerShellCommand(psCommand)

        if status != self.STATUS_OK:
            print("Error: " + std_err)
            self.logger.error("USB vermutlich nicht geblockt: {}".format(std_err))
            return False

        self.__usbBlocked = True if std_out.rstrip() == "4" else False

        print("USB blockiert für "+self.__hostName+": "+str(block))

        return True

    def isUsbBlocked(self):
        """
        reads blocking status of this client (from registry)
        and returns USB-ENABLED or USB-BLOCKED
        """
        psCommand = 'Get-ItemPropertyValue -Path "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\USBSTOR\\" -Name Start'
        std_out, std_err, status = self.runPowerShellCommand(psCommand)

        if status != self.STATUS_OK:
            print("Error: " + std_err)
            self.__usbBlocked = "unbekannt"
            return self.__usbBlocked

        self.__usbBlocked = True if std_out.rstrip() == "4" else False
        self.logger.info("USB ist blockiert: {}".format(str(self.__usbBlocked)))
        return self.__usbBlocked

    def allowInternetAccess(self):
        """
        convenience function to remove previously configured firewall rules
        """
        return self.blockInternetAccess(block=False)

    def blockInternetAccess(self, block=True):
        """
        blocks or unblocks web access on client machine,
        returns True if commands were successful, False in case of errors
        """
        blockList = [
            {"name": "Block Http", "port": 80, "protocol": "TCP"},
            {"name": "Block Https", "port": 443, "protocol": "TCP"},
            {"name": "Block Dns", "port": 53, "protocol": "UDP"},
            {"name": "Block CIFS1", "port": 139, "protocol": "TCP"},
            {"name": "Block CIFS2", "port": 445, "protocol": "TCP"}
        ]

        script = []
        if block == False:
            self.logger.info("reaktiviere Internet")
            for entry in blockList:
                command = '$r = Get-NetFirewallRule -DisplayName "{0}" 2> $null; if ($r) { Remove-NetFirewallRule -DisplayName "{0}" } else { write-host "Rule exists, noting to do" }'
                #command = '$r = m "{0}" 2> $null; if ($r) { Remove-NetFirewallRule -DisplayName "{0}" } else { write-host "Rule exists, noting to do" }'
                command = command.replace("{0}", entry['name'])
                script.append(command)

            script.append("Set-SmbServerConfiguration -EnableSMB1Protocol $true -Force")
            script.append("Set-SmbServerConfiguration -EnableSMB2Protocol $true -Force")

        else:
            self.logger.info("blockiere Internet-Zugriff")
            self.configureFirewallService(True)
            for entry in blockList:
                command = '$r = Get-NetFirewallRule -DisplayName "{0}" 2> $null; if ($r) { write-host "Rule exists, noting to do" } else { New-NetFirewallRule -Name "{0}" -DisplayName "{0}" -Enabled 1 -Direction Outbound -Action Block -RemotePort {1} -Protocol {2} }'
                command = command.replace("{0}", entry['name'])
                command = command.replace("{1}", str(entry['port']))
                command = command.replace("{2}", entry['protocol'])
                script.append(command)

            script.append("Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force")
            script.append("Set-SmbServerConfiguration -EnableSMB2Protocol $false -Force")

        p, shell_id = self.getRemoteConnection(timeout=20)

        script = ";".join(script)

        t0 = time.time()
        if self.debug:
            print("running: " + script)
        encoded_ps = b64encode(script.encode('utf_16_le')).decode('ascii')
        command_id = p.run_command(shell_id, 'powershell -encodedcommand {0}'.format(encoded_ps), [])
        std_out, std_err, status_code = p.get_command_output(shell_id, command_id)

        p.cleanup_command(shell_id, command_id)
        p.close_shell(shell_id)

        if self.debug:
            print("firewall config took: " + str(round(time.time() - t0)) + "sec")
            print("std_out:")
            for line in str(std_out).split(r"\r\n"):
                print(line)

        if status_code != self.STATUS_OK:
            print("status_code: " + str(status_code))
            print("error_code: " + str(std_err))
            self.logger.error("Bearbeiten der Firewall nicht erfolgreich: {}".format(std_err))
            self.__internetBlocked = "unbekannt"
            return False

        print("Internet blockiert für "+self.__hostName+": "+str(block))
        self.__internetBlocked = block
        return True

    def isInternetBlocked(self):
        return self.__internetBlocked

    def isFirewallServiceEnabled(self):
        """
        """
        testCommand = 'Get-NetFirewallProfile | Where-Object {$_.Enabled -ne "true"}'
        std_out, std_err, status = self.runPowerShellCommand(command=testCommand)

        if status == self.STATUS_OK and std_out.rstrip() != "":
            print("following firewalls are not active: " + std_out)
            self.logger.info("Firewall-Service nicht aktiv")
            return False

        self.logger.info("Firewall-Service aktiv")
        return True

    def configureFirewallService(self, enable=True):
        """
        enable or disable windows defender firewall service for all network profiles
        """
        testCommand = 'Set-NetFirewallProfile -Enabled {}'.format(enable)
        std_out, std_err, status = self.runPowerShellCommand(command=testCommand)

        if status != self.STATUS_OK:
            print("error activating/deactivating firewalls: " + std_err)
            print("std_out:: " + std_out)
            self.error("Firewall-Service Problem: {}".format(str(std_err)))

            return False

        self.logger.info("Firewall-Service aktiv: {}".format(str(enable)))
        time.sleep(3)
        return True

    def testPing(self, dst):
        """
        simple ping test to a remote dst; use e.g before retrieving client files to make sure firewall allows access,
        returns True on Success, False otherwise
        """

        textCommandPing = 'try { Clear-DNSClientCache; if (Test-Connection "$1$" -Quiet -Count 1 )  { Write-Host PING_OK } else { Write-Host PING_NOK } } catch { Write-host DNS_FAIL }'.replace(
            '$1$', dst)

        std_out, std_err, status = self.runPowerShellCommand(command=textCommandPing)
        if status == self.STATUS_OK and std_out.rstrip() in ["PING_NOK", "DNS_FAIL"]:
            self.__internetBlocked = True
            print("DNS is blocked for dst: " + dst)
            return False
        else:
            self.__internetBlocked = False
            print("DNS unblocked, PING ok")

        return True

    def testInternetBlocked(self):
        """
        testing web connectivity (first clear local dns cache, then ping www.wiss.ch, then try http protocol
        fixed: cleared cached DNS
        """

        testWebConnectivityHost = "www.wiss.ch"

        testCommandHttp = 'try { $client = New-Object System.Net.WebClient; $res=$client.DownloadString("http://$1$"); write-host 1} catch{ write-host -1}'.replace(
            "$1$", testWebConnectivityHost)

        if not (self.testPing(testWebConnectivityHost)):
            return self.__internetBlocked

        std_out, std_err, status = self.runPowerShellCommand(command=testCommandHttp)
        if status == self.STATUS_OK:
            if std_out == "-1":
                self.__internetBlocked = True
                print("HTTP is blocked")
            elif std_out == "1":
                self.__internetBlocked = False
                print("HTTP is unblocked")

        return self.__internetBlocked

    def setCandidateName(self, candidateName):
        """
        sets given candidate name on remote machine
        by writing it to a file on the winrm user home directory
        """
        #if len(candidateName)>12: #odd hack to stay within Powershell line length limits...
        #    candidateName = candidateName[0:12]

        command = '''
            $file = "C:\\Users\\$0$\\ecman.json";
            $json=ConvertFrom-Json -InputObject (Gc $file -Raw);
            if ($json.PSObject.Properties.Name -notcontains "candidate_name") { 
                $json | Add-Member NoteProperty -Name "candidate_name" -Value "$1$" } 
            else  { $json.candidate_name="$1$" }
            $json | ConvertTo-Json | Out-File $file; 
            '''.replace("$0$", self.remoteAdminUser).replace('$1$', candidateName)
        print("setup name: " + command)
        std_out, std_err, status = self.runPowerShellCommand(command)
        if status != self.STATUS_OK:
            print(std_err)
        else:
            self.candidateName = candidateName
            self.setLockScreenPicture()

        self.logger.info("Kandidat name gesetzt: {}".format(self.candidateName))

        return status

    def getCandidateName(self, remote=False):
        """
        returns candidate name configured for this client
        """
        if remote == False:
            return self.candidateName

        self.checkStatusFile()  # automatically retrieves remote candidate name (amongst bunch of other things) 

        return self.candidateName

    def checkUserConfig(self):
        """
        check preconfigured exam user folder
        check default ecman.json folder
        """
        command = '$baseDir="C:\\Users\\$1$\\"; Write-Host (Test-Path $baseDir)'.replace("$1$", self.candidateLogin)
        if self.debug: print("CheckUserConfig command: " + command)
        std_out, std_err, status = self.runPowerShellCommand(command)

        if status != self.STATUS_OK:
            if self.debug: print("Error checking user folder on LB client: " + std_err)
            self.state = Computer.State.STATE_STUDENT_ACCOUNT_NOT_READY
            self.logger.error("Fehler beim Prüfen des LBUser-Verzeichnis (student): {}".format(str(std_err)))
            return False

        if std_out.find("False") >= 0:
            if self.debug: print("Client-User {} HOME-Verzeichnis existiert nicht. Bitte erstmalig einloggen!".format(
                self.candidateLogin))
            self.state = Computer.State.STATE_STUDENT_ACCOUNT_NOT_READY
            self.logger.warn("LBUser-Verzeichnis (student) nicht vorhanden")
            return False

        elif std_out.find("True") >= 0:
            '''
            important: ensure the winrm - admin user folder exists, otherwise create it
            '''
            command = '''$baseDir="C:\\Users\\$1$\\"; 
                if (Test-Path $baseDir){ } 
                else { 
                    try { New-Item -Path $baseDir -Force -ItemType directory; } 
                    catch { Write-Host "NOK" } }'''.replace("$1$", self.remoteAdminUser)
            if self.debug: print("CheckUserConfig command: " + command)
            std_out, std_err, status = self.runPowerShellCommand(command)

            if status != self.STATUS_OK:
                if self.debug: print("Error checking remote-admin folder: " + std_err)
                self.state = Computer.State.STATE_ADMIN_STORAGE_NOT_READY
                self.logger.error("Fehler beim Prüfen des WinRM User-verzeichnisses")
                return False

            if std_out.find("NOK") >= 0:
                if self.debug: print("Client remote admin folder does not exist.")
                self.state = Computer.State.STATE_ADMIN_STORAGE_NOT_READY
                self.logger.error("WinRM User-verzeichnis nicht vorhanden")
                return False

            return True

        print("computer.checkUserConfig: you shouldnt see this message at all: " + std_out)
        return False

    def checkStatusFile(self):
        """
        checks if file C:\\Users\\winrm\\ecman.json exists on client,
        creates it if it doesn't exists and retrieves its content
        """
        if not (self.checkUserConfig()):
            return False

        command = '''
        $file = "C:\\Users\\$1$\\ecman.json"; 
        if (Get-Item $file 2> $null) { 
            $content = Get-Content $file; 
            foreach ($line in $content){ Write-Host $line } 
        } else { 
            Set-Content -Path $file "{}"; Write-Host "{}";
        }'''.replace("$1$", self.remoteAdminUser)

        if self.debug:
            print("CheckStatus command: " + command)

        std_out, std_err, status = self.runPowerShellCommand(command)

        if status != self.STATUS_OK:
            if self.debug: print("Error checking status file: " + std_err)
            self.logger.error("Fehler beim Lesen des Status-Datei ecman.conf: " + std_err)
            return False

        self.statusFile = std_out
        self.logger.info("Remote status file: {}".format(std_out))

        # parse std_out for status info
        myJson = json.loads(self.statusFile)

        self.candidateName = myJson.get("candidate_name")
        self.state = Computer.State.STATE_INIT
        match = myJson.get("client_state")
        if match:
            for x in Computer.State:
                if x.name == match:
                    self.state = x
                    break

        match = myJson.get("last_update")
        if match:
            self.last_update = match

        match = myJson.get("lb_src")
        if match:
            match = match.replace("\\", "/")
            self.lb_dataDirectory = match

            self.lb_dataDirectory = self.lb_dataDirectory.split("/")[-1]
            if self.debug:
                print("fetched user name: " + self.candidateName)
                print("fetched client state: " + self.state.name)
                print("fetched previous data dir: " + self.lb_dataDirectory)

        return True

    def createBunchOfStupidFiles(self, numberOfFiles=1000):
        '''
        really only for testing purposes
        :param numberOfFiles: number of files to create on remote machines Desktop
        :return:
        '''
        command = 'for /l %x in (1, 1, {0}) do echo %x > C:\\Users\\' + \
                  self.candidateLogin + '\\Desktop\\LB_Daten\\%x.txt'.format(numberOfFiles)
        status = self.__runRemoteCommand(command, [])
        self.logger.info("Created bunch of files: " + str(status))

    def checkFileSanity(self, maxFiles=100, maxFileSize=1000000):
        """
        returns True if remote Desktop contains less than maxFiles with a total size less than maxFileSize (in bytes)
        returns False otherwise
        """
        command = '$summary=(Get-ChildItem -Recurse C:\\Users\\' + self.candidateLogin + '\\Desktop) | Measure-Object -property length -sum; Write-Host "Files:" $summary.Count "; Size:" $summary.Sum;'
        out, err, status = self.runPowerShellCommand(command)

        if status != self.STATUS_OK:
            self.logger.error("Fehler beim Überprüfen der Dateien im Lösungsverzeichnis: " + err)
            return False

        self.logger.info(out)

        files, size = out.replace("Files:", "").replace("Size:", "").split(";")
        errors = 0
        if int(files) > maxFiles:
            self.logger.warning("Desktop enthält zu viele Dateien: " + files)
            errors += 1
            self.state = Computer.State.STATE_RETRIVAL_FAIL
        if int(size) > maxFileSize:
            self.logger.warning("Desktop-Dateien in Summe zu gross: " + size)
            errors += 1
            self.state = Computer.State.STATE_RETRIVAL_FAIL

        return errors == 0

    def getHostName(self):
        """
        returns hostname for given ip
        fetches remote hostname only if local attribute is empty
        """
        if self.__hostName != "" and self.__hostName != "--unknown--":
            return self.__hostName

        p, shell_id = self.getRemoteConnection()

        # TODO: try option in Protocol:: operation_timeout_sec=1

        try:
            command_id = p.run_command(shell_id, 'hostname', [])
            std_out, std_err, status_code = p.get_command_output(shell_id, command_id)

            p.cleanup_command(shell_id, command_id)
            p.close_shell(shell_id)

            if status_code != self.STATUS_OK:
                print("Error: " + std_err.decode("850"))
                self.__hostName = "--unknown--"

            else:
                self.__hostName = std_out.decode("utf-8").replace("\r\n", "")

        except (InvalidCredentialsError):
            self.logger.error("Remotemanagement-Benutzer oder Passwort ungültig.")
            self.state = Computer.State.STATE_WINRM_LOGIN_FAIL
            self.__hostName = "--invalid remote user--"

        except Exception as ex:
            self.logger.error("Konnte Hostnamen nicht abfragen: " + str(ex))
            self.state = Computer.State.STATE_WINRM_LOGIN_FAIL
            self.__hostName = "--unknown error--"

        return self.__hostName

    def shutdown(self):
        self.logger.info("PC wird heruntergefahren")
        try:
            return self.__runRemoteCommand("shutdown /s /t 3", []) == self.STATUS_OK

        except Exception as ex:
            print(ex)
            return False

        return True

    def reboot(self):
        self.logger.info("PC wird neu gestartet")
        try:
            return self.__runRemoteCommand("shutdown /r /t 2", []) == self.STATUS_OK

        except Exception as ex:
            print(ex)
            return False

        return True

    def setLockScreenPicture(self, file="C:\\Windows\\Web\\Screen\\img100.jpg"):
        """
        add currently set candidate name to lock screen image for this computer
        """
        command = []
        # command.append('takeown /F "{0}"'.format(file))
        # command.append('icacls "{0}" /grant winrm:("d","f")'.format(file))
        command.append('magick convert -fill green -draw \
            \"rectangle 0,40,5000,260\" {0} {0}'.format(file))

        command.append("magick convert -font arial -fill white -pointsize 120 -draw \
            \"text 600,200 '{0}'\" {1} {1}".format(self.candidateName, file))
        # struggeling with user write permissions on img100 XOR REGEDIT KEY 

        for x in command:
            out, err, status = self.runPowerShellCommand(x)
            if status != self.STATUS_OK:
                if self.debug: print("error running script: " + x)
                if self.debug: print("lets assume imagemagick isnt installed... " + err)
                self.state = Computer.State.STATE_IMAGEMAGICK_MISSING
                return False
        command = []
        command.append(
            'if (!(Test-Path "HKLM:\Software\Policies\Microsoft\Windows\Personalization\")){ New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\Personalization\" -ErrorAction Ignore}')
        command.append(
            'Set-ItemProperty -Name LockScreenImage -Path "HKLM:\\Software\\Policies\\Microsoft\\Windows\\Personalization\\" -Value {}'.format(
                file))
        command.append(
            'Set-ItemProperty -Name ForceStartBackground -Path "HKLM:\\Software\\Policies\\Microsoft\\Windows\\Personalization\\" -Value 0')
        command.append(
            'Set-ItemProperty -Name NoChangingLockScreen -Path "HKLM:\\Software\\Policies\\Microsoft\\Windows\\Personalization\\" -Value 1')

        for x in command:
            out, err, status = self.runPowerShellCommand(x)
            if status != self.STATUS_OK:
                if self.debug: print("error setting GPO lock screen: " + x)
                if self.debug: print("lets assume something failed on GPO stuff: " + err)
                self.state = Computer.State.STATE_GPO_BGIMAGE_FAIL
                return False

        return True

    def blankScreen(self):
        """
        supposed to blank screen on WIN computer; doesn't work remote yet...
        """
        # command = r"powershell (Add-Type '[DllImport(\"user32.dll\")]^public static extern int SendMessage(int hWnd, int hMsg, int wParam, int lParam);' -Name a -Pas)::SendMessage(-1,0x0112,0xF170,2)"
        # command = r"%systemroot%\system32\scrnsave.scr /s"
        command = r"runas /user:Sven runas /user:student%systemroot%\system32\scrnsave.scr /s"
        self.__runRemoteCommand(command, [])

    def runPowerShellCommand(self, command=""):  # , timeout=30):
        """
        run a powershell command remotely on given ip,
        just prints std_out, std_err and status
        returns std_out, std_err and status (0 == good) instead of True and False
        """
        p, shell_id = self.getRemoteConnection()
        # operation_timeout_sec=timeout+1, read_timeout_sec=timeout+2)

        encoded_ps = b64encode(command.encode('utf_16_le')).decode('ascii')
        command_id = p.run_command(shell_id, 'powershell -encodedcommand {0}'.format(encoded_ps), [])
        std_out, std_err, status_code = p.get_command_output(shell_id, command_id)
        p.cleanup_command(shell_id, command_id)
        p.close_shell(shell_id)
        return std_out.decode("850").rstrip(), std_err.decode("850").rstrip(), status_code

    def deployClientFiles(self, filepath, server_user, server_passwd, domain):
        """
        copy the content of filepath (recursively) to this client machine
        prints std_out, std_err and status
        returns True on success, False otherwise
        """
        script = ""
        try:
            with open("scripts/FileCopy.ps1") as file:
                script = file.read()
        except Exception:
            with open("../scripts/FileCopy.ps1") as file:
                script = file.read()

        # replace script parameters     
        script = script.replace("$src$", filepath.format('utf_16_le'))
        # script=script.replace('$dst$','C:\\Users\\$user$\\Desktop\\LB_Daten\\')
        script = script.replace('$dst$', 'C:\\Users\\$user$\\Desktop\\')
        script = script.replace('$user$', self.candidateLogin)
        script = script.replace('$server_user$', server_user)
        script = script.replace('$server_pwd$', server_passwd)
        script = script.replace('$domain$', domain)

        if len(script)>MAX_PS_LENGTH:
            self.state = Computer.State.STATE_COPY_FAIL
            self.logger.info("generated Copy Script too long")
            if self.debug:
                print("generated Copy Script too long")
            return


        if self.debug:
            print("***********************************")
            print(script)
            print("***********************************")

        try:
            status, error = self.runCopyScript(script)

            if status == self.STATUS_OK:
                self.lb_dataDirectory = filepath.split("/")[-1]
                self.lb_dataDirectory = self.lb_dataDirectory.split("/")[-1]
                self.filepath = filepath
                self.state = Computer.State.STATE_DEPLOYED
                self.logger.info("Client erfolgreich für Prüfung konfiguriert. Folgende Dateien auf Desktop:")
                self.getRemoteFileListing(True)  # get desktop file listing for log
                return True
            else:
                self.logger.error(error.decode("850"))

        except Exception as e:
            print(e)
            self.logger.error(str(e))

        self.state = Computer.State.STATE_COPY_FAIL
        return False

    def retrieveClientFiles(self, filepath, server_user, server_passwd, domain):
        """
        copy LB-data files from this machine to destination (which has to be a writable SMB share)
        within a folder with the candidates name that will be created on destination;
        breaks if Computer state is not deployed or candidate name is empty
        returns True on success, False otherwise
        """

        if self.candidateName == "":
            if self.getCandidateName(True) == "":
                raise Exception("Candidate name not set")

        if self.lb_dataDirectory == "" or self.lb_dataDirectory == None:
            raise Exception("lb_data path invalid")

        lb_dataDirectory = self.lb_dataDirectory.split("#")[-1]

        self.logger.info("Prüfungsdaten {} vom Client auf LBV-Share kopieren: {}. Aktuell befinden sich folgende Daten auf dem Desktop: ".
                         format(lb_dataDirectory, filepath.replace("#", "/")))

        self.getRemoteFileListing(True) # get desktop file listing for log

        self.configureFirewallService(enable=False)
        script = ""
        try:
            with open("scripts/FileCopyFromClient.ps1") as file:
                script = file.read()
        except Exception:
            with open("../scripts/FileCopyFromClient.ps1") as file:
                script = file.read()

        # replace script parameters     
        script = script.replace("$dst$", filepath.format('utf_16_le'))
        script = script.replace("$module$", lb_dataDirectory)
        script = script.replace('$src$', 'C:\\Users\\$user$\\Desktop\\*')
        script = script.replace('$user$', self.candidateLogin)
        script = script.replace('$candidateName$', self.candidateName.replace(" ", "_"))

        script = script.replace('$server_user$', server_user)
        script = script.replace('$server_pwd$', server_passwd)
        script = script.replace('$domain$', domain)

        if len(script)>MAX_PS_LENGTH:
            self.state = Computer.State.STATE_RETRIVAL_FAIL
            self.logger.info("generated Copy Script too long")
            if self.debug:
                print("generated Copy Script too long")
            return

        if self.debug:
            self.logger.info(script)
            print("***********************************")
            print(script)
            print("***********************************")

        status, error = self.runCopyScript(script)

        if status == self.STATUS_OK:
            self.state = Computer.State.STATE_FINISHED
            self.logger.info(
                "<h3>Kopieren der Prüfungsleistungen auf Server war erfolgreich.</h3> <p>Details: " + error.decode(
                    "850").replace('\r\n', '<br>\n').replace('\n', '<br>\n') + "</p>")
            return True

        else:
            self.state = Computer.State.STATE_RETRIVAL_FAIL
            self.logger.critical(
                "Kopieren der Prüfungsleistungen auf Server nicht erfolgreich: {}".format(error.decode("850")))
            print("Fehler beim Ergebnisse zum Server kopieren: "+error.decode("850"))
            return False

    def runCopyScript(self, script):
        """
        internes Kopierskript
        """
        p, shell_id = self.getRemoteConnection(timeout=20)

        encoded_ps = b64encode(script.encode('utf_16_le')).decode('ascii')
        command_id = p.run_command(shell_id, 'powershell -encodedcommand {0}'.format(encoded_ps), [])
        std_out, std_err, status = p.get_command_output(shell_id, command_id)
        p.cleanup_command(shell_id, command_id)
        p.close_shell(shell_id)

        if self.debug:
            print("std_out:")
            for line in str(std_out).split(r"\r\n"):
                print(line)

        if status != self.STATUS_OK or not (std_out.rstrip().endswith(b"SUCCESS")):
            self.logger.error("error running script on client - status_code: " + str(status))
            self.logger.error("error_code: " + str(std_err))
            print(str(std_err))
            return -1, b"ERROR" + std_out.rstrip().split(b"ERROR")[-1]

        return status, std_out

    def __runPowerShellScript(self, scriptfile="FileCopy.ps1", isFile=True):
        """
        run the content of a powershell script given in scriptfile
        if isFile=True, scriptFile must contain path to Powershell script,
        if isFile==False, scriptFile is treaded as scripting string
        prints std_out, std_err and status
        returns std_out
        """
        script = ""
        if isFile == True:
            with open(scriptfile) as file:
                script = file.read()
        else:
            script = scriptfile

        s = Session(self.ip, auth=(self.remoteAdminUser, self.passwd))
        r = s.run_ps(script)
        if self.debug:
            print("std_out:")
            for line in str(r.std_out).split(r"\r\n"):
                print(line)
        if r.status_code != self.STATUS_OK:
            print("status_code: " + str(r.status_code))
            print("error: " + str(r.std_err))

        return r.std_out.decode("utf-8").rstrip()
