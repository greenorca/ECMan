'''
Created on Jan 19, 2019

@author: sven
'''

import socket, time
from PySide2 import QtCore
from PySide2.QtCore import QThreadPool, QRunnable, QThread, QObject, Signal
from ui.lbClientButton import LbClient
from worker.computer import Computer

class MySignals(QObject):
    addClient = Signal(int)
    threadFinished = Signal(int)
    
class ScannerThread(QRunnable):
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
            
        except Exception as ex:
            #print("crashed scanning IP {} because of {}".format(self.ip, ex))
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
            tScanner = ScannerThread(remote_ip, 5986)
            tScanner.connector.addClient.connect(self.addClient)
            tScanner.connector.threadFinished.connect(self.updateProgress)
            
            threads.start(tScanner)
    
    def updateProgress(self, value):
        self.counter = self.counter + 1
        self.updateProgressSignal.emit(self.counter)     
        
    def addClient(self, ip):
        self.addClientSignal.emit(ip)   
    

class RetrieveResultsThread(QRunnable):
    def __init__(self, client:LbClient, dst: str ):
        QRunnable.__init__(self)
        self.client = client
        self.dst = dst
        self.connector = MySignals()
    
    def run(self):
        try:
            # test connectivity
            if (self.client.computer.testPing(self.dst.split("#")[0])==False):
                print("tear down firewall for client "+self.client.computer.hostname)
                self.client.computer.allowInternetAccess()
            
            self.client.retrieveClientFiles(self.dst)        
            
        except Exception as ex:
            #print("crashed scanning IP {} because of {}".format(self.ip, ex))
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
        
    def __init__(self, clients: [], dst):
        '''
        ctor, required params:
        clients: array of lbClient instances to copy data from    
        '''
        QtCore.QThread.__init__(self)
        self.clients = clients
        self.dst = dst
        self.cnt = 0

    def run(self):
        threads = QThreadPool()
        threads.setMaxThreadCount(10)
        for client in self.clients:       
            thread = RetrieveResultsThread(client, self.dst)
            thread.connector.threadFinished.connect(self.updateProgress)
            threads.start(thread)            
        
    def updateProgress(self, value):
        self.cnt = self.cnt + 1
        self.updateProgressSignal.emit(self.cnt)
        
        
#Inherit from QThread
class CopyExamsWorker(QtCore.QThread):
    '''
    does threaded copying of lb data,
    signals "done threads"    
    source: https://stackoverflow.com/questions/20657753/python-pyside-and-progress-bar-threading#20661135
    '''    
    updateProgress = QtCore.Signal(int)
        
    def __init__(self, clients: [], src):
        '''
        ctor, required params:
        clients: array of lbClient instances to copy data to
        
        '''
        QtCore.QThread.__init__(self)
        self.clients = clients
        self.src = src

    #A QThread is run by calling it's start() function, which calls this run()
    #function in it's own "thread". 
    def run(self):
        threads = QThreadPool()
        threads.setMaxThreadCount(10)
        for client in self.clients:       
            thread = CopyExamsTask(client,self.src)
            threads.start(thread)
            print("copy thread started for "+client.computer.getHostName())
        
        maxThreads = threads.activeThreadCount()
         
        print("done thread setup, should all be running now")            
        while threads.activeThreadCount() > 0:
            self.updateProgress.emit(maxThreads - threads.activeThreadCount())
            time.sleep(1)
        self.updateProgress.emit(maxThreads)    
            

class CopyExamsTask(QtCore.QRunnable):
    
    def __init__(self,client,src):
        QtCore.QRunnable.__init__(self)
        self.client = client
        self.src = src        
    
    def run(self):
        self.client.deployClientFiles(self.src)

class ResetClientsWorker(QtCore.QThread):
    '''
    does threaded copying of lb data,
    signals "done threads"    
    source: https://stackoverflow.com/questions/20657753/python-pyside-and-progress-bar-threading#20661135
    '''    
    updateProgress = QtCore.Signal(int)
        
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
            threads.start(thread)
            print("reset thread started for "+client.computer.getHostName())
        
        maxThreads = threads.activeThreadCount()
         
        print("done thread setup, should all be running now")            
        while threads.activeThreadCount() > 0:
            self.updateProgress.emit(maxThreads - threads.activeThreadCount())
            time.sleep(1)
        self.updateProgress.emit(maxThreads)    
            

class ResetClientTask(QtCore.QRunnable):
    '''
    runnable thread to reset logical state of client (without restarting it)
    '''
    def __init__(self,client,resetCandidateName):
        QtCore.QRunnable.__init__(self)
        self.client = client
        self.resetCandidateName = resetCandidateName        
    
    def run(self):
        self.client.resetComputerStatus(self.resetCandidateName)
        
if __name__ == "__main__":
    ip = "192.168.0.114"
    port = 5986
    
    #compi = Computer(ip, remoteAdminUser="winrm", passwd="lalelu", candidateLogin="Sven", fetchHostname=False)
    
    scan = ScannerThread(ip, port)
    
    scan.start()    
    scan.join()
    
    print("done: "+str(scan.done))