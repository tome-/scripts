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
      self.nets = 0
      self.linets = []

   def genEnd(self,stat):
      if stat == "offline":
         self.genActionItem('Login','hamachi login')
      else:
         if self.nets:
            self.out += ' <separator/>\n'
         self.genActionItem('Logout','hamachi logout')
      self.out += '</openbox_pipe_menu>\n'

   def genNet(self):
      def gNext():
         if len(self.linets) != 0:
            line = self.linets[0]
            self.linets.remove(line)
            return line.decode()
         else:
            return ''
      while len(self.linets):
         line = gNext()
         sbn = line.split() ; nname = ''
         if sbn[0] == "*" or sbn[0] == "x":
            nname = sbn[0] + ' '
            sbn.remove(sbn[0])
         nname += sbn[0]
         if self.nets: self.out += ' <separator/>\n'
         self.nets += 1
         self.out += ' <menu id="ham-%s" label="%s">\n' % (sbn[0],nname)
         while line != "":
            line = gNext()
            if line.find("[") >= 0: break
            if line != "":
               sbt = line.split() ; online = clname = '' 
               if sbt[0] == "*" or sbt[0] == "x":
                  online = sbt[0]+' '
                  sbt.remove(sbt[0])
               clid = sbt[0]
               if sbt[1].isalpha():
                  clname = " [%s]" % sbt[1]
                  sbt.remove(sbt[1])
               clip = sbt[1]
               self.out += '  <menu id="%s-menu" label="%s%s%s">\n' % (clip,online,clip,clname)
               self.out += '   <separator label="ID: %s"/>\n' % clid
               if online != "":
                  self.genActionItem('SSH','xterm -e "ssh %s"' % clip,'  ')
                  self.out += '  <separator/>\n'
               self.genActionItem('Ping','xterm -e "ping -w 10 -c 10 %s"' % clip,'  ')
               self.out += '  </menu>\n'
         self.out += ' </menu>\n'
      return self.nets

   def genActionItem(self,name,cmd,spc=''):
      self.out += spc + ' <item label="%s">\n' % name
      self.out += spc + '  <action name="Execute">\n'
      self.out += spc + '   <execute>%s</execute>\n' % cmd
      self.out += spc + '  </action>\n'
      self.out += spc + ' </item>\n'

   def genStatus(self):
      result = None
      try:
         pr = sp.Popen(['hamachi'],stdout=sp.PIPE,stderr=sp.STDOUT)
         try:
            lines = pr.stdout.readlines()
            pr.kill()
         except: pass
         pr.stdout.close()
         adr = nick = clid = ''
         for i in range(len(lines)):
            spl = lines[i].decode().split()
            if len(spl):
               if spl[0] == "address": adr = spl[2]
               if spl[0] == "nickname": nick = spl[2]
               if spl[0] == "client": clid = spl[3]
               if spl[0] == "status": result = spl[2]
         self.out += ' <separator label="%s%s"/>\n' % (adr,'' if nick == '' else ' ['+nick+']')
         self.out += ' <separator label="ID: %s"/>\n' % clid
      except OSError:
         self.out += ' <item label="Hamachi not installed ?!"/>\n'
      return result

   def doJob(self):
      hstop = False
      stat = self.genStatus()
      try:
         if not stat or stat != "logged": raise()
         pr = sp.Popen(['hamachi','list'],stdout=sp.PIPE,stderr=sp.STDOUT)
         try:
            self.linets = pr.stdout.readlines()
            pr.kill()
         except:
            pass
         pr.stdout.close()
      except:
         pass
      if len(self.linets):
         if len(self.linets[0].split()) == 0:
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

