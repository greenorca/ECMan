'''
Created on Feb 22, 2019

@author: sven
'''

from PySide2.QtWidgets import QLabel,QLineEdit, QWizard,QWizardPage,QVBoxLayout,QHBoxLayout,QApplication,\
    QGridLayout, QListWidget, QWidget, QTreeWidget, QTreeWidgetItem, QListWidgetItem, QStyle
from pathlib import Path
from socket import gaierror
from configparser import ConfigParser
from worker.sharebrowser import ShareBrowser


comboBoxData = [
        ("Python","/path/to/python"),
        ("PyQt5","/path/to/pyqt5"),
        ("PySide2","/path/to/pyside2")    
    ]


class EcWizard(QWizard):
    '''
    wizard for selection of CIFS/SMB based exam shares based on user specified login credentials and serverName names 
    '''
    PAGE_LOGON = 1
    PAGE_SELECT = 2
    
    TYPE_LB_SELECTION = 1
    TYPE_RESULT_DESTINATION = 2
    
    def __init__(self, parent=None, username="", password="", servername="", domain = "", wizardType = TYPE_LB_SELECTION):
        '''
        Constructor
        '''
        super(EcWizard, self).__init__(parent)
        
        self.title = "LB-Auswahl"
        self.subtitle = "Wählen Sie die zu kopierende LB aus"
        if wizardType == self.TYPE_RESULT_DESTINATION:
            self.title = "Zielverzeichnis aüf Kandidatendaten auswählen"
            self.subtitle= ""
        
        self.config = ConfigParser()
        self.configFile = Path(str(Path.home())+"/.ecman.conf")
        if self.configFile.exists():
            self.config.read_file(open(str(self.configFile)))
        else:
            self.configFile.touch()
        
        self.setPage(self.PAGE_LOGON, Page1(self, username, password, servername, domain))
        self.setPage(self.PAGE_SELECT, Page2(self, self.title,self.subtitle))
        self.setWindowTitle("ECMan - {}".format(self.title))
        self.resize(640,480)
        self.server = None
        self.defaultShare = None
        self.finished.connect(someFun)
    
    def setServer(self, server):
        self.server=server
        
    def connectServer(self):
        return self.server.connect()
    
    def getShares(self):
        return self.server.getShares()
    
    def getFolderContent(self, path):
        share = path.split("/")[0]
        path = path.replace(share,"")    
        return self.server.getDirectoryContent(share,path)
        
class Page1(QWizardPage):
    def __init__(self, parent=None, username="", password="", servername="", domain = ""):
        super(Page1, self).__init__(parent)
        self.parent = parent
        self.setTitle("Server Authentifizierung")
        
        lblUsername = QLabel("Netzwerk - Benutzername")
        editUsername = QLineEdit(username)
        self.registerField("username", editUsername) 
        lblUsername.setBuddy(editUsername)
        
        lblDomainName = QLabel("Domäne")
        editDomainName = QLineEdit(domain)
        self.registerField("domainname", editDomainName) 
        lblDomainName.setBuddy(editDomainName)
        
        lblPasswort = QLabel("Passwort")
        editPasswort = QLineEdit(password)
        editPasswort.setEchoMode(QLineEdit.Password)
        self.registerField("password*", editPasswort) 
        lblPasswort.setBuddy(editPasswort)
        
        lblServerName = QLabel("Servername")
        editServerName = QLineEdit(servername)
        self.registerField("servername", editServerName) 
        lblServerName.setBuddy(editServerName)
                
        layout = QGridLayout()
        layout.addWidget(lblUsername)
        layout.addWidget(editUsername)
        layout.addWidget(lblDomainName)
        layout.addWidget(editDomainName)
        layout.addWidget(lblPasswort)
        layout.addWidget(editPasswort)
        
        layout.addWidget(lblServerName)
        layout.addWidget(editServerName)
        
        self.setLayout(layout)
        
    #def nextId(self):
        
    def validatePage(self):
        '''
        check if given credentials and serverName name are valid
        only then proceed to next wizard page
        '''
        print("validating page")
        
        server = self.parent.field("servername")
        
        server = server.replace("\\","/") # get rid of those ill used backslashes
        server = server.replace("//","") # kick leading //
        
        parts = server.split("/")
        server = parts[0]
        share = parts[1] if len(parts)>1 else None    
        
        
        self.wizard().setServer(ShareBrowser(server,
                                self.wizard().field("username"),
                                self.wizard().field("password"),
                                self.wizard().field("domainname")))
        try:
            connected = self.wizard().connectServer()
            print("logon successful: "+str(connected))
            if share is None:
                shares = self.wizard().getShares()
                if len(shares)<0:
                    print("no shares found")
                    
                if not(shares==None):
                    return True
            else:
                print("connecting to a hidden share")
                files = self.wizard().getFolderContent(share)
                if files is None or len(files)==0:
                    print("nothing found in hidden share")
                else:
                    self.wizard().defaultShare = share
                    return True
                
        except gaierror as ex:
            #TODO: we probably want to distinguish beteween logon errors and serverName not found errors,
            # then go back to previous page  
            self.setSubTitle("Server nicht gefunden: "+str(ex))
        except Exception as ex:
            self.setSubTitle("Anmeldefehler") 
            print(ex)
            
        return False
 
class Page2(QWizardPage):
    def __init__(self, parent=None, title="Auswahl LB",subtitle = "Wählen Sie die zu kopierende LB aus"):
        super(Page2, self).__init__(parent)
        self.setTitle(title)
        self.setSubTitle(subtitle)
        self.validSelection = False;
        
   
    def validatePage(self, *args, **kwargs):
        if len(self.folderList.selectedItems())==1:
            item = self.folderList.selectedItems()[0]
            self.wizard().defaultShare = item.path
            return item.isDirectory
        return False; 
 
    def initializePage(self):
        # print("setting up page 2")
        if self.layout()!=None:
            # print("wiping out previous entries")
            while self.layout().count()>0:
                self.layout().removeItem(self.layout().itemAt(0))
        
        self.tree = QTreeWidget()
        if self.wizard().defaultShare != None:
            self.tree.addTopLevelItem(MyTreeWidgetItem(self.tree, self.wizard().defaultShare)) 
        
        else:    
            shares = self.wizard().getShares()
            if shares==None:
                print("No shares found...")
                return
            print(",".join([x.name for x in shares]))         
            
        
            for m in shares:
                if m.name not in ["ADMIN$","C$","IPC$","NETLOGON","SYSVOL"]:
                    #button = QPushButton(m.name)
                    #button.clicked.connect(self.btnClicked)
                    self.tree.addTopLevelItem(MyTreeWidgetItem(self.tree, m))  

        shareListBox = QWidget()
        shareListBoxLayout = QVBoxLayout()
        self.tree.setHeaderLabel("Freigaben")
        self.tree.itemClicked.connect(self.treeViewItemClicked)
        shareListBoxLayout.addWidget(self.tree)
        shareListBox.setLayout(shareListBoxLayout)
        
        self.folderList = QListWidget()
        # self.folderList.itemClicked.connect(self.validateSelection)
        folderListBox = QWidget()
        folderListBoxLayout = QVBoxLayout()
        folderListBoxLayout.addWidget(QLabel("Modul auswählen:"))
        folderListBoxLayout.addWidget(self.folderList)
        folderListBox.setLayout(folderListBoxLayout)
        
        layout = QHBoxLayout()
        layout.addWidget(shareListBox)
        layout.addWidget(folderListBox)
        self.setLayout(layout)
        
    #===========================================================================
    # def btnClicked(self):
    #     print("I've been clicked:: " + self.sender().text())
    #===========================================================================
      
    def treeViewItemClicked(self,item):
        print("received treeview click on: "+str(item))
        self.folderList.clear()
        self.validSelection = False;
        hasChildren = item.childCount()>0 # don't add children again
        try:
            content = self.wizard().getFolderContent(item.path)
            content = sorted(content, key = lambda entry: (not(entry.isDirectory), entry.filename))
            for x in content:                
                if not(x.filename.startswith(".")): 
                    newItemPath = item.path+"/"+x.filename
                    icon = QStyle.SP_DirIcon if x.isDirectory else QStyle.SP_FileIcon 
                    self.folderList.addItem(MyListWidgetItem(
                        self.style().standardIcon(icon),
                        newItemPath, x.isDirectory, self.folderList))
                    if not(hasChildren) and x.isDirectory:
                        item.addChild(MyTreeWidgetItem(self.tree, newItemPath))
        except Exception as ex:
            # smb.smb_structs.OperationFailure ??
            print(str(ex))
            pass  

#===============================================================================
# class QIComboBox(QComboBox):
#     def __init__(self,parent=None):
#         super(QIComboBox, self).__init__(parent)
# 
#     #@pyside2Property(str)
#     def currentItemData(self):
#         return self.itemData(self.currentIndex()).toString()
#===============================================================================
class MyTreeWidgetItem(QTreeWidgetItem):  
      
    def __init__(self, treeview, path):
        super(MyTreeWidgetItem, self).__init__(treeview=treeview, strings=[path])
        if type(path)==str:
            self.path = path
        else: 
            self.path = path.name
        self.setText(0, self.path.split("/")[-1])
   
class MyListWidgetItem(QListWidgetItem):
    def __init__(self, icon, path, isDirectory, listView):
        super(MyListWidgetItem, self).__init__(icon, path, listView)
        self.path = path
        self.isDirectory = isDirectory
        self.setText(path.split("/")[-1])
        
def someFun(): 
    print("event received: ")
    
if __name__ == '__main__':
    import sys
    app = QApplication(sys.argv)
    wizard = EcWizard(parent=None, username="sven", domain="HSH", servername="odroid/lb_share")
    wizard.setModal(True)
    result = wizard.exec_()
    print("I'm done, wizard result="+str(result))
    if result==1:
        print("selected values: %s - %s - %s - %s"%
              (wizard.field("username"), wizard.field("password"), wizard.field("servername"), wizard.defaultShare))    
    #app.exec_()
    
'''
## im Windows (auf WISS-PC) den Domänennamen weglassen

## Ich sehe das LBV-Share nicht vom Linux...

sven@sven-N13xWU:~$ smbclient -L 10.103.0.95 -W WISS-SC -U sven.schirmer@wiss-online.ch

WARNING: The "syslog" option is deprecated
Enter sven.schirmer@wiss-online.ch's password: 

    Sharename       Type      Comment
    ---------       ----      -------
    IPC$            IPC       IPC Service ()
    OpenshareSG     Disk      
Reconnecting with SMB1 for workgroup listing.

    Server               Comment
    ---------            -------
    NSSGSC01             

    Workgroup            Master
    ---------            -------
    WISS-SC     
    
    smbclient -k //win-serverName/share$/folder
tree connect failed: NT_STATUS_BAD_NETWORK_NAME

smbclient -k //win-serverName/share$
Try "help" to get a list of possible commands.
smb: \>

So he can only connect if I use the path to the hidden share. I can't directly connect to sub-directories inside the hidden parent share.
        '''