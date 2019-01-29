import unittest, os
from worker.computer import Computer
import time

ipAddress = "192.168.0.114"
user = "winrm"
passwd = "Remote0815"

targetHostname = "W10ACCL0"
testWebConnectivityHost="www.wiss.ch"

class TestComputer(unittest.TestCase):
    def setUp(self):
        self.compi = Computer(ipAddress, user, passwd, False)
        self.STATUS_OK=0
        pass
    
    def test_firewallService(self):
        self.assertTrue(self.compi.configureFirewallService(enable=True), "firewall service activation failed")
        self.assertTrue(self.compi.isFirewallServiceEnabled(), "firwall services might not be activated")
        self.assertTrue(self.compi.configureFirewallService(enable=False), "firewall service deactivation failed")
        self.assertFalse(self.compi.isFirewallServiceEnabled(), "firwall services might not be deactivated")
        
        
    def test_firewallRules(self):    
        '''
        test web connectivity, then block internet (port 53,80,443), then assert no connectivity
        TODO: UNSOLVED: real DNS test? Ping doesn't really do that (for cached resources, ping still works)
        TODO: test firewall status: netsh advfirewall show allprofiles state;
        Set-NetFirewallProfile -Enabled true
        ''' 
        testCommand = 'if (Test-Connection $1$ -Quiet -Count 1) { Write-Host "1" } else { Write-Host "-1" }'.replace('$1$', testWebConnectivityHost)
        testCommandHttp = 'try { $client = New-Object System.Net.WebClient; $res=$client.DownloadString("http://$1$"); write-host 1} catch{ write-host -1}'.replace("$1$", testWebConnectivityHost)
        print(testCommandHttp)
        
        # check firewall service is enabled
        if not(self.compi.isFirewallServiceEnabled()):
            self.compi.configureFirewallService(enable=True)
        
        # check previous rules are deleted
        result = self.compi.blockInternetAccess(False)
        self.assertTrue(result, "result of firewall turnoff operation should be True") 
            
        std_out, std_err, status = self.compi.runPowerShellCommand(command=testCommand)
        self.assertEqual(status, self.STATUS_OK, "initial staus problem: "+std_err)
        self.assertEqual(std_out, "1", "inital connection failed, should have worked")
        
        result = self.compi.blockInternetAccess(True)
        self.assertTrue(result, "result of firewall operation should be True")
        time.sleep(1)
        #self.assertEquals(self.compi.runPowerShellCommand(command=testCommand)[0], "0", "DNS should not be possbile after blocking")
        # TODO: test port 80, 443!
        std_out, std_err, status = self.compi.runPowerShellCommand(command=testCommandHttp)
        self.assertEqual(status, self.STATUS_OK, "status after connection attempt: "+std_err)
        self.assertEqual(std_out, "-1", "HTTP should not be possible after blocking")
        
        result = self.compi.blockInternetAccess(False)
        self.assertTrue(result, "result of firewall turnoff operation should be True")        
        time.sleep(1)
        
        std_out, std_err, status = self.compi.runPowerShellCommand(command=testCommandHttp)
        self.assertEqual(status, self.STATUS_OK, "status after firewall down: "+std_err)
        self.assertEquals(std_out, "1", "HTTP should be possible after blocking")
        
    def test_ctor(self):
        self.assertEquals(self.compi.ip, ipAddress, "Computer instance not properly set up")

    def test_getHostName(self):
        hostname = self.compi.getHostName()
        self.assertEqual(targetHostname, hostname, "HostName doesn't match")
        
    def test_candidateNameFunctions(self):
        STATUS_OK = 0
        candidateName = "Käptn Blaubär"
        self.assertEquals(STATUS_OK, self.compi.setCandidateName(candidateName),"Setup Candidate name failed")
        self.assertEquals(candidateName, self.compi.getCandidateName(),"Candidate name retrieval failed or didn't match")
                

    def test_deployAndListFiles(self):
        '''
        actually deploys files to given client, assumes static network location is valid
        '''
        filepath=r"\\odroid\lb_share\M104"
              
        status, error = self.compi.deployClientFiles(filepath, empty=True)
        self.assertTrue( status, "Status Deployment Copy NOK: "+error)
        self.assertEqual(Computer.State.STATE_DEPLOYED, self.compi.state, "Computer not in status 'DEPLOYED'")
      
        if os.name !="nt":
            filepath = "/mnt/PiData/lb_share/M104" # sorry for the linux hack, just mount smb share before running the tests
          
        remoteFileListing = self.compi.getRemoteFileListing()
        # print("received RemoteFilesListing: \n"+remoteFileListing)
          
        for f in os.listdir(filepath):
            self.assertTrue(-1 < remoteFileListing.find(f),"file missing on client: {}".format(f))
 
    def test_deployAndRetrieveFiles(self):
        '''
        test if file retrieval from client works, assumes static network location is valid
        (still buggy)
        '''
 
        # first: deploy lb files     
        filepath=r"\\odroid\lb_share\M104"
        status, error = self.compi.deployClientFiles(filepath, empty=True)
        self.assertTrue(status, "Status Deployment Copy NOK: "+error)
        self.assertEqual(Computer.State.STATE_DEPLOYED, self.compi.state, "Computer not in status 'DEPLOYED'")
      
      # second: rerieve lb files     
        filepath=r"\\odroid\lb_share\Ergebnisse"         
        status, error = self.compi.retrieveClientFiles(filepath)
        self.assertTrue(status, "Error retrieving files: "+error)
        self.assertEqual(Computer.State.STATE_FINISHED, self.compi.state, "Computer not in status 'FINISHED'")  
        
        # compare folder contents
        if os.name !="nt": # convert for Unix Test systems
            filepath = "/mnt/PiData/lb_share/Ergebnisse/M104/"
        else: 
            filepath = filepath+"\\"
              
        remoteResultFileListing = self.compi.getRemoteFileListing()
          
        files=os.listdir(filepath+self.compi.candidateName.replace(" ", "_"))
        for f in files:
            self.assertTrue(-1 < remoteResultFileListing.find(f),"file missing on result set: {}".format(f))  
       

if __name__ == "__main__":
    unittest.main()