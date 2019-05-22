# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'ui/Ui_MainWindow2.ui',
# licensing of 'ui/Ui_MainWindow2.ui' applies.
#
# Created: Wed May 22 09:54:42 2019
#      by: pyside2-uic  running on PySide2 5.12.3
#
# WARNING! All changes made in this file will be lost!

from PySide2 import QtCore, QtGui, QtWidgets

class Ui_MainWindow(object):
    def setupUi(self, MainWindow):
        MainWindow.setObjectName("MainWindow")
        MainWindow.resize(795, 587)
        icon = QtGui.QIcon()
        icon.addPixmap(QtGui.QPixmap("../green_orca.png"), QtGui.QIcon.Normal, QtGui.QIcon.Off)
        MainWindow.setWindowIcon(icon)
        self.centralwidget = QtWidgets.QWidget(MainWindow)
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Expanding)
        sizePolicy.setHorizontalStretch(1)
        sizePolicy.setVerticalStretch(1)
        sizePolicy.setHeightForWidth(self.centralwidget.sizePolicy().hasHeightForWidth())
        self.centralwidget.setSizePolicy(sizePolicy)
        self.centralwidget.setObjectName("centralwidget")
        self.gridLayout_2 = QtWidgets.QGridLayout(self.centralwidget)
        self.gridLayout_2.setObjectName("gridLayout_2")
        self.mainLayout = QtWidgets.QVBoxLayout()
        self.mainLayout.setObjectName("mainLayout")
        self.label_2 = QtWidgets.QLabel(self.centralwidget)
        self.label_2.setObjectName("label_2")
        self.mainLayout.addWidget(self.label_2)
        self.detect_select = QtWidgets.QHBoxLayout()
        self.detect_select.setObjectName("detect_select")
        self.label = QtWidgets.QLabel(self.centralwidget)
        self.label.setObjectName("label")
        self.detect_select.addWidget(self.label)
        self.lineEditIpRange = QtWidgets.QLineEdit(self.centralwidget)
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Minimum, QtWidgets.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.lineEditIpRange.sizePolicy().hasHeightForWidth())
        self.lineEditIpRange.setSizePolicy(sizePolicy)
        self.lineEditIpRange.setObjectName("lineEditIpRange")
        self.detect_select.addWidget(self.lineEditIpRange)
        self.btnDetectClient = QtWidgets.QPushButton(self.centralwidget)
        self.btnDetectClient.setObjectName("btnDetectClient")
        self.detect_select.addWidget(self.btnDetectClient)
        self.horizontalLayout_2 = QtWidgets.QHBoxLayout()
        self.horizontalLayout_2.setObjectName("horizontalLayout_2")
        self.progressBar = QtWidgets.QProgressBar(self.centralwidget)
        self.progressBar.setEnabled(False)
        self.progressBar.setProperty("value", 0)
        self.progressBar.setObjectName("progressBar")
        self.horizontalLayout_2.addWidget(self.progressBar)
        self.detect_select.addLayout(self.horizontalLayout_2)
        self.mainLayout.addLayout(self.detect_select)
        self.line = QtWidgets.QFrame(self.centralwidget)
        self.line.setFrameShape(QtWidgets.QFrame.HLine)
        self.line.setFrameShadow(QtWidgets.QFrame.Sunken)
        self.line.setObjectName("line")
        self.mainLayout.addWidget(self.line)
        self.label_3 = QtWidgets.QLabel(self.centralwidget)
        self.label_3.setObjectName("label_3")
        self.mainLayout.addWidget(self.label_3)
        self.naming_select = QtWidgets.QHBoxLayout()
        self.naming_select.setObjectName("naming_select")
        self.btnNameClients = QtWidgets.QPushButton(self.centralwidget)
        self.btnNameClients.setEnabled(False)
        self.btnNameClients.setObjectName("btnNameClients")
        self.naming_select.addWidget(self.btnNameClients)
        self.btnSelectAllClients = QtWidgets.QPushButton(self.centralwidget)
        self.btnSelectAllClients.setEnabled(False)
        self.btnSelectAllClients.setStyleSheet("text-align:center")
        self.btnSelectAllClients.setObjectName("btnSelectAllClients")
        self.naming_select.addWidget(self.btnSelectAllClients)
        self.btnUnselectClients = QtWidgets.QPushButton(self.centralwidget)
        self.btnUnselectClients.setEnabled(False)
        self.btnUnselectClients.setObjectName("btnUnselectClients")
        self.naming_select.addWidget(self.btnUnselectClients)
        spacerItem = QtWidgets.QSpacerItem(40, 20, QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Minimum)
        self.naming_select.addItem(spacerItem)
        self.mainLayout.addLayout(self.naming_select)
        self.line_2 = QtWidgets.QFrame(self.centralwidget)
        self.line_2.setFrameShape(QtWidgets.QFrame.HLine)
        self.line_2.setFrameShadow(QtWidgets.QFrame.Sunken)
        self.line_2.setObjectName("line_2")
        self.mainLayout.addWidget(self.line_2)
        self.horizontalLayout_4 = QtWidgets.QHBoxLayout()
        self.horizontalLayout_4.setObjectName("horizontalLayout_4")
        self.label_4 = QtWidgets.QLabel(self.centralwidget)
        self.label_4.setObjectName("label_4")
        self.horizontalLayout_4.addWidget(self.label_4)
        self.lblExamName = QtWidgets.QLabel(self.centralwidget)
        self.lblExamName.setText("")
        self.lblExamName.setObjectName("lblExamName")
        self.horizontalLayout_4.addWidget(self.lblExamName)
        spacerItem1 = QtWidgets.QSpacerItem(40, 20, QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Minimum)
        self.horizontalLayout_4.addItem(spacerItem1)
        self.mainLayout.addLayout(self.horizontalLayout_4)
        self.choose_deploy = QtWidgets.QHBoxLayout()
        self.choose_deploy.setObjectName("choose_deploy")
        self.btnSelectExam = QtWidgets.QPushButton(self.centralwidget)
        self.btnSelectExam.setEnabled(True)
        self.btnSelectExam.setObjectName("btnSelectExam")
        self.choose_deploy.addWidget(self.btnSelectExam)
        self.checkBoxWipeHomedir = QtWidgets.QCheckBox(self.centralwidget)
        self.checkBoxWipeHomedir.setToolTip("")
        self.checkBoxWipeHomedir.setChecked(True)
        self.checkBoxWipeHomedir.setObjectName("checkBoxWipeHomedir")
        self.choose_deploy.addWidget(self.checkBoxWipeHomedir)
        self.btnPrepareExam = QtWidgets.QPushButton(self.centralwidget)
        self.btnPrepareExam.setEnabled(False)
        self.btnPrepareExam.setAutoFillBackground(False)
        self.btnPrepareExam.setObjectName("btnPrepareExam")
        self.choose_deploy.addWidget(self.btnPrepareExam)
        self.btnBlockUsb = QtWidgets.QPushButton(self.centralwidget)
        self.btnBlockUsb.setChecked(False)
        self.btnBlockUsb.setObjectName("btnBlockUsb")
        self.choose_deploy.addWidget(self.btnBlockUsb)
        self.btnBlockWebAccess = QtWidgets.QPushButton(self.centralwidget)
        self.btnBlockWebAccess.setChecked(False)
        self.btnBlockWebAccess.setObjectName("btnBlockWebAccess")
        self.choose_deploy.addWidget(self.btnBlockWebAccess)
        self.mainLayout.addLayout(self.choose_deploy)
        self.gridLayout_2.addLayout(self.mainLayout, 0, 0, 1, 1)
        self.label_5 = QtWidgets.QLabel(self.centralwidget)
        self.label_5.setObjectName("label_5")
        self.gridLayout_2.addWidget(self.label_5, 2, 0, 1, 1)
        self.tabs = QtWidgets.QTabWidget(self.centralwidget)
        self.tabs.setObjectName("tabs")
        self.tab_pcs = QtWidgets.QWidget()
        self.tab_pcs.setObjectName("tab_pcs")
        self.verticalLayout = QtWidgets.QVBoxLayout(self.tab_pcs)
        self.verticalLayout.setObjectName("verticalLayout")
        self.frame = QtWidgets.QFrame(self.tab_pcs)
        self.frame.setFrameShape(QtWidgets.QFrame.NoFrame)
        self.frame.setFrameShadow(QtWidgets.QFrame.Plain)
        self.frame.setLineWidth(0)
        self.frame.setObjectName("frame")
        self.horizontalLayout = QtWidgets.QHBoxLayout(self.frame)
        self.horizontalLayout.setSpacing(4)
        self.horizontalLayout.setContentsMargins(10, 0, 10, 0)
        self.horizontalLayout.setObjectName("horizontalLayout")
        self.verticalLayout.addWidget(self.frame)
        self.clientFrame = QtWidgets.QFrame(self.tab_pcs)
        self.clientFrame.setFrameShape(QtWidgets.QFrame.NoFrame)
        self.clientFrame.setFrameShadow(QtWidgets.QFrame.Raised)
        self.clientFrame.setLineWidth(0)
        self.clientFrame.setObjectName("clientFrame")
        self.verticalLayout.addWidget(self.clientFrame)
        spacerItem2 = QtWidgets.QSpacerItem(20, 40, QtWidgets.QSizePolicy.Minimum, QtWidgets.QSizePolicy.Expanding)
        self.verticalLayout.addItem(spacerItem2)
        self.horizontalFrame = QtWidgets.QFrame(self.tab_pcs)
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Minimum)
        sizePolicy.setHorizontalStretch(1)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.horizontalFrame.sizePolicy().hasHeightForWidth())
        self.horizontalFrame.setSizePolicy(sizePolicy)
        self.horizontalFrame.setObjectName("horizontalFrame")
        self._2 = QtWidgets.QGridLayout(self.horizontalFrame)
        self._2.setSizeConstraint(QtWidgets.QLayout.SetNoConstraint)
        self._2.setContentsMargins(-1, 0, -1, -1)
        self._2.setObjectName("_2")
        spacerItem3 = QtWidgets.QSpacerItem(40, 20, QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Minimum)
        self._2.addItem(spacerItem3, 0, 0, 1, 1)
        self._2.setColumnStretch(0, 1)
        self.verticalLayout.addWidget(self.horizontalFrame)
        self.tabs.addTab(self.tab_pcs, "")
        self.tab_candidates = QtWidgets.QWidget()
        self.tab_candidates.setObjectName("tab_candidates")
        self.gridLayout = QtWidgets.QGridLayout(self.tab_candidates)
        self.gridLayout.setObjectName("gridLayout")
        self.btnApplyCandidateNames = QtWidgets.QPushButton(self.tab_candidates)
        self.btnApplyCandidateNames.setObjectName("btnApplyCandidateNames")
        self.gridLayout.addWidget(self.btnApplyCandidateNames, 1, 0, 1, 1)
        self.checkBox_OverwriteExisitingNames = QtWidgets.QCheckBox(self.tab_candidates)
        self.checkBox_OverwriteExisitingNames.setObjectName("checkBox_OverwriteExisitingNames")
        self.gridLayout.addWidget(self.checkBox_OverwriteExisitingNames, 1, 1, 1, 1)
        self.textEditCandidates = QtWidgets.QTextEdit(self.tab_candidates)
        self.textEditCandidates.setAcceptRichText(False)
        self.textEditCandidates.setObjectName("textEditCandidates")
        self.gridLayout.addWidget(self.textEditCandidates, 0, 0, 1, 2)
        self.tabs.addTab(self.tab_candidates, "")
        self.tab_log = QtWidgets.QWidget()
        self.tab_log.setObjectName("tab_log")
        self.gridLayout_3 = QtWidgets.QGridLayout(self.tab_log)
        self.gridLayout_3.setObjectName("gridLayout_3")
        self.textEditLog = QtWidgets.QTextEdit(self.tab_log)
        self.textEditLog.setObjectName("textEditLog")
        self.gridLayout_3.addWidget(self.textEditLog, 0, 0, 1, 1)
        self.tabs.addTab(self.tab_log, "")
        self.gridLayout_2.addWidget(self.tabs, 5, 0, 1, 1)
        self.retrieve = QtWidgets.QHBoxLayout()
        self.retrieve.setObjectName("retrieve")
        self.btnGetExams = QtWidgets.QPushButton(self.centralwidget)
        self.btnGetExams.setEnabled(False)
        self.btnGetExams.setObjectName("btnGetExams")
        self.retrieve.addWidget(self.btnGetExams)
        self.btnSaveExamLog = QtWidgets.QPushButton(self.centralwidget)
        self.btnSaveExamLog.setEnabled(False)
        self.btnSaveExamLog.setObjectName("btnSaveExamLog")
        self.retrieve.addWidget(self.btnSaveExamLog)
        spacerItem4 = QtWidgets.QSpacerItem(40, 20, QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Minimum)
        self.retrieve.addItem(spacerItem4)
        self.gridLayout_2.addLayout(self.retrieve, 3, 0, 1, 1)
        self.line_3 = QtWidgets.QFrame(self.centralwidget)
        self.line_3.setFrameShape(QtWidgets.QFrame.HLine)
        self.line_3.setFrameShadow(QtWidgets.QFrame.Sunken)
        self.line_3.setObjectName("line_3")
        self.gridLayout_2.addWidget(self.line_3, 1, 0, 1, 1)
        MainWindow.setCentralWidget(self.centralwidget)
        self.menubar = QtWidgets.QMenuBar(MainWindow)
        self.menubar.setGeometry(QtCore.QRect(0, 0, 795, 23))
        self.menubar.setObjectName("menubar")
        self.menuKonfiguration = QtWidgets.QMenu(self.menubar)
        self.menuKonfiguration.setObjectName("menuKonfiguration")
        self.menuBatch_Operationen = QtWidgets.QMenu(self.menubar)
        self.menuBatch_Operationen.setObjectName("menuBatch_Operationen")
        self.menuHilfe = QtWidgets.QMenu(self.menubar)
        self.menuHilfe.setObjectName("menuHilfe")
        MainWindow.setMenuBar(self.menubar)
        self.statusbar = QtWidgets.QStatusBar(MainWindow)
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Minimum, QtWidgets.QSizePolicy.Minimum)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.statusbar.sizePolicy().hasHeightForWidth())
        self.statusbar.setSizePolicy(sizePolicy)
        self.statusbar.setMinimumSize(QtCore.QSize(100, 20))
        self.statusbar.setObjectName("statusbar")
        MainWindow.setStatusBar(self.statusbar)
        self.actionBearbeiten = QtWidgets.QAction(MainWindow)
        self.actionBearbeiten.setObjectName("actionBearbeiten")
        self.actionAlle_Clients_zur_cksetzen = QtWidgets.QAction(MainWindow)
        self.actionAlle_Clients_zur_cksetzen.setObjectName("actionAlle_Clients_zur_cksetzen")
        self.actionAlle_Clients_deaktivieren = QtWidgets.QAction(MainWindow)
        self.actionAlle_Clients_deaktivieren.setObjectName("actionAlle_Clients_deaktivieren")
        self.actionAlle_Clients_rebooten = QtWidgets.QAction(MainWindow)
        self.actionAlle_Clients_rebooten.setObjectName("actionAlle_Clients_rebooten")
        self.actionAlle_Clients_herunterfahren = QtWidgets.QAction(MainWindow)
        self.actionAlle_Clients_herunterfahren.setObjectName("actionAlle_Clients_herunterfahren")
        self.actionAlle_Benutzer_benachrichtigen = QtWidgets.QAction(MainWindow)
        self.actionAlle_Benutzer_benachrichtigen.setObjectName("actionAlle_Benutzer_benachrichtigen")
        self.actionOnlineHelp = QtWidgets.QAction(MainWindow)
        self.actionOnlineHelp.setObjectName("actionOnlineHelp")
        self.actionOfflineHelp = QtWidgets.QAction(MainWindow)
        self.actionOfflineHelp.setObjectName("actionOfflineHelp")
        self.menuKonfiguration.addAction(self.actionBearbeiten)
        self.menuBatch_Operationen.addAction(self.actionAlle_Clients_zur_cksetzen)
        self.menuBatch_Operationen.addAction(self.actionAlle_Clients_rebooten)
        self.menuBatch_Operationen.addAction(self.actionAlle_Clients_herunterfahren)
        self.menuBatch_Operationen.addSeparator()
        self.menuBatch_Operationen.addAction(self.actionAlle_Benutzer_benachrichtigen)
        self.menuHilfe.addAction(self.actionOnlineHelp)
        self.menuHilfe.addAction(self.actionOfflineHelp)
        self.menubar.addAction(self.menuKonfiguration.menuAction())
        self.menubar.addAction(self.menuBatch_Operationen.menuAction())
        self.menubar.addAction(self.menuHilfe.menuAction())

        self.retranslateUi(MainWindow)
        self.tabs.setCurrentIndex(0)
        QtCore.QMetaObject.connectSlotsByName(MainWindow)

    def retranslateUi(self, MainWindow):
        MainWindow.setWindowTitle(QtWidgets.QApplication.translate("MainWindow", "MainWindow", None, -1))
        self.label_2.setText(QtWidgets.QApplication.translate("MainWindow", "1. Erkennen:", None, -1))
        self.label.setText(QtWidgets.QApplication.translate("MainWindow", "IP-Bereich: ", None, -1))
        self.lineEditIpRange.setText(QtWidgets.QApplication.translate("MainWindow", "192.168.0.*", None, -1))
        self.btnDetectClient.setText(QtWidgets.QApplication.translate("MainWindow", "Client-PCs erkennen", None, -1))
        self.label_3.setText(QtWidgets.QApplication.translate("MainWindow", "2. Namen vergeben und PCs auswählen:", None, -1))
        self.btnNameClients.setText(QtWidgets.QApplication.translate("MainWindow", "Namen zuweisen", None, -1))
        self.btnSelectAllClients.setText(QtWidgets.QApplication.translate("MainWindow", "Alle Client-PCs auswählen", None, -1))
        self.btnUnselectClients.setText(QtWidgets.QApplication.translate("MainWindow", "Alle Client-PCs abwählen", None, -1))
        self.label_4.setText(QtWidgets.QApplication.translate("MainWindow", "3. Prüfung auswählen und einspielen:", None, -1))
        self.btnSelectExam.setText(QtWidgets.QApplication.translate("MainWindow", "Prüfung auswählen", None, -1))
        self.checkBoxWipeHomedir.setText(QtWidgets.QApplication.translate("MainWindow", "HOME-Verzeichnis leeren", None, -1))
        self.btnPrepareExam.setToolTip(QtWidgets.QApplication.translate("MainWindow", "Achtung: bereits vorhandene Daten werden überschrieben", None, -1))
        self.btnPrepareExam.setText(QtWidgets.QApplication.translate("MainWindow", "Prüfung einspielen", None, -1))
        self.btnBlockUsb.setText(QtWidgets.QApplication.translate("MainWindow", "USB blockieren", None, -1))
        self.btnBlockWebAccess.setText(QtWidgets.QApplication.translate("MainWindow", "Web blockieren", None, -1))
        self.label_5.setText(QtWidgets.QApplication.translate("MainWindow", "4. Prüfungsergebnisse abholen:", None, -1))
        self.tabs.setTabText(self.tabs.indexOf(self.tab_pcs), QtWidgets.QApplication.translate("MainWindow", "Client - PCs", None, -1))
        self.btnApplyCandidateNames.setText(QtWidgets.QApplication.translate("MainWindow", "Kandidatennamen zuweisen", None, -1))
        self.checkBox_OverwriteExisitingNames.setText(QtWidgets.QApplication.translate("MainWindow", "existierende Namen überschreiben", None, -1))
        self.textEditCandidates.setPlaceholderText(QtWidgets.QApplication.translate("MainWindow", "Copy / paste Kandidatennamen aus Excel (pro Zeile ein Name)", None, -1))
        self.tabs.setTabText(self.tabs.indexOf(self.tab_candidates), QtWidgets.QApplication.translate("MainWindow", "Kandidaten", None, -1))
        self.tabs.setTabText(self.tabs.indexOf(self.tab_log), QtWidgets.QApplication.translate("MainWindow", "Log", None, -1))
        self.btnGetExams.setText(QtWidgets.QApplication.translate("MainWindow", "Prüfungsdaten abholen", None, -1))
        self.btnSaveExamLog.setText(QtWidgets.QApplication.translate("MainWindow", "Prüfungslog speichern", None, -1))
        self.menuKonfiguration.setTitle(QtWidgets.QApplication.translate("MainWindow", "&Konfiguration", None, -1))
        self.menuBatch_Operationen.setTitle(QtWidgets.QApplication.translate("MainWindow", "Tools", None, -1))
        self.menuHilfe.setTitle(QtWidgets.QApplication.translate("MainWindow", "Hi&lfe", None, -1))
        self.actionBearbeiten.setText(QtWidgets.QApplication.translate("MainWindow", "&Bearbeiten", None, -1))
        self.actionAlle_Clients_zur_cksetzen.setText(QtWidgets.QApplication.translate("MainWindow", "&Alle Clients zurücksetzen", None, -1))
        self.actionAlle_Clients_deaktivieren.setText(QtWidgets.QApplication.translate("MainWindow", "Alle &Clients: Auswahl aufheben", None, -1))
        self.actionAlle_Clients_rebooten.setText(QtWidgets.QApplication.translate("MainWindow", "Alle Clients &rebooten", None, -1))
        self.actionAlle_Clients_herunterfahren.setText(QtWidgets.QApplication.translate("MainWindow", "Alle Clients &herunterfahren", None, -1))
        self.actionAlle_Benutzer_benachrichtigen.setText(QtWidgets.QApplication.translate("MainWindow", "Alle &Benutzer benachrichtigen", None, -1))
        self.actionOnlineHelp.setText(QtWidgets.QApplication.translate("MainWindow", "&Online-Hilfe öffnen", None, -1))
        self.actionOfflineHelp.setText(QtWidgets.QApplication.translate("MainWindow", "Offline-&Hilfe öffnen", None, -1))

