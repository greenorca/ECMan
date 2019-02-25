'''
Created on Feb 22, 2019

@author: sven
'''

from PySide2.QtWidgets import QLabel,QLineEdit,QComboBox,QWizard,QWizardPage,QVBoxLayout,QHBoxLayout,QApplication,\
    QGridLayout, QPushButton, QListWidget, QWidget, QTreeWidget, QTreeWidgetItem
from PySide2 import QtCore
from pathlib import Path
from socket import gaierror
from configparser import ConfigParser
from worker.sharebrowser import ShareBrowser
import os

comboBoxData = [
        ("Python","/path/to/python"),
        ("PyQt5","/path/to/pyqt5"),
        ("PySide2","/path/to/pyside2")    
    ]


class EcWizard(QWizard):
    '''
    classdocs
    '''
    PAGE_LOGON = 1
    PAGE_SELECT = 2

    def __init__(self, parent=None):
        '''
        Constructor
        '''
        super(EcWizard, self).__init__(parent)
        
        self.config = ConfigParser()
        self.configFile = Path(str(Path.home())+"/.ecman.conf")
        if self.configFile.exists():
            self.config.read_file(open(str(self.configFile)))
        else:
            self.configFile.touch()
        
        self.setPage(self.PAGE_LOGON, Page1(self))
        self.setPage(self.PAGE_SELECT, Page2(self))
        self.setWindowTitle("ECMan - Konfigurationswizard")
        self.resize(640,480)
        self.server = None
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
    def __init__(self, parent=None):
        super(Page1, self).__init__(parent)
        self.parent = parent
        self.setTitle("Server Authentifizierung")
        
        lblUsername = QLabel("Netzwerk - Benutzername")
        editUsername = QLineEdit("")
        self.registerField("username", editUsername) 
        lblUsername.setBuddy(editUsername)
        
        lblDomainName = QLabel("Domäne")
        editDomainName = QLineEdit("")
        self.registerField("domainname", editDomainName) 
        lblDomainName.setBuddy(editDomainName)
        
        lblPasswort = QLabel("Passwort")
        editPasswort = QLineEdit()
        editPasswort.setEchoMode(QLineEdit.Password)
        self.registerField("password*", editPasswort) 
        lblPasswort.setBuddy(editPasswort)
        
        lblServerName = QLabel("Servername")
        editServerName = QLineEdit("")
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
        check if given credentials and server name are valid
        only then proceed to next wizard page
        '''
        print("validating page")
        self.wizard().setServer(ShareBrowser(self.parent.field("servername"),
                                self.wizard().field("username"),
                                self.wizard().field("password"),
                                self.wizard().field("domainname")))
        try:
            connected = self.wizard().connectServer()
            print("logon successful: "+str(connected))
            shares = self.wizard().getShares()
            if len(shares)<0:
                print("no shares found")
                
            if not(shares==None):
                return True
            
            
        except gaierror as ex:
            #TODO: we probably want to distinguish beteween logon errors and server not found errors,
            # then go back to previous page  
            self.setSubTitle("Server nicht gefunden: "+str(ex))
        except Exception as ex:
            self.setSubTitle("Anmeldefehler") 
            print(ex)
            
        return False
 
class Page2(QWizardPage):
    def __init__(self, parent=None):
        super(Page2, self).__init__(parent)
        self.setTitle("Auswahl LB")
        self.setSubTitle("Wählen Sie die zu kopierende LB aus")
        
 
    def initializePage(self):
        print("setting up page 2")
        if self.layout()!=None:
            print("wiping out previous entries")
            while self.layout().count()>0:
                self.layout().removeItem(self.layout().itemAt(0))
        
        self.tree = QTreeWidget()
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
        folderListBox = QWidget()
        folderListBoxLayout = QVBoxLayout()
        folderListBoxLayout.addWidget(QLabel("Verzeichnisse"))
        folderListBoxLayout.addWidget(self.folderList)
        folderListBox.setLayout(folderListBoxLayout)
        
        layout = QHBoxLayout()
        layout.addWidget(shareListBox)
        layout.addWidget(folderListBox)
        self.setLayout(layout)
        
    def btnClicked(self):
        print("I've been clicked:: " + self.sender().text())
      
    def treeViewItemClicked(self,item):
        print("received treeview click on: "+str(item))
        self.folderList.clear()
        hasChildren = item.childCount()>0 # don't add children again
        content = self.wizard().getFolderContent(item.path)
        for x in content:                
            if not(x.filename.startswith(".")): 
                newItemPath = item.path+"/"+x.filename
                self.folderList.addItem(newItemPath)
                if not(hasChildren) and x.isDirectory:
                    item.addChild(MyTreeWidgetItem(self.tree, newItemPath))  

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
        
def someFun(): 
    print("event received: ")
    
if __name__ == '__main__':
    import sys
    app = QApplication(sys.argv)
    wizard = EcWizard()
    wizard.setModal(True)
    result = wizard.exec_()
    print("I'm done, wizard result="+str(result))    
    #app.exec_()