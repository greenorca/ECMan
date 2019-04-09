'''
Created on Mar 10, 2019

@author: sven
'''
import pdfkit

class LogfileHandler:
    '''
    class that reads plaintext logfiles from Computer class and dumps it into PDF logfiles
    '''


    def __init__(self, logfile, candidateName):
        '''
        Constructor
        '''
        self.logfile = logfile
        self.candidateName = candidateName
        
        
    def createPdf(self, targetFile):
        '''
        reads log file and creates pdf from its content
        '''
        with open(self.logfile) as f:
            content = f.readlines()
            
        
        html_content = "<br>".join(content).\
            replace("WARNING","<span style={color:'red'; font-weight:'bold';}>WARNING</span>)").\
            replace("ERROR","<span style={color:'red'; font-weight:'bold';}>ERROR</span>")
        
        html_content = "<articles><h1>Deployment Protokoll f&uuml;r {0}</h1>{1}</section>". \
            format(self.candidateName, html_content)
        
        html_content = html_content.replace("ü", "&uuml;").\
            replace("ä", "&auml;").\
            replace("ö", "&ouml")
        
        
        pdfkit.from_string(html_content, targetFile)    