#!/bin/bash
# Name:     xdgautostart
# About:    starts autostart .desktops files ( local and sys )
# Author:   grimi <grimi at poczta dot fm>
# License:  GNU GPL v3
# Required: bashv4,grep

shopt -s nullglob


usage() {
   echo "USAGE: [-r] <desktop name>"
   echo "   -r:   run mode; default: show only what's to be executed"
   exit 1
}

if [ "$1" == "-r" ]; then
   RUNMODE=1 && shift
fi

if [ "${1/-h/}" == "" ]; then
   usage
fi

DESK="$1"

declare -A tab

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
         if [ -z "$RUNMODE" ]; then
            (( nr++ ))
            echo -e "$nr) $app:\n\t ==> ${cmd:5}"
         else
            ( sleep 0.1 && ${cmd:5} )&
         fi
      fi
   fi
done


