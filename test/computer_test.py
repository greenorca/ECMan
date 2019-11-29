import unittest
from configparser import ConfigParser
from pathlib import Path

from worker.computer import Computer
from worker.sharebrowser import ShareBrowser

class ComputerTestCase(unittest.TestCase):

    ip = "192.168.0.95"
    configFile = Path(str(Path.home()) + "/.ecman.conf")

    def setUp(self):
        self.config = ConfigParser()
        self.config.read_file(open(str(self.configFile)))

        self.port = self.config.get("General", "winrm_port", fallback=5986)

        self.client_lb_user = self.config.get("Client", "lb_user", fallback="student")
        self.user = self.config.get("Client", "user", fallback="")
        self.passwd = self.config.get("Client", "pwd", fallback="")

        self.server_user = self.config.get("Test", "server_user", fallback="jotest")
        self.server_passwd = self.config.get("Test", "server_passwd")
        self.domain = self.config.get("Test", "domain")

        self.serverpath = self.config.get("Test", "serverpath", fallback="##odroid#lb_share#")
        self.lb_path = self.config.get("Test", "lb_path",fallback="LB#M100")
        self.erg_path = self.config.get("Test", "erg_path", fallback="ERG#IFZ-526-001")

        self.sut = Computer(self.ip, self.user, self.passwd, self.client_lb_user, fetchHostname=False)

    def test_client_name(self):
        '''
        tests remote username setup
        :return:
        '''
        desiredName = "Hans Heiri";
        self.sut.setCandidateName(desiredName)
        self.assertEqual(self.sut.candidateName, desiredName)
        self.assertEqual(self.sut.getCandidateName(remote=True), desiredName)

        desiredName = "Mary Mayo";
        self.sut.setCandidateName(desiredName)
        self.assertEqual(self.sut.candidateName, desiredName)
        self.assertEqual(self.sut.getCandidateName(remote=True), desiredName)

    def test_reset(self):
        self.sut.resetStatus(True)
        self.assertEqual(self.sut.getCandidateName(remote=True), None)

    def test_lb_deploy(self):
        '''
        tests remote deployment process (first reset the remote machine)
        :return:
        '''
        self.sut.resetStatus(False)
        self.assertEqual(self.sut.state, Computer.State.STATE_INIT,"should be STATE_INIT after reset")
        retval = self.sut.deployClientFiles(self.serverpath + self.lb_path, self.server_user, self.server_passwd, self.domain)
        self.assertTrue(retval)
        self.assertEqual(self.sut.state, Computer.State.STATE_DEPLOYED,"should be state_deployed after successful exam deployment")
        self.assertEqual(self.serverpath + self.lb_path, self.sut.filepath, "LB path should rather match")

    def test_lb_deploy_fail(self):
        '''
        tests remote deployment process (first reset the remote machine)
        :return:
        '''
        self.sut.resetStatus(False)
        self.assertEqual(self.sut.state, Computer.State.STATE_INIT,"should be STATE_INIT after reset")
        retval = self.sut.deployClientFiles("guggus", self.server_user, self.server_passwd, self.domain)
        self.assertFalse(retval)
        self.assertEqual(self.sut.state, Computer.State.STATE_COPY_FAIL,"should be STATE_COPY_FAIL after failure of exam deployment")


    def test_lb_deploy_retrieval(self):
        '''
        tests remote deployment process (first reset the remote machine)
        and retrieval
        :return:
        '''
        self.sut.resetStatus(False)
        self.assertEqual(self.sut.state, Computer.State.STATE_INIT,"should be STATE_INIT after reset")
        desiredName = "Hans Heiri";
        self.sut.setCandidateName(desiredName)
        self.assertEqual(self.sut.candidateName, desiredName, "name setup failed")

        retval = self.sut.deployClientFiles(self.serverpath + self.lb_path, self.server_user, self.server_passwd, self.domain)
        self.assertTrue(retval)
        self.assertEqual(self.sut.state, Computer.State.STATE_DEPLOYED,"should be state_deployed after successful exam deployment")
        self.assertEqual(self.serverpath + self.lb_path, self.sut.serverpath, "LB path should rather match")

        retval = self.sut.retrieveClientFiles(self.serverpath+self.erg_path, self.server_user, self.server_passwd, self.domain)
        self.assertTrue(retval)
        self.assertEqual(self.sut.state, Computer.State.STATE_FINISHED,"should be STATE_FINISHED after successful exam retrieval")

        servername = [x for x in self.serverpath.split("#") if x != ""][0]
        sharename = [x for x in self.serverpath.split("#") if x != ""][1]
        modulname = self.lb_path.split("#")[-1]
        sharebrowser = ShareBrowser(servername, self.server_user, self.server_passwd, domain=self.domain)
        content = sharebrowser.getDirectoryContent(sharename, self.erg_path.replace("#","//")+"//"+modulname)
        self.assertIn(self.sut.candidateName.replace(" ","_"), [x.filename for x in content],
                      "Result directory missing for candidate {}".format(self.sut.candidateName))
        content = sharebrowser.getDirectoryContent(sharename,
                       self.erg_path.replace("#", "//") + "//" + modulname + "//" + self.sut.candidateName.replace(" ","_"))
        self.assertIn("desktop_{}.zip".format(self.sut.candidateName.replace(" ","_")),
                      [x.filename for x in content], "Desktop ZIP file missing")

    def test_lb_deploy_retrieval(self):
        '''
        tests remote deployment process (first reset the remote machine)
        and retrieval
        :return:
        '''
        self.sut.resetStatus(False)
        self.assertEqual(self.sut.state, Computer.State.STATE_INIT,"should be STATE_INIT after reset")
        desiredName = "Hans Heiri";
        self.sut.setCandidateName(desiredName)
        self.assertEqual(self.sut.candidateName, desiredName, "name setup failed")

        retval = self.sut.deployClientFiles(self.serverpath + self.lb_path, self.server_user, self.server_passwd, self.domain)
        self.assertTrue(retval)
        self.assertEqual(self.sut.state, Computer.State.STATE_DEPLOYED,"should be state_deployed after successful exam deployment")
        self.assertEqual(self.serverpath + self.lb_path, self.sut.filepath, "LB path should rather match")

        retval = self.sut.retrieveClientFiles(self.serverpath+"lalelu", self.server_user, self.server_passwd, self.domain)
        self.assertFalse(retval,"should have failed to copy")

        retval = self.sut.retrieveClientFiles("lalelu", self.server_user, self.server_passwd, self.domain)
        self.assertFalse(retval,"should have failed to copy")


if __name__ == '__main__':
    unittest.main()
