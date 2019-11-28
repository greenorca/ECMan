import os
from configparser import ConfigParser
from pathlib import Path

from PySide2.QtWidgets import QApplication

from ui.ecLoginWizard import EcLoginWizard
from ui.ecManRemoteTerminal import EcManRemoteTerminal
from ui.ecShareWizard import EcShareWizard
from worker.computer import Computer

'''
terminal based test menu for basic interaction of ECMan Computer class and external client
configuration is grabbed but not stored in $HOME/.ecman.conf 

'''


def printMenu(items):
    for i, x in enumerate(items):
        print(str(i + 1) + ": " + x)


if __name__ == "__main__":

    default_ip = "172.23.24.13"
    abspath = os.path.abspath(__file__)
    dname = os.path.dirname(abspath)
    print("cd: " + dname)
    os.chdir(dname)

    if not (os.path.exists("logs")):
        os.makedirs("logs")

    ip = input("Enter IP or hostname, enter for default : [{}]".format(default_ip))
    if len(ip) == 0:
        ip = default_ip

    config = ConfigParser()
    configFile = Path(str(Path.home()) + "/.ecman.conf")
    config.read_file(open(str(configFile)))

    lb_server = config.get("General", "lb_server", fallback="")
    port = config.get("General", "winrm_port", fallback=5986)
    client_lb_user = config.get("Client", "lb_user", fallback="student")
    user = config.get("Client", "user", fallback="")
    network_user = config.get("General", "username", fallback="")
    passwd = config.get("Client", "pwd", fallback="")

    compi = Computer(ip, user, passwd, candidateLogin=client_lb_user, fetchHostname=True)
    compi.debug = True
    # compi.createBunchOfStupidFiles()
    # result = compi.checkFileSanity(100, 1000000)
    # print(err)
    # print(result)
    # compi.getRemoteFileListing()

    # with open(compi.logfile_name) as log:
    #    print("\n".join(log.readlines()))

    tests = ["open remote shell", "checkUserConfig", "testRemoteFileList" ,"read_old_state", "deploy_retrieve",
             "testInternet", "setCandidateName", "getCandidateName", "testUsbBlocking", "reset"]

    currentTest = "2"
    while (currentTest > "0" and currentTest[0] < "a"):
        printMenu(tests)
        currentTest = input("Testauswahl?")
        choice = 0
        try:
            choice = int(currentTest) - 1

        except Exception as x:
            exit();

        if tests[choice] == "open remote shell":
            app = QApplication.instance()
            if app is None:
                app = QApplication([])
            terminalDialog = EcManRemoteTerminal(parent=None, client=compi)
            terminalDialog.setModal(True)
            result = terminalDialog.exec_()

        elif tests[choice] == "testRemoteFileList":
            x = compi.getRemoteFileListing()
            assert(x)

        elif tests[choice] == "checkUserConfig":
            assert (compi.checkStatusFile())

        elif tests[choice] == "reset":
            compi.resetClientHomeDirectory()
            compi.resetStatus(resetCandidateName=True)

        elif tests[choice] == "read_old_state":
            compi.checkStatusFile()

        elif tests[choice] == "testInternet":
            compi.configureFirewallService()

            server = "www.mastersong.de"
            print("Online: " + str(compi.testPing(server)))
            compi.blockInternetAccess()
            print("Online: " + str(compi.testPing(server)))
            compi.allowInternetAccess()
            print("Online: " + str(compi.testPing(server)))

            print("Testing firewall status")
            status = compi.isFirewallServiceEnabled()
            print("result: " + str(status))
            blocked = False
            compi.sendMessage("Internet is blocked: {}".format(str(blocked)))
            compi.blockInternetAccess(blocked)

        elif tests[choice] == "testUsbBlocking":
            print("Hopefully blocked now: " + str(compi.isUsbBlocked()))
            compi.disableUsbAccess(False)
            input("Press any key to continue")
            print("Hopefully enabled now: " + str(compi.isUsbBlocked()))
            input("Press any key to continue")

        elif tests[choice] == "setCandidateName":
            candidateName = "Emil Grünschnabel"
            print("set candidate name to: " + candidateName)
            compi.setCandidateName(candidateName)
            print("remote candidate name is: " + compi.getCandidateName())
            print("please check login screen...")

        elif tests[choice] == "getCandidateName":
            print("Remote Name: "+str(compi.getCandidateName(True)))
            print("Lokaler Name: "+str(compi.candidateName))

        elif tests[choice] == "deploy_retrieve":
            # thats the local stuff on tuxedo machine

            app = QApplication.instance()
            if app is None:
                app = QApplication([])
            wizard = EcLoginWizard(parent=None, username=network_user,
                                   domain=config.get("General", "domain", fallback=""),
                                   servername=lb_server)

            wizard.setModal(True)
            result = wizard.exec_()
            print("I'm done, wizard result=" + str(result))
            if result != 1:
                continue

            server = wizard.server

            print("selected values: %s - %s " %
                  (wizard.field("username"),
                   wizard.field("servername")))

            wiz2 = EcShareWizard(parent=None, server=server,
                                 wizardType=EcShareWizard.TYPE_LB_SELECTION)
            wiz2.setModal(True)
            result = wiz2.exec_()
            print("I'm done, wizard result=" + str(result))
            if result != 1:
                continue

            lb_directory = wiz2.selectedPath
            module = lb_directory.split("/")[-1]
            print("Selected module: " + module)
            compi.setCandidateName("Emil Grünschnabel")
            retval, msg = compi.deployClientFiles(lb_directory,
                                                  server.user, server.password, server.domain)

            if retval == False:
                print("Error copying: " + msg)
            assert (compi.state == Computer.State.STATE_DEPLOYED)
            assert (compi.lb_dataDirectory == lb_directory.split("/")[-1])
            print(compi.getRemoteFileListing())
            print(compi.lb_files)
            print("now wait a bit...")

            if server == None or server.connect() == False:
                wizard = EcLoginWizard(parent=None, username=network_user,
                                       domain=config.get("General", "domain", fallback=""),
                                       servername=lb_server)

                wizard.setModal(True)
                result = wizard.exec_()
                print("I'm done, wizard result=" + str(result))
                if result != 1:
                    continue

                server = wizard.server

            wizard = EcShareWizard(parent=None, server=server,
                                   wizardType=EcShareWizard.TYPE_RESULT_DESTINATION)
            wizard.setModal(True)
            result = wizard.exec_()
            print("I'm done, wizard result=" + str(result))
            if result != 1:
                continue

            lb_directory = wizard.selectedPath
            x = compi.retrieveClientFiles(lb_directory,
                                          server.user, server.password, server.domain)
            print(x)
            assert (compi.state == Computer.State.STATE_FINISHED)
            app.quit()
        else:
            print("Testmethode (noch) nicht vorhanden")
