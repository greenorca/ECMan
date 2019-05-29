"""
Created on Feb 22, 2019

@author: sven
"""

from socket import gaierror

from PySide2.QtWidgets import QLabel, QLineEdit, QWizard, QWizardPage, QApplication, \
    QGridLayout

from worker.sharebrowser import ShareBrowser


class EcLoginWizard(QWizard):
    """
    wizard for selection of CIFS/SMB based exam shares based on user specified login credentials and serverName names
    """
    PAGE_LOGON = 1

    def __init__(self, parent=None, username="", servername="", domain=""):
        """
        Constructor
        """
        super(EcLoginWizard, self).__init__(parent)
        self.setWizardStyle(QWizard.ModernStyle)
        self.title = "An Netzwerk anmelden"

        self.setPage(self.PAGE_LOGON, LoginPage(self, username, servername, domain))
        self.setWindowTitle("ECMan - {}".format(self.title))
        self.resize(450, 350)
        self.server = None
        self.defaultShare = None


class LoginPage(QWizardPage):

    def __init__(self, parent, username="", servername="", domain=""):
        super(LoginPage, self).__init__(parent)
        self.setTitle("Server Authentifizierung")

        lblUsername = QLabel("Netzwerk - Benutzername")
        editUsername = QLineEdit(username)
        self.registerField("username", editUsername)
        lblUsername.setBuddy(editUsername)

        lblDomainName = QLabel("Domäne")
        editDomainName = QLineEdit(domain)
        self.registerField("domainname", editDomainName)
        lblDomainName.setBuddy(editDomainName)

        lblPasswort = QLabel("Passwort")
        editPasswort = QLineEdit()
        editPasswort.setEchoMode(QLineEdit.Password)
        self.registerField("password*", editPasswort)
        lblPasswort.setBuddy(editPasswort)

        lblServerName = QLabel("Servername")
        editServerName = QLineEdit(servername)
        self.registerField("servername", editServerName)
        lblServerName.setBuddy(editServerName)

        layout = QGridLayout()
        layout.addWidget(lblUsername)
        layout.addWidget(editUsername)
        layout.addWidget(lblDomainName)
        layout.addWidget(editDomainName)
        layout.addWidget(lblPasswort)
        layout.addWidget(editPasswort)
        layout.addWidget(lblServerName)
        layout.addWidget(editServerName)

        self.setLayout(layout)

    def validatePage(self):
        """
        only proceed to next wizard page if given credentials and serverName name are valid
        """
        print("validating page")

        serverName = self.wizard().field("servername")

        serverName = serverName.replace("\\", "/")  # get rid of those sick backslashes
        serverName = serverName.replace("//", "")  # remove leading //

        parts = serverName.split("/")
        serverName = parts[0]
        hiddenShareName = parts[1] if len(parts) > 1 else None  # fetch hidden share name  

        server = ShareBrowser(serverName,
                              self.wizard().field("username"),
                              self.wizard().field("password"),
                              self.wizard().field("domainname"))

        try:
            if server.connect() == True:
                self.wizard().server = server
                if hiddenShareName is None:  # in case of regular smb/cifs shares
                    shares = server.getShares()
                    if shares != None and len(shares) > 0:
                        return True
                else:
                    print("connecting to a hidden share")
                    server.defaultShare = hiddenShareName
                    return True
            else:
                raise Exception("logon error")

        except gaierror as ex:
            # we probably want to distinguish beteween logon errors and serverName not found errors,
            # then disable OK button   
            self.setSubTitle("Server nicht gefunden: " + str(ex))
        except Exception as ex:
            self.setSubTitle("Anmeldefehler")
            print(ex)

        return False


if __name__ == '__main__':
    import sys

    app = QApplication(sys.argv)
    wizard = EcLoginWizard(parent=None, username="sven.schirmer@wiss-online.ch",
                           domain="", servername="NSSGSC01/LBV")
    wizard = EcLoginWizard(parent=None, username="sven",
                           domain="HSH", servername="odroid")
    wizard.setModal(True)
    result = wizard.exec_()
    print("I'm done, wizard result=" + str(result))

'''    
    smbclient -k //win-serverName/share$/folder
tree connect failed: NT_STATUS_BAD_NETWORK_NAME

smbclient -k //win-serverName/share$
Try "help" to get a list of possible commands.
smb: \>

So he can only connect if I use the path to the hidden share. I can't directly connect to sub-directories inside the hidden parent share.
        '''
