# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'configDialog.ui',
# licensing of 'configDialog.ui' applies.
#
# Created: Tue Jan 22 17:20:58 2019
#      by: pyside2-uic  running on PySide2 5.12.0
#
# WARNING! All changes made in this file will be lost!

from PySide2 import QtCore, QtGui, QtWidgets

class Ui_Dialog(object):
    def setupUi(self, Dialog):
        Dialog.setObjectName("Dialog")
        Dialog.resize(400, 300)
        self.buttonBox = QtWidgets.QDialogButtonBox(Dialog)
        self.buttonBox.setGeometry(QtCore.QRect(50, 260, 341, 32))
        self.buttonBox.setOrientation(QtCore.Qt.Horizontal)
        self.buttonBox.setStandardButtons(QtWidgets.QDialogButtonBox.Cancel|QtWidgets.QDialogButtonBox.Ok)
        self.buttonBox.setObjectName("buttonBox")
        self.formLayoutWidget = QtWidgets.QWidget(Dialog)
        self.formLayoutWidget.setGeometry(QtCore.QRect(10, 10, 381, 241))
        self.formLayoutWidget.setObjectName("formLayoutWidget")
        self.formLayout = QtWidgets.QFormLayout(self.formLayoutWidget)
        self.formLayout.setContentsMargins(0, 0, 0, 0)
        self.formLayout.setObjectName("formLayout")
        self.label = QtWidgets.QLabel(self.formLayoutWidget)
        self.label.setObjectName("label")
        self.formLayout.setWidget(0, QtWidgets.QFormLayout.LabelRole, self.label)
        self.comboBox_LbServer = QtWidgets.QComboBox(self.formLayoutWidget)
        self.comboBox_LbServer.setEditable(True)
        self.comboBox_LbServer.setObjectName("comboBox_LbServer")
        self.formLayout.setWidget(0, QtWidgets.QFormLayout.FieldRole, self.comboBox_LbServer)
        self.label_2 = QtWidgets.QLabel(self.formLayoutWidget)
        self.label_2.setObjectName("label_2")
        self.formLayout.setWidget(1, QtWidgets.QFormLayout.LabelRole, self.label_2)
        self.lineEdit_StdLogin = QtWidgets.QLineEdit(self.formLayoutWidget)
        self.lineEdit_StdLogin.setObjectName("lineEdit_StdLogin")
        self.formLayout.setWidget(1, QtWidgets.QFormLayout.FieldRole, self.lineEdit_StdLogin)
        self.label_3 = QtWidgets.QLabel(self.formLayoutWidget)
        self.label_3.setObjectName("label_3")
        self.formLayout.setWidget(3, QtWidgets.QFormLayout.LabelRole, self.label_3)
        self.lineEdit_winRmUser = QtWidgets.QLineEdit(self.formLayoutWidget)
        self.lineEdit_winRmUser.setObjectName("lineEdit_winRmUser")
        self.formLayout.setWidget(3, QtWidgets.QFormLayout.FieldRole, self.lineEdit_winRmUser)
        self.label_4 = QtWidgets.QLabel(self.formLayoutWidget)
        self.label_4.setObjectName("label_4")
        self.formLayout.setWidget(4, QtWidgets.QFormLayout.LabelRole, self.label_4)
        self.lineEdit_winRmPwd = QtWidgets.QLineEdit(self.formLayoutWidget)
        self.lineEdit_winRmPwd.setInputMethodHints(QtCore.Qt.ImhSensitiveData)
        self.lineEdit_winRmPwd.setObjectName("lineEdit_winRmPwd")
        self.formLayout.setWidget(4, QtWidgets.QFormLayout.FieldRole, self.lineEdit_winRmPwd)
        self.label_5 = QtWidgets.QLabel(self.formLayoutWidget)
        self.label_5.setObjectName("label_5")
        self.formLayout.setWidget(2, QtWidgets.QFormLayout.LabelRole, self.label_5)
        self.lineEdit_winRmPort = QtWidgets.QLineEdit(self.formLayoutWidget)
        self.lineEdit_winRmPort.setObjectName("lineEdit_winRmPort")
        self.formLayout.setWidget(2, QtWidgets.QFormLayout.FieldRole, self.lineEdit_winRmPort)

        self.retranslateUi(Dialog)
        QtCore.QObject.connect(self.buttonBox, QtCore.SIGNAL("accepted()"), Dialog.accept)
        QtCore.QObject.connect(self.buttonBox, QtCore.SIGNAL("rejected()"), Dialog.reject)
        QtCore.QMetaObject.connectSlotsByName(Dialog)
        Dialog.setTabOrder(self.comboBox_LbServer, self.lineEdit_StdLogin)
        Dialog.setTabOrder(self.lineEdit_StdLogin, self.lineEdit_winRmPort)
        Dialog.setTabOrder(self.lineEdit_winRmPort, self.lineEdit_winRmUser)
        Dialog.setTabOrder(self.lineEdit_winRmUser, self.lineEdit_winRmPwd)

    def retranslateUi(self, Dialog):
        Dialog.setWindowTitle(QtWidgets.QApplication.translate("Dialog", "Dialog", None, -1))
        self.label.setText(QtWidgets.QApplication.translate("Dialog", "LB Server", None, -1))
        self.label_2.setText(QtWidgets.QApplication.translate("Dialog", "Standard-Login", None, -1))
        self.lineEdit_StdLogin.setToolTip(QtWidgets.QApplication.translate("Dialog", "Benutzername der Prüfungskandidaten auf Client PC, sollte student sein", None, -1))
        self.lineEdit_StdLogin.setText(QtWidgets.QApplication.translate("Dialog", "student", None, -1))
        self.label_3.setText(QtWidgets.QApplication.translate("Dialog", "WinRM-Login", None, -1))
        self.lineEdit_winRmUser.setToolTip(QtWidgets.QApplication.translate("Dialog", "Benutzername für Remotezugriff (wie im Konfigskript für Client-PCs)", None, -1))
        self.lineEdit_winRmUser.setText(QtWidgets.QApplication.translate("Dialog", "winrm", None, -1))
        self.label_4.setText(QtWidgets.QApplication.translate("Dialog", "WinRM-Passwort", None, -1))
        self.lineEdit_winRmPwd.setToolTip(QtWidgets.QApplication.translate("Dialog", "Passwort für Remotezugriff (wie im Konfigskript für Client-PCs)", None, -1))
        self.label_5.setText(QtWidgets.QApplication.translate("Dialog", "WinRM-Port", None, -1))
        self.lineEdit_winRmPort.setText(QtWidgets.QApplication.translate("Dialog", "5986", None, -1))

