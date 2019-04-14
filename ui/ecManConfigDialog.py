'''
Created on Jan 22, 2019

@author: sven
'''
from PySide2.QtWidgets import QDialog, QApplication
from PySide2.QtGui import QIntValidator
from configparser import ConfigParser
from pathlib import Path
from ui.configDialog import Ui_Dialog

class EcManConfigDialog(QDialog):
    '''
    QDialog based Configuration dialog for ECMan app
    adapted from https://www.codementor.io/deepaksingh04/design-simple-dialog-using-pyqt5-designer-tool-ajskrd09n
    and https://stackoverflow.com/questions/19379120/how-to-read-a-config-file-using-python#19379306
    class inherists from QDialog, and contains the UI defined in ConfigDialog (based on configDialog.ui) 
    '''

    def __init__(self, parent=None, configFile=""):
        '''
        Constructor        
        '''
        super(EcManConfigDialog,self).__init__(parent)
        self.ui = Ui_Dialog()
        
        self.ui.setupUi(self)
        self.setWindowTitle("ECMan - Konfiguration")
        self.ui.lineEdit_MaxFiles.setValidator(QIntValidator(10, 100, self))
        self.ui.lineEdit_MaxFileSize.setValidator(QIntValidator(10, 1000, self))
        
        self.ui.comboBox_LbServer.addItem("")
        self.ui.comboBox_LbServer.addItem("//odroid/lb_share")
        self.ui.comboBox_LbServer.addItem("//NSSGSC01/LBV")
        self.config = ConfigParser()
        self.configFile=configFile
        
        if self.configFile == "":
            self.configFile = Path(str(Path.home())+"/.ecman.conf")
        else:
            self.configFile = Path(configFile)
            
        if self.configFile.exists():
            
            self.config.read_file(open(str(self.configFile)))
            
            #lineEdit_lconfig.get("General","lb_server",fallback="")
            # self.ui.comboBox_LbServer.addItem(self.config.get("General", "lb_server",fallback=""))
            self.ui.comboBox_LbServer.setCurrentText(self.config.get("General", "lb_server",fallback=""))
            self.ui.lineEdit_StdLogin.setText(self.config.get("Client", "lb_user",fallback="student"))
            self.ui.lineEdit_winRmPort.setText(self.config.get("General", "winrm_port",fallback="5986"))
            self.ui.lineEdit_winRmUser.setText(self.config.get("Client","user"))
            self.ui.lineEdit_winRmPwd.setText(self.config.get("Client","pwd"))
            self.ui.lineEdit_MaxFiles.setText(self.config.get("Client","max_files",fallback="100"))
            self.ui.lineEdit_MaxFileSize.setText(self.config.get("Client","max_fileSize",fallback="100"))
            
                        
    def saveConfig(self):
        '''
        saves entered configuration items
        TODO: make bulletproof
        '''
        if not(self.configFile.exists()):
            self.configFile.touch()
            
        self.config.read_file(open(str(self.configFile)))
        
        if not(self.config.has_section("General")):
            self.config.add_section("General")
        self.config["General"]["winrm_port"] = self.ui.lineEdit_winRmPort.text()
        self.config["General"]["lb_server"] = self.ui.comboBox_LbServer.currentText()
        
        if not(self.config.has_section("Client")):
            self.config.add_section("Client")
        self.config["Client"]["lb_user"] = self.ui.lineEdit_StdLogin.text()
        self.config["Client"]["user"] =  self.ui.lineEdit_winRmUser.text()
        self.config["Client"]["pwd"] = self.ui.lineEdit_winRmPwd.text()
        self.config["Client"]["max_files"]=self.ui.lineEdit_MaxFiles.text()
        self.config["Client"]["max_fileSize"]=self.ui.lineEdit_MaxFileSize.text()
        
        self.config.write(open(self.configFile,'w'))
        
        
if __name__ == "__main__":
    '''
    just for testing
    '''
    app = QApplication()
    dlg = EcManConfigDialog(None, "dummy.conf")
    result = dlg.exec_()
    if result == 1:
        dlg.saveConfig()