'''
Created on Jan 28, 2019

@author: sven
'''
from PySide2.QtWidgets import QDialog
from ui.progressDialog import Ui_progressDialog
from PySide2.QtWidgets import QApplication

class EcManProgressDialog(QDialog):
    '''
    QDialog based Configuration dialog for ECMan app
    adapted from https://www.codementor.io/deepaksingh04/design-simple-dialog-using-pyqt5-designer-tool-ajskrd09n
    and https://stackoverflow.com/questions/19379120/how-to-read-a-config-file-using-python#19379306
    class inherists from QDialog, and contains the UI defined in ConfigDialog (based on configDialog.ui) 
    '''

    def __init__(self, parent=None, title="Change me if you can"):
        '''
        Constructor        
        '''
        super(EcManProgressDialog,self).__init__(parent)
        self.ui = Ui_progressDialog()        
        self.ui.setupUi(self)
        # self.ui.setWindowTitle(title)
        self.setModal(True)
        
    def setMaxValue(self, value):
        self.ui.progressBar.setMaximum(value)
        pass
    
    def setValue(self, value):
        self.ui.progressBar.setValue(value)
        if self.ui.progressBar.maximum() == value:
            self.done(0)
        pass