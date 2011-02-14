#!/usr/bin/python
# -*- coding: utf8 -*-

################################################################
'''
 Name:    ob-hamachi
 About:   hamachi v0.9.* support for openbox
 Author:  grimi < grimi at poczta dot fm>
 License: GNU GPL v3
'''
################################################################


import os,sys,fcntl,time
import subprocess as sp


class hamachi():
    def __init__(self):
        self.out = '<?xml version="1.0" encoding="UTF-8"?>\n'
        self.out += '<openbox_pipe_menu>\n'
        try:
            fd = open(os.path.join(os.path.expanduser('~'),'.hamachi/state'),'r')
            ti = fd.readline().split()
            if ti[0] == 'Identity':
                tn = fd.readline().split()
                self.out += ' <separator label="%s' % ti[1]
                if tn[0] == 'Nickname':
                    self.out += ' (%s)' % tn[1]
                self.out += '"/>\n'
            fd.close()
        except:
            self.out += ' <separator label="Hamachi"/>\n'

    def genEnd(self,stop=False):
        if stop == False:
            self.out += ' <item label="Start">\n'
            self.out += '  <action name="Execute">\n'
            self.out += '   <execute>bash -c "hamachi start;sleep 15;hamachi get-nicks"&amp;</execute>\n'
            self.out += '  </action>\n'
            self.out += ' </item>\n'
        else:
            self.out += ' <item label="Stop">\n'
            self.out += '  <action name="Execute">\n'
            self.out += '   <execute>bash -c "hamachi stop&amp;pid=$!;sleep 2;kill &amp;>/dev/null $pid"</execute>\n'
            self.out += '  </action>\n'
            self.out += ' </item>\n'
            self.out += ' <item label="Kill">\n'
            self.out += '  <action name="Execute">\n'
            self.out += '   <execute>killall -q 3</execute>\n'
            self.out += '  </action>\n'
            self.out += ' </item>\n'
        self.out += '</openbox_pipe_menu>\n'

    def genNet(self,fd):
        i = 0
        while self.buf != "":
            sbn = self.buf.split() ; nname = ''
            if sbn[0] == "*":
                nname = 'V '
                sbn.remove("*")
            nname += sbn[0] 
            self.out += ' <menu id="ham-%s" label="%s">\n' % (sbn[0],nname)
            while self.buf != "":
                self.buf = fd.readline()
                if self.buf.find("[") >= 0: break
                if self.buf != "":
                    sbt = self.buf.split()
                    lip = ip = sbt[0]
                    if ip == "*":
                        lip = "V"
                    elif ip == "x":
                        lip = "--"
                    if ip == "*" or ip == "x":
                        sbt.remove(ip)
                        ip = sbt[0]
                        lip += ' '+ip
                    if len(sbt)>1 and sbt[1][0].isalpha():
                        lip += ' (%s)' % sbt[1]
                    if lip[:2] == "V ":
                        self.out += '  <menu id="%s-menu" label="%s">\n' % (ip,lip)
                        self.out += '    <item label="SSH">\n'
                        self.out += '      <action name="Execute">\n'
                        self.out += '        <execute>xterm -e "ssh %s"</execute>\n' % ip
                        self.out += '      </action>\n'
                        self.out += '    </item>\n'
                        self.out += '    <item label="Ping">\n'
                        self.out += '      <action name="Execute">\n'
                        self.out += '        <execute>xterm -e "ping -c 10 %s"</execute>\n' % ip
                        self.out += '      </action>\n'
                        self.out += '    </item>\n'
                        self.out += '  </menu>\n'
                    else:
                        self.out += '  <item label="%s"/>\n' % lip
            self.out += ' </menu>\n'
            i += 1
        self.out += ' <separator/>\n'
        return i > 0

    def doJob(self):
        hstop = False
        try:
            pr = sp.Popen(['hamachi','list'],stdout=sp.PIPE,stderr=sp.STDOUT)
            fcntl.fcntl(pr.stdout,fcntl.F_SETFL,os.O_NONBLOCK)
            time.sleep(0.1)
            try:
                self.buf = pr.stdout.readline()
                if len(self.buf) != 0 and self.buf.find("Hamachi does not") != 0:
                    if self.buf == "\n":
                        self.out += ' <item label="Can\'t get info from hamachi!"/>\n'
                    else:
                        hstop = self.genNet(pr.stdout)
                pr.kill()
            except:
                pass
            pr.stdout.close()
        except OSError:
            self.out += ' <item label="Hamachi not installed ?!"/>\n'
        self.genEnd(hstop)
        return self.out

##############################################################################


if __name__ == "__main__":
    if len(sys.argv) == 2:
        if sys.argv[1] == "--help" or sys.argv[1] == "-h":
            print("%s : the hamachi support for openbox\n" % sys.argv[0])
            exit(1)
    print(hamachi().doJob())
