#!/bin/bash
# Name:     deskrun
# About:    starts .desktops files ( local and sys )
# Author:   grimi <grimi at poczta dot fm>
# License:  GNU GPL v3
# Required: bashv4,grep,eval

shopt -s nullglob


usage() {
   echo "USAGE: [-t] [-a <desktop name>] [-r <.desktop file>]"
   echo "   -t:   test mode, not run, show only what's to be executed"
   echo "   -a:   autostart mode, as arg desktop name"
   echo "   -r:   run mode, as arg desktop file (full path or just name)"
   exit 1
}


autostart() {
   [ -z "$1" ] && usage

   local DESK="$1"
   local -A tab
   local app auto nr cmd

   for app in /etc/xdg/autostart/*.desktop; do
      tab[${app##*/}]="$app"
   done
   for app in ~/.config/autostart/*.desktop; do
      tab[${app##*/}]="$app"
   done

   for app in ${tab[@]}; do
      if ( ! grep -iq "hidden=true" "$app" ); then
         auto="$(grep -wi "onlyshowin=.*$DESK" "$app")"
         if [ -z "$auto" ]; then
            grep -wiq "onlyshowin=" "$app" || \
               (grep -wiq "notshowin=.*$DESK" "$app" || auto=1)
         fi
         if [ -n "$auto" ]; then
            cmd="$(grep -i 'exec=' "$app")"
            if [ -n "$TESTMODE" ]; then
               (( nr++ ))
               echo -e "$nr) $app:\n\t ==> ${cmd:5}"
            else
               ( sleep 0.1 && eval "${cmd:5}" )&
            fi
         fi
      fi
   done
}


runmode() {
   [ -z "$1" ] && usage

   local file="$1"
   local cmd

   [ "$file" == "${file%.desktop}" ] && file+=".desktop"

   if [ "${file##*/}" == "$file" ]; then
      if [ -f "$XDG_DATA_HOME/applications/$file" ]; then
         file="$XDG_DATA_HOME/applications/$file"
      elif [ -f "/usr/share/applications/$file" ]; then
         file="/usr/share/applications/$file"
      fi
   fi

   if [ -f "$file" ]; then
      cmd="$(grep -m 1 -i 'exec=' "$file")"
      if [ -n "$TESTMODE" ]; then
         echo -e "${file##*/}:\n\t ==> ${cmd:5}"
      else
         ( sleep 0.1 && eval exec "${cmd:5}" )&
      fi
   fi
}



[ -z "$1" ] && usage

while [ -n "$1" ]; do
   case "$1" in
      -t) TESTMODE=1 ;;
      -a) autostart "$2" ; break ;;
      -r) runmode "$2" ; break ;;
      *)  usage ;;
   esac
   shift
done


