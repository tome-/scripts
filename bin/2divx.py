#!/usr/bin/python
## Name:     2divx
## About:    simple python wrapper for mencoder
## Author:   grimi < grimi at poczta dot fm >
## Requires: mencoder
## Licence:  GNU GPL v3


from __future__ import unicode_literals,print_function

class Todivx:
   def __init__(self):
      from os import getenv
      self.lang = getenv('LANG').split('_')[0]
      if self.lang == "pl":
         self.msgtab = {"usage":"%prog [opcje] <plik wideo> [...]",
            "out":"nazwa docelowego wideo (domyślnie: taka jak źródłowego [z rozszerzeniem .avi])",
            "video":"gęstość bitowa wideo (domyślnie: 900)","audio":"gęstość bitowa audio (domyślnie: 128)",
            "crop":"obcinaj wideo <w:s>[:x:y]","scale":"skaluj wideo x:y",
            "band":"rozszerz wideo do podanej proporcji, czarnym pasem w dolnej części",
            "fps":"ustaw ilość klatek na sek dla wideo","mbd":"algorytm mbd: 0, 1 lub 2 (domyślnie: 2)",
            "freq":"częstotliwość dla strumienia audio (domyślnie: 44100)",
            "subt":"dodaj napisy ('auto' = taka sama nazwa jak wideo)",
            "subscl":"skalowanie czcionki napisów (domyślnie: 4)",
            "vol":"zmiana głośności (od -200dB do 60dB, domyślnie: 0dB)",
            "trell":"ustaw optymalną quanizację","xvid":"tryb xvid","nskip":"nie opuszczaj ramek",
            "threads":"używaj wielu wątków od 1 do 8 (domyślnie: 1 )",
            "verb":"pokaż informację 'wyrzucane' przez mencodera",
            "test":"nie wykonuj, pokaż komendę w stdout",
            "erargs":"Wymagany co najmniej jeden argument. Użyj opcji -h !",
            "break":"\n... przerywam, użyto ctrl-c ..."}
      else:
         self.msgtab = {"usage":"[options] <video file> [...]",
            "out":"name of target wideo (default: the same as source name [with .avi suffix])",
            "video":"video bitrate (default: 900)","audio":"audio bitrate (default: 128)",
            "crop":"crop video <w:h>[:x:y]","scale":"scale of video x:y",
            "band":"expand video to the given aspect, adding black band at the bottom",
            "fps":"set fps for video (default: ignore)","mbd":"mbd algoritm: 0, 1 or 2 (default: 2)",
            "freq":"output audio frequency (default: 44100)",
            "subt":"add subtitle ('auto' = the same name as video)",
            "subscl":"subtitle font scale (default: 4)",
            "vol":"change volume (from -200dB to 60dB, default: 0dB)",
            "trell":"setup optimal quantization","xvid":"xvid mode","nskip":"no skip frame",
            "threads":"use threads from 1 to 8 (default: 1)",
            "verb":"show normal output from mencoder",
            "test":"put command line to stdout","erargs":"Required at least one arg. Maybe try -h option!",
            "break":"\n... breaking up, ctrl-c was used ..."}

   def parseargs(self):
      from  optparse import OptionParser
      self.parser = OptionParser(usage=self.msgtab["usage"])
      self.parser.add_option("-o","--output",type="string",default=None,help=self.msgtab["out"])
      self.parser.add_option("-v","--vbitr",type="int",default="900",help=self.msgtab["video"])
      self.parser.add_option("-a","--abitr",type="int",default="128",help=self.msgtab["audio"])
      self.parser.add_option("-c","--crop",type="string",default=None,help=self.msgtab["crop"])
      self.parser.add_option("-s","--scale",type="string",default=None,help=self.msgtab["scale"])
      self.parser.add_option("-b","--band",type="string",default=None,help=self.msgtab["band"])
      self.parser.add_option("-f","--fps",type="float",default=0,help=self.msgtab["fps"])
      self.parser.add_option("-m","--mbd",type="int",default=2,help=self.msgtab["mbd"])
      self.parser.add_option("-r","--freq",type="int",default=44100,help=self.msgtab["freq"])
      self.parser.add_option("-i","--sub",type="string",default=None,help=self.msgtab["subt"])
      self.parser.add_option("-j","--subscale",type="int",default=4,help=self.msgtab["subscl"])
      self.parser.add_option("-u","--vol",type="int",default=0,help=self.msgtab["vol"])
      self.parser.add_option("-d","--threads",type="int",default=1,help=self.msgtab["threads"])
      self.parser.add_option("-t","--trell",action="store_true",help=self.msgtab["trell"])
      self.parser.add_option("-x","--xvid",action="store_true",help=self.msgtab["xvid"])
      self.parser.add_option("-n","--noskip",action="store_true",help=self.msgtab["nskip"])
      self.parser.add_option("-k","--test",action="store_true",help=self.msgtab["test"])
      self.parser.add_option("-V","--verbose",action="store_true",help=self.msgtab["verb"])
      self.opts,self.args = self.parser.parse_args()

   def buildcmd(self):
      from os.path import exists
      extra = ""
      if self.args[0][:6].lower() == "dvd://":
         out = "dvd-" + self.args[0][6:]
         extra += " -alang " + self.lang + ",en"
         if self.opts.sub:
            extra += " -slang \"" + self.opts.sub + "\""
      else:
         out = self.opts.output if self.opts.output else self.args[0]
         x = out.rfind(".")
         if x > 0:  out = out[:x]
      if exists(out+".avi"):
         for x in range(1000):
            if not exists(out+"-"+str(x)+".avi"):
               out += "-" + str(x) ; break
      extra += " -o \"" + out + ".avi\""
      if self.opts.mbd > 2:  self.opts.mbd = 2
      video="vcodec=mpeg4:vbitrate=" + str(self.opts.vbitr) + ":mbd=" + \
         str(self.opts.mbd) + ":sc_threshold=1000000000:cgop"
      if self.opts.trell: video += ":trell:cbp"
      video+= ":threads=" + str(min(abs(self.opts.threads),8))
      audio="mp3lame -lameopts cbr:preset=" + str(self.opts.abitr) + \
         " -af resample=" + str(abs(self.opts.freq)) + ":0:1" + \
         ",volume=" + str(self.opts.vol)
      vfilter = " -vf "
      extra += " -ffourcc XVID" if self.opts.xvid else " -ffourcc DX50"
      if self.opts.sub:
         if self.opts.sub != "auto":
            sub = self.opts.sub
         else:
            sub = self.args[0]
            x = sub.rfind('.')
            if x > 0:  sub = sub[:x]
            for x in [".txt",".sub",".srt"]:
               if exists(sub+x):
                  sub += x ; break
            else:  sub = ""
         extra += " -fontconfig -subfont-text-scale " + str(self.opts.subscl) + " -subpos 100 -subcp enca:" + self.lang + ":utf-8"
         if exists(sub):  extra += " -sub \"" + sub + "\""
      else:
         extra += " -noautosub"
      if self.opts.crop:
         vfilter += "crop=" + self.opts.crop + ","
      if self.opts.scale:
         vfilter += "scale=" + self.opts.scale + ","
      if self.opts.band:
         vfilter += "expand="
         if self.opts.scale:
            sctab = self.opts.scale.split(":")
            vfilter += sctab[0] + ":" if int(sctab[0]) > 0 else "0:"
            vfilter += sctab[1] if int(sctab[1]) > 0 else "0"
         else:
            vfilter += "0:0"
         vfilter += ":0:0:0:" + self.opts.band + ":2,softskip,"
      if self.opts.fps:
         extra += " -ofps " + str(self.opts.fps)
         vfilter += "framestep=1,filmdint=dint_thres=256,harddup,"
      if self.opts.noskip:
         extra += " -noskip"
         if not self.opts.fps:  vfilter += "harddup,"
      if len(self.args) > 1: extra += " -idx"
      vfilter = vfilter[:len(vfilter)-1] if vfilter != " -vf " else ""
      self.command="nice -n 3 mencoder -ni -oac " + audio+" -ovc lavc -lavcopts " + \
         video + extra + vfilter
      for x in range(len(self.args)):
         self.command += " \"" + self.args[x] + "\""

   def progress(self,line,prsize=18):
      if line[:4] == "Pos:":
         lspl = line.split()
         for x in lspl:
            if "%" in x:
               x = x.replace('(','')
               perc = int(x[:len(x)-2])
            elif "fps" in x:
               fps = x.split('.')[0]+'fps'
            elif "min" in x:
               rtime = x
            elif "mb" in x:
               size = x
         time = lspl[1] if not "f" in lspl[1] else lspl[0].split(':')[1]
         xt = int(int(time.split('.')[0])/10)
         th = int(xt / 3600) ; tm = int((xt - (th*3600))/60) ; ts = xt - (th*3600) - (tm*60)
         time = "%02d:%02d:%02d" % (th,tm,ts)
         perc = min(perc,100)
         prsize = min(prsize,50)
         y = ""
         for x in range(1,int(prsize*perc/100)+1): y += '#'
         fmt = '%%%02ds' % -prsize
         fmt = '[ %s < %s : %s ] [ %03d%% : ' + fmt + ' : %s ]  \r'
         print(fmt % (time,rtime,fps,perc,y,size),end="")

   def dojob(self):
      from subprocess import Popen,PIPE,STDOUT
      from time import sleep
      self.parseargs()
      if len(self.args) > 0 and len(self.args[0]) > 0:
         self.buildcmd()
         if self.opts.test:
            print(self.command)
         else:
            if self.opts.verbose:
               pr = Popen(self.command,shell=True)
            else:
               pr = Popen(self.command,shell=True,stdout=PIPE,stderr=STDOUT)
            try:
               if not self.opts.verbose:
                  line = ""
                  while True:
                     chr = pr.stdout.read(1).decode()
                     if chr == "":
                        break
                     elif chr == "\n" or chr == "\r":
                        self.progress(line)
                        line = ""
                     else:
                        line += chr
                  print()
               pr.wait()
            except KeyboardInterrupt:
               print(self.msgtab["break"])
            try: pr.kill()
            except: pass
      elif len(self.args) == 0:
         self.parser.print_usage()
      else:
         print(self.msgtab["erargs"])
#########


if __name__=="__main__":
   Todivx().dojob()

