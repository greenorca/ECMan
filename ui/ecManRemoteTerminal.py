# from worker.computer import Computer
from PySide2.QtCore import Qt
from PySide2.QtWidgets import QDialog

from ui.remoteTerminal import Ui_Dialog
from worker.computer import Computer


class EcManRemoteTerminal(QDialog):
    '''
    QDialog based remote admin dialog for ECMan app
    adapted from https://www.codementor.io/deepaksingh04/design-simple-dialog-using-pyqt5-designer-tool-ajskrd09n
    and https://stackoverflow.com/questions/19379120/how-to-read-a-config-file-using-python#19379306
    class inherists from QDialog, and contains the UI defined in ConfigDialog (based on configDialog.ui) 
    '''

    def __init__(self, parent=None, client: Computer = None):
        '''
        Constructor        
        '''
        super(EcManRemoteTerminal, self).__init__(parent)
        self.client = client
        self.ui = Ui_Dialog()
        self.ui.setupUi(self)
        self.ui.txtCommand.returnPressed.connect(self.sendCommand)

        with open("scripts/ps_samples.txt") as commands:
            for line in commands:
                info, command = line.split("::")
                self.ui.comboBox.addItem(info, command)

        self.ui.comboBox.currentIndexChanged.connect(self.commandSelectionChanged)

        self.setWindowTitle("{} Remote-PowerShell (VORSICHT!)".format(client.getHostName()))

        self.commandHistory = []
        self.previousCommandIndex = 0

    def keyPressEvent(self, event):
        '''
        enter previous commands in shell
        :param event:
        :return:
        '''
        super(EcManRemoteTerminal, self).keyPressEvent(event)
        if len(self.commandHistory) > 0:
            if event.key() == Qt.Key_Up:
                self.currentCommandIndex = (self.currentCommandIndex - 1) % (len(self.commandHistory))
                command = self.commandHistory[self.currentCommandIndex]
                self.ui.txtCommand.setText(command)
            elif event.key() == Qt.Key_Down:
                self.currentCommandIndex = (self.currentCommandIndex + 1) % (len(self.commandHistory))
                if self.currentCommandIndex > 0:
                    self.ui.txtCommand.setText(self.commandHistory[self.currentCommandIndex])
            else:
                self.currentCommandIndex = len(self.commandHistory)


    def commandSelectionChanged(self):
        self.ui.txtCommand.setText(self.ui.comboBox.itemData(self.ui.comboBox.currentIndex()).replace('\n', ''))
        self.ui.txtCommand.setFocus()

    def execCommand(self, command):
        self.ui.resultField.append("<b>" + self.ui.txtCommand.text() + "</b><br>")
        out, error, state = self.client.runPowerShellCommand(command)

        if state == 0:
            self.ui.resultField.append(
                "<pre>" + out.replace("\\r\\n\\r\\n", "\\r\\n").replace("<", "&lt;").replace(">", "&gt;") + "</pre>")
        else:
            self.ui.resultField.append(
                "<span color='red'>" + "<pre>" + error.replace("<", "&lt;").replace(">", "&gt;") + "</pre>" + "</span>")

    def sendCommand(self):
        self.commandHistory.append(self.ui.txtCommand.text())
        self.currentCommandIndex = len(self.commandHistory)
        self.execCommand(self.ui.txtCommand.text())
        self.ui.txtCommand.setText("")


'''
if __name__ == "__main__":
'''
# just for testing
'''
app = QApplication()
dlg = EcManRemoteDialog(None, None)
result = dlg.exec_()
'''
