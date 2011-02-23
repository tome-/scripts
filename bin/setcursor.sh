#!/bin/bash
# Name:    setcursor
# About:   script for setup cursor on WM's 
# Author:  grimi < grimi at poczta dot fm >
# License: GNU GPL v3

prefs="$HOME/.cursor"
store=0

listcursors() {
 local i hdir="$(pwd)"
 cd "/usr/share/icons"
 for i in *; do
   [ -f "$i/cursors/left_ptr" ] && echo "$i"
 done
 cd "$HOME/.icons"
 for i in *; do
   [ -d "$i/cursors/left_ptr" ] && echo "$i"
 done
 cd "$hdir"
}

setupcursor() {
 local i
 for i in $(listcursors); do
   if [ "$1" = "$i" ]; then
      echo "Xcursor.theme: $i"|xrdb -merge
      echo "Xcursor.size: $2"|xrdb -merge
      break
   fi
 done
}

showusage() {
  echo "USAGE: ${0##*/} [options] <cursor name> [cursor size]"
  echo "Options:"
  echo "        -h: for display this page"
  echo "        -l: list available cursors"
  echo "        -s: store cursor name to '$prefs'"
  echo "        -r: restore cursor from '$prefs'"
  echo "        -c: curren't stored cursor"
}

rescursor() {
 if [ -e "$prefs" ]; then
    local name size pref="$(cat "$prefs")"
    name="${ref%:*}" ; size="${pref#*:}"
    if [ "$name" = "$size" ]; then
       setupcursor "$name"
    else
       setupcursor "$name" "$size"
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

if [ $# = 1 -o $# = 2 ] && [ -n "$1" ]; then
  setupcursor "$1" "$2"
  if [ $store = 1 ]; then
     if [ -n "$2" ] && [ -z "${2//[0-9]/}" ]; then
        echo "$1:$2" > "$prefs"
     else
        echo "$1" > "$prefs"
     fi
 fi
else
  showusage
fi


