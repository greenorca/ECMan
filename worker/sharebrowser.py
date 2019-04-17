from smb.SMBConnection import SMBConnection
import os, socket
from pathlib import Path
from configparser import ConfigParser
'''
Created on Feb 19, 2019

@author: sven
'''


class ShareBrowser(object):
    '''
    simple class to connect with given credentials to given serverName name and retrieve the servers shares
     
    '''

    def __init__(self, servername, username, password, domain="", is_direct_tcp=True, port = 445):
        '''
        Constructor
        is_direct_tcp = False --> port = 139;
        is_direct_tcp = True --> port = 445
        '''
        self.serverName = servername
        self.user = username
        self.password = password
        self.conn = SMBConnection(self.user, self.password, socket.gethostname(), self.serverName, domain = domain, is_direct_tcp=is_direct_tcp)
        self.port = port
        self.isConnected = False
        
    def connect(self):
        '''
        actually establishes connection (for the user setup in ctor) 
        '''
        print("connecting to: "+self.serverName)
        self.isConnected = self.conn.connect(self.serverName, self.port)
        
        return self.isConnected
    
    def getShares(self):
        '''
        lists (non-hidden) shares for this server
        '''
        if not(self.isConnected):
            self.connect()
            
        return self.conn.listShares()
    
    def getDirectoryContent(self, share, path):
        '''
        lists content for (as well hidden) shares and their sub directories 
        '''
        if not(self.isConnected):
            self.connect()
    
        return self.conn.listPath(service_name=share, path=path)
        

    def disconnect(self):
        self.conn.close()
    
if __name__ == "__main__":
    
    ip = '192.168.56.100'
    config = ConfigParser()
    configFile = Path(str(Path.home()) + "/.ecman.conf")
    config.read_file(open(str(configFile)))
        
    lb_server = config.get("General", "lb_server", fallback="")
    port = config.get("General", "winrm_port", fallback=5986)
    client_lb_user = config.get("Client", "lb_user", fallback="student") 
    user = config.get("Client", "user", fallback="")
    passwd = config.get("Client", "pwd", fallback="")  
    
    if os.name=="posix":
        server = ShareBrowser("odroid", user, passwd, is_direct_tcp=True, port=445)
        sharename = "lb_share"
        folder=""
        #sharename = "documents"
        #folder="lb_share"
    else:
        server = ShareBrowser("WIN-DC1", user, passwd, domain="green-orca.com", is_direct_tcp=True, port=445)
        sharename = "documents"
        folder="lb_share"
       
        
    print("connected: "+ str(server.connect()))
    shares = server.getShares()
    print("shares: ")
    print(os.linesep.join([x.name for x in shares]))
    try:
        fileList = server.conn.listPath(sharename, folder)
        directories = os.linesep.join(x.filename for x in fileList if x.isDirectory and x.filename!=".." and x.filename!=".")
        files = os.linesep.join(x.filename for x in fileList if not(x.isDirectory))
        print("================================")
        print("directories: " +directories)
        print("files: " +files)
        
    except Exception as ex:
        print("Unable to connect to shared device: "+str(ex))
    
    with open("/home/sven/Nextcloud/Documents/Projects/WISS_LB_Deploy/netzplan.png", "rb") as fileObj:
        server.conn.storeFile(sharename, "Ergebnisse/netzplan.png", fileObj)
        
    server.disconnect()
    
