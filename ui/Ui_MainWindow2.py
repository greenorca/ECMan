# -*- coding: utf-8 -*-

################################################################################
## Form generated from reading UI file 'Ui_MainWindow2.ui'
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


class Ui_MainWindow(object):
    def setupUi(self, MainWindow):
        if MainWindow.objectName():
            MainWindow.setObjectName(u"MainWindow")
        MainWindow.resize(795, 587)
        icon = QIcon()
        icon.addFile(u"../green_orca.png", QSize(), QIcon.Normal, QIcon.Off)
        MainWindow.setWindowIcon(icon)
        self.actionBearbeiten = QAction(MainWindow)
        self.actionBearbeiten.setObjectName(u"actionBearbeiten")
        self.actionAlle_Clients_zur_cksetzen = QAction(MainWindow)
        self.actionAlle_Clients_zur_cksetzen.setObjectName(u"actionAlle_Clients_zur_cksetzen")
        self.actionAlle_Clients_deaktivieren = QAction(MainWindow)
        self.actionAlle_Clients_deaktivieren.setObjectName(u"actionAlle_Clients_deaktivieren")
        self.actionAlle_Clients_rebooten = QAction(MainWindow)
        self.actionAlle_Clients_rebooten.setObjectName(u"actionAlle_Clients_rebooten")
        self.actionAlle_Clients_herunterfahren = QAction(MainWindow)
        self.actionAlle_Clients_herunterfahren.setObjectName(u"actionAlle_Clients_herunterfahren")
        self.actionAlle_Benutzer_benachrichtigen = QAction(MainWindow)
        self.actionAlle_Benutzer_benachrichtigen.setObjectName(u"actionAlle_Benutzer_benachrichtigen")
        self.actionOnlineHelp = QAction(MainWindow)
        self.actionOnlineHelp.setObjectName(u"actionOnlineHelp")
        self.actionOfflineHelp = QAction(MainWindow)
        self.actionOfflineHelp.setObjectName(u"actionOfflineHelp")
        self.actionSortClientByCandidateName = QAction(MainWindow)
        self.actionSortClientByCandidateName.setObjectName(u"actionSortClientByCandidateName")
        self.actionSortClientByComputerName = QAction(MainWindow)
        self.actionSortClientByComputerName.setObjectName(u"actionSortClientByComputerName")
        self.actionVersionInfo = QAction(MainWindow)
        self.actionVersionInfo.setObjectName(u"actionVersionInfo")
        self.actionDisplayIPs = QAction(MainWindow)
        self.actionDisplayIPs.setObjectName(u"actionDisplayIPs")
        self.centralwidget = QWidget(MainWindow)
        self.centralwidget.setObjectName(u"centralwidget")
        sizePolicy = QSizePolicy(QSizePolicy.Expanding, QSizePolicy.Expanding)
        sizePolicy.setHorizontalStretch(1)
        sizePolicy.setVerticalStretch(1)
        sizePolicy.setHeightForWidth(self.centralwidget.sizePolicy().hasHeightForWidth())
        self.centralwidget.setSizePolicy(sizePolicy)
        self.gridLayout_2 = QGridLayout(self.centralwidget)
        self.gridLayout_2.setObjectName(u"gridLayout_2")
        self.mainLayout = QVBoxLayout()
        self.mainLayout.setObjectName(u"mainLayout")
        self.label_2 = QLabel(self.centralwidget)
        self.label_2.setObjectName(u"label_2")

        self.mainLayout.addWidget(self.label_2)

        self.detect_select = QHBoxLayout()
        self.detect_select.setObjectName(u"detect_select")
        self.label = QLabel(self.centralwidget)
        self.label.setObjectName(u"label")

        self.detect_select.addWidget(self.label)

        self.lineEditIpRange = QLineEdit(self.centralwidget)
        self.lineEditIpRange.setObjectName(u"lineEditIpRange")
        sizePolicy1 = QSizePolicy(QSizePolicy.Minimum, QSizePolicy.Fixed)
        sizePolicy1.setHorizontalStretch(0)
        sizePolicy1.setVerticalStretch(0)
        sizePolicy1.setHeightForWidth(self.lineEditIpRange.sizePolicy().hasHeightForWidth())
        self.lineEditIpRange.setSizePolicy(sizePolicy1)

        self.detect_select.addWidget(self.lineEditIpRange)

        self.btnDetectClient = QPushButton(self.centralwidget)
        self.btnDetectClient.setObjectName(u"btnDetectClient")

        self.detect_select.addWidget(self.btnDetectClient)

        self.horizontalLayout_2 = QHBoxLayout()
        self.horizontalLayout_2.setObjectName(u"horizontalLayout_2")
        self.progressBar = QProgressBar(self.centralwidget)
        self.progressBar.setObjectName(u"progressBar")
        self.progressBar.setEnabled(False)
        self.progressBar.setValue(0)

        self.horizontalLayout_2.addWidget(self.progressBar)


        self.detect_select.addLayout(self.horizontalLayout_2)


        self.mainLayout.addLayout(self.detect_select)

        self.line = QFrame(self.centralwidget)
        self.line.setObjectName(u"line")
        self.line.setFrameShape(QFrame.HLine)
        self.line.setFrameShadow(QFrame.Sunken)

        self.mainLayout.addWidget(self.line)

        self.label_3 = QLabel(self.centralwidget)
        self.label_3.setObjectName(u"label_3")

        self.mainLayout.addWidget(self.label_3)

        self.naming_select = QHBoxLayout()
        self.naming_select.setObjectName(u"naming_select")
        self.btnNameClients = QPushButton(self.centralwidget)
        self.btnNameClients.setObjectName(u"btnNameClients")
        self.btnNameClients.setEnabled(False)

        self.naming_select.addWidget(self.btnNameClients)

        self.btnSelectAllClients = QPushButton(self.centralwidget)
        self.btnSelectAllClients.setObjectName(u"btnSelectAllClients")
        self.btnSelectAllClients.setEnabled(False)
        self.btnSelectAllClients.setStyleSheet(u"text-align:center")

        self.naming_select.addWidget(self.btnSelectAllClients)

        self.btnUnselectClients = QPushButton(self.centralwidget)
        self.btnUnselectClients.setObjectName(u"btnUnselectClients")
        self.btnUnselectClients.setEnabled(False)

        self.naming_select.addWidget(self.btnUnselectClients)

        self.horizontalSpacer_3 = QSpacerItem(40, 20, QSizePolicy.Expanding, QSizePolicy.Minimum)

        self.naming_select.addItem(self.horizontalSpacer_3)


        self.mainLayout.addLayout(self.naming_select)

        self.line_2 = QFrame(self.centralwidget)
        self.line_2.setObjectName(u"line_2")
        self.line_2.setFrameShape(QFrame.HLine)
        self.line_2.setFrameShadow(QFrame.Sunken)

        self.mainLayout.addWidget(self.line_2)

        self.horizontalLayout_4 = QHBoxLayout()
        self.horizontalLayout_4.setObjectName(u"horizontalLayout_4")
        self.label_4 = QLabel(self.centralwidget)
        self.label_4.setObjectName(u"label_4")

        self.horizontalLayout_4.addWidget(self.label_4)

        self.lblExamName = QLabel(self.centralwidget)
        self.lblExamName.setObjectName(u"lblExamName")

        self.horizontalLayout_4.addWidget(self.lblExamName)

        self.horizontalSpacer_4 = QSpacerItem(40, 20, QSizePolicy.Expanding, QSizePolicy.Minimum)

        self.horizontalLayout_4.addItem(self.horizontalSpacer_4)


        self.mainLayout.addLayout(self.horizontalLayout_4)

        self.choose_deploy = QHBoxLayout()
        self.choose_deploy.setObjectName(u"choose_deploy")
        self.btnSelectExam = QPushButton(self.centralwidget)
        self.btnSelectExam.setObjectName(u"btnSelectExam")
        self.btnSelectExam.setEnabled(True)

        self.choose_deploy.addWidget(self.btnSelectExam)

        self.checkBoxWipeHomedir = QCheckBox(self.centralwidget)
        self.checkBoxWipeHomedir.setObjectName(u"checkBoxWipeHomedir")
        self.checkBoxWipeHomedir.setChecked(True)

        self.choose_deploy.addWidget(self.checkBoxWipeHomedir)

        self.btnPrepareExam = QPushButton(self.centralwidget)
        self.btnPrepareExam.setObjectName(u"btnPrepareExam")
        self.btnPrepareExam.setEnabled(False)
        self.btnPrepareExam.setAutoFillBackground(False)

        self.choose_deploy.addWidget(self.btnPrepareExam)

        self.btnBlockUsb = QPushButton(self.centralwidget)
        self.btnBlockUsb.setObjectName(u"btnBlockUsb")
        self.btnBlockUsb.setChecked(False)

        self.choose_deploy.addWidget(self.btnBlockUsb)

        self.btnBlockWebAccess = QPushButton(self.centralwidget)
        self.btnBlockWebAccess.setObjectName(u"btnBlockWebAccess")
        self.btnBlockWebAccess.setChecked(False)

        self.choose_deploy.addWidget(self.btnBlockWebAccess)


        self.mainLayout.addLayout(self.choose_deploy)


        self.gridLayout_2.addLayout(self.mainLayout, 0, 0, 1, 1)

        self.label_5 = QLabel(self.centralwidget)
        self.label_5.setObjectName(u"label_5")

        self.gridLayout_2.addWidget(self.label_5, 2, 0, 1, 1)

        self.tabs = QTabWidget(self.centralwidget)
        self.tabs.setObjectName(u"tabs")
        self.tab_pcs = QWidget()
        self.tab_pcs.setObjectName(u"tab_pcs")
        self.verticalLayout = QVBoxLayout(self.tab_pcs)
        self.verticalLayout.setObjectName(u"verticalLayout")
        self.frame = QFrame(self.tab_pcs)
        self.frame.setObjectName(u"frame")
        self.frame.setFrameShape(QFrame.NoFrame)
        self.frame.setFrameShadow(QFrame.Plain)
        self.frame.setLineWidth(0)
        self.horizontalLayout = QHBoxLayout(self.frame)
        self.horizontalLayout.setSpacing(4)
        self.horizontalLayout.setObjectName(u"horizontalLayout")
        self.horizontalLayout.setContentsMargins(10, 0, 10, 0)

        self.verticalLayout.addWidget(self.frame)

        self.clientFrame = QFrame(self.tab_pcs)
        self.clientFrame.setObjectName(u"clientFrame")
        self.clientFrame.setFrameShape(QFrame.NoFrame)
        self.clientFrame.setFrameShadow(QFrame.Raised)
        self.clientFrame.setLineWidth(0)

        self.verticalLayout.addWidget(self.clientFrame)

        self.verticalSpacer_2 = QSpacerItem(20, 40, QSizePolicy.Minimum, QSizePolicy.Expanding)

        self.verticalLayout.addItem(self.verticalSpacer_2)

        self.horizontalFrame = QFrame(self.tab_pcs)
        self.horizontalFrame.setObjectName(u"horizontalFrame")
        sizePolicy2 = QSizePolicy(QSizePolicy.Expanding, QSizePolicy.Minimum)
        sizePolicy2.setHorizontalStretch(1)
        sizePolicy2.setVerticalStretch(0)
        sizePolicy2.setHeightForWidth(self.horizontalFrame.sizePolicy().hasHeightForWidth())
        self.horizontalFrame.setSizePolicy(sizePolicy2)
        self._2 = QGridLayout(self.horizontalFrame)
        self._2.setObjectName(u"_2")
        self._2.setSizeConstraint(QLayout.SetNoConstraint)
        self._2.setContentsMargins(-1, 0, -1, -1)
        self.horizontalSpacer = QSpacerItem(40, 20, QSizePolicy.Expanding, QSizePolicy.Minimum)

        self._2.addItem(self.horizontalSpacer, 0, 0, 1, 1)

        self._2.setColumnStretch(0, 1)

        self.verticalLayout.addWidget(self.horizontalFrame)

        self.tabs.addTab(self.tab_pcs, "")
        self.tab_candidates = QWidget()
        self.tab_candidates.setObjectName(u"tab_candidates")
        self.gridLayout = QGridLayout(self.tab_candidates)
        self.gridLayout.setObjectName(u"gridLayout")
        self.btnApplyCandidateNames = QPushButton(self.tab_candidates)
        self.btnApplyCandidateNames.setObjectName(u"btnApplyCandidateNames")

        self.gridLayout.addWidget(self.btnApplyCandidateNames, 1, 0, 1, 1)

        self.checkBox_OverwriteExisitingNames = QCheckBox(self.tab_candidates)
        self.checkBox_OverwriteExisitingNames.setObjectName(u"checkBox_OverwriteExisitingNames")

        self.gridLayout.addWidget(self.checkBox_OverwriteExisitingNames, 1, 1, 1, 1)

        self.textEditCandidates = QTextEdit(self.tab_candidates)
        self.textEditCandidates.setObjectName(u"textEditCandidates")
        self.textEditCandidates.setAcceptRichText(False)

        self.gridLayout.addWidget(self.textEditCandidates, 0, 0, 1, 2)

        self.tabs.addTab(self.tab_candidates, "")
        self.tab_log = QWidget()
        self.tab_log.setObjectName(u"tab_log")
        self.gridLayout_3 = QGridLayout(self.tab_log)
        self.gridLayout_3.setObjectName(u"gridLayout_3")
        self.textEditLog = QTextEdit(self.tab_log)
        self.textEditLog.setObjectName(u"textEditLog")

        self.gridLayout_3.addWidget(self.textEditLog, 0, 0, 1, 1)

        self.tabs.addTab(self.tab_log, "")

        self.gridLayout_2.addWidget(self.tabs, 5, 0, 1, 1)

        self.retrieve = QHBoxLayout()
        self.retrieve.setObjectName(u"retrieve")
        self.btnGetExams = QPushButton(self.centralwidget)
        self.btnGetExams.setObjectName(u"btnGetExams")
        self.btnGetExams.setEnabled(False)

        self.retrieve.addWidget(self.btnGetExams)

        self.btnSaveExamLog = QPushButton(self.centralwidget)
        self.btnSaveExamLog.setObjectName(u"btnSaveExamLog")
        self.btnSaveExamLog.setEnabled(False)

        self.retrieve.addWidget(self.btnSaveExamLog)

        self.horizontalSpacer_2 = QSpacerItem(40, 20, QSizePolicy.Expanding, QSizePolicy.Minimum)

        self.retrieve.addItem(self.horizontalSpacer_2)


        self.gridLayout_2.addLayout(self.retrieve, 3, 0, 1, 1)

        self.line_3 = QFrame(self.centralwidget)
        self.line_3.setObjectName(u"line_3")
        self.line_3.setFrameShape(QFrame.HLine)
        self.line_3.setFrameShadow(QFrame.Sunken)

        self.gridLayout_2.addWidget(self.line_3, 1, 0, 1, 1)

        MainWindow.setCentralWidget(self.centralwidget)
        self.menubar = QMenuBar(MainWindow)
        self.menubar.setObjectName(u"menubar")
        self.menubar.setGeometry(QRect(0, 0, 795, 22))
        self.menuKonfiguration = QMenu(self.menubar)
        self.menuKonfiguration.setObjectName(u"menuKonfiguration")
        self.menuBatch_Operationen = QMenu(self.menubar)
        self.menuBatch_Operationen.setObjectName(u"menuBatch_Operationen")
        self.menuHilfe = QMenu(self.menubar)
        self.menuHilfe.setObjectName(u"menuHilfe")
        self.menuAnsicht = QMenu(self.menubar)
        self.menuAnsicht.setObjectName(u"menuAnsicht")
        MainWindow.setMenuBar(self.menubar)
        self.statusbar = QStatusBar(MainWindow)
        self.statusbar.setObjectName(u"statusbar")
        sizePolicy3 = QSizePolicy(QSizePolicy.Minimum, QSizePolicy.Minimum)
        sizePolicy3.setHorizontalStretch(0)
        sizePolicy3.setVerticalStretch(0)
        sizePolicy3.setHeightForWidth(self.statusbar.sizePolicy().hasHeightForWidth())
        self.statusbar.setSizePolicy(sizePolicy3)
        self.statusbar.setMinimumSize(QSize(100, 20))
        MainWindow.setStatusBar(self.statusbar)

        self.menubar.addAction(self.menuKonfiguration.menuAction())
        self.menubar.addAction(self.menuBatch_Operationen.menuAction())
        self.menubar.addAction(self.menuAnsicht.menuAction())
        self.menubar.addAction(self.menuHilfe.menuAction())
        self.menuKonfiguration.addAction(self.actionBearbeiten)
        self.menuBatch_Operationen.addAction(self.actionAlle_Clients_zur_cksetzen)
        self.menuBatch_Operationen.addAction(self.actionAlle_Clients_rebooten)
        self.menuBatch_Operationen.addAction(self.actionAlle_Clients_herunterfahren)
        self.menuBatch_Operationen.addSeparator()
        self.menuBatch_Operationen.addAction(self.actionAlle_Benutzer_benachrichtigen)
        self.menuHilfe.addAction(self.actionOnlineHelp)
        self.menuHilfe.addAction(self.actionOfflineHelp)
        self.menuHilfe.addAction(self.actionVersionInfo)
        self.menuAnsicht.addAction(self.actionSortClientByCandidateName)
        self.menuAnsicht.addAction(self.actionSortClientByComputerName)
        self.menuAnsicht.addAction(self.actionDisplayIPs)

        self.retranslateUi(MainWindow)

        self.tabs.setCurrentIndex(0)


        QMetaObject.connectSlotsByName(MainWindow)
    # setupUi

    def retranslateUi(self, MainWindow):
        MainWindow.setWindowTitle(QCoreApplication.translate("MainWindow", u"MainWindow", None))
        self.actionBearbeiten.setText(QCoreApplication.translate("MainWindow", u"&Bearbeiten", None))
        self.actionAlle_Clients_zur_cksetzen.setText(QCoreApplication.translate("MainWindow", u"&Alle Clients zur\u00fccksetzen", None))
        self.actionAlle_Clients_deaktivieren.setText(QCoreApplication.translate("MainWindow", u"Alle &Clients: Auswahl aufheben", None))
        self.actionAlle_Clients_rebooten.setText(QCoreApplication.translate("MainWindow", u"Alle Clients &rebooten", None))
        self.actionAlle_Clients_herunterfahren.setText(QCoreApplication.translate("MainWindow", u"Alle Clients &herunterfahren", None))
        self.actionAlle_Benutzer_benachrichtigen.setText(QCoreApplication.translate("MainWindow", u"Alle &Benutzer benachrichtigen", None))
        self.actionOnlineHelp.setText(QCoreApplication.translate("MainWindow", u"&Online-Hilfe \u00f6ffnen", None))
        self.actionOfflineHelp.setText(QCoreApplication.translate("MainWindow", u"Offline-&Hilfe \u00f6ffnen", None))
        self.actionSortClientByCandidateName.setText(QCoreApplication.translate("MainWindow", u"Clients nach Kandidatenname sortieren", None))
        self.actionSortClientByComputerName.setText(QCoreApplication.translate("MainWindow", u"Clients nach Rechnername sortieren", None))
        self.actionVersionInfo.setText(QCoreApplication.translate("MainWindow", u"Versionsinfo", None))
        self.actionDisplayIPs.setText(QCoreApplication.translate("MainWindow", u"IP-Adressen anzeigen / verbergen", None))
        self.label_2.setText(QCoreApplication.translate("MainWindow", u"1. Erkennen:", None))
        self.label.setText(QCoreApplication.translate("MainWindow", u"IP-Bereich: ", None))
        self.lineEditIpRange.setText(QCoreApplication.translate("MainWindow", u"192.168.0.*", None))
        self.btnDetectClient.setText(QCoreApplication.translate("MainWindow", u"Client-PCs erkennen", None))
        self.label_3.setText(QCoreApplication.translate("MainWindow", u"2. Namen vergeben und PCs ausw\u00e4hlen:", None))
        self.btnNameClients.setText(QCoreApplication.translate("MainWindow", u"Namen zuweisen", None))
        self.btnSelectAllClients.setText(QCoreApplication.translate("MainWindow", u"Alle Client-PCs ausw\u00e4hlen", None))
        self.btnUnselectClients.setText(QCoreApplication.translate("MainWindow", u"Alle Client-PCs abw\u00e4hlen", None))
        self.label_4.setText(QCoreApplication.translate("MainWindow", u"3. Pr\u00fcfung ausw\u00e4hlen und einspielen:", None))
        self.lblExamName.setText("")
        self.btnSelectExam.setText(QCoreApplication.translate("MainWindow", u"Pr\u00fcfung ausw\u00e4hlen", None))
#if QT_CONFIG(tooltip)
        self.checkBoxWipeHomedir.setToolTip("")
#endif // QT_CONFIG(tooltip)
        self.checkBoxWipeHomedir.setText(QCoreApplication.translate("MainWindow", u"HOME-Verzeichnis leeren", None))
#if QT_CONFIG(tooltip)
        self.btnPrepareExam.setToolTip(QCoreApplication.translate("MainWindow", u"Achtung: bereits vorhandene Daten werden \u00fcberschrieben", None))
#endif // QT_CONFIG(tooltip)
        self.btnPrepareExam.setText(QCoreApplication.translate("MainWindow", u"Pr\u00fcfung einspielen", None))
        self.btnBlockUsb.setText(QCoreApplication.translate("MainWindow", u"USB blockieren", None))
        self.btnBlockWebAccess.setText(QCoreApplication.translate("MainWindow", u"Web blockieren", None))
        self.label_5.setText(QCoreApplication.translate("MainWindow", u"4. Pr\u00fcfungsergebnisse abholen:", None))
        self.tabs.setTabText(self.tabs.indexOf(self.tab_pcs), QCoreApplication.translate("MainWindow", u"Client - PCs", None))
        self.btnApplyCandidateNames.setText(QCoreApplication.translate("MainWindow", u"Kandidatennamen zuweisen", None))
        self.checkBox_OverwriteExisitingNames.setText(QCoreApplication.translate("MainWindow", u"existierende Namen \u00fcberschreiben", None))
        self.textEditCandidates.setPlaceholderText(QCoreApplication.translate("MainWindow", u"Copy / paste Kandidatennamen aus Excel (pro Zeile ein Name)", None))
        self.tabs.setTabText(self.tabs.indexOf(self.tab_candidates), QCoreApplication.translate("MainWindow", u"Kandidaten", None))
        self.tabs.setTabText(self.tabs.indexOf(self.tab_log), QCoreApplication.translate("MainWindow", u"Log", None))
        self.btnGetExams.setText(QCoreApplication.translate("MainWindow", u"Pr\u00fcfungsdaten abholen", None))
        self.btnSaveExamLog.setText(QCoreApplication.translate("MainWindow", u"Pr\u00fcfungslog speichern", None))
        self.menuKonfiguration.setTitle(QCoreApplication.translate("MainWindow", u"&Konfiguration", None))
        self.menuBatch_Operationen.setTitle(QCoreApplication.translate("MainWindow", u"Tools", None))
        self.menuHilfe.setTitle(QCoreApplication.translate("MainWindow", u"Hi&lfe", None))
        self.menuAnsicht.setTitle(QCoreApplication.translate("MainWindow", u"Ansicht", None))
    # retranslateUi

