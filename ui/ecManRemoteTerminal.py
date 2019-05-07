#from worker.computer import Computer
from PySide2.QtWidgets import QDialog, QApplication
from ui.remoteTerminal import Ui_Dialog

class EcManRemoteTerminal(QDialog):
    '''
    QDialog based remote admin dialog for ECMan app
    adapted from https://www.codementor.io/deepaksingh04/design-simple-dialog-using-pyqt5-designer-tool-ajskrd09n
    and https://stackoverflow.com/questions/19379120/how-to-read-a-config-file-using-python#19379306
    class inherists from QDialog, and contains the UI defined in ConfigDialog (based on configDialog.ui) 
    '''

    def __init__(self, parent=None, client=None):
        '''
        Constructor        
        '''
        super(EcManRemoteTerminal,self).__init__(parent)
        self.client = client
        self.ui = Ui_Dialog()
        self.ui.setupUi(self)
        self.ui.txtCommand.returnPressed.connect(self.sendCommand)
        
        with open("scripts/ps_samples.txt") as commands:
            for line in commands:
                info, command = line.split("::")
                self.ui.comboBox.addItem(info, command)
        
        self.ui.comboBox.currentIndexChanged.connect(self.commandSelectionChanged)
        
        self.setWindowTitle("Remote-PowerShell (VORSICHT!)")
        
    def commandSelectionChanged(self):
        self.ui.txtCommand.setText(self.ui.comboBox.itemData(self.ui.comboBox.currentIndex()).replace('\n',''))
        self.ui.txtCommand.setFocus()
        
    def execCommand(self, command):
        out, error, state = self.client.runPowerShellCommand(command)
        
        if state == 0:
            self.ui.resultField.append(out)
        else:
            self.ui.resultField.append("<span color='red'>"+error+"</span>")
    
    def sendCommand(self):
        self.ui.resultField.append("<b>"+self.ui.txtCommand.text()+"</b><br>")
        self.execCommand(self.ui.txtCommand.text())
        self.ui.txtCommand.setText("")
    
'''
if __name__ == "__main__":
'''
#just for testing
'''
app = QApplication()
dlg = EcManRemoteDialog(None, None)
result = dlg.exec_()
'''