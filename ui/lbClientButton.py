'''
Created on Jan 20, 2019

@author: sven
'''

from threading import Thread
from time import asctime, clock
from worker.computer import Computer
from PySide2.QtWidgets import QPushButton, QMenu, QInputDialog
from PySide2.QtCore import Qt, QThread, QThreadPool, QRunnable

class LbClient(QPushButton):
    '''
    class to handle and visualize state of lb_client_computers
    '''
    def __init__(self, ip, user, passwd, parentApp):
        self.computer = Computer(ip, user, passwd)
        QPushButton.__init__(self,self.computer.ip)
        self.parentApp = parentApp
        self.log = LbClient.Log()
        self.isSelected = False
        self.lastUpdate = None
        myThread = LbClient.WorkerThread(self)
        QThreadPool.globalInstance().start(myThread)
        
        menu = QMenu(self)
        
        act0 = menu.addAction("Ping-Message anzeigen")
        act0.triggered.connect(self.computer.sendMessage)
        
        act1 = menu.addAction("Aktivierung umkehren")
        act1.triggered.connect(self.toggleSelection)
        
        act2 = menu.addAction("Kandidat-Namen setzen")
        act2.triggered.connect(self.setCandidateName)
        
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
        
        self.setMenu(menu)
        self.setOwnToolTip()
        
    class Log:
        
        def __init__(self):
            self.__log = []
            
        def append(self, msg):
            self.__log.append(asctime()+"::"+msg)

        def getLog(self):
            return self.__log

    def setCandidateName(self):
        candidateName, ok = QInputDialog.getText(self, "Eingabe","Name des Kandidaten eingeben")
        if ok and (len(candidateName) !=0):
            self.computer.setCandidateName(candidateName)
            self.setLabel()
            self.log.append(msg=" candidate name set: "+candidateName)
        pass

    def setOwnToolTip(self):
        if self.lastUpdate != None and clock() - self.lastUpdate < 0.05:
            return
        
        self.lastUpdate = clock()    
        
        errorLog=""
        if len(self.log.getLog()) > 0:    
            errorLog = "<h4>Log: </h4>" + "</p><p>".join(self.log.getLog()) + "</p>"
        
        remoteFiles = ""
        if self.computer.state != Computer.State.STATE_INIT:
            remoteFiles = self.computer.getRemoteFileListing() 
        
        self.setToolTip("<h4>Status</h4>"
                        + self.computer.state.name+"<br>"
                        + "USB gesperrt: " + str(self.computer.isUsbBlocked())+"<br>"
                        + "Internet gesperrt: " + str(self.computer.isInternetBlocked())
                        + remoteFiles
                        + errorLog)
               

    def deployClientFiles(self, path=None):
        if path == None or path==False:
            path=self.parentApp.getExamPath()
            
        if path == "":
            self.parentApp.showMessageBox("grober Fehler","LB-Verzeichnispfad leer")
            return 
        
        status, error = self.computer.deployClientFiles(filepath=path, empty=True)
        
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
        self.__colorizeWidgetByClientState()

    def retrieveClientFiles(self, filepath):
        try:
            status, error = self.computer.retrieveClientFiles(filepath)
            if status != True:
                self.log.append(msg=" error: retrieving files from client: "+filepath+", cause: "+error)
            else:
                self.log.append(msg=" success: retrieved files from client: "+filepath)
                self.isSelected = False;
                self.setOwnToolTip() 

        except Exception as ex:
            self.log.append(msg=" Exception retrieving client files: "+str(ex))
            
        self.setOwnToolTip() 
        self.__colorizeWidgetByClientState()
    
    def __colorizeWidgetByClientState(self):        
        colorString = ""
        if self.computer.state == Computer.State.STATE_DEPLOYED:
            colorString = "background-color: yellow;"
        elif self.computer.state == Computer.State.STATE_FINISHED:
            colorString = "background-color: green;"
        elif self.computer.state == Computer.State.STATE_COPY_FAIL or \
            self.computer.state == Computer.State.STATE_RETRIVAL_FAIL:
            colorString = "background-color: red;"
            
        fontStyle = "font-weight:normal";
        if self.isSelected:
            fontStyle = "font-weight:bold";
        
        self.setStyleSheet("QPushButton {"+ colorString + fontStyle +"}")
            
    def select(self):
        self.log.append(msg=" selecting client {}".format(self.computer.hostname))
        self.isSelected = True
        self.__colorizeWidgetByClientState()

    def unselect(self):
        self.log.append(msg=" unselecting client {}".format(self.computer.hostname))
        self.isSelected = False
        self.__colorizeWidgetByClientState()

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
        if self.computer.hostname != "":
            label = label +"\n"+ self.computer.hostname
        try:
            if self.computer.getCandidateName() != "":
                label = label +"\n"+ self.computer.candidateName
        except Exception:
            self.log.append(msg=" Warning, couldnt get candidate name for {} // {}".format(self.computer.hostname,self.computer.ip))
        
        self.setText(label)
    
    def blockUsbAccess(self):
        self.computer.disableUsbAccess(True)
        self.setOwnToolTip() 
        
        
    def allowUsbAccess(self):
        self.computer.disableUsbAccess(False)
        self.setOwnToolTip() 
      
    def blockUsbAccessThread(self):
            Thread(target=self.blockUsbAccess).start()
      
    def allowUsbAccessThread(self):
            Thread(target=self.allowUsbAccess).start()
            
    def allowInternetAccessThread(self):
        Thread(target=self.blockInternetAccess(block=False)).start()

    def blockInternetAccessThread(self):
        Thread(target=self.blockInternetAccess(block=True)).start()
        
    def blockInternetAccess(self, block=True):
        print('blocking internet access: '+str(block))
        self.computer.blockInternetAccess(block)
        self.setOwnToolTip()

    class WorkerThread(QRunnable):
        '''
        get the hostname asynchronously
        '''
        def __init__(self, widget):
            QRunnable.__init__(self)
            self.widget =widget
            self.computer = widget.computer
            
        def run(self):
            #sleep(random.randint(2,5))
            try:
                print("fetching this computers name")
                self.computer.hostname = self.computer.getHostName()
                print("finished fetching this computers name")
                
            except Exception as ex:
                print("crashed fetching this computers name: "+str(ex))
                self.computer.hostname = "--invalid--"
                pass
            self.widget.setLabel()
            