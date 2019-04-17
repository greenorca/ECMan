from PySide2.QtWidgets import QApplication
from configparser import ConfigParser
from pathlib import Path
from worker.computer import Computer
from ui.ecWiz import EcWizard
import os

'''
terminal based test menu for basic interaction of ECMan Computer class and external client
configuration is grabbed but not stored in $HOME/.ecman.conf 

'''

def printMenu(items):
    for i, x in enumerate(items):
        print(str(i+1)+": "+x)

if __name__=="__main__":
    
    abspath = os.path.abspath(__file__)
    dname = os.path.dirname(abspath)
    print("cd: "+dname)
    os.chdir(dname)
    
    if not(os.path.exists("logs")):
        os.makedirs("logs")
    
    ip = input("Enter IP or hostname: ")
    config = ConfigParser()
    configFile = Path(str(Path.home()) + "/.ecman.conf")
    config.read_file(open(str(configFile)))
        
    lb_server = config.get("General", "lb_server", fallback="")
    port = config.get("General", "winrm_port", fallback=5986)
    client_lb_user = config.get("Client", "lb_user", fallback="student") 
    user = config.get("Client", "user", fallback="")
    lb_user = config.get("Client", "lb_user", fallback="")
    passwd = config.get("Client", "pwd", fallback="")  
    
    compi = Computer(ip, user, passwd, candidateLogin=client_lb_user, fetchHostname=True)
    compi.debug = True
    # compi.createBunchOfStupidFiles()
    # result = compi.checkFileSanity(100, 1000000)
    #print(err)
    #print(result)
    #compi.getRemoteFileListing()
    
    #with open(compi.logfile_name) as log:
    #    print("\n".join(log.readlines()))
    
    tests = ["checkUserConfig", "read_old_state", "deploy_retrieve", 
             "testInternet", "setCandidateName", "testUsbBlocking", "reset"]
        
        
    currentTest="1"
    while (currentTest > "0" and currentTest[0] < "a"): 
        printMenu(tests)
        currentTest = input("Testauswahl?")
        choice = 0
        try: 
            choice = int(currentTest)-1
            
        except Exception as x:
            exit();
                
        if tests[choice] == "checkUserConfig":
            assert(compi.checkStatusFile())
            
        elif tests[choice] == "reset":
            compi.resetClientHomeDirectory()
            compi.resetStatus(resetCandidateName=True)
        
        elif tests[choice] == "read_old_state":
            compi.checkStatusFile()
           
        elif tests[choice] == "testInternet":
            compi.configureFirewallService()
        
            server = "www.mastersong.de"
            print("Online: "+str(compi.testPing(server)))
            compi.blockInternetAccess()
            print("Online: "+str(compi.testPing(server)))
            compi.allowInternetAccess()
            print("Online: "+str(compi.testPing(server)))
            
            print("Testing firewall status")
            status = compi.isFirewallServiceEnabled()
            print("result: "+str(status))
            blocked = False
            compi.sendMessage("Internet is blocked: {}".format(str(blocked)))
            compi.blockInternetAccess(blocked)
            
            
        elif tests[choice] == "testUsbBlocking":
            print("Hopefully blocked now: "+str(compi.isUsbBlocked()))
            compi.disableUsbAccess(False)
            input("Press any key to continue")
            print("Hopefully enabled now: "+str(compi.isUsbBlocked()))    
            input("Press any key to continue")
            
        elif tests[choice] == "setCandidateName":
            candidateName = "Emil Grünschnabel"
            print("set candidate name to: "+candidateName)
            compi.setCandidateName(candidateName)
            print("remote candidate name is: "+compi.getCandidateName())
            print("please check login screen...")
            
        elif tests[choice] == "deploy_retrieve": 
            # thats the local stuff on tuxedo machine
            from time import sleep
            app = QApplication.instance()
            if app is None: 
                app = QApplication([])
            wizard = EcWizard(parent=None, username=lb_user, 
                                  domain=config.get("General","domain", fallback=""), 
                                  servername=lb_server, 
                                  wizardType=EcWizard.TYPE_LB_SELECTION)
           
            wizard.setModal(True)
            result = wizard.exec_()
            print("I'm done, wizard result=" + str(result))
            if result != 1:
                continue
            print("selected values: %s - %s - %s" % 
                  (wizard.field("username"), 
                   wizard.field("servername"), wizard.defaultShare))    
            
            config["General"]["servername"] = wizard.field("servername")
            config["General"]["domain"] = wizard.field("domainname")
            config["General"]["username"] = wizard.field("username")
        
            lb_directory = "//" + wizard.server.serverName + "/" + wizard.defaultShare
            lb_directory = lb_directory.replace("/", "#")
            module = wizard.defaultShare.split("/")[-1]
            print("Selected module: "+module)
            compi.setCandidateName("Emil Grünschnabel")
            retval, msg = compi.deployClientFiles(lb_directory, 
                                                  wizard.field("username"), wizard.field("password"), 
                                                  wizard.field("domainname"), True)
            if retval == False:
                print("Error copying: "+msg)
            assert(compi.state == Computer.State.STATE_DEPLOYED)
            assert(compi.lb_dataDirectory == lb_directory)
            print(compi.getRemoteFileListing())
            print(compi.lb_files) 
            print("now wait a bit...")
            
            wizard = EcWizard(parent=None, username=config.get("General","username", fallback=""), 
                                  domain=config.get("General","domain", fallback=""), 
                                  servername=config.get("General","servername", fallback=""), 
                                  wizardType=EcWizard.TYPE_RESULT_DESTINATION)
           
            wizard.setModal(True)
            result = wizard.exec_()
            print("I'm done, wizard result=" + str(result))
            if result != 1:
                continue
            
            lb_directory = "//" + wizard.server.serverName + "/" + wizard.defaultShare
            lb_directory = lb_directory.replace("/", "#")
            x = compi.retrieveClientFiles(lb_directory, wizard.field("username"), wizard.field("password"), 
                                                  wizard.field("domainname"))
            print(x)
            assert(compi.state == Computer.State.STATE_FINISHED)
            app.quit()    
        else:
            print("Testmethode (noch) nicht vorhanden") 