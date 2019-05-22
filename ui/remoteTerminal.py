# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'remoteTerminal.ui',
# licensing of 'remoteTerminal.ui' applies.
#
# Created: Tue May  7 19:37:52 2019
#      by: pyside2-uic  running on PySide2 5.12.0
#
# WARNING! All changes made in this file will be lost!

from PySide2 import QtCore, QtWidgets


class Ui_Dialog(object):
    def setupUi(self, Dialog):
        Dialog.setObjectName("Dialog")
        Dialog.resize(516, 303)
        self.verticalLayout = QtWidgets.QVBoxLayout(Dialog)
        self.verticalLayout.setObjectName("verticalLayout")
        self.resultField = QtWidgets.QTextBrowser(Dialog)
        self.resultField.setObjectName("resultField")
        self.verticalLayout.addWidget(self.resultField)
        self.txtCommand = QtWidgets.QLineEdit(Dialog)
        self.txtCommand.setObjectName("txtCommand")
        self.verticalLayout.addWidget(self.txtCommand)
        self.comboBox = QtWidgets.QComboBox(Dialog)
        self.comboBox.setObjectName("comboBox")
        self.verticalLayout.addWidget(self.comboBox)

        self.retranslateUi(Dialog)
        QtCore.QMetaObject.connectSlotsByName(Dialog)

    def retranslateUi(self, Dialog):
        Dialog.setWindowTitle(QtWidgets.QApplication.translate("Dialog", "Dialog", None, -1))
