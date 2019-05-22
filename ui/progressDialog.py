# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'progressDialog.ui',
# licensing of 'progressDialog.ui' applies.
#
# Created: Mon Jan 28 18:45:42 2019
#      by: pyside2-uic  running on PySide2 5.12.0
#
# WARNING! All changes made in this file will be lost!

from PySide2 import QtCore, QtWidgets


class Ui_progressDialog(object):
    def setupUi(self, progressDialog):
        progressDialog.setObjectName("progressDialog")
        progressDialog.resize(582, 154)
        self.label = QtWidgets.QLabel(progressDialog)
        self.label.setGeometry(QtCore.QRect(20, 20, 541, 18))
        self.label.setObjectName("label")
        self.progressBar = QtWidgets.QProgressBar(progressDialog)
        self.progressBar.setGeometry(QtCore.QRect(20, 50, 551, 41))
        self.progressBar.setProperty("value", 24)
        self.progressBar.setObjectName("progressBar")

        self.retranslateUi(progressDialog)
        QtCore.QMetaObject.connectSlotsByName(progressDialog)

    def retranslateUi(self, progressDialog):
        progressDialog.setWindowTitle(QtWidgets.QApplication.translate("progressDialog", "Fortschritt", None, -1))
        self.label.setText(
            QtWidgets.QApplication.translate("progressDialog", "Bitte warten, Aufträge werden ausgeführt", None, -1))
