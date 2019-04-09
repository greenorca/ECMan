import os, sys, socket
import subprocess, ctypes
# from time import sleep
from PySide2.QtWidgets import QApplication, QMainWindow, QFileDialog, QMessageBox, QGridLayout, QInputDialog
from PySide2.QtGui import QTextDocument
from PySide2.QtCore import QUrl, QEvent, Qt, QThreadPool
from threading import Thread
from configparser import ConfigParser
from pathlib import Path
from datetime import date
# import scripts.winrm_toolbox as remote_tools
from worker.logfile_handler import LogfileHandler
from worker.sharebrowser import ShareBrowser
from worker.computer import Computer
from ui.logger import Logger
from ui.uiWorkers import ScannerWorker, CopyExamsWorker, RetrieveResultsWorker, ResetClientsWorker, SetCandidateNamesWorker, SendMessageTask
from ui.lbClientButton import LbClient
from ui.Ui_MainWindow import Ui_MainWindow
from ui.ecManConfigDialog import EcManConfigDialog
from ui.ecManProgressDialog import EcManProgressDialog
from ui.ecWiz import EcWizard

'''
Start app for exam deployment software
author: Sven Schirmer
last_revision: 2019-03-26

'''


class MainWindow(QMainWindow, Ui_MainWindow):

    def __init__(self):
        super(MainWindow, self).__init__()
        self.setupUi(self)
        self.grid_layout = QGridLayout()
        
        self.btnDetectClient.clicked.connect(self.detectClients)
        
        self.btnSelectAllClients.clicked.connect(self.selectAllCLients)
        
        self.btnSelectExam.clicked.connect(self.selectExamByWizard)
        self.btnSelectExam.setEnabled(True)
        
        self.btnPrepareExam.clicked.connect(self.prepareExam)
        self.btnPrepareExam.setEnabled(True)
        
        self.btnGetExams.clicked.connect(self.retrieveExamFilesByWizard)
        self.btnGetExams.setEnabled(True)
        self.btnSaveExamLog.clicked.connect(self.saveExamLog)
        #self.btnSaveExamLog.setEnabled(False)
        
        self.actionBearbeiten.triggered.connect(self.openConfigDialog)      
        self.actionAlle_Clients_deaktivieren.triggered.connect(self.unselectAllCLients)
        self.actionAlle_Benutzer_benachrichtigen.triggered.connect(self.sendMessage)
        self.actionAlle_Clients_zur_cksetzen.triggered.connect(self.resetClients)
        self.actionAlle_Clients_rebooten.triggered.connect(self.rebootAllClients)
        self.actionAlle_Clients_herunterfahren.triggered.connect(self.shutdownAllClients)
               
        self.btnApplyCandidateNames.clicked.connect(self.applyCandidateNames)
                
        # self.progressBar.setStyleSheet("QProgressBar { background-color: #CD96CD; width: 10px; margin: 0.5px; }")
        self.appTitle = 'ECMan - Exam Client Manager'                             
        self.setWindowTitle(self.appTitle)
        
        self.logger = Logger(self.textEditLog)
        self.show()
        self.getConfig()
        
        self.network_username = None
        self.network_password = None
        self.network_domain = None
        self.network_servername = None
        
        self.detectClients()
    
    def checkOldLogFiles(self):
        '''
        dummy, 
        '''
        pass
    
    def resetClients(self):
        '''
        resets remote files and configuration for all connected clients
        '''

        items = ["Nein", "Ja"]
        item, ok = QInputDialog().getItem(self, "Alles zurücksetzen?",
                                          "USB-Sticks und Internet werden freigeben.\nKandidaten-Namen ebenfalls zurücksetzen? ",
                                          items, 0, False) 
        if ok == False:
            return
        
        resetCandidateName = True if item == "Ja" else False
        
        clients = [self.grid_layout.itemAt(i).widget() for i in range(self.grid_layout.count())]
        
        progressDialog = EcManProgressDialog(self, "Reset Clients")
        progressDialog.setMaxValue(self.grid_layout.count())
        progressDialog.resetValue()
        progressDialog.open()        
        
        self.worker = ResetClientsWorker(clients, resetCandidateName)
        self.worker.updateProgressSignal.connect(progressDialog.incrementValue)
        self.worker.start()
        
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
        super(MainWindow, self).closeEvent(event) 
    
    def selectAllCLients(self):
        '''
        marks / selects all connected client pcs 
        '''
        for i in range(self.grid_layout.count()): 
            self.grid_layout.itemAt(i).widget().select()            
            
    def unselectAllCLients(self):
        '''
        unmarks / unselects all connected client pcs 
        '''
        for i in range(self.grid_layout.count()): 
            self.grid_layout.itemAt(i).widget().unselect()
    
    def shutdownAllClients(self):
        for i in range(self.grid_layout.count()): 
            self.grid_layout.itemAt(i).widget().shutdownClient()
    
    def rebootAllClients(self):
        for i in range(self.grid_layout.count()): 
            self.grid_layout.itemAt(i).widget().computer.reboot()

    def sendMessage(self):
        
        message, ok = QInputDialog.getText(self, "Eingabe", "Nachricht an Kandidaten eingeben")
        if ok:
            for i in range(self.grid_layout.count()): 
                QThreadPool.globalInstance().start(
                    SendMessageTask(self.grid_layout.itemAt(i).widget(), message)
                    )
     
    def applyCandidateNames(self):
        '''
        reads candidate names from respective textEditField (line by line)
        and applies these names to (random) client pcs
        '''
        names = self.textEditCandidates.toPlainText().rstrip().splitlines()
        # cleanup and remove duplicate names
        names = [x.strip() for x in names]
        names = list(set(names))
        
        clients = [self.grid_layout.itemAt(i).widget() for i in range(self.grid_layout.count())]
        
        # select only the computers without candidate name
        if self.checkBox_OverwriteExisitingNames.checkState() != Qt.CheckState.Checked:
            clients = [x for x in clients if x.computer.getCandidateName() == ""]
            
        if len(names) > len(clients):
            self.showMessageBox("Fehler",
                                "Nicht genug Prüfungs-PCs für alle {} Kandidaten".format(str(len(names))),
                                messageType=QMessageBox.Warning)
            return 
        
        progressDialog = EcManProgressDialog(self, "Hello World")
        progressDialog.setMaxValue(len(names))
        progressDialog.resetValue()
        progressDialog.open()        
        
        self.worker = SetCandidateNamesWorker(clients, names)
        self.worker.updateProgressSignal.connect(progressDialog.incrementValue)
        self.worker.start() 
        
    def getConfig(self):
        '''
        sets inial values for app 
        '''        
        self.lb_server = ""
        self.port = 5986
        self.user = ""
        self.passwd = ""
        
        self.configFile = Path(str(Path.home()) + "/.ecman.conf")
        
        if not(self.configFile.exists()):
            result = self.openConfigDialog()
            
        if self.configFile.exists() or result == 1:
            self.refreshConfig()
        
        self.result_directory = ""
        
        self.sharenames = []  # dump all eventually created local Windows-Shares in this array
        self.debug = True
        # fetch own ip adddress
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            s.connect(('9.9.9.9', 1))  # connect() for UDP doesn't send packets
            self.ip_address = s.getsockname()[0]
            parts = self.ip_address.split(".")[0:-1]
            self.ipRange = ".".join(parts) + ".*"
            self.lineEditIpRange.setText(self.ipRange)
            self.appTitle = self.windowTitle() + " on " + self.ip_address
            self.setWindowTitle(self.appTitle)
        except Exception as ex:
            self.ip_address, ok = QInputDialog.getText(self, "Keine Verbindung zum Internet",
                                                       "Möglicherweise gelingt der Sichtflug. Bitte geben Sie die lokale IP-Adresse ein:")
            
            self.log("no connection to internet:" + str(ex))
            
    def refreshConfig(self):
        '''
        reads config file into class variables
        '''
        config = ConfigParser()
        config.read_file(open(str(self.configFile)))
        
        self.lb_server = config.get("General", "lb_server", fallback="")
        self.port = config.get("General", "winrm_port", fallback=5986)
        self.client_lb_user = config.get("Client", "lb_user", fallback="student") 
        self.user = config.get("Client", "user", fallback="")
        self.passwd = config.get("Client", "pwd", fallback="")    
    
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
        if (value == self.progressBar.maximum()): 
            self.enableButtons(True)
    
    def enableButtons(self, enable):
        
        if type(enable) != bool:
            raise Exception("Invalid parameter, must be boolean")
        
        self.btnSelectAllClients.setEnabled(enable)           
        self.btnPrepareExam.setEnabled(enable)
        self.btnGetExams.setEnabled(enable)
        self.btnDetectClient.setEnabled(enable)        
        
    def retrieveExamFilesByWizard(self):
        '''
        retrieve exam files for all clients
        '''
        # find all suitable clients (required array for later threading)
        clients = [self.grid_layout.itemAt(i).widget() for i in range(self.grid_layout.count()) 
                   if self.grid_layout.itemAt(i).widget().isSelected and 
                   self.grid_layout.itemAt(i).widget().computer.state in [Computer.State.STATE_DEPLOYED,
                                                                          Computer.State.STATE_FINISHED,
                                                                          Computer.State.STATE_RETRIVAL_FAIL]]
                
        if len(clients) == 0:
            self.showMessageBox("Abbruch", "Keine Clients ausgewählt bzw. deployed")
            return 
        
        unknownClients = [c for c in clients if c.computer.getCandidateName() == ""]
        
        for unknown in unknownClients:
            unknown.computer.state = Computer.State.STATE_RETRIVAL_FAIL
            unknown._colorizeWidgetByClientState()
        
        if unknownClients != []: 
            choice = QMessageBox.critical(self,
                              "Achtung",
                              "{} clients ohne gültigen Kandidatennamen.<br>Rückholung für alle anderen fortsetzen?".format(str(len(unknownClients))),
                              QMessageBox.Yes, QMessageBox.No) 
               
            if choice == QMessageBox.No:
                return;
        
        clients = [c for c in clients if c not in unknownClients]
        
        retVal = QMessageBox.StandardButton.Yes
        if self.result_directory != "":
            retVal = QMessageBox.question(self, "Warnung", "Ergebnispfad bereits gesetzt: {}, neu auswählen".format(
                self.result_directory.replace("#", "/")))
            
        if retVal == QMessageBox.StandardButton.Yes:
            if socket.gethostname() == "sven-V5-171":
                wizard = EcWizard(parent=self, username="sven", domain="HSH", servername="odroid/lb_share",
                          wizardType=EcWizard.TYPE_LB_SELECTION)
            else:
                wizard = EcWizard(parent=None, username=self.network_username, domain=self.network_domain, servername=self.network_servername,
                          wizardType=EcWizard.TYPE_RESULT_DESTINATION)
                wizard = EcWizard(parent=self, username="sven.schirmer@wiss-online.ch", domain="", servername="NSSGSC01/LBV",
                          wizardType=EcWizard.TYPE_RESULT_DESTINATION)
            
            wizard.setModal(True)
            result = wizard.exec_()
            print("I'm done, wizard result=" + str(result))
            if result == 1:
                print("selected values: %s - %s - %s" % 
                      (wizard.field("username"), wizard.field("servername"), wizard.defaultShare))    
                
                self.network_username = wizard.field("username")
                self.network_password = wizard.field("password")
                self.network_domain = wizard.field("domainname")
                self.network_servername = wizard.server.serverName
            
                self.result_directory = "//" + self.network_servername + "/" + wizard.defaultShare
                
            else:
                print("Abbruch, kein Zielverzeichnis ausgewählt")
                return
                
        else:
            print("Abbruch, kein Zielverzeichnis ausgewählt")
            return
             
        self.result_directory = self.result_directory.replace("/", "#")     
        self.log("save result files into: " + self.result_directory.replace("#", "\\"))
           
        progressDialog = EcManProgressDialog(self, "Hello World")
        progressDialog.setMaxValue(len(clients))
        progressDialog.resetValue()
        progressDialog.open()
         
        self.log("starting to retrieve files")
        
        self.worker = RetrieveResultsWorker(clients, self.result_directory, self.network_username,
                                            self.network_password, self.network_domain)
        self.worker.updateProgressSignal.connect(progressDialog.incrementValue)
        self.worker.start()        
        
        self.btnSaveExamLog.setEnabled(True)
        
        '''
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
        '''
      
    
    def prepareExam(self):
        self.copyFilesToClient()
        pass
    
    def copyFilesToClient(self):
        '''
        copies selected exam folder to all connected clients that are selected and not in STATE_DEPLOYED or STATE_FINISHED
        '''
        if self.lb_directory == "" or self.lb_directory == None:
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
        progressDialog.resetValue()
        progressDialog.open()
        
        self.worker = CopyExamsWorker(clients, self.lb_directory, server_user=self.network_username,
                                      server_passwd=self.network_password,
                                      server_domain=self.network_domain)
        self.worker.updateProgressSignal.connect(progressDialog.incrementValue)
        self.worker.start()    
        
    def detectClients(self):
        '''
        starts portscan to search for winrm enabled clients
        '''
        ip_range = self.lineEditIpRange.text()
        if not(ip_range.endswith('*')):
            self.showMessageBox('Eingabefehler', 'Gültiger IP-V4 Bereich endet mit * (z.B. 192.168.0.*)')
            return

        self.ipRange = ip_range
        self.progressBar.setEnabled(True)
        self.progressBar.setValue(0)
        
        self.enableButtons(enable=False)
        # clear previous client buttons
        try:
            for i in reversed(range(self.grid_layout.count())): 
                self.grid_layout.itemAt(i).widget().close()
                self.grid_layout.itemAt(i).widget().deleteLater()
        except:
            pass
        self.clientFrame.setLayout(self.grid_layout)

        self.progressBar.setMaximum(253)
        self.worker = ScannerWorker(self.ipRange, self.ip_address)
        self.worker.updateProgressSignal.connect(self.updateProgressBar)
        self.worker.addClientSignal.connect(self.addClient)
        self.worker.start()        
        
    def addClient(self, ip):
        '''
        populate GUI with newly received client ips (only last byte required)
        '''
        self.log("new client signal received: " + str(ip))
        clientIp = self.ipRange.replace("*", str(ip))
        button = LbClient(clientIp, remoteAdminUser=self.user, passwd=self.passwd,
                          candidateLogin=self.client_lb_user, parentApp=self)
        button.setMinimumHeight(50)
        # button.installEventFilter(self)
        self.grid_layout.addWidget(button, self.grid_layout.count() / 4, self.grid_layout.count() % 4)  
        self.clientFrame.setLayout(self.grid_layout)     
        # QtGui.qApp.processEvents()
        
    def getExamPath(self):
        return self.lb_directory
    
    def selectExamByWizard(self):
        '''
        provides ability to select serverName share plus logon credentials and lb directory using a wizard 
        '''
        if socket.gethostname() == "sven-V5-171":
            wizard = EcWizard(parent=self, username="sven", domain="HSH", servername="odroid/lb_share",
                          wizardType=EcWizard.TYPE_LB_SELECTION)
        else:
            wizard = EcWizard(parent=self, wizardType=EcWizard.TYPE_LB_SELECTION)
            wizard = EcWizard(parent=self, username="sven.schirmer@wiss-online.ch", domain="", servername="NSSGSC01/LBV", wizardType=EcWizard.TYPE_LB_SELECTION)
       
        wizard.setModal(True)
        result = wizard.exec_()
        print("I'm done, wizard result=" + str(result))
        if result == 1:
            print("selected values: %s - %s - %s - %s" % 
                  (wizard.field("username"), wizard.field("password"), wizard.field("servername"), wizard.defaultShare))    
            
            self.network_username = wizard.field("username")
            self.network_password = wizard.field("password")
            self.network_domain = wizard.field("domainname")
            self.network_servername = wizard.server.serverName
            
            self.lb_directory = "//" + self.network_servername + "/" + wizard.defaultShare
            self.lb_directory = self.lb_directory.replace("/", "#")    
                     
            self.setWindowTitle(self.appTitle + " - LB-Verzeichnis::" + self.lb_directory.split("#")[-1])
            self.log("setup LB directory: " + self.lb_directory)
            self.btnPrepareExam.setEnabled(True)
            
        else:
            print("TODO: offer fallback with local shares?")
        
    def saveExamLog(self):
        '''
        on demand, store all client logs as PDF
        todo - test
        '''
        #fname = QFileDialog.getExistingDirectory(self, 'Zielverzeichnis für Logdaten', options=QFileDialog.ShowDirsOnly)
        #if fname != '':
        if self.result_directory==None or len(self.result_directory)==0:
            self.showMessageBox("Fehler", 
                                "Ergebnispfad für Prüfungsdaten nicht gesetzt.<br>Bitte zuerst Prüfungsdaten abholen.", 
                                QMessageBox.Error)
            return 
        
        clients = [self.grid_layout.itemAt(i).widget() for i in range(self.grid_layout.count())]
        for client in clients:
            lb_dataDirectory = client.computer.lb_dataDirectory.split("#")[-1]
            pdfFileName = "protocol_"+date.today().__str__()+"_"+client.computer.getCandidateName().replace(" ","_")+".pdf"
            LogfileHandler(client.computer.logfile_name, client.computer.getCandidateName()).\
                createPdf(pdfFileName)
            smbServer = ShareBrowser(self.network_servername, self.network_username, self.network_password) 
            if not (smbServer.connect()):
                self.showMessageBox("Fehler", 
                            "Verbindung zum Server kann nicht aufgebaut werden.", 
                            QMessageBox.Error)
                return 
        
            with open(pdfFileName, "rb") as file:
                sharename = self.result_directory.replace("##","").split("#")[1]
                destination = "/".join(self.result_directory.replace("##","").split("#")[2:])+"/"+lb_dataDirectory+"/"
                smbServer.conn.storeFile(sharename, destination + pdfFileName, file)
        
        
    def __runLocalPowerShellAsRoot(self, command):
        # see https://docs.microsoft.com/en-us/windows/desktop/api/shellapi/nf-shellapi-shellexecutew#parameters
        retval = ctypes.windll.shell32.ShellExecuteW(None , "runas",  # runas admin, 
            "C:\\WINDOWS\\system32\\WindowsPowerShell\\v1.0\\powershell.exe",  # file to run
            command,  # actual powershell command
            None, 0)  # last param disables popup powershell window...
    
        if retval != 42:
            self.log("ReturnCode after creating smbShare: " + str(retval))
            subprocess.run(["C:\\WINDOWS\\system32\\WindowsPowerShell\\v1.0\\powershell.exe", "Get-SmbShare"])
            raise Exception("ReturnCode after running powershell: " + str(retval))
        
    def __openFile(self):
        fname = QFileDialog.getOpenFileName(self, 'Open file', '/home')
        if fname[0]:
            f = open(fname[0], 'r')
        with f:
            data = f.read()
            doc = QTextDocument(data, None)
            self.textEditLog.setDocument(doc)
    
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
                self.log(str(type(currentObject)) + " not recognized")           
             
        # elif event.type() == QEvent.Leave:
        #    pass
        return False

    def showMessageBox(self, title, message, messageType=QMessageBox.Information):
        '''
        convinence wrapper
        '''
        msg = QMessageBox(messageType, title, message, parent=self) 
        if messageType != QMessageBox.Information:
            msg.setStandardButtons(QMessageBox.Abort)
        return msg.exec_()


if __name__ == '__main__':
    if os.name == "posix":
        os.chdir(os.path.dirname(__file__))
    else:
        os.chdir(os.path.dirname(sys.path[0]))
        #os.chdir(os.path.dirname(__file__))
    if not(os.path.exists("logs")):
        os.makedirs("logs")
        
    app = QApplication(sys.argv)
    mainWin = MainWindow()
    ret = app.exec_()
    sys.exit(ret)
