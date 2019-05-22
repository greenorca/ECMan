'''
Created on Jan 19, 2019

@author: sven
'''

from PySide2.QtWidgets import QTextEdit


class Logger(object):
    '''
    class provides abstraction for logging 
    '''

    def __init__(self, textEdit=None):
        '''
        creates an instance of logger class. if textEdit is an instance of QTextEdit, all log messages will be appended
        here  
        '''
        self.debug = True
        if type(textEdit) == QTextEdit:
            self.textEdit = textEdit
        else:
            self.textEdit = None;

    def log(self, message):
        if self.textEdit == None:
            print(message)
            return
        if self.debug:
            print(message)
        self.textEdit.append(message + "\n")
