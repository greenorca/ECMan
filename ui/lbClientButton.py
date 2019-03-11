'''
Created on Jan 20, 2019

@author: sven
'''

from time import asctime, clock
from worker.computer import Computer
from PySide2.QtWidgets import QPushButton, QMenu, QInputDialog, QWidget
from PySide2.QtCore import Qt, QThreadPool, QRunnable, Signal, QObject
from PySide2.QtGui import QFont, QPalette

class LbClient(QPushButton):
    '''
    class to handle and visualize state of lb_client_computers
    '''
    def __init__(self, ip, remoteAdminUser, passwd, candidateLogin, parentApp):
        self.computer = Computer(ip, remoteAdminUser=remoteAdminUser, passwd=passwd, candidateLogin=candidateLogin)
        QPushButton.__init__(self,self.computer.ip)
        self.parentApp = parentApp
        self.log = LbClient.Log()
        
        self.isSelected = False
        self.lastUpdate = None
        myThread = LbClient.CheckStatusThread(self)
        myThread.connector.checkStateSignal.connect(self.setLabel)
        myThread.connector.checkStateSignal.connect(self.setOwnToolTip)        
        QThreadPool.globalInstance().start(myThread)
        menu = QMenu(self)
        
        act0 = menu.addAction("Ping-Message anzeigen")
        act0.triggered.connect(self.computer.sendMessage)
        
        act1 = menu.addAction("Aktivierung umkehren")
        act1.triggered.connect(self.toggleSelection)
        
        act2 = menu.addAction("Kandidat-Namen setzen")
        act2.triggered.connect(self.setCandidateNameDialog)
        
        act3 = menu.addAction("Dateien zum Client kopieren")
        act3.triggered.connect(self.deployClientFiles)
        
        act4 = menu.addAction("USB blockieren")
        act4.triggered.connect(self.blockUsbAccessThread)

        act5 = menu.addAction("USB aktivieren")
        act5.triggered.connect(self.allowUsbAccessThread)
        
        act6 = menu.addAction("Internet deaktivieren")
        act6.triggered.connect(self.blockInternetAccessThread)
        
        act7 = menu.addAction("Internet freigeben")
        act7.triggered.connect(self.allowInternetAccessThread)
        
        act8 = menu.addAction("LB-Status zurücksetzen")
        act8.triggered.connect(self.resetComputerStatusConfirm)
        
        menu.addAction("Bildschirm schwärzen").triggered.connect(self.computer.blankScreen)
        menu.addAction("Client herunterfahren").triggered.connect(self.shutdownClient)
        
        self.setMenu(menu)
        
    class Log:
        
        def __init__(self):
            self.__log = []
            
        def append(self, msg):
            self.__log.append(asctime()+"::"+msg)

        def getLog(self):
            return self.__log

    def setCandidateNameDialog(self):
        '''
        opens GUI dialog to enter a candidate name, call actual setter method
        '''
        candidateName, ok = QInputDialog.getText(self, "Eingabe","Name des Kandidaten eingeben")
        if ok and (len(candidateName) !=0):
            self.setCandidateName(candidateName)
        pass
    
    def setCandidateName(self, candidateName, doUpdate = True, doReset=False):
        '''
        sets candidate name on remote computer 
        '''
        self.computer.setCandidateName(candidateName, doReset)
        if doUpdate:
            self.setLabel()
        
        self.log.append(msg=" candidate name set: "+candidateName)
    
    def shutdownClient(self):
        self.log.append(msg=" shutting down")
        QThreadPool.globalInstance().start(LbClient.ShutdownTask(self))
        
    def setOwnToolTip(self):
        if self.lastUpdate != None and clock() - self.lastUpdate < 0.05:
            return
        
        self.lastUpdate = clock()    
        
        errorLog=""
        if len(self.log.getLog()) > 0:    
            errorLog = "<h4>Log: </h4>" + "</p><p>".join(self.log.getLog()) + "</p>"
        
        #if self.computer.state != Computer.State.STATE_INIT:
        remoteFiles = self.computer.getRemoteFileListing() 
        if type(remoteFiles)==bytes:
            remoteFiles = "ERROR: "+remoteFiles.decode()
        
        self.setToolTip("<h4>Status</h4>"
                        + self.computer.state.name+"<br>"
                        + "USB gesperrt: " + str(self.computer.isUsbBlocked())+"<br>"
                        + "Internet gesperrt: " + str(self.computer.isInternetBlocked())
                        + remoteFiles
                        + errorLog)
    
    def resetComputerStatusConfirm(self):
        self.resetComputerStatus(resetCandidateName=None)
    
    def resetComputerStatus(self, resetCandidateName=None):
        if resetCandidateName==None: 
            items = ["Nein","Ja"]
            item, ok = QInputDialog().getItem(self, "Client-Status zurücksetzen", "Kandidat-Name zurücksetzen? ", items, 0, False) 
            if ok == False:
                return
            resetCandidateName = True if item=="Ja" else False
        
        try:
            self.log.append(msg=" alle Daten und Einstellungen zurücksetzen")
            self.computer.reset(resetCandidateName) 
            self.setLabel()
            #self.setOwnToolTip()
        except Exception as ex:
            print("Died reseting client: "+str(ex))  
            self.log.append(msg=" Fehler beim zurücksetzen der Daten und Einstellungen")     
            

    def deployClientFiles(self, server_user, server_passwd, server_domain, path=None):
        if path == None or path==False:
            path=self.parentApp.getExamPath()
            
        if server_user == "" or server_passwd == "":
            msg= " Anmeldecredentials für LB-Share fehlen"
            self.parentApp.showMessageBox("grober Fehler:", msg)
            self.log.append(msg)
            return 
            
        if path == "":
            msg= " LB-Verzeichnispfad leer"
            self.parentApp.showMessageBox("grober Fehler", msg)
            self.log.append(msg)
            return 
        
        status, error = self.computer.deployClientFiles(path, server_user, server_passwd, server_domain,  empty=True)
        
        if status != True:
            self.log.append(" error: deploying client: "+path+", cause: "+error)
        else:
            self.log.append(" success: deployed client: "+path.replace("#","/"))
            
            if self.parentApp.checkBoxBlockUsb.checkState()==Qt.CheckState.Checked:
                success = self.computer.disableUsbAccess(block=True)
                print(" USB gesperrt: "+str(success))
                self.log.append(" USB gesperrt: "+str(success))
            
            if self.parentApp.checkBoxBlockWebAccess.checkState()==Qt.CheckState.Checked:
                success = self.computer.blockInternetAccess(block=True)
                print(" Internet gesperrt: "+str(success))
                self.log.append(" Internet gesperrt: "+str(success))
            
        self.setOwnToolTip() 
        self._colorizeWidgetByClientState()

    def retrieveClientFiles(self, filepath, server_user, server_passwd, server_domain):
        try:
            status, error = self.computer.retrieveClientFiles(filepath, server_user, server_passwd, server_domain)
            if status != True:
                self.log.append(msg=" error: retrieving files from client: "+filepath+", cause: "+error)
            else:
                self.log.append(msg=" success: retrieved files from client: "+filepath)
                self.isSelected = False;
                self.setOwnToolTip() 

        except Exception as ex:
            self.log.append(msg=" Exception retrieving client files: "+str(ex))
            
        self.setOwnToolTip() 
        self._colorizeWidgetByClientState()
    
    def _colorizeWidgetByClientState(self):        
        colorString = ""
        pal = QPalette()
        # set black background
        
        self.setAutoFillBackground(True);
        pal.setColor(QPalette.Button, Qt.lightGray);
        if self.computer.state == Computer.State.STATE_DEPLOYED:
            colorString = "background-color: yellow;"
            pal.setColor(QPalette.Button, Qt.yellow);
        elif self.computer.state == Computer.State.STATE_FINISHED:
            colorString = "background-color: green;"
            pal.setColor(QPalette.Button, Qt.green);
        elif self.computer.state.value < 0:
            colorString = "background-color: red;"
            pal.setColor(QPalette.Button, Qt.red);
        
        
        self.setPalette(pal);
            
        fontStyle = "font-weight:normal;";
        myFont=QFont()
        myFont.setBold(False)
        if self.isSelected:
            fontStyle = "font-weight:bold;";
            myFont.setBold(True)
            
        self.setFont(myFont)
        
        #self.setStyleSheet("QPushButton {"+ colorString + fontStyle +"}")
     
    #===========================================================================
    # def paintEvent(self, event):
    #      opt = QStyleOption() 
    #      opt.init(self);
    #      p = QPainter(self)
    #      style()->drawPrimitive(QStyle::PE_Widget, opt, p, self);
    #     
    #      QPushButton.paintEvent(event);
    #         
    #===========================================================================
    
    def select(self):
        if self.computer.state != Computer.State.STATE_STUDENT_ACCOUNT_NOT_READY:
            self.log.append(msg=" selecting client {}".format(self.computer.getHostName()))
            self.isSelected = True
        self._colorizeWidgetByClientState()

    def unselect(self):
        self.log.append(msg=" unselecting client {}".format(self.computer.getHostName()))
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
            label = label +"\n"+ self.computer.getHostName()
        
        label = label +"\n"+ self.computer.getCandidateName()        
        self.setText(label)
        self._colorizeWidgetByClientState()
    
    def blockUsbAccess(self):
        self.computer.disableUsbAccess(True)
        self.setOwnToolTip() 
        #TODO: implelemt as QRunnable
        
        
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
        print('blocking internet access: '+str(block))
        self.computer.blockInternetAccess(block)
        self.setOwnToolTip()

    class BlockInternetThread(QRunnable):
        def __init__(self, widget):
            QRunnable.__init__(self)
            self.widget =widget
            
        def run(self):
            self.widget.computer.blockInternetAccess()
            self.widget.setOwnToolTip()

    class AllowInternetThread(QRunnable):
        def __init__(self, widget):
            QRunnable.__init__(self)
            self.widget =widget
            
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
            self.widget =widget
            self.computer = widget.computer
            self.connector = LbClient.StatusThreadSignal()
            
        def run(self):
            #sleep(random.randint(2,5))
            try:
                self.computer.checkStatusFile()
                self.connector.checkStateSignal.emit()
                print("fetching this computers name")
                self.computer.getHostName()
                print("finished fetching this computers name")
                
            except Exception as ex:
                print("crashed fetching this computers name: "+str(ex))
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
                self.widget.setEnabled(False)
                colorString = "background-color: grey;"
                self.widget.setStyleSheet("QPushButton {"+ colorString + "}")


