'''
Created on Jan 20, 2019

@author: sven
'''

from time import asctime, clock

from PySide2.QtCore import Qt, QThreadPool, QRunnable, Signal, QObject
from PySide2.QtGui import QFont, QPalette
from PySide2.QtWidgets import QPushButton, QMenu, QInputDialog, QMessageBox

from ui.ecManRemoteTerminal import EcManRemoteTerminal
from worker.computer import Computer


class LbClient(QPushButton):
    '''
    class to handle and visualize state of lb_client_computers
    '''

    def __init__(self, ip, remoteAdminUser, passwd, candidateLogin, parentApp, test=False):
        self.computer = Computer(ip,
                                 remoteAdminUser=remoteAdminUser, passwd=passwd,
                                 candidateLogin=candidateLogin,
                                 fetchHostname=(test == False))
        QPushButton.__init__(self, self.computer.ip)
        self.parentApp = parentApp
        self.log = LbClient.Log()
        self.isSelected = False
        self.lastUpdate = None
        if test == True:
            self.computer.state = Computer.State.STATE_COPY_FAIL
            self.setLabel()
            self._colorizeWidgetByClientState()
            return

        myThread = LbClient.CheckStatusThread(self)
        myThread.connector.checkStateSignal.connect(self.setLabel)
        myThread.connector.checkStateSignal.connect(self.setOwnToolTip)
        QThreadPool.globalInstance().start(myThread)

        menu = QMenu(self)
        act0 = menu.addAction("Popup-Nachricht senden")
        act0.triggered.connect(self.computer.sendMessage)

        act1 = menu.addAction("Auswahl umkehren")
        act1.triggered.connect(self.toggleSelection)

        act2 = menu.addAction("Kandidat-Namen setzen")
        act2.triggered.connect(self.setCandidateNameDialog)

        act3 = menu.addAction("Dateien zum Client kopieren")
        act3.triggered.connect(self.deployClientFiles)

        act4 = menu.addAction("USB sperren")
        act4.triggered.connect(self.blockUsbAccessThread)

        act5 = menu.addAction("USB aktivieren")
        act5.triggered.connect(self.allowUsbAccessThread)

        act6 = menu.addAction("Internet sperren")
        act6.triggered.connect(self.blockInternetAccessThread)

        act7 = menu.addAction("Internet freigeben")
        act7.triggered.connect(self.allowInternetAccessThread)

        act8 = menu.addAction("LB-Status zurücksetzen")
        act8.triggered.connect(self.resetComputerStatusConfirm)

        act9 = menu.addAction("LB-Daten zurücksetzen")
        act9.triggered.connect(self.resetClientHomeDirectory)

        act10 = menu.addAction("Powershell öffnen")
        act10.triggered.connect(self.openTerminal)

        # menu.addAction("Bildschirm schwärzen").triggered.connect(self.computer.blankScreen)
        menu.addAction("Client herunterfahren").triggered.connect(self.shutdownClient)

        self.setMenu(menu)

    class Log:

        def __init__(self):
            self.__log = []

        def append(self, msg):
            self.__log.append(asctime() + "::" + msg)

        def getLog(self):
            return self.__log

    def openTerminal(self):
        terminalDialog = EcManRemoteTerminal(parent=self.parentApp, client=self.computer)
        terminalDialog.setModal(True)
        result = terminalDialog.exec_()

    def setCandidateNameDialog(self):
        '''
        opens GUI dialog to enter a candidate name, call actual setter method
        '''
        candidateName, ok = QInputDialog.getText(self, "Eingabe", "Name des Kandidaten eingeben")
        if ok and (len(candidateName) != 0):
            self.setCandidateName(candidateName)
        pass

    def setCandidateName(self, candidateName, doUpdate=True, doReset=False):
        '''
        sets candidate name on remote computer 
        '''
        self.computer.setCandidateName(candidateName, doReset)
        if doUpdate:
            self.setLabel()

        self.log.append(msg=" Kandidat-Name gesetzt: " + candidateName)

    def shutdownClient(self):
        self.log.append(msg=" herunterfahren")
        QThreadPool.globalInstance().start(LbClient.ShutdownTask(self))

    def setOwnToolTip(self):
        if self.lastUpdate != None and clock() - self.lastUpdate < 0.05:
            return

        self.lastUpdate = clock()

        errorLog = ""
        if len(self.log.getLog()) > 0:
            errorLog = "<h4>Log: </h4>" + "</p><p>".join(self.log.getLog()) + "</p>"

        # if self.computer.state != Computer.State.STATE_INIT:
        remoteFiles = self.computer.getRemoteFileListing()
        if type(remoteFiles) == bytes:
            remoteFiles = "ERROR: " + remoteFiles.decode()

        self.setToolTip("<h4>Status</h4>"
                        + self.computer.state.name + "<br>"
                        + "USB gesperrt: " + str(self.computer.isUsbBlocked()) + "<br>"
                        + "Internet gesperrt: " + str(self.computer.isInternetBlocked())
                        + remoteFiles
                        + errorLog)

    def resetComputerStatusConfirm(self):
        self.resetComputerStatus(resetCandidateName=None)

    def resetComputerStatus(self, resetCandidateName=None):
        '''
        resets client status **and data!**
        resets candidate name if resetCandidateName = True,
        opens a confirmation dialog if resetCandidateName = None (default),
        skips client name reset if resetCandidateName = False
        '''
        if resetCandidateName == None:
            items = ["Nein", "Ja"]
            item, ok = QInputDialog().getItem(self, "Client-Status zurücksetzen?", "Kandidat-Name zurücksetzen? ",
                                              items, 0, False)
            if ok == False:
                return
            resetCandidateName = True if item == "Ja" else False

        try:
            self.log.append(msg=" alle Daten und Einstellungen zurücksetzen")
            self.computer.resetStatus(resetCandidateName)
            self.setLabel()
            # self.setOwnToolTip()
        except Exception as ex:
            print("Fehler beim Zurücksetzen vom Client-PC: " + str(ex))
            self.log.append(msg=" Fehler beim Zurücksetzen der Daten und Einstellungen")

    def resetClientHomeDirectory(self):
        if QMessageBox.critical(self, "Achtung", "Alle Benutzerdaten löschen?",
                                QMessageBox.Yes, QMessageBox.No) == QMessageBox.Yes:
            self.computer.resetClientHomeDirectory()

    def deployClientFiles(self, server_user, server_passwd, server_domain, path=None, reset=False):
        '''
        starts remote copy process for path,
        wipes remote non-system files in user home dir before if reset=True 
        '''
        if path is None or path is False:
            path = self.parentApp.getExamPath()

        if server_user == "" or server_passwd == "":
            msg = " Anmeldecredentials für LB-Share fehlen"
            self.parentApp.showMessageBox("grober Fehler:", msg)
            self.log.append(msg)
            return

        if path == "":
            msg = " LB-Verzeichnispfad leer"
            self.parentApp.showMessageBox("grober Fehler", msg)
            self.log.append(msg)
            return

        if reset is True:
            success = self.computer.resetClientHomeDirectory()
            self.log.append(" Client-Daten gelöscht: " + str(success))
        else:
            self.log.append(" Löschen der Client-Daten nicht gewünscht.")

        status, error = self.computer.deployClientFiles(path, server_user, server_passwd, server_domain)

        if status != True:
            self.log.append(" Fehler Prüfungsdaten zum Client kopieren: " + path + ", Ursache: " + error)
        else:
            self.log.append(" Prüfungsdaten zum Client kopieren erfolgreich: " + path.replace("#", "/"))

        self.setOwnToolTip()
        self._colorizeWidgetByClientState()

    def retrieveClientFiles(self, filepath, server_user, server_passwd, server_domain, maxFiles=500,
                            maxFileSize=10000000):
        try:
            if self.computer.checkFileSanity(maxFiles, maxFileSize):

                status, error = self.computer.retrieveClientFiles(filepath, server_user, server_passwd, server_domain)
                if status != True:
                    self.log.append(msg=" Fehler beim Kopieren der Resultate: " +
                                        filepath + ", Ursache: " + error)
                else:
                    self.log.append(msg=" Resultate erfolgreich kopiert: " +
                                        filepath)
                    self.isSelected = False;

            else:
                self.log.append(msg=" Fehler: zu viele Dateien im Lösungsverzeichnis")

        except Exception as ex:
            self.log.append(msg=" Exception beim Kopieren der Resultate: " + str(ex))
            self.computer.state = Computer.State.STATE_RETRIVAL_FAIL

        self.setOwnToolTip()
        self._colorizeWidgetByClientState()

    def _colorizeWidgetByClientState(self):
        #self.setAutoFillBackground(True);
        #pal = QPalette()
        #pal.setColor(QPalette.Button, Qt.lightGray)
        color_string = ""
        if self.computer.state == Computer.State.STATE_DEPLOYED:
            color_string = "background-color: #FF7700;"
        elif self.computer.state == Computer.State.STATE_FINISHED:
            color_string = "background-color: #33BB33;"

        elif self.computer.state.value < 0:
            color_string = "background-color: red;"

        font_style = "font-weight: normal;"
        if self.isSelected:
            font_style = "font-weight: bold;"

        #self.setPalette(pal)
        self.setStyleSheet(color_string + font_style)

    def select(self):
        if self.computer.state != Computer.State.STATE_STUDENT_ACCOUNT_NOT_READY:
            self.log.append(msg=" ausgewählt {}".format(self.computer.getHostName()))
            self.isSelected = True
        self._colorizeWidgetByClientState()

    def unselect(self):
        self.log.append(msg=" abgewählt {}".format(self.computer.getHostName()))
        self.isSelected = False
        self._colorizeWidgetByClientState()

    def toggleSelection(self):
        '''
        set or reset selection state
        '''
        if self.isSelected:
            self.unselect()
        else:
            self.select()

    def setLabel(self):
        label = self.computer.ip
        if self.computer.getHostName() != "":
            label = label + "\n" + self.computer.getHostName()

        label = label + "\n" + (self.computer.getCandidateName() or "-LEER-")
        self.setText(label)
        self._colorizeWidgetByClientState()

    def blockUsbAccess(self):
        self.computer.disableUsbAccess(True)
        self.setOwnToolTip()

    def allowUsbAccess(self):
        self.computer.disableUsbAccess(False)
        self.setOwnToolTip()

    def blockUsbAccessThread(self):
        QThreadPool.globalInstance().start(LbClient.blockUsbAccess(self))

    def allowUsbAccessThread(self):
        QThreadPool.globalInstance().start(LbClient.allowUsbAccess(self))

    def allowInternetAccessThread(self):
        QThreadPool.globalInstance().start(LbClient.AllowInternetThread(self))

    def blockInternetAccessThread(self):
        QThreadPool.globalInstance().start(LbClient.BlockInternetThread(self))

    def blockInternetAccess(self, block=True):
        print('blocking internet access: ' + str(block))
        self.computer.blockInternetAccess(block)
        self.setOwnToolTip()

    class BlockInternetThread(QRunnable):

        def __init__(self, widget):
            QRunnable.__init__(self)
            self.widget = widget

        def run(self):
            self.widget.computer.blockInternetAccess()
            self.widget.setOwnToolTip()

    class AllowInternetThread(QRunnable):

        def __init__(self, widget):
            QRunnable.__init__(self)
            self.widget = widget

        def run(self):
            self.widget.computer.allowInternetAccess()
            self.widget.setOwnToolTip()

    class StatusThreadSignal(QObject):

        checkStateSignal = Signal()

    class CheckStatusThread(QRunnable):
        '''
        get the hostname asynchronously
        '''

        def __init__(self, widget):
            QRunnable.__init__(self)
            self.widget = widget
            self.computer = widget.computer
            self.connector = LbClient.StatusThreadSignal()

        def run(self):
            # sleep(random.randint(2,5))
            try:
                self.computer.checkStatusFile()
                self.connector.checkStateSignal.emit()
                print("fetching this computers name")
                self.computer.getHostName()
                print("finished fetching this computers name")

            except Exception as ex:
                self.widget.log.append("crashed fetching this computers name: " + str(ex))
                pass

            self.widget.setLabel()

    class ShutdownTask(QRunnable):
        '''
        simple thread to shutdown given pc (respectively the pc attached to this widget) 
        '''

        def __init__(self, widget):
            QRunnable.__init__(self)
            self.widget = widget

        def run(self):
            if self.widget.computer.shutdown() == True:
                self.widget.deleteLater()

            else:
                colorString = "background-color: red;"
                self.widget.setStyleSheet("QPushButton {" + colorString + "}")
