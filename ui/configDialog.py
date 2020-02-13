# -*- coding: utf-8 -*-

################################################################################
## Form generated from reading UI file 'configDialog.ui'
##
## Created by: Qt User Interface Compiler version 5.14.1
##
## WARNING! All changes made in this file will be lost when recompiling UI file!
################################################################################

from PySide2.QtCore import (QCoreApplication, QMetaObject, QObject, QPoint,
    QRect, QSize, QUrl, Qt)
from PySide2.QtGui import (QBrush, QColor, QConicalGradient, QCursor, QFont,
    QFontDatabase, QIcon, QLinearGradient, QPalette, QPainter, QPixmap,
    QRadialGradient)
from PySide2.QtWidgets import *


class Ui_Dialog(object):
    def setupUi(self, Dialog):
        if Dialog.objectName():
            Dialog.setObjectName(u"Dialog")
        Dialog.resize(401, 435)
        self.verticalLayout = QVBoxLayout(Dialog)
        self.verticalLayout.setObjectName(u"verticalLayout")
        self.formLayout = QFormLayout()
        self.formLayout.setObjectName(u"formLayout")
        self.formLayout.setSizeConstraint(QLayout.SetMinimumSize)
        self.formLayout.setFieldGrowthPolicy(QFormLayout.ExpandingFieldsGrow)
        self.label = QLabel(Dialog)
        self.label.setObjectName(u"label")

        self.formLayout.setWidget(0, QFormLayout.LabelRole, self.label)

        self.comboBox_LbServer = QComboBox(Dialog)
        self.comboBox_LbServer.setObjectName(u"comboBox_LbServer")
        self.comboBox_LbServer.setEditable(True)

        self.formLayout.setWidget(0, QFormLayout.FieldRole, self.comboBox_LbServer)

        self.label_2 = QLabel(Dialog)
        self.label_2.setObjectName(u"label_2")

        self.formLayout.setWidget(1, QFormLayout.LabelRole, self.label_2)

        self.lineEdit_StdLogin = QLineEdit(Dialog)
        self.lineEdit_StdLogin.setObjectName(u"lineEdit_StdLogin")

        self.formLayout.setWidget(1, QFormLayout.FieldRole, self.lineEdit_StdLogin)

        self.label_9 = QLabel(Dialog)
        self.label_9.setObjectName(u"label_9")

        self.formLayout.setWidget(2, QFormLayout.LabelRole, self.label_9)

        self.lineEdit_OnlineWiki = QLineEdit(Dialog)
        self.lineEdit_OnlineWiki.setObjectName(u"lineEdit_OnlineWiki")

        self.formLayout.setWidget(2, QFormLayout.FieldRole, self.lineEdit_OnlineWiki)

        self.line_2 = QFrame(Dialog)
        self.line_2.setObjectName(u"line_2")
        self.line_2.setFrameShape(QFrame.HLine)
        self.line_2.setFrameShadow(QFrame.Sunken)

        self.formLayout.setWidget(3, QFormLayout.SpanningRole, self.line_2)

        self.label_5 = QLabel(Dialog)
        self.label_5.setObjectName(u"label_5")

        self.formLayout.setWidget(4, QFormLayout.LabelRole, self.label_5)

        self.lineEdit_winRmPort = QLineEdit(Dialog)
        self.lineEdit_winRmPort.setObjectName(u"lineEdit_winRmPort")

        self.formLayout.setWidget(4, QFormLayout.FieldRole, self.lineEdit_winRmPort)

        self.label_3 = QLabel(Dialog)
        self.label_3.setObjectName(u"label_3")

        self.formLayout.setWidget(5, QFormLayout.LabelRole, self.label_3)

        self.lineEdit_winRmUser = QLineEdit(Dialog)
        self.lineEdit_winRmUser.setObjectName(u"lineEdit_winRmUser")

        self.formLayout.setWidget(5, QFormLayout.FieldRole, self.lineEdit_winRmUser)

        self.label_4 = QLabel(Dialog)
        self.label_4.setObjectName(u"label_4")

        self.formLayout.setWidget(6, QFormLayout.LabelRole, self.label_4)

        self.lineEdit_winRmPwd = QLineEdit(Dialog)
        self.lineEdit_winRmPwd.setObjectName(u"lineEdit_winRmPwd")
        self.lineEdit_winRmPwd.setInputMethodHints(Qt.ImhHiddenText|Qt.ImhNoAutoUppercase|Qt.ImhNoPredictiveText|Qt.ImhSensitiveData)
        self.lineEdit_winRmPwd.setEchoMode(QLineEdit.Password)

        self.formLayout.setWidget(6, QFormLayout.FieldRole, self.lineEdit_winRmPwd)

        self.line = QFrame(Dialog)
        self.line.setObjectName(u"line")
        self.line.setFrameShape(QFrame.HLine)
        self.line.setFrameShadow(QFrame.Sunken)

        self.formLayout.setWidget(7, QFormLayout.SpanningRole, self.line)

        self.label_6 = QLabel(Dialog)
        self.label_6.setObjectName(u"label_6")

        self.formLayout.setWidget(9, QFormLayout.LabelRole, self.label_6)

        self.lineEdit_MaxFileSize = QLineEdit(Dialog)
        self.lineEdit_MaxFileSize.setObjectName(u"lineEdit_MaxFileSize")

        self.formLayout.setWidget(9, QFormLayout.FieldRole, self.lineEdit_MaxFileSize)

        self.label_7 = QLabel(Dialog)
        self.label_7.setObjectName(u"label_7")

        self.formLayout.setWidget(10, QFormLayout.LabelRole, self.label_7)

        self.lineEdit_MaxFiles = QLineEdit(Dialog)
        self.lineEdit_MaxFiles.setObjectName(u"lineEdit_MaxFiles")

        self.formLayout.setWidget(10, QFormLayout.FieldRole, self.lineEdit_MaxFiles)

        self.label_8 = QLabel(Dialog)
        self.label_8.setObjectName(u"label_8")

        self.formLayout.setWidget(11, QFormLayout.LabelRole, self.label_8)

        self.checkBox_HiddenFiles = QCheckBox(Dialog)
        self.checkBox_HiddenFiles.setObjectName(u"checkBox_HiddenFiles")
        self.checkBox_HiddenFiles.setEnabled(False)
        self.checkBox_HiddenFiles.setChecked(True)

        self.formLayout.setWidget(11, QFormLayout.FieldRole, self.checkBox_HiddenFiles)

        self.label_10 = QLabel(Dialog)
        self.label_10.setObjectName(u"label_10")

        self.formLayout.setWidget(8, QFormLayout.SpanningRole, self.label_10)

        self.buttonBox = QDialogButtonBox(Dialog)
        self.buttonBox.setObjectName(u"buttonBox")
        self.buttonBox.setOrientation(Qt.Horizontal)
        self.buttonBox.setStandardButtons(QDialogButtonBox.Cancel|QDialogButtonBox.Ok)

        self.formLayout.setWidget(14, QFormLayout.FieldRole, self.buttonBox)

        self.label_11 = QLabel(Dialog)
        self.label_11.setObjectName(u"label_11")

        self.formLayout.setWidget(12, QFormLayout.LabelRole, self.label_11)

        self.checkBox_advancedFeatures = QCheckBox(Dialog)
        self.checkBox_advancedFeatures.setObjectName(u"checkBox_advancedFeatures")

        self.formLayout.setWidget(12, QFormLayout.FieldRole, self.checkBox_advancedFeatures)


        self.verticalLayout.addLayout(self.formLayout)

        QWidget.setTabOrder(self.comboBox_LbServer, self.lineEdit_StdLogin)
        QWidget.setTabOrder(self.lineEdit_StdLogin, self.lineEdit_OnlineWiki)
        QWidget.setTabOrder(self.lineEdit_OnlineWiki, self.lineEdit_winRmPort)
        QWidget.setTabOrder(self.lineEdit_winRmPort, self.lineEdit_winRmUser)
        QWidget.setTabOrder(self.lineEdit_winRmUser, self.lineEdit_winRmPwd)
        QWidget.setTabOrder(self.lineEdit_winRmPwd, self.lineEdit_MaxFileSize)
        QWidget.setTabOrder(self.lineEdit_MaxFileSize, self.lineEdit_MaxFiles)
        QWidget.setTabOrder(self.lineEdit_MaxFiles, self.checkBox_HiddenFiles)

        self.retranslateUi(Dialog)
        self.buttonBox.accepted.connect(Dialog.accept)
        self.buttonBox.rejected.connect(Dialog.reject)

        QMetaObject.connectSlotsByName(Dialog)
    # setupUi

    def retranslateUi(self, Dialog):
        Dialog.setWindowTitle(QCoreApplication.translate("Dialog", u"Dialog", None))
        self.label.setText(QCoreApplication.translate("Dialog", u"LB Server", None))
        self.label_2.setText(QCoreApplication.translate("Dialog", u"Standard-Login", None))
#if QT_CONFIG(tooltip)
        self.lineEdit_StdLogin.setToolTip(QCoreApplication.translate("Dialog", u"Benutzername der Pr\u00fcfungskandidaten auf Client PC, sollte student sein", None))
#endif // QT_CONFIG(tooltip)
        self.lineEdit_StdLogin.setText(QCoreApplication.translate("Dialog", u"student", None))
        self.label_9.setText(QCoreApplication.translate("Dialog", u"Online-Wiki", None))
        self.lineEdit_OnlineWiki.setText(QCoreApplication.translate("Dialog", u"https://github.com/greenorca/ECMan/wiki", None))
        self.label_5.setText(QCoreApplication.translate("Dialog", u"WinRM-Port", None))
        self.lineEdit_winRmPort.setText(QCoreApplication.translate("Dialog", u"5986", None))
        self.label_3.setText(QCoreApplication.translate("Dialog", u"WinRM-Login", None))
#if QT_CONFIG(tooltip)
        self.lineEdit_winRmUser.setToolTip(QCoreApplication.translate("Dialog", u"Benutzername f\u00fcr Remotezugriff (wie im Konfigskript f\u00fcr Client-PCs)", None))
#endif // QT_CONFIG(tooltip)
        self.lineEdit_winRmUser.setText(QCoreApplication.translate("Dialog", u"winrm", None))
        self.label_4.setText(QCoreApplication.translate("Dialog", u"WinRM-Passwort", None))
#if QT_CONFIG(tooltip)
        self.lineEdit_winRmPwd.setToolTip(QCoreApplication.translate("Dialog", u"Passwort f\u00fcr Remotezugriff (wie im Konfigskript f\u00fcr Client-PCs)", None))
#endif // QT_CONFIG(tooltip)
        self.lineEdit_winRmPwd.setText("")
#if QT_CONFIG(tooltip)
        self.label_6.setToolTip(QCoreApplication.translate("Dialog", u"Hier Limite f\u00fcr die maximale Dateigr\u00f6sse der L\u00f6sungsdaten setzen.", None))
#endif // QT_CONFIG(tooltip)
        self.label_6.setText(QCoreApplication.translate("Dialog", u"max. Dateigr\u00f6sse (MB)", None))
        self.lineEdit_MaxFileSize.setText(QCoreApplication.translate("Dialog", u"1000", None))
#if QT_CONFIG(tooltip)
        self.label_7.setToolTip(QCoreApplication.translate("Dialog", u"Hier Limite f\u00fcr die maximale Anzahl L\u00f6sungsdateien setzen.", None))
#endif // QT_CONFIG(tooltip)
        self.label_7.setText(QCoreApplication.translate("Dialog", u"max. Dateien", None))
        self.lineEdit_MaxFiles.setText(QCoreApplication.translate("Dialog", u"1000", None))
        self.label_8.setText(QCoreApplication.translate("Dialog", u"versteckte Dateien", None))
#if QT_CONFIG(tooltip)
        self.checkBox_HiddenFiles.setToolTip(QCoreApplication.translate("Dialog", u"versteckte Dateien und Ordner (.*) werden derzeit ignoriert.", None))
#endif // QT_CONFIG(tooltip)
        self.checkBox_HiddenFiles.setText(QCoreApplication.translate("Dialog", u"ignorieren", None))
        self.label_10.setText(QCoreApplication.translate("Dialog", u"Pr\u00fcfungsergebnisse abholen:", None))
        self.label_11.setText(QCoreApplication.translate("Dialog", u"zus\u00e4tzliche Features", None))
        self.checkBox_advancedFeatures.setText(QCoreApplication.translate("Dialog", u"aktivieren", None))
    # retranslateUi

