'''
Created on Feb 22, 2019

@author: sven
'''
import re

from PySide2.QtWidgets import QLabel, QWizard, QWizardPage, QVBoxLayout, QHBoxLayout, QListWidget, QWidget, QTreeWidget, \
    QTreeWidgetItem, QListWidgetItem, QStyle
from PySide2.QtCore import Qt

class EcShareWizard(QWizard):
    '''
    wizard to select CIFS/SMB based exam shares based on user specified login credentials and serverName names
    '''
    PAGE_SELECT = 1

    TYPE_LB_SELECTION = 1
    TYPE_RESULT_DESTINATION = 2

    def __init__(self, parent=None, server=None,
                 wizardType=TYPE_LB_SELECTION):
        '''
        Constructor
        '''
        super(EcShareWizard, self).__init__(parent)
        self.setWizardStyle(QWizard.ModernStyle)
        self.title = "LB-Auswahl"
        self.subtitle = "Wählen Sie das gewünschte Modul links aus"
        self.type = self.TYPE_LB_SELECTION
        if wizardType == self.TYPE_RESULT_DESTINATION:
            self.title = "Zielverzeichnis für Kandidatendaten auswählen"
            self.subtitle = "Bitte Klassenverzeichnis links auswählen.<br>Das Modulverzeichnis für LB wird automatisch erstellt."
            self.type = self.TYPE_RESULT_DESTINATION

        self.setPage(self.PAGE_SELECT, ShareSelectionPage(self, self.title, self.subtitle))
        self.setWindowTitle("ECMan - {}".format(self.title))
        self.resize(450, 350)
        self.server = server
        self.defaultShare = server.defaultShare
        self.selectedPath = None

    def connectServer(self):
        return self.server.connect()

    def getShares(self):
        return self.server.getShares()

    def getFolderContent(self, path):
        share = path.split("/")[0]
        path = path.replace(share, "")
        return self.server.getDirectoryContent(share, path)


class ShareSelectionPage(QWizardPage):

    def __init__(self, parent=None, title="Auswahl LB", subtitle="Wählen Sie das Prüfungsmodul aus"):
        super(ShareSelectionPage, self).__init__(parent)
        self.setTitle(title)
        self.setSubTitle(subtitle)
        self.validSelection = False;

    def validatePage(self, *args, **kwargs):
        '''
        test if only one tree view item is selected and if this item matches the naming conventions
        '''
        if len(self.tree.selectedItems()) == 1:
            item = self.tree.selectedItems()[0]
            self.wizard().selectedPath = "//" + self.wizard().server.serverName + "/" + item.path
            if self.wizard().type == EcShareWizard.TYPE_LB_SELECTION:
                if re.compile("^M[1-9][0-9]{2}").match(item.name) == None:
                    self.setSubTitle("Bitte Prüfungsverzeichnis alá M101 oder M226A auswählen")
                    return False
            else:
                if re.compile("^(UIFZ|IFZ|ICT)-").match(item.name) == None:
                    self.setSubTitle("Bitte Klassenverzeichnis alá UIFZ-926-001 oder IFZ-926-001 auswählen")
                    return False

            self.setSubTitle("")
            return True

        self.wizard().selectedPath = None
        return False;

    def initializePage(self):
        if self.layout() != None:
            # print("clean up previous entries")
            while self.layout().count() > 0:
                self.layout().removeItem(self.layout().itemAt(0))

        self.tree = QTreeWidget()
        if self.wizard().defaultShare != None:
            self.tree.addTopLevelItem(MyTreeWidgetItem(self.tree,
                                                       self.wizard().defaultShare))

        else:
            shares = self.wizard().getShares()
            if shares == None:
                print("No shares found...")
                return
            print(",".join([x.name for x in shares]))

            for m in shares:
                if m.name not in ["ADMIN$", "C$", "IPC$", "NETLOGON", "SYSVOL"]:
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

        folderListHeaderMessage = "Verzeichnisinhalt"
        folderListBoxLayout.addWidget(QLabel(folderListHeaderMessage))

        folderListBoxLayout.addWidget(self.folderList)
        folderListBox.setLayout(folderListBoxLayout)

        layout = QHBoxLayout()
        layout.addWidget(shareListBox)
        layout.addWidget(folderListBox)
        self.setLayout(layout)

    def treeViewItemClicked(self, item):
        print("received treeview click on: " + str(item))
        self.folderList.clear()
        self.validSelection = False;
        hasChildren = item.childCount() > 0  # don't add children again
        try:
            content = self.wizard().getFolderContent(item.path)
            content = sorted(content, key=lambda entry: (not (entry.isDirectory), entry.filename))
            for x in content:
                if not (x.filename.startswith(".")):
                    newItemPath = item.path + "/" + x.filename
                    icon = QStyle.SP_DirIcon if x.isDirectory else QStyle.SP_FileIcon
                    self.folderList.addItem(MyListWidgetItem(
                        self.style().standardIcon(icon),
                        newItemPath, x.isDirectory, self.folderList))
                    if not (hasChildren) and x.isDirectory:
                        item.addChild(MyTreeWidgetItem(self.tree, newItemPath))
        except Exception as ex:
            # smb.smb_structs.OperationFailure ??
            print(str(ex))
            pass


class MyTreeWidgetItem(QTreeWidgetItem):

    def __init__(self, treeview, path):
        super(MyTreeWidgetItem, self).__init__(treeview=treeview, strings=[path])
        if type(path) == str:
            self.path = path
        else:
            self.path = path.name
        self.name = self.path.split("/")[-1]
        self.setText(0, self.name)


class MyListWidgetItem(QListWidgetItem):

    def __init__(self, icon, path, isDirectory, listView):
        super(MyListWidgetItem, self).__init__(icon, path, listView)
        self.path = path
        self.isDirectory = isDirectory
        self.setText(path.split("/")[-1])
        self.setFlags(self.flags() & Qt.ItemIsSelectable) #
