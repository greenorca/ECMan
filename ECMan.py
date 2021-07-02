#!/usr/bin/python3

import ctypes
import os, os.path
import time
import socket
import subprocess
import sys
import webbrowser
from configparser import ConfigParser
from datetime import date
from pathlib import Path

from PySide2.QtCore import QEvent, Qt, QThreadPool
from PySide2.QtGui import QTextDocument, QKeySequence
# from time import sleep
from PySide2.QtWidgets import QApplication, QMainWindow, QFileDialog, QMessageBox, QGridLayout, QInputDialog, \
    QShortcut, QStatusBar

#from ui.Ui_MainWindow import Ui_MainWindow
from ui.Ui_MainWindow2 import Ui_MainWindow
from ui.ecLoginWizard import EcLoginWizard
from ui.ecManConfigDialog import EcManConfigDialog
from ui.ecManProgressDialog import EcManProgressDialog
from ui.ecShareWizard import EcShareWizard
from ui.lbClientButton import LbClient
from ui.logger import Logger
from ui.uiWorkers import ScannerWorker, CopyExamsWorker, RetrieveResultsWorker, ResetClientsWorker, \
    SetCandidateNamesWorker, SendMessageTask
from worker.computer import Computer
# import scripts.winrm_toolbox as remote_tools
from worker.logfile_handler import LogfileHandler

'''
Start app for exam deployment software
author: Sven Schirmer
last revision: see github
'''

# this information is used for "Info", only adjust for official releases
version = "2021-05-29"

class MainWindow(QMainWindow, Ui_MainWindow):

    def __init__(self, ui_demo=False):
        super(MainWindow, self).__init__()
        self.setupUi(self)
        self.grid_layout = QGridLayout()

        self.btnDetectClient.clicked.connect(self.detectClients)
        self.lineEditIpRange.returnPressed.connect(self.detectClients)
        self.btnSelectAllClients.clicked.connect(self.selectAllCLients)

        shortcut = QShortcut(QKeySequence(self.tr("Ctrl+A")), self)
        shortcut.activated.connect(self.selectAllCLients)

        self.btnUnselectClients.clicked.connect(self.unselectAllCLients)
        self.btnSelectExam.clicked.connect(self.selectExamByWizard)
        self.btnSelectExam.setEnabled(True)

        self.btnPrepareExam.clicked.connect(self.prepareExam)
        self.btnPrepareExam.setEnabled(False)

        self.btnGetExams.clicked.connect(self.retrieveExamFilesByWizard)
        self.btnGetExams.setEnabled(True)
        self.btnSaveExamLog.clicked.connect(self.saveExamLog)
        # self.btnSaveExamLog.setEnabled(False)

        self.actionBearbeiten.triggered.connect(self.openConfigDialog)
        self.actionAlle_Benutzer_benachrichtigen.triggered.connect(self.sendMessage)
        self.actionAlle_Clients_zur_cksetzen.triggered.connect(self.resetClients)
        self.actionAlle_Clients_rebooten.triggered.connect(self.rebootAllClients)
        self.actionAlle_Clients_herunterfahren.triggered.connect(self.shutdownAllClients)
        self.actionOnlineHelp.triggered.connect(self.openHelpUrl)
        self.actionOfflineHelp.triggered.connect(self.openHelpUrlOffline)
        self.actionSortClientByCandidateName.triggered.connect(self.sortButtonsByCandidateName)
        self.actionSortClientByComputerName.triggered.connect(self.sortButtonsByComputerName)
        self.actionVersionInfo.triggered.connect(self.showVersionInfo)
        self.actionDisplayIPs.triggered.connect(self.toggleClientIpDisplay)

        self.btnApplyCandidateNames.clicked.connect(self.applyCandidateNames)
        self.btnNameClients.clicked.connect(self.activateNameTab)

        self.btnBlockUsb.clicked.connect(self.blockUsb)
        self.btnBlockWebAccess.clicked.connect(self.blockWebAccess)

        self.appTitle = 'ECMan - Exam Client Manager'
        self.setWindowTitle(self.appTitle)

        self.logger = Logger(self.textEditLog)

        self.lb_directory = None
        self.advancedUi = False
        self.configure()
        self.show()
        if ui_demo is False:
            self.detectClients()

        else:
            self.clientFrame.setLayout(self.grid_layout)
            for i in range(6):
                self.addTestClient(i + 100)

        self.statusBar = QStatusBar();
        self.setStatusBar(self.statusBar)

    def sortButtonsByCandidateName(self):
        '''
        sort LbClient-widgets by candidate name
        :return: nothing
        '''
        clients = [self.grid_layout.itemAt(i).widget() for i in range(self.grid_layout.count())]
        clients = sorted(clients, key=lambda client: client.computer.candidateName)
        self.arrangeClientButtons(clients)

    def sortButtonsByComputerName(self):
        '''
        supposed to sort LbClient-widgets by candidate name
        :return: nothing
        '''
        clients = [self.grid_layout.itemAt(i).widget() for i in range(self.grid_layout.count())]
        clients = sorted(clients, key=lambda client: client.computer.getHostName())
        self.arrangeClientButtons(clients)

    def toggleClientIpDisplay(self):
        clients = [self.grid_layout.itemAt(i).widget() for i in range(self.grid_layout.count())]
        for client in clients:
            client.toggleShowIp()

    def arrangeClientButtons(self, clients):
        try:
            for i in reversed(range(self.grid_layout.count())):
                self.grid_layout.removeItem(self.grid_layout.itemAt(i))
        except:
            pass

        self.clientFrame.setLayout(self.grid_layout)
        for button in clients:
            self.grid_layout.addWidget(button, self.grid_layout.count() / 4, self.grid_layout.count() % 4)

        self.clientFrame.setLayout(self.grid_layout)


    def activateNameTab(self):
        if self.textEditCandidates.toPlainText()=="":
            candidates = "\n".join(str(x+1) for x in range(self.grid_layout.count()))
            self.textEditCandidates.setText(candidates)

        self.tabs.setCurrentWidget(self.tab_candidates)


    def openHelpUrl(self):
        webbrowser.open(self.config.get("General", "wikiurl", fallback="https://github.com/greenorca/ECMan/wiki"))

    def openHelpUrlOffline(self):
        webbrowser.open("file://" + os.getcwd().replace("\\", "/") + "/help/Home.html")

    def checkOldLogFiles(self):
        """
        dummy,
        """
        pass

    def blockUsb(self):
        block = self.btnBlockUsb.text() == "USB blockieren"
        clients = [self.grid_layout.itemAt(i).widget() for i in range(self.grid_layout.count())
                   if self.grid_layout.itemAt(i).widget().isSelected]

        if block:
            for client in clients:
                client.blockUsbAccessThread()
            self.btnBlockUsb.setText("USB freigeben")
        else:
            for client in clients:
                client.allowUsbAccessThread()
            self.btnBlockUsb.setText("USB blockieren")


    def blockWebAccess(self):
        block = self.btnBlockWebAccess.text() == "Web blockieren"
        clients = [self.grid_layout.itemAt(i).widget() for i in range(self.grid_layout.count())
                   if self.grid_layout.itemAt(i).widget().isSelected]
        if block:
            for client in clients:
                client.blockInternetAccessThread()

            self.btnBlockWebAccess.setText("Web freigeben")

        else:
            for client in clients:
                client.allowInternetAccessThread()

            self.btnBlockWebAccess.setText("Web blockieren")



    def resetClients(self):
        """
        resets remote files and configuration for all connected clients
        """

        items = ["Ja, Namen zurücksetzen","Nein, Namen beibehalten"]
        item, ok = QInputDialog().getItem(self, "LB-Status zurücksetzen",
                                          "USB-Sticks und Internet werden freigeben.\nDaten im Benutzerverzeichnis werden NICHT gelöscht.\nKandidaten-Namen zurücksetzen? ",
                                          items, 0, False)
        if ok is False:
            return

        resetCandidateName = True if item.startswith("Ja") else False

        clients = [self.grid_layout.itemAt(i).widget() for i in range(self.grid_layout.count())]

        progressDialog = EcManProgressDialog(self, "Reset Clients")
        progressDialog.setMaxValue(self.grid_layout.count())
        progressDialog.resetValue()
        progressDialog.open()

        self.worker = ResetClientsWorker(clients, resetCandidateName)
        self.worker.updateProgressSignal.connect(progressDialog.incrementValue)
        self.worker.start()

    def closeEvent(self, event):
        """
        overrides closeEvent of base class, clean up

        """
        print("cleaning up...")
        #         try:* especially remove shares created on Windows hosts
        #             for share in self.sharenames:
        #                 Thread(target=self.runLocalPowerShellAsRoot("Remove-SmbShare -Name {} -Force".format(share))).start()
        #         except Exception:
        #             pass
        #
        print("done cleaning up...")
        super(MainWindow, self).closeEvent(event)

    def selectAllCLients(self):
        """
        marks / selects all connected client pcs
        """
        for i in range(self.grid_layout.count()):
            self.grid_layout.itemAt(i).widget().select()

    def unselectAllCLients(self):
        """
        unmarks / unselects all connected client pcs
        """
        for i in range(self.grid_layout.count()):
            self.grid_layout.itemAt(i).widget().unselect()

    def shutdownAllClients(self):
        for i in range(self.grid_layout.count()):
            self.grid_layout.itemAt(i).widget().shutdownClient()

    def rebootAllClients(self):
        for i in range(self.grid_layout.count()):
            self.grid_layout.itemAt(i).widget().computer.reboot()
            self.grid_layout.itemAt(i).widget().deleteLater()
        # TODO TEST sven
        #for i in range(self.grid_layout.count()):
        #    self.grid_layout.removeItem(self.grid_layout.itemAt(i))

    def sendMessage(self):

        message, ok = QInputDialog.getText(self, "Eingabe", "Nachricht an Kandidaten eingeben")
        if ok:
            for i in range(self.grid_layout.count()):
                QThreadPool.globalInstance().start(
                    SendMessageTask(self.grid_layout.itemAt(i).widget(), message)
                )

    def applyCandidateNames(self):
        """
        reads candidate names from respective textEditField (line by line)
        and applies these names to (random) client pcs
        """
        names = self.textEditCandidates.toPlainText().rstrip().splitlines()
        # cleanup and remove duplicate names
        names = [x.strip() for x in names]
        names = list(set(names))

        clients = [self.grid_layout.itemAt(i).widget() for i in range(self.grid_layout.count())]

        # select only the computers without candidate name
        if self.checkBox_OverwriteExisitingNames.checkState() != Qt.CheckState.Checked:
            clients = [x for x in clients if
                       x.computer.getCandidateName() == "" or x.computer.getCandidateName() is None]

        if len(names) > len(clients):
            self.showMessageBox("Fehler",
                                "Nicht genug Prüfungs-PCs für alle {} Kandidaten".format(str(len(names))),
                                messageType=QMessageBox.Warning)
            return

        progressDialog = EcManProgressDialog(self, "Fortschritt Kandidatennamen setzen")
        progressDialog.setMaxValue(len(names))
        progressDialog.resetValue()

        self.worker = SetCandidateNamesWorker(clients, names)
        self.worker.updateProgressSignal.connect(progressDialog.incrementValue)
        self.worker.start()

        progressDialog.open()
        self.tabs.setCurrentWidget(self.tab_pcs)

    def configure(self):
        """
        sets inial values for app
        """
        self.port = 5986
        self.server = None

        self.configFile = Path(str(Path.home()) + "/.ecman.conf")

        if not (self.configFile.exists()):
            result = self.openConfigDialog()

        if self.configFile.exists() or result == 1:
            self.readConfigFile()

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
            self.ipRange, ok = QInputDialog.getText(self, "Keine Verbindung zum Internet",
                                                    "Möglicherweise gelingt der Sichtflug. Bitte geben Sie die lokale IP-Adresse ein:")

            self.log("no connection to internet:" + str(ex))

    def readConfigFile(self):
        """
        reads config file into class variables
        """
        self.config = ConfigParser()
        self.config.read_file(open(str(self.configFile)))

        self.port = self.config.get("General", "winrm_port", fallback=5986)

        self.client_lb_user = self.config.get("Client", "lb_user", fallback="student")
        self.user = self.config.get("Client", "user", fallback="")
        self.passwd = self.config.get("Client", "pwd", fallback="")
        self.maxFiles = int(self.config.get("Client", "max_files", fallback="1000"))
        self.maxFileSize = int(
            self.config.get("Client", "max_filesize", fallback="1000")) * 1024 * 1024  # thats MB now...

        self.advancedUi = self.config.get('General','advanced_ui',fallback="False") == "True"
        pass

    def openConfigDialog(self):
        """
        opens configuration dialog
        """
        config_dialog = EcManConfigDialog(self)
        result = config_dialog.exec_()
        if result == 1:
            config_dialog.saveConfig()
            self.readConfigFile()
        return result

    def log(self, message):
        """
        basic logging functionality
        TODO: improve...
        """
        self.logger.log(message)

    def updateProgressBar(self, value):
        self.progressBar.setValue(value)
        if (value == self.progressBar.maximum()):
            self.enableButtons(True)
            self.progressBar.setEnabled(False)

    def enableButtons(self, enable):

        if type(enable) != bool:
            raise Exception("Invalid parameter, must be boolean")
        self.btnNameClients.setEnabled(enable)
        self.btnSelectAllClients.setEnabled(enable)
        self.btnUnselectClients.setEnabled(enable)
        self.btnPrepareExam.setEnabled(enable)
        self.btnGetExams.setEnabled(enable)
        self.btnSaveExamLog.setEnabled(enable)
        self.btnDetectClient.setEnabled(enable)
        self.btnBlockWebAccess.setEnabled(enable)
        self.btnBlockUsb.setEnabled(enable)

    def retrieveExamFilesByWizard(self):
        """
        retrieve exam files for all clients
        """
        # find all suitable clients (required array for later threading)
        clients = [self.grid_layout.itemAt(i).widget() for i in range(self.grid_layout.count())
                   if self.grid_layout.itemAt(i).widget().isSelected and
                   self.grid_layout.itemAt(i).widget().computer.state in [Computer.State.STATE_DEPLOYED,
                                                                          Computer.State.STATE_FINISHED,
                                                                          Computer.State.STATE_RETRIVAL_FAIL]]

        if len(clients) == 0:
            self.showMessageBox("Achtung", "Keine Clients ausgewählt bzw. deployed")
            return

        unknownClients = [c for c in clients if c.computer.getCandidateName() == "" or c.computer.getCandidateName() == None]

        for unknown in unknownClients:
            unknown.computer.state = Computer.State.STATE_RETRIVAL_FAIL
            unknown._colorizeWidgetByClientState()

        if unknownClients != []:
            choice = QMessageBox.critical(self,
                                          "Achtung",
                                          "{} clients ohne gültigen Kandidatennamen.<br>Rückholung für alle anderen fortsetzen?".format(
                                              str(len(unknownClients))),
                                          QMessageBox.Yes, QMessageBox.No)

            if choice == QMessageBox.No:
                return;

        clients = [c for c in clients if c not in unknownClients]

        retVal = QMessageBox.StandardButton.Yes
        if self.result_directory != "":

            items = ["Ergebnispfad neu auswählen", "Weiter mit bisherigem Verzeichnis"]
            item, ok = QInputDialog().getItem(self, "Achtung",
                          "LB-Ergebnisverzeichnis ist bereits ausgewählt.\nErneutes Abholen kann existierende Ergebnisse überschreiben.\nWas möchten Sie tun?",
                          items, 0, False)

            if ok is False:
                return

        if self.result_directory == "" or item == "Ergebnispfad neu auswählen":

            if self.server is None or self.server.connect() is not True:
                self.server = self.getServerCredentialsByWizard()
                if self.server is None:
                    return

            wizard = EcShareWizard(parent=self, server=self.server,
                                   wizardType=EcShareWizard.TYPE_RESULT_DESTINATION, advanced_Ui = self.advancedUi)


            wizard.setModal(True)
            result = wizard.exec_()
            print("I'm done, wizard result=" + str(result))
            if result == 1:
                print("selected values: %s - %s - %s" %
                      (wizard.field("username"), wizard.field("servername"), wizard.selectedPath))

                self.result_directory = wizard.selectedPath

            else:
                print("Abbruch, kein Zielverzeichnis ausgewählt")
                return

        self.result_directory = self.result_directory.replace("/", "#")
        self.log("save result files into: " + self.result_directory.replace("#", "\\"))

        progressDialog = EcManProgressDialog(self, "Fortschritt Ergebnisse kopieren")
        progressDialog.setMaxValue(len(clients))
        progressDialog.resetValue()
        progressDialog.open()

        self.log("starting to retrieve files")

        self.worker = RetrieveResultsWorker(clients, self.server.user, self.server.password, self.server.domain,
                                            self.result_directory, self.maxFiles, self.maxFileSize)
        self.worker.updateProgressSignal.connect(progressDialog.incrementValue)
        self.worker.start()

        self.btnSaveExamLog.setEnabled(True)

    def prepareExam(self):
        self.copyFilesToClient()
        pass

    def copyFilesToClient(self):
        """
        copies selected exam folder to all connected clients that are selected and not in STATE_DEPLOYED or STATE_FINISHED
        """
        if self.lb_directory == None or self.lb_directory == "":
            self.showMessageBox("Fehler", "Kein Prüfungsordner ausgewählt")
            return

        clients = [self.grid_layout.itemAt(i).widget() for i in range(self.grid_layout.count())
                   if self.grid_layout.itemAt(i).widget().isSelected and
                    self.grid_layout.itemAt(i).widget().computer.state not in [Computer.State.STATE_DEPLOYED,
                                                                              Computer.State.STATE_FINISHED]]

        if len([x for x in clients if x.computer.candidateName == None]) > 0:
            self.showMessageBox("Warnung", "Bitte Kandidatenname für alle PCs vergeben")
            return

        if len(clients) == 0:
            self.showMessageBox("Warnung", "Keine Client-PCs ausgewählt oder Prüfungen bereits aktiv")
            return



        progressDialog = EcManProgressDialog(self, "Fortschritt LB-Client-Deployment")
        progressDialog.setMaxValue(len(clients))
        progressDialog.resetValue()
        progressDialog.open()

        self.worker = CopyExamsWorker(clients, self.server.user, self.server.password, self.server.domain,
                                      src = self.lb_directory,
                                      reset=(self.checkBoxWipeHomedir.checkState() == Qt.CheckState.Checked))
        self.worker.updateProgressSignal.connect(progressDialog.incrementValue)
        self.worker.start()

    def detectClients(self):
        """
        starts portscan to search for winrm enabled clients
        """
        ip_range = self.lineEditIpRange.text()
        if not (ip_range.endswith('*')):
            self.showMessageBox('Eingabefehler', 'Gültiger IP-V4 Bereich endet mit * (z.B. 192.168.0.*)')
            return

        try:
            self.worker.exit()
        except Exception as ex:
            print("crashed on stopping existing scanner thread: "+str(ex))

        self.ipRange = ip_range
        self.progressBar.setEnabled(True)
        self.progressBar.setValue(0)

        self.enableButtons(enable=False)
        self.clientCount = 0
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
        """
        populate GUI with newly received client ips
        param ip: only last byte required
        param scan: wether or not scan the Client (set to False only for GUI testing)
        """
        self.log("new client signal received: " + str(ip))
        self.clientCount += 1
        self.statusBar.showMessage(str(self.clientCount)+ " clients detected", 0)

        clientIp = self.ipRange.replace("*", str(ip))
        button = LbClient(clientIp, remoteAdminUser=self.user, passwd=self.passwd,
                          candidateLogin=self.client_lb_user, parentApp=self)
        button.setMinimumHeight(50)
        # button.installEventFilter(self)
        self.grid_layout.addWidget(button, self.grid_layout.count() / 4, self.grid_layout.count() % 4)
        self.clientFrame.setLayout(self.grid_layout)
        # QtGui.qApp.processEvents()

    def addTestClient(self, ip):
        """
        populate GUI with dummy buttons
        param ip: only last byte required
        """
        self.log("new client signal received: " + str(ip))
        clientIp = self.ipRange.replace("*", str(ip))
        button = LbClient(clientIp, remoteAdminUser=self.user, passwd=self.passwd,
                          candidateLogin=self.client_lb_user,
                          parentApp=self, test=True)
        button.setMinimumHeight(50)
        # button.installEventFilter(self)
        self.grid_layout.addWidget(button, self.grid_layout.count() / 4, self.grid_layout.count() % 4)
        self.clientFrame.setLayout(self.grid_layout)
        # QtGui.qApp.processEvents()

    def getExamPath(self):
        return self.lb_directory

    def getServerCredentialsByWizard(self):
        """
        open server config and login dialog, returns server object or None
        """
        wizard = EcLoginWizard(parent=self,
                               username=self.config.get("General", "username", fallback=""),
                               domain=self.config.get("General", "domain", fallback=""),
                               servername=self.config.get("General", "lb_server", fallback=""))

        wizard.setModal(True)
        result = wizard.exec_()
        print("I'm done, wizard result=" + str(result))
        if result == 1:
            self.config["General"]["username"] = wizard.field("username")
            self.config["General"]["domain"] = wizard.field("domainname")
            self.config["General"]["servername"] = wizard.server.serverName

            self.saveConfig()
            return wizard.server

        return None

    def selectExamByWizard(self):
        """
        provides ability to select serverName share plus logon credentials and lb directory using a wizard
        """

        if self.server == None or self.server.connect() is False:
            self.server = self.getServerCredentialsByWizard()

        wizard = EcShareWizard(parent=self, server=self.server,
                               wizardType=EcShareWizard.TYPE_LB_SELECTION, advanced_Ui=self.advancedUi)

        wizard.setModal(True)
        result = wizard.exec_()
        print("I'm done, wizard result=" + str(result))
        if result == 1:
            self.lb_directory = wizard.selectedPath
            self.setWindowTitle(self.appTitle + " - LB-Verzeichnis::" + self.lb_directory.split("/")[-1])
            self.log("setup LB directory: " + self.lb_directory.split("/")[-1])
            self.btnPrepareExam.setEnabled(True)
            self.lblExamName.setText(self.lb_directory)
        else:
            self.log("no valid share selected")

    def saveExamLog(self):
        """
        on demand, store all client logs as PDF
        """
        if self.result_directory == None or len(self.result_directory) == 0:
            self.showMessageBox("Fehler",
                                "Ergebnispfad für Prüfungsdaten nicht gesetzt.<br>Bitte zuerst Prüfungsdaten abholen.",
                                QMessageBox.Error)
            return

        clients = [self.grid_layout.itemAt(i).widget() for i in range(self.grid_layout.count())]
        for client in clients:
            lb_dataDirectory = client.computer.lb_dataDirectory.split("#")[-1]
            pdfFileName = "protocol_" + date.today().__str__() + "_" + client.computer.getCandidateName().replace(" ",
                                                                                                                  "_") + ".pdf"
            LogfileHandler(client.computer.logfile_name, client.computer.getCandidateName()). \
                createPdf(pdfFileName)
            if not (self.server.connect()):
                self.showMessageBox("Fehler",
                                    "Verbindung zum Server kann nicht aufgebaut werden.",
                                    QMessageBox.Error)
                return

            with open(pdfFileName, "rb") as file:
                sharename = self.result_directory.replace("##", "").split("#")[1]
                destination = "/".join(
                    self.result_directory.replace("##", "").split("#")[2:]) + "/" + lb_dataDirectory + "/"
                self.server.conn.storeFile(sharename, destination + pdfFileName, file)

    def __runLocalPowerShellAsRoot(self, command):
        """
        maybe useful at some stage again
        # see https://docs.microsoft.com/en-us/windows/desktop/api/shellapi/nf-shellapi-shellexecutew#parameters
        :param command:
        :return:
        """

        retval = ctypes.windll.shell32.ShellExecuteW(None, "runas",  # runas admin,
                                                     "C:\\WINDOWS\\system32\\WindowsPowerShell\\v1.0\\powershell.exe",
                                                     # file to run
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

    def saveConfig(self):
        """
        write to file what's currently set in config
        """
        if not (self.configFile.exists()):
            self.configFile.touch()

        self.config.write(open(self.configFile, 'w'))

    def eventFilter(self, currentObject, event):
        """
        unused, define mouseover events (with tooltips) for LbClient widgets
        """
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
        """
        convinence wrapper
        """
        msg = QMessageBox(messageType, title, message, parent=self)
        if messageType != QMessageBox.Information:
            msg.setStandardButtons(QMessageBox.Abort)
        return msg.exec_()

    def showVersionInfo(self):
        info = "<b>Offizielles Release:</b><br>" + version
        try:
            # latest release - make sure to save this file before building :-)
            modDate = time.localtime(os.path.getmtime(__file__))
            info = info + "<br><br><b>Diese Version:</b><br>" + time.strftime("%Y-%m-%d", modDate)
        except:
            pass

        self.showMessageBox("ECMan - Version", info)

if __name__ == '__main__':
    '''
    print("os.chdir: "+os.path.dirname(__file__))
    if os.name == "posix":
        os.chdir(os.path.dirname(__file__))
    else:
        print("switching to directory: "+os.path.dirname(sys.path[0]))
        os.chdir(os.path.dirname(sys.path[0]))
        #os.chdir(os.path.dirname(__file__))
    '''
    abspath = os.path.abspath(__file__)
    dname = os.path.dirname(abspath)
    print("cd: " + dname)
    os.chdir(dname)

    if not (os.path.exists("logs")):
        os.makedirs("logs")

    app = QApplication(sys.argv)
    ui_demo = False
    if len(sys.argv) > 1:
        ui_demo = sys.argv[1] == "--demo"
    mainWin = MainWindow(ui_demo=ui_demo)
    ret = app.exec_()
    sys.exit(ret)
