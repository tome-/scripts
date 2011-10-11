#!/usr/bin/python

################################################################
'''
 Name:    ob-hamachi
 About:   hamachi v2 support for openbox
 Author:  grimi < grimi at poczta dot fm>
 License: GNU GPL v3
'''
################################################################


import os , sys
import subprocess as sp


class hamachi():
   def __init__(self):
      self.out = '<?xml version="1.0" encoding="UTF-8"?>\n'
      self.out += '<openbox_pipe_menu>\n'
      self.numnets = 0
      self.linetabs = []

   def genEnd(self,stat):
      if stat == "offline":
         self.genActionItem('Login','hamachi login')
      elif stat != "norunned":
         if self.numnets:
            self.out += ' <separator/>\n'
         self.genActionItem('Logout','hamachi logout')
      self.out += '</openbox_pipe_menu>\n'

   def genNet(self):
      def gNext():
         if len(self.linetabs) != 0:
            line = self.linetabs[0]
            self.linetabs.remove(line)
            return line.decode()
         else:
            return ''
      while len(self.linetabs):
         line = gNext()
         nettab = line.split() ; netname = netstat = ''
         if nettab[0] == "*" or nettab[0] == "x":
            netstat = nettab[0] + ' '
            nettab.remove(nettab[0])
         netname = nettab[0].split('[')[1].split(']')[0]
         if self.numnets: self.out += ' <separator/>\n'
         self.numnets += 1
         self.out += ' <menu id="ham-%s" label="%s%s">\n' % (nettab[0],netstat,netname)
         self.out += '  <separator label="%s"/>' % (netname)
         while line != "":
            line = gNext()
            if line.find("[") >= 0:
               self.linetabs.insert(0,line.encode())
               break
            if line != "":
               cltab = line.split() ; clstat = clname = ''
               if cltab[0] == "*" or cltab[0] == "x":
                  clstat = cltab[0]+' '
                  cltab.remove(cltab[0])
               clid = cltab[0]
               if cltab[1].isalpha():
                  clname = "%s : " % cltab[1]
                  cltab.remove(cltab[1])
               clip = cltab[1]
               self.out += '  <menu id="%s-menu" label="%s%s%s">\n' % (clip,clstat,clname,clip)
               self.out += '   <separator label="%s%s"/>\n' % (clname,clip)
               self.out += '   <separator label="ID: %s"/>\n' % clid
               self.genActionItem('Ping','xterm -T "Pinging: %s" -g 60x18 -e "ping -w 10 -c 10 %s;echo -en \'\\n:::Hit ENTER:::\';read"' \
                     % (clname.split()[0] if len(clname) else '',clip),'  ')
               if clstat != "" and clstat[0] != "x":
                  self.out += '  <separator/>\n'
                  self.genActionItem('SSH','xterm -e "ssh %s"' % clip,'  ')
                  self.genActionItem('SSH - X','xterm -e "ssh -Y %s"' % clip,'  ')
               self.out += '  </menu>\n'
         if len(netstat) > 0 and netstat[0] == "*":
            self.out += '  <separator/>\n'
            self.genActionItem('Offline','hamachi go-offline %s' % netname,' ')
         else:
            self.out += '  <separator/>\n'
            self.genActionItem('Online','hamachi go-online %s' % netname,' ')
         self.out += ' </menu>\n'
      return self.numnets

   def genActionItem(self,name,cmd,space=''):
      self.out += space + ' <item label="%s">\n' % name
      self.out += space + '  <action name="Execute">\n'
      self.out += space + '   <execute>%s</execute>\n' % cmd
      self.out += space + '  </action>\n'
      self.out += space + ' </item>\n'

   def genStatus(self):
      result = None
      try:
         pr = sp.Popen(['hamachi'],stdout=sp.PIPE,stderr=sp.STDOUT)
         try:
            lines = pr.stdout.readlines()
            pr.kill()
         except: pass
         pr.stdout.close()
         if 'logmein-hamachi start' in lines[1].decode():
            self.out += ' <item label="Hamachi does not running ?!"/>\n'
            return 'norunned'
         adr = nick = clid = ''
         for i in range(len(lines)):
            infotab = lines[i].decode().split()
            if len(infotab):
               if infotab[0] == "address":  adr    = infotab[2]
               if infotab[0] == "nickname": nick   = infotab[2]
               if infotab[0] == "client":   clid   = infotab[3]
               if infotab[0] == "status":   result = infotab[2]
         self.out += ' <separator label="%s : %s"/>\n' % (nick,adr)
         self.out += ' <separator label="ID: %s"/>\n' % clid
      except OSError:
         self.out += ' <item label="Hamachi does not installed ?!"/>\n'
      return result

   def doJob(self):
      hstop = False
      stat = self.genStatus()
      try:
         if not stat or stat != "logged": raise()
         pr = sp.Popen(['hamachi','list'],stdout=sp.PIPE,stderr=sp.STDOUT)
         try:
            self.linetabs = pr.stdout.readlines()
            pr.kill()
         except:
            pass
         pr.stdout.close()
      except:
         pass
      if len(self.linetabs):
         if len(self.linetabs[0].split()) == 0:
            self.out += ' <item label="Can\'t get info from hamachi!"/>\n'
         else:
            self.genNet()
      self.genEnd(stat)
      return self.out

##############################################################################


if __name__ == "__main__":
   if len(sys.argv) == 2:
      if sys.argv[1] == "--help" or sys.argv[1] == "-h":
         print("%s : the hamachi support for openbox\n" % sys.argv[0])
         exit(1)
   print(hamachi().doJob())

