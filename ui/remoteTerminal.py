# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'ui/remoteTerminal.ui',
# licensing of 'ui/remoteTerminal.ui' applies.
#
# Created: Tue May 28 16:53:31 2019
#      by: pyside2-uic  running on PySide2 5.12.3
#
# WARNING! All changes made in this file will be lost!

from PySide2 import QtCore, QtGui, QtWidgets

class Ui_Form(object):
    def setupUi(self, Form):
        Form.setObjectName("Form")
        Form.resize(517, 301)
        self.verticalLayout = QtWidgets.QVBoxLayout(Form)
        self.verticalLayout.setObjectName("verticalLayout")
        self.resultField = QtWidgets.QTextBrowser(Form)
        self.resultField.setLineWrapMode(QtWidgets.QTextEdit.FixedColumnWidth)
        self.resultField.setLineWrapColumnOrWidth(40)
        self.resultField.setObjectName("resultField")
        self.verticalLayout.addWidget(self.resultField)
        self.txtCommand = QtWidgets.QLineEdit(Form)
        self.txtCommand.setObjectName("txtCommand")
        self.verticalLayout.addWidget(self.txtCommand)
        self.comboBox = QtWidgets.QComboBox(Form)
        self.comboBox.setObjectName("comboBox")
        self.verticalLayout.addWidget(self.comboBox)

        self.retranslateUi(Form)
        QtCore.QMetaObject.connectSlotsByName(Form)

    def retranslateUi(self, Form):
        Form.setWindowTitle(QtWidgets.QApplication.translate("Form", "Form", None, -1))

