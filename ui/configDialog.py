# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'configDialog.ui',
# licensing of 'configDialog.ui' applies.
#
# Created: Sun May  5 15:40:32 2019
#      by: pyside2-uic  running on PySide2 5.12.0
#
# WARNING! All changes made in this file will be lost!

from PySide2 import QtCore, QtWidgets


class Ui_Dialog(object):
    def setupUi(self, Dialog):
        Dialog.setObjectName("Dialog")
        Dialog.resize(401, 372)
        self.verticalLayout = QtWidgets.QVBoxLayout(Dialog)
        self.verticalLayout.setObjectName("verticalLayout")
        self.formLayout = QtWidgets.QFormLayout()
        self.formLayout.setSizeConstraint(QtWidgets.QLayout.SetMinimumSize)
        self.formLayout.setFieldGrowthPolicy(QtWidgets.QFormLayout.ExpandingFieldsGrow)
        self.formLayout.setObjectName("formLayout")
        self.label = QtWidgets.QLabel(Dialog)
        self.label.setObjectName("label")
        self.formLayout.setWidget(0, QtWidgets.QFormLayout.LabelRole, self.label)
        self.comboBox_LbServer = QtWidgets.QComboBox(Dialog)
        self.comboBox_LbServer.setEditable(True)
        self.comboBox_LbServer.setObjectName("comboBox_LbServer")
        self.formLayout.setWidget(0, QtWidgets.QFormLayout.FieldRole, self.comboBox_LbServer)
        self.label_2 = QtWidgets.QLabel(Dialog)
        self.label_2.setObjectName("label_2")
        self.formLayout.setWidget(1, QtWidgets.QFormLayout.LabelRole, self.label_2)
        self.lineEdit_StdLogin = QtWidgets.QLineEdit(Dialog)
        self.lineEdit_StdLogin.setObjectName("lineEdit_StdLogin")
        self.formLayout.setWidget(1, QtWidgets.QFormLayout.FieldRole, self.lineEdit_StdLogin)
        self.label_9 = QtWidgets.QLabel(Dialog)
        self.label_9.setObjectName("label_9")
        self.formLayout.setWidget(2, QtWidgets.QFormLayout.LabelRole, self.label_9)
        self.lineEdit_OnlineWiki = QtWidgets.QLineEdit(Dialog)
        self.lineEdit_OnlineWiki.setObjectName("lineEdit_OnlineWiki")
        self.formLayout.setWidget(2, QtWidgets.QFormLayout.FieldRole, self.lineEdit_OnlineWiki)
        self.line_2 = QtWidgets.QFrame(Dialog)
        self.line_2.setFrameShape(QtWidgets.QFrame.HLine)
        self.line_2.setFrameShadow(QtWidgets.QFrame.Sunken)
        self.line_2.setObjectName("line_2")
        self.formLayout.setWidget(3, QtWidgets.QFormLayout.SpanningRole, self.line_2)
        self.label_5 = QtWidgets.QLabel(Dialog)
        self.label_5.setObjectName("label_5")
        self.formLayout.setWidget(4, QtWidgets.QFormLayout.LabelRole, self.label_5)
        self.lineEdit_winRmPort = QtWidgets.QLineEdit(Dialog)
        self.lineEdit_winRmPort.setObjectName("lineEdit_winRmPort")
        self.formLayout.setWidget(4, QtWidgets.QFormLayout.FieldRole, self.lineEdit_winRmPort)
        self.label_3 = QtWidgets.QLabel(Dialog)
        self.label_3.setObjectName("label_3")
        self.formLayout.setWidget(5, QtWidgets.QFormLayout.LabelRole, self.label_3)
        self.lineEdit_winRmUser = QtWidgets.QLineEdit(Dialog)
        self.lineEdit_winRmUser.setObjectName("lineEdit_winRmUser")
        self.formLayout.setWidget(5, QtWidgets.QFormLayout.FieldRole, self.lineEdit_winRmUser)
        self.label_4 = QtWidgets.QLabel(Dialog)
        self.label_4.setObjectName("label_4")
        self.formLayout.setWidget(6, QtWidgets.QFormLayout.LabelRole, self.label_4)
        self.lineEdit_winRmPwd = QtWidgets.QLineEdit(Dialog)
        self.lineEdit_winRmPwd.setInputMethodHints(
            QtCore.Qt.ImhHiddenText | QtCore.Qt.ImhNoAutoUppercase | QtCore.Qt.ImhNoPredictiveText | QtCore.Qt.ImhSensitiveData)
        self.lineEdit_winRmPwd.setText("")
        self.lineEdit_winRmPwd.setEchoMode(QtWidgets.QLineEdit.Password)
        self.lineEdit_winRmPwd.setObjectName("lineEdit_winRmPwd")
        self.formLayout.setWidget(6, QtWidgets.QFormLayout.FieldRole, self.lineEdit_winRmPwd)
        self.line = QtWidgets.QFrame(Dialog)
        self.line.setFrameShape(QtWidgets.QFrame.HLine)
        self.line.setFrameShadow(QtWidgets.QFrame.Sunken)
        self.line.setObjectName("line")
        self.formLayout.setWidget(7, QtWidgets.QFormLayout.SpanningRole, self.line)
        self.label_6 = QtWidgets.QLabel(Dialog)
        self.label_6.setObjectName("label_6")
        self.formLayout.setWidget(9, QtWidgets.QFormLayout.LabelRole, self.label_6)
        self.lineEdit_MaxFileSize = QtWidgets.QLineEdit(Dialog)
        self.lineEdit_MaxFileSize.setObjectName("lineEdit_MaxFileSize")
        self.formLayout.setWidget(9, QtWidgets.QFormLayout.FieldRole, self.lineEdit_MaxFileSize)
        self.label_7 = QtWidgets.QLabel(Dialog)
        self.label_7.setObjectName("label_7")
        self.formLayout.setWidget(10, QtWidgets.QFormLayout.LabelRole, self.label_7)
        self.lineEdit_MaxFiles = QtWidgets.QLineEdit(Dialog)
        self.lineEdit_MaxFiles.setObjectName("lineEdit_MaxFiles")
        self.formLayout.setWidget(10, QtWidgets.QFormLayout.FieldRole, self.lineEdit_MaxFiles)
        self.label_8 = QtWidgets.QLabel(Dialog)
        self.label_8.setObjectName("label_8")
        self.formLayout.setWidget(11, QtWidgets.QFormLayout.LabelRole, self.label_8)
        self.checkBox_HiddenFiles = QtWidgets.QCheckBox(Dialog)
        self.checkBox_HiddenFiles.setEnabled(False)
        self.checkBox_HiddenFiles.setChecked(True)
        self.checkBox_HiddenFiles.setObjectName("checkBox_HiddenFiles")
        self.formLayout.setWidget(11, QtWidgets.QFormLayout.FieldRole, self.checkBox_HiddenFiles)
        self.buttonBox = QtWidgets.QDialogButtonBox(Dialog)
        self.buttonBox.setOrientation(QtCore.Qt.Horizontal)
        self.buttonBox.setStandardButtons(QtWidgets.QDialogButtonBox.Cancel | QtWidgets.QDialogButtonBox.Ok)
        self.buttonBox.setObjectName("buttonBox")
        self.formLayout.setWidget(12, QtWidgets.QFormLayout.FieldRole, self.buttonBox)
        self.label_10 = QtWidgets.QLabel(Dialog)
        self.label_10.setObjectName("label_10")
        self.formLayout.setWidget(8, QtWidgets.QFormLayout.SpanningRole, self.label_10)
        self.verticalLayout.addLayout(self.formLayout)

        self.retranslateUi(Dialog)
        QtCore.QObject.connect(self.buttonBox, QtCore.SIGNAL("accepted()"), Dialog.accept)
        QtCore.QObject.connect(self.buttonBox, QtCore.SIGNAL("rejected()"), Dialog.reject)
        QtCore.QMetaObject.connectSlotsByName(Dialog)
        Dialog.setTabOrder(self.comboBox_LbServer, self.lineEdit_StdLogin)
        Dialog.setTabOrder(self.lineEdit_StdLogin, self.lineEdit_OnlineWiki)
        Dialog.setTabOrder(self.lineEdit_OnlineWiki, self.lineEdit_winRmPort)
        Dialog.setTabOrder(self.lineEdit_winRmPort, self.lineEdit_winRmUser)
        Dialog.setTabOrder(self.lineEdit_winRmUser, self.lineEdit_winRmPwd)
        Dialog.setTabOrder(self.lineEdit_winRmPwd, self.lineEdit_MaxFileSize)
        Dialog.setTabOrder(self.lineEdit_MaxFileSize, self.lineEdit_MaxFiles)
        Dialog.setTabOrder(self.lineEdit_MaxFiles, self.checkBox_HiddenFiles)

    def retranslateUi(self, Dialog):
        Dialog.setWindowTitle(QtWidgets.QApplication.translate("Dialog", "Dialog", None, -1))
        self.label.setText(QtWidgets.QApplication.translate("Dialog", "LB Server", None, -1))
        self.label_2.setText(QtWidgets.QApplication.translate("Dialog", "Standard-Login", None, -1))
        self.lineEdit_StdLogin.setToolTip(QtWidgets.QApplication.translate("Dialog",
                                                                           "Benutzername der Prüfungskandidaten auf Client PC, sollte student sein",
                                                                           None, -1))
        self.lineEdit_StdLogin.setText(QtWidgets.QApplication.translate("Dialog", "student", None, -1))
        self.label_9.setText(QtWidgets.QApplication.translate("Dialog", "Online-Wiki", None, -1))
        self.label_5.setText(QtWidgets.QApplication.translate("Dialog", "WinRM-Port", None, -1))
        self.lineEdit_winRmPort.setText(QtWidgets.QApplication.translate("Dialog", "5986", None, -1))
        self.label_3.setText(QtWidgets.QApplication.translate("Dialog", "WinRM-Login", None, -1))
        self.lineEdit_winRmUser.setToolTip(QtWidgets.QApplication.translate("Dialog",
                                                                            "Benutzername für Remotezugriff (wie im Konfigskript für Client-PCs)",
                                                                            None, -1))
        self.lineEdit_winRmUser.setText(QtWidgets.QApplication.translate("Dialog", "winrm", None, -1))
        self.label_4.setText(QtWidgets.QApplication.translate("Dialog", "WinRM-Passwort", None, -1))
        self.lineEdit_winRmPwd.setToolTip(QtWidgets.QApplication.translate("Dialog",
                                                                           "Passwort für Remotezugriff (wie im Konfigskript für Client-PCs)",
                                                                           None, -1))
        self.label_6.setToolTip(QtWidgets.QApplication.translate("Dialog",
                                                                 "Hier Limite für die maximale Dateigrösse der Lösungsdaten setzen.",
                                                                 None, -1))
        self.label_6.setText(QtWidgets.QApplication.translate("Dialog", "max. Dateigrösse (MB)", None, -1))
        self.lineEdit_MaxFileSize.setText(QtWidgets.QApplication.translate("Dialog", "100", None, -1))
        self.label_7.setToolTip(
            QtWidgets.QApplication.translate("Dialog", "Hier Limite für die maximale Anzahl Lösungsdateien setzen.",
                                             None, -1))
        self.label_7.setText(QtWidgets.QApplication.translate("Dialog", "max. Dateien", None, -1))
        self.lineEdit_MaxFiles.setText(QtWidgets.QApplication.translate("Dialog", "100", None, -1))
        self.label_8.setText(QtWidgets.QApplication.translate("Dialog", "versteckte Dateien", None, -1))
        self.checkBox_HiddenFiles.setToolTip(
            QtWidgets.QApplication.translate("Dialog", "versteckte Dateien und Ordner (.*) werden derzeit ignoriert.",
                                             None, -1))
        self.checkBox_HiddenFiles.setText(QtWidgets.QApplication.translate("Dialog", "ignorieren", None, -1))
        self.label_10.setText(QtWidgets.QApplication.translate("Dialog", "Prüfungsergebnisse abholen:", None, -1))
