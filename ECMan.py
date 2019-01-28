import os, sys, socket
import subprocess, ctypes, time
#from time import sleep
from PySide2.QtWidgets import QApplication, QMainWindow, QFileDialog, QMessageBox, QGridLayout #QInputDialog
from PySide2.QtGui import QTextDocument
from PySide2.QtCore import QUrl, QEvent
from threading import Thread
from configparser import ConfigParser
from pathlib import Path
# import scripts.winrm_toolbox as remote_tools
from worker.computer import Computer
from ui.logger import Logger
from ui.uiWorkers import ScannerWorker, CopyExamsWorker, RetrieveResultsWorker
from ui.lbClientButton import LbClient
from ui.Ui_MainWindow import Ui_MainWindow
from ui.ecManConfigDialog import EcManConfigDialog
from ui.ecManProgressDialog import EcManProgressDialog

'''
Start app for exam deployment software
author: Sven Schirmer
last_revision: 2019-01-16

TODO: 
create Windows-Installer, e.g.: http://www.pyinstaller.org/#welcome-to-pyinstaller-official-website
ping given share on windows-client before net use; perhaps add path to host file if ping doesn't work

'''
class MainWindow(QMainWindow, Ui_MainWindow):
    def __init__(self):
        super(MainWindow,self).__init__()
        self.setupUi(self)
        self.grid_layout = QGridLayout()
        
        self.btnDetectClient.clicked.connect(self.detectClients)
        
        self.btnSelectExam.clicked.connect(self.selectExam)
        self.btnSelectExam.setEnabled(True)
        
        self.btnPrepareExam.clicked.connect(self.prepareExam)
        self.btnPrepareExam.setEnabled(True)
        
        self.btnGetExams.clicked.connect(self.retrieveExamFiles)
        self.btnGetExams.setEnabled(True)
        
        self.btnSelectAllClients.clicked.connect(self.selectAllCLients)
        self.btnUnselectAllClients.clicked.connect(self.unselectAllCLients)
           
        self.actionBearbeiten.triggered.connect(self.openConfigDialog)              
        #self.progressBar.setStyleSheet("QProgressBar { background-color: #CD96CD; width: 10px; margin: 0.5px; }")
                                         
        self.setWindowTitle('ECMan - Exam Client Manager')
        
        self.logger = Logger(self.textEdit)
        self.show()
        self.getConfig()
        #self.detectClients()
    
    def closeEvent(self, event):
        '''
        overrides closeEvent of base class, clean up
        * especially remove shares created on Windows hosts
        '''
        print("cleaning up...")
        try:
            for share in self.sharenames:
                Thread(target=self.runLocalPowerShellAsRoot("Remove-SmbShare -Name {} -Force".format(share))).start()
        except Exception:
            pass
        print("done cleaning up...")
        super(MainWindow,self).closeEvent(event) 
    
    def selectAllCLients(self):
        for i in range(self.grid_layout.count()): 
            self.grid_layout.itemAt(i).widget().select()            
            
    def unselectAllCLients(self):
        for i in range(self.grid_layout.count()): 
            self.grid_layout.itemAt(i).widget().unselect()
            
        
    def getConfig(self):
        '''
        sets inial values for app 
        '''        
        self.lb_server = ""
        self.port = 5986
        self.user = ""
        self.passwd = ""
        
        self.configFile = Path(str(Path.home())+"/.ecman.conf")
        
        if not(self.configFile.exists()):
            result = self.openConfigDialog()
            
        if self.configFile.exists() or result==1:
            self.refreshConfig()
        
        #=======================================================================
        # self.lb_server = "file:///192.168.0.50/lb_share"
        # if os.name=='nt':
        #     self.lb_server = r"\\192.168.0.50\lb_share"
        #=======================================================================
        
        self.lb_directory = ""
        self.result_directory = ""
        
        self.sharenames = [] # dump all eventually created local Windows-Shares in this array - TODO: remove all these shares on exit
        self.debug=True
        # fetch own ip adddress
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            s.connect(('9.9.9.9', 1))  # connect() for UDP doesn't send packets
            self.ip_address = s.getsockname()[0]
            parts = self.ip_address.split(".")[0:-1]
            self.ipRange=".".join(parts)+".*"
            self.lineEditIpRange.setText(self.ipRange)
            self.setWindowTitle(self.windowTitle()+" on "+self.ip_address)
        except Exception as ex:
            self.showMessageBox("Fehler", "Keine Verbindung zum Internet<br>Möglicherweise gelingt der Sichtflug.")
            self.log("no connection to internet:"+ex)
            pass
        
    def refreshConfig(self):
        '''
        reads config file into class variables
        '''
        config = ConfigParser()
        config.read_file(open(str(self.configFile)))
        
        self.lb_server = config.get("General","lb_server",fallback="")
        self.port=config.get("General", "winrm_port",fallback=5986)
        self.client_lb_user = config.get("Client", "lb_user", fallback="student") 
        self.user = config.get("Client","user",fallback="")
        self.passwd = config.get("Client","pwd",fallback="")    
    
    def openConfigDialog(self):
        '''
        opens configuration dialog
        '''
        configDialog = EcManConfigDialog(self)
        result = configDialog.exec_()
        if result == 1:
            configDialog.saveConfig()
            self.refreshConfig()
        return result
        
    def log(self, message):
        '''
        basic logging functionality
        TODO: improve...
        '''
        self.logger.log(message) 
        
    def updateProgressBar(self, value):
        self.progressBar.setValue(value)
     
    def retrieveExamFiles(self):
        '''
        retrieve exam files for all clients
        '''
        # find all suitable clients (required array for later threading)
        clients = [self.grid_layout.itemAt(i).widget() for i in range(self.grid_layout.count()) 
                   if self.grid_layout.itemAt(i).widget().isSelected and 
                   self.grid_layout.itemAt(i).widget().computer.state in [Computer.State.STATE_DEPLOYED, Computer.State.STATE_FINISHED]]
                
        if len(clients) == 0:
            self.showMessageBox("Warnung", "keine Clients ausgewählt bzw. deployed")
            return 
        
        self.progressBar.setMaximum(len(clients))
        self.progressBar.setValue(0)
        
        retVal = QMessageBox.StandardButton.Yes
        if self.result_directory != "":
            retVal =  QMessageBox.question(self, "Warnung", "Ergebnispfad bereits gesetzt: {}, neu auswählen".format(self.result_directory))
            
        if retVal == QMessageBox.StandardButton.Yes:
            fname = QFileDialog.getExistingDirectoryUrl(self, 'Kandidaten-Dateien kopieren nach', options=QFileDialog.ShowDirsOnly)
        
            if fname is None or fname.url()=="":
                # user aborted ...
                return         
            self.result_directory = fname.url()
        
        if os.name=="posix":
            if self.debug: 
                self.log("raw result directory: "+self.result_directory)
            self.result_directory = self.result_directory.replace("file:///run/user/1000/gvfs/smb-share:server=", "##")
            
        else:
            self.result_directory = self.result_directory.replace("file:","")
            # if local directory was selected (e.g. C:\ or D:\), create Share with PowerShell
            if (self.result_directory.find("C:/")>-1 or self.result_directory.find("D:/")>-1):
                sharename = self.result_directory.split("/")[-1]
                if not(sharename in self.sharenames): 
                    smbShareCreateCommand="New-SmbShare -Name {} -Path {} -FullAccess winrm,sven".format(sharename, self.result_directory.replace("///",""))
                    self.log("Creating new share: "+smbShareCreateCommand)
                    try:
                        self.runLocalPowerShellAsRoot(smbShareCreateCommand)
                        self.sharenames.append(sharename)
                        self.result_directory = "//"+socket.gethostname() + "/" + sharename
                    except Exception as ex:
                        self.log("Share konnte nicht eingerichtet werden: "+ex.args[0])
                        self.result_directory = None
                        raise Exception("Share für Prüfungsergebnisse konnte nicht eingerichtet werden")  
             
        self.result_directory = self.result_directory.replace(",share=","#" ).replace("/","#" )     
        self.log("save result files into: "+self.result_directory.replace("#","\\"))
            
        self.worker = RetrieveResultsWorker(clients, self.result_directory)
        self.worker.updateProgress.connect(self.updateProgressBar)
        self.worker.start()        
        
    def prepareExam(self):
        self.copyFilesToClient()
        pass
    
    def copyFilesToClient(self):
        '''
        copies selected exam folder to all connected clients that are selected and not in STATE_DEPLOYED or STATE_FINISHED
        '''
        if self.lb_directory=="" or self.lb_directory==None:
            self.showMessageBox("Fehler", "Kein Prüfungsordner ausgewählt")
            return
        
        clients = [self.grid_layout.itemAt(i).widget() for i in range(self.grid_layout.count()) 
                   if self.grid_layout.itemAt(i).widget().isSelected and 
                   self.grid_layout.itemAt(i).widget().computer.state not in [Computer.State.STATE_DEPLOYED, Computer.State.STATE_FINISHED]]
                
        if len(clients) == 0:
            self.showMessageBox("Warnung", "keine Clients ausgewählt bzw. bereits deployed")
            return 
        
        progressDialog = EcManProgressDialog(self, "Hello World")
        progressDialog.setMaxValue(len(clients))
        progressDialog.setValue(0)
        progressDialog.open()
        
        
        self.worker = CopyExamsWorker(clients, self.lb_directory)
        self.worker.updateProgress.connect(progressDialog.setValue)
        self.worker.start()    
        
        
    def detectClients(self):
        '''
        starts portscan to search for winrm enabled clients
        '''
        ip_range = self.lineEditIpRange.text()
        if not(ip_range.endswith('*')):
            self.showMessageBox('Eingabefehler','Gültiger IP-V4 Bereich endet mit * (z.B. 192.168.0.*)')
            return

        self.ipRange = ip_range
        self.progressBar.setEnabled(True)
        self.progressBar.setValue(0)
        
        # clear previous client buttons
        try:
            for i in range(self.grid_layout.count()): 
                self.grid_layout.itemAt(i).widget().close()
        except:
            pass
        self.clientFrame.setLayout(self.grid_layout)

        self.progressBar.setMaximum(253)
        self.worker = ScannerWorker(self.ipRange, self.ip_address)
        self.worker.updateProgress.connect(self.updateProgressBar)
        self.worker.addClient.connect(self.addClient)
        self.worker.start()        
        
        
    def addClient(self, ip):
        '''
        populate GUI with newly received client ips (only last byte required)
        '''
        self.log("new client signal received: "+ str(ip))
        clientIp = self.ipRange.replace("*",str(ip))
        button = LbClient(clientIp, self.user, self.passwd, self)
        button.setMinimumHeight(50)
        #button.installEventFilter(self)
        self.grid_layout.addWidget(button, self.grid_layout.count()/4, self.grid_layout.count()%4)  
        self.clientFrame.setLayout(self.grid_layout)     
        #QtGui.qApp.processEvents()
    
        
    def getExamPath(self):
        return self.lb_directory
        
    def selectExam(self):
        '''
        opens a file chooser dialog to select an exam directory 
        POSIX: file:///run/user/1000/gvfs/smb-share:server=odroid,share=lb_share/m104
        Windows: file://vboxsvr/Nextcloud/IPA/muster_kriterien_2018.odt
        '''
        #fname = QFileDialog.getOpenFileUrl(self, 'LB-Daten auswählen', QUrl.fromUserInput(self.lb_server), options=QFileDialog.ShowDirsOnly)
        #fname = QFileDialog.getOpenFileName(self, 'LB-Daten auswählen', self.lb_server, options=QFileDialog.ShowDirsOnly)
        fname = QFileDialog.getExistingDirectoryUrl(self, 'LB-Daten auswählen', dir=QUrl.fromUserInput(self.lb_server), options=QFileDialog.ShowDirsOnly)
        if fname!="":
            self.log("Path selected: {}".format(fname.url()))
            self.lb_directory = fname.url()
            if os.name=="posix":
                if self.debug: 
                    self.log(self.lb_directory)
                self.lb_directory = self.lb_directory.replace("file:///run/user/1000/gvfs/smb-share:server=", "##")
                self.lb_directory = self.lb_directory.replace(",share=","#" ).replace("/","#" )
            else:
                self.lb_directory = self.lb_directory.replace("file:","")
                # if local directory was selected (e.g. C:\ or D:\), create Share with PowerShell
                if (self.lb_directory.find("C:/")>-1 or self.lb_directory.find("D:/")>-1):
                    sharename = self.lb_directory.split("/")[-1] 
                    smbShareCreateCommand="New-SmbShare -Name {} -Path {} -ReadAccess winrm,sven".format(sharename, self.lb_directory.replace("///",""))
                    self.log("Creating new share: "+smbShareCreateCommand)
                    try:
                        self.runLocalPowerShellAsRoot(smbShareCreateCommand)
                        self.sharenames.append(sharename)
                        self.lb_directory = "//"+socket.gethostname() + "/" + sharename # important: update directory string to match smb-path
                    except Exception as ex:
                        self.showMessageBox("Fehler", "Share konnte nicht eingerichtet werden")
                        self.log("Share konnte nicht eingerichtet werden: "+str(ex))
                        self.lb_directory = None
                        sharename = None
                    
                self.lb_directory = self.lb_directory.replace("/","#" )    
                 
            self.log(self.lb_directory)
            self.btnPrepareExam.setEnabled(True)
        
    def runLocalPowerShellAsRoot(self, command):
        # see https://docs.microsoft.com/en-us/windows/desktop/api/shellapi/nf-shellapi-shellexecutew#parameters
        retval = ctypes.windll.shell32.ShellExecuteW(None ,"runas",  # runas admin, 
            "C:\\WINDOWS\\system32\\WindowsPowerShell\\v1.0\\powershell.exe",  #file to run
            command, # actual powershell command
            None, 0) # last param disables popup powershell window...
    
        if retval != 42:
            self.log("ReturnCode after creating smbShare: "+str(retval))
            subprocess.run(["C:\\WINDOWS\\system32\\WindowsPowerShell\\v1.0\\powershell.exe", "Get-SmbShare"])
            raise Exception("ReturnCode after running powershell: "+str(retval))
        
    def __openFile(self):
        fname = QFileDialog.getOpenFileName(self, 'Open file','/home')
        if fname[0]:
            f = open(fname[0], 'r')
        with f:
            data = f.read()
            doc = QTextDocument(data, None)
            self.textEdit.setDocument(doc)
    
    def saveFile(self):
        pass

    def eventFilter(self, currentObject, event):
        '''
        unused, define mouseover events (with tooltips) for LbClient widgets
        '''
        if event.type() == QEvent.Enter:
            if isinstance(currentObject, LbClient):
                print("Mouseover event catched")
                currentObject.setOwnToolTip()
                return True
            else:
                self.log(str(type(currentObject))+" not recognized")           
             
        #elif event.type() == QEvent.Leave:
        #    pass
        return False

    def showMessageBox(self, title, message):
        '''
        convinence wrapper
        '''
        msg = QMessageBox(QMessageBox.Information, title, message, parent=self) 
        msg.setStandardButtons(QMessageBox.Ok)
        return msg.exec_()


if __name__ == '__main__':
    os.chdir(os.path.dirname(sys.argv[0]))
    app = QApplication(sys.argv)
    mainWin = MainWindow()
    ret = app.exec_()
    sys.exit(ret)
