#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#       vbitc.py
#
#       Copyright 2010 grimi <grimi at poczta dot fm>
#
#       This program is free software; you can redistribute it and/or modify
#       it under the terms of the GNU General Public License as published by
#       the Free Software Foundation; either version 2 of the License, or
#       (at your option) any later version.
#
#       This program is distributed in the hope that it will be useful,
#       but WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#       GNU General Public License for more details.
#
#       You should have received a copy of the GNU General Public License
#       along with this program; if not, write to the Free Software
#       Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#       MA 02110-1301, USA.


class BitCalc:
   def __init__(self):
      import sys
      if len(sys.argv) < 3 or len(sys.argv) > 4:
         print("USAGE: <time(hh:mm:ss)> <size(in MB)> [audio btr(def 128kb)]")
         exit(1)
      tab = sys.argv[1].split(":")
      self.secs =  int(tab[0]) * 60 * 60
      self.secs += int(tab[1]) * 60
      self.secs += int(tab[2])
      if len(sys.argv) == 4:
         akb = int(sys.argv[3]) * self.secs / 8
      else:
         akb = 16 * self.secs      # 16 = 128 / 8
      self.kbyte = int(sys.argv[2]) * 1024 - akb
   def gen(self):
      print("%d kbps" % ((self.kbyte/self.secs)*8) )


def main():
   BitCalc().gen()
   return 0

if __name__ == '__main__':
   main()

