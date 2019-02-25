from smb.SMBConnection import SMBConnection
import os, socket
'''
Created on Feb 19, 2019

@author: sven
'''


class ShareBrowser(object):
    '''
    simple class to connect with given credentials to given server name and retrieve the servers shares 
    '''

    def __init__(self, servername, username, password, domain="", is_direct_tcp=True, port = 445):
        '''
        Constructor
        is_direct_tcp = False --> port = 139;
        is_direct_tcp = True --> port = 445
        '''
        self.server = servername
        self.user = username
        self.password = password
        self.conn = SMBConnection(self.user, self.password, socket.gethostname(), self.server, domain = domain, is_direct_tcp=is_direct_tcp)
        self.port = port
        self.isConnected = False
        
    def connect(self):
        '''
        port 139 works fine if is_direct_tcp=False;
        use port 445 for is_direct_tcp=True
        '''
        print("connecting to: "+self.server)
        self.isConnected = self.conn.connect(self.server, self.port)
        
        return self.isConnected
    
    def getShares(self):
        if not(self.isConnected):
            self.connect()
            
        return self.conn.listShares()
    
    def getDirectoryContent(self, share, path):
        if not(self.isConnected):
            self.connect()
    
        return self.conn.listPath(service_name=share, path=path)
        

    def disconnect(self):
        self.conn.close()
    
if __name__ == "__main__":
    
    if os.name=="posix":
        server = ShareBrowser("odroid", "winrm", "lalelu", is_direct_tcp=True, port=445)
        server = ShareBrowser("192.168.56.101", "sven", "lalelu", domain="green-orca.com", is_direct_tcp=True, port=445)
        sharename = "lb_share"
        folder=""
        sharename = "documents"
        folder="lb_share"
    else:
        server = ShareBrowser("W10ACCL0", "winrm", "lalelu")
        server = ShareBrowser("WIN-DC1", "sven", "lalelu", domain="green-orca.com", is_direct_tcp=True, port=445)
        sharename = "documents"
        folder="lb_share"
       
        
    print("connected: "+ str(server.connect()))
    shares = server.getShares()
    print("shares: ")
    print(os.linesep.join([x.name for x in shares]))
    try:
        fileList = server.conn.listPath(sharename, folder)
        directories = os.linesep.join(x.filename for x in fileList if x.isDirectory)
        files = os.linesep.join(x.filename for x in fileList if not(x.isDirectory))
        print("================================")
        print("directories: " +directories)
        print("files: " +files)
        
    except Exception as ex:
        print("Unable to connect to shared device: "+str(ex))
        
    server.disconnect()
    