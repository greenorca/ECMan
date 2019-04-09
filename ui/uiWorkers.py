'''
Created on Jan 19, 2019

@author: sven
'''

import socket, time
from PySide2 import QtCore
from PySide2.QtCore import QThreadPool, QRunnable, QThread, QObject, Signal
from ui.lbClientButton import LbClient
#from worker.computer import Computer

class MySignals(QObject):
    addClient = Signal(int)
    updateClientLabel = Signal(int)
    threadFinished = Signal(int)

class ScannerTask(QRunnable):
    '''
    scanning thread; see https://stackoverflow.com/questions/26174743/making-a-fast-port-scanner
    '''
    def __init__(self, ip, port, timeout=1):
        QRunnable.__init__(self)
        self.ip = ip
        self.port=port
        self.done=-1
        self.timeout=timeout
        self.connector = MySignals()
    
    def run(self):
        TCPsock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        TCPsock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        TCPsock.settimeout(self.timeout)
        try:
            #sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            #self.log("scanning "+self.ip)
            TCPsock.connect((self.ip, self.port))
            print("done scanning "+self.ip)
            ip = int(self.ip.split(".")[-1])
            self.connector.addClient.emit(ip)          
            
        except Exception:
            #print("crashed scanning IP {} because of {}".format(self.ip, ex))
            #===================================================================
            # r = random.Random()
            # if r.random() > 0.9:
            #     ip = int(self.ip.split(".")[-1])
            #     self.connector.addClient.emit(ip)
            #===================================================================
            pass
        
           
        self.connector.threadFinished.emit(1)    

#Inherit from QThread
class ScannerWorker(QThread):
    '''
    does threaded scanning of IP range and port,
    signals "done threads" and successful ips     
    source: https://stackoverflow.com/questions/20657753/python-pyside-and-progress-bar-threading#20661135
    '''
    
    updateProgressSignal = QtCore.Signal(int)
    # signal returns only last byte of IP adress
    addClientSignal = QtCore.Signal(int)
    
    def __init__(self, ipRange: str, ipAdress: str):
        '''
        ctor, required params:
        ipRange: str like 192.168.0.*
        ipAdress: this machines ipAdress as string
        '''
        QtCore.QThread.__init__(self)
        self.ipRange = ipRange
        self.ipAdress = ipAdress
        self.counter = 0

    #A QThread is run by calling it's start() function, which calls this run()
    #function in it's own "thread". 
    def run(self):
        # searching for clients
        threads = QThreadPool()
        threads.setMaxThreadCount(20)
        for i in range(254):       
            remote_ip = self.ipRange.replace("*",str(i+1))
            tScanner = ScannerTask(remote_ip, 5986)
            tScanner.connector.addClient.connect(self.addClient)
            tScanner.connector.threadFinished.connect(self.updateProgress)
            
            threads.start(tScanner)
    
    def updateProgress(self, value):
        self.counter = self.counter + 1
        self.updateProgressSignal.emit(self.counter)     
        
    def addClient(self, ip):
        self.addClientSignal.emit(ip)   
    

class RetrieveResultsTask(QRunnable):
    def __init__(self, client:LbClient, dst: str, server_user, server_passwd, server_domain, maxFiles=100, maxFileSize=100000):
        QRunnable.__init__(self)
        self.client = client
        self.dst = dst
        self.connector = MySignals()
        self.server_user = server_user 
        self.server_passwd = server_passwd
        self.server_domain = server_domain
        self.maxFiles = maxFiles
        self.maxFileSize = maxFileSize
    
    def run(self):
        try:
            # test connectivity
            if (self.client.computer.testPing(self.dst.replace("##","").
                        replace("\\\\","").split("#")[0])==False):
                print("tear down firewall for client ")
                self.client.computer.allowInternetAccess()
            
            self.client.retrieveClientFiles(self.dst, 
                        self.server_user, self.server_passwd, self.server_domain, self.maxFiles, self.maxFileSize)        
            
        except Exception as ex:
            print("crashed retrieving results into dst: {} because of {}".format(self.dst, ex))
            pass
           
        self.connector.threadFinished.emit(1)
    
#Inherit from QThread
class RetrieveResultsWorker(QThread):
    '''
    does threaded retrieval of lb data,
    signals "done threads"    
    source: https://stackoverflow.com/questions/20657753/python-pyside-and-progress-bar-threading#20661135
    '''    
    updateProgressSignal = QtCore.Signal(int)
        
    def __init__(self, clients: [], dst, server_user, server_passwd, server_domain):
        '''
        ctor, required params:
        clients: array of lbClient instances to copy data from    
        '''
        QtCore.QThread.__init__(self)
        self.clients = clients
        self.dst = dst
        self.cnt = 0
        self.server_user = server_user 
        self.server_passwd = server_passwd
        self.server_domain = server_domain

    def run(self):
        threads = QThreadPool()
        threads.setMaxThreadCount(10)
        for client in self.clients: 
            print("setup file retrival for "+client.computer.getCandidateName())      
            thread = RetrieveResultsTask(client, self.dst, self.server_user, self.server_passwd, self.server_domain)
            thread.connector.threadFinished.connect(self.updateProgress)
            threads.start(thread)
            time.sleep(0.3)            
        
    def updateProgress(self, value):
        self.updateProgressSignal.emit(1)
        
        
#Inherit from QThread
class CopyExamsWorker(QtCore.QThread):
    '''
    does threaded copying of lb data,
    signals "done threads"    
    source: https://stackoverflow.com/questions/20657753/python-pyside-and-progress-bar-threading#20661135
    '''    
    updateProgressSignal = QtCore.Signal(int)
        
    def __init__(self, clients: [], src, server_user, server_passwd, server_domain):
        '''
        ctor, required params:
        clients: array of lbClient instances to copy data to
        
        '''
        QtCore.QThread.__init__(self)
        self.clients = clients
        self.src = src
        self.server_user = server_user 
        self.server_passwd = server_passwd
        self.server_domain = server_domain

    #A QThread is run by calling it's start() function, which calls this run()
    #function in it's own "thread". 
    def run(self):
        threads = QThreadPool()
        threads.setMaxThreadCount(10)
        for client in self.clients:       
            thread = CopyExamsTask(client,self.src, self.server_user, self.server_passwd, self.server_domain)
            thread.connector.threadFinished.connect(self.updateProgress)
            threads.start(thread)
            print("copy thread started for "+client.computer.getHostName())
        
    def updateProgress(self, val):
        self.updateProgressSignal.emit(1)       
            

class CopyExamsTask(QtCore.QRunnable):
    
    def __init__(self,client,src, server_user, server_passwd, server_domain):
        QtCore.QRunnable.__init__(self)
        self.client = client
        self.src = src        
        self.server_user = server_user 
        self.server_passwd = server_passwd
        self.server_domain = server_domain
        self.connector = MySignals()
         
    def run(self):
        self.client.deployClientFiles(self.server_user, self.server_passwd, self.server_domain, self.src)
        self.connector.threadFinished.emit(1)

class ResetClientsWorker(QtCore.QThread):
    '''
    does threaded copying of lb data,
    signals "done threads"    
    source: https://stackoverflow.com/questions/20657753/python-pyside-and-progress-bar-threading#20661135
    '''    
    updateProgressSignal = QtCore.Signal(int)
    # signal returns only last byte of IP adress
    updateClientSignal = QtCore.Signal(int)
        
    def __init__(self, clients: [], resetCandidateNames=True):
        '''
        ctor, required params:
        clients: array of lbClient instances to copy data to        
        '''
        QtCore.QThread.__init__(self)
        self.clients = clients
        self.resetCandidateNames = resetCandidateNames

    #A QThread is run by calling it's start() function, which calls this run()
    #function in it's own "thread". 
    def run(self):
        threads = QThreadPool()
        threads.setMaxThreadCount(10)
        for client in self.clients:       
            thread = ResetClientTask(client,self.resetCandidateNames)
            thread.connector.updateClientLabel.connect(self.updateClientLabel)
            thread.connector.threadFinished.connect(self.updateProgress)
            threads.start(thread)
            print("reset thread started for "+client.computer.getHostName())
        
        print("done thread setup, should all be running now")            
     
    def updateProgress(self, val):
        self.updateProgressSignal.emit(1)
            
    def updateClientLabel(self):
        self.updateClientSignal.emit(self)

class ResetClientTask(QtCore.QRunnable):
    '''
    runnable thread to reset logical state of client (without restarting it)
    '''   
    
    def __init__(self,client,resetCandidateName):
        QtCore.QRunnable.__init__(self)
        self.client = client
        self.resetCandidateName = resetCandidateName
        self.connector = MySignals()        
    
    def run(self):
        try:
            self.client.resetComputerStatus(self.resetCandidateName)
            self.client.allowUsbAccess()
            self.client.blockInternetAccess(block=False)
            
        except Exception as ex:
            print("Died reseting client@{}, cause: ".format(self.client.computer.getHostName()) + str(ex))
            
        self.connector.updateClientLabel.emit(self)
        self.connector.threadFinished.emit(1)
        
############################################

class SetCandidateNameTask(QtCore.QRunnable):
    '''
    runnable thread to set candidate name of client computer
    '''
    def __init__(self,client,candidateName):
        QtCore.QRunnable.__init__(self)
        self.client = client
        self.candidateName = candidateName  
        self.connector = MySignals()      
    
    def run(self):
        try:
            self.client.setCandidateName(self.candidateName, doUpdate=True, doReset=False)
        except Exception as ex:
            print("Died while setting candidate name: "+str(ex))
        self.connector.threadFinished.emit(1)


class SetCandidateNamesWorker(QtCore.QThread):
    '''
    does threaded candidate setup,
    signals "done threads"    
    source: https://stackoverflow.com/questions/20657753/python-pyside-and-progress-bar-threading#20661135
    '''    
    updateProgressSignal = QtCore.Signal(int)
    
    def __init__(self, clients: list, candidateNames: list):
        '''
        ctor, required params:
        clients: array of lbClient instances to copy data to
        candidateNames: array of strings (no further string cleanup is done in here)        
        '''
        QtCore.QThread.__init__(self)
        self.clients = clients
        self.candidateNames = candidateNames

    #A QThread is run by calling it's start() function, which calls this run()
    #function in it's own "thread". 
    def run(self):
        threads = QThreadPool()
        threads.setMaxThreadCount(10)
        for i in range(len(self.candidateNames)):
            task = SetCandidateNameTask(self.clients[i],self.candidateNames[i])  
            task.connector.threadFinished.connect(self.updateProgress())     
            threads.start(task)
            print("candidate name setter thread started for "+self.candidateNames[i])
        
        print("done thread setup, should all be running now")            
        #maxThreads = threads.activeThreadCount()
        #while threads.activeThreadCount() > 0:
        #    self.updateProgress.emit(maxThreads - threads.activeThreadCount())
        #    time.sleep(1)
        #self.updateProgress.emit(maxThreads)    
     
    def updateProgress(self):
        self.updateProgressSignal.emit(1)
        #TODO        


############################################
        
class SendMessageTask(QtCore.QRunnable):
    '''
    runnable thread to send messages to a client computer
    '''
    def __init__(self, client, message):
        QtCore.QRunnable.__init__(self)
        self.client = client
        self.message = message    
    
    def run(self):
        self.client.computer.sendMessage(self.message)
        
if __name__ == "__main__":
    ip = "192.168.0.114"
    port = 5986
    
    #compi = Computer(ip, remoteAdminUser="winrm", passwd="lalelu", candidateLogin="Sven", fetchHostname=False)
    
    scan = ScannerTask(ip, port)
    
    scan.start()    
    scan.join()
    
    print("done: "+str(scan.done))