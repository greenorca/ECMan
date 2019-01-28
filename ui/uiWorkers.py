'''
Created on Jan 19, 2019

@author: sven
'''

import socket, time
from threading import Thread
from PySide2 import QtCore
from PySide2.QtCore import QThreadPool, QRunnable, QThread

class ScannerThread(Thread):
    '''
    scanning thread; see https://stackoverflow.com/questions/26174743/making-a-fast-port-scanner
    '''
    def __init__(self, ip, port, timeout=5):
        Thread.__init__(self)
        self.ip = ip
        self.port=port
        self.done=-1
        self.timeout=timeout
    
    def run(self):
        TCPsock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        TCPsock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        TCPsock.settimeout(self.timeout)
        try:
            #sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            #self.log("scanning "+self.ip)
            TCPsock.connect((self.ip, self.port))
            print("done scanning "+self.ip)         
            self.done=1            
            
        except Exception as ex:
            print("crashed scanning IP {} because of {}".format(self.ip, ex))
            # self.addClient.emit(-1)
        
        

#Inherit from QThread
class ScannerWorker(QtCore.QThread):
    '''
    does threaded scanning of IP range and port,
    signals "done threads" and successful ips     
    source: https://stackoverflow.com/questions/20657753/python-pyside-and-progress-bar-threading#20661135
    '''
    
    updateProgress = QtCore.Signal(int)
    # signal returns only last byte of IP adress
    addClient = QtCore.Signal(int)
    
    def __init__(self, ipRange: str, ipAdress: str):
        '''
        ctor, required params:
        ipRange: str like 192.168.0.*
        ipAdress: this machines ipAdress as string
        '''
        QtCore.QThread.__init__(self)
        self.ipRange = ipRange
        self.ipAdress = ipAdress

    #A QThread is run by calling it's start() function, which calls this run()
    #function in it's own "thread". 
    def run(self):
        threads = []
        # searching for clients
        for i in range(254):       
            remote_ip = self.ipRange.replace("*",str(i+1))
            tScanner = ScannerThread(remote_ip, 5986)
            threads.append(tScanner)
            tScanner.start()
        
        for t in threads:
            try:
                t.join()
                if t.done==1:
                    ip = int(t.ip.split(".")[-1])
                    self.addClient.emit(ip)
                    
            except Exception as ex:
                print(ex)
            self.updateProgress.emit(i)
                
            
        self.updateProgress.emit(255)
    
    def relay(self, ip):
        self.addClient.emit(ip)

#Inherit from QThread
class RetrieveResultsWorker(QtCore.QThread):
    '''
    does threaded retrieval of lb data,
    signals "done threads"    
    source: https://stackoverflow.com/questions/20657753/python-pyside-and-progress-bar-threading#20661135
    '''
    
    updateProgress = QtCore.Signal(int)
    
    
    def __init__(self, clients: [], dst):
        '''
        ctor, required params:
        clients: array of lbClient instances to copy data from
        
        '''
        QtCore.QThread.__init__(self)
        self.clients = clients
        self.dst = dst

    #A QThread is run by calling it's start() function, which calls this run()
    #function in it's own "thread". 
    def run(self):
        threads = []
        # searching for clients
        for client in self.clients:       
            thread = Thread(target=client.retrieveClientFiles(self.dst))
            threads.append(thread)
            thread.start()            
        
        i=0
        for t in threads:
            t.join()
            self.updateProgress.emit(i+1)
            i=i+1;
        
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

        
if __name__ == "__main__":
    ip = "192.168.0.105"
    port = 5986
    scan = ScannerThread(ip, port)
    
    scan.start()
    
    scan.join()
    
    print("done: "+str(scan.done))