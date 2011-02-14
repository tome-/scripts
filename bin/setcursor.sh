#!/bin/bash
# Name:    setcursor
# About:   script for setup cursor on WM's 
# Author:  grimi < grimi at poczta dot fm >
# License: GNU GPL v3

prefs="$HOME/.cursor"
store=0

findcursors() {
 sysp="/usr/share/icons"
 for i in $(ls -1 $sysp); do
   if [ -e "${sysp}/${i}/cursors" ]; then
      echo $i
   fi
 done
 sysp="$HOME/.icons"
 for i in $(ls -1 $sysp); do
   if [ -e "${sysp}/${i}/cursors" ]; then
      echo $i
   fi
 done
}

setupcursor() {
 for i in $(findcursors); do
   if [ $1 = $i ]; then
      echo "Xcursor.theme: $i"|xrdb -merge
      echo "Xcursor.size: $2"|xrdb -merge
      break
   fi
 done
}

listcursors() {
 for i in $(findcursors); do
    echo $i
 done
}


showusage() {
  echo "USAGE: $(basename "$0") [options] <cursor name> [cursor size]"
  echo "Options:"
  echo "        -h: for display this page"
  echo "        -l: list available cursors"
  echo "        -s: store cursor name to '$prefs'"
  echo "        -r: restore cursor from '$prefs'"
  echo "        -c: curren't stored cursor"
}

rescursor() {
 if [ -e "$prefs" ]; then
    name=$(cat "$prefs"|cut -f 1 -d ":")
    size=$(cat "$prefs"|grep ":"|cut -f 2 -d ":")
    if [ -z $size ]; then
       setupcursor $name
    else
       setupcursor $name $size
    fi
 fi
}


currentcur() {
 if [ -e "$prefs" ]; then
    cat "$prefs"
 fi
}


while getopts ":rslhc" opt; do
  case $opt in
     l) listcursors && exit;;
     s) store=1;;
     r) rescursor && exit;;
     h) showusage && exit;;
     c) currentcur && exit;;
  esac
done

shift $((OPTIND-1)); OPTIND=1

if [ $# = 1 ] || [ $# = 2 ]; then
  setupcursor $1 $2
  if [ $store = 1 ]; then
     if [ ! -z $2 ] && [ ! -z $(echo $2|grep "^[0-9]*$") ]; then
        echo "$1:$2" > "$prefs"
     else
        echo "$1" > "$prefs"
     fi
 fi
else
  showusage
fi


