'''
# creates a local share on windows PC

sharename = self.lb_directory.split("/")[-1] 
smbShareCreateCommand = "New-SmbShare -Name {} -Path {} -ReadAccess winrm,sven".format(sharename, self.lb_directory.replace("///", ""))
self.log("Creating new share: " + smbShareCreateCommand)
try:
    self.__runLocalPowerShellAsRoot(smbShareCreateCommand)
    self.sharenames.append(sharename)
    self.lb_directory = "//" + socket.gethostname() + "/" + sharename  # important: update directory string to match smb-path
except Exception as ex:
    self.showMessageBox("Fehler", "Share konnte nicht eingerichtet werden")
    self.log("Share konnte nicht eingerichtet werden: " + str(ex))
    self.lb_directory = None
    sharename = None
                        
'''