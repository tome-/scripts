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
   [[ -z $1 ]] && usage

   local DESK="$1"
   local -A tab
   local -i nr=0
   local app auto cmd run

   [[ ${DESK,,} == "any" ]] && DESK=""

   for app in /etc/xdg/autostart/*.desktop; do
      tab[${app##*/}]="$app"
   done
   for app in ~/.config/autostart/*.desktop; do
      tab[${app##*/}]="$app"
   done

   for app in "${tab[@]}"; do
      auto=0
      if ( ! grep -i "hidden=true" "$app"|grep -ivq "#.*hidden" ); then
         (grep -iw "onlyshowin=.*$DESK" "$app"|grep -ivq "#.*onlyshowin") && auto=1
         if [[ $auto -ne 1 ]]; then
            (grep -i "onlyshowin=" "$app"|grep -ivq "#.*onlyshowin") || \
               { (grep -iw "notshowin=.*$DESK" "$app"|grep -ivq "#.*notshowin") || auto=1; }
         fi
         if [[ $auto -eq 1 ]]; then
            cmd="$(grep -iw 'exec=*' "$app")"
            if [[ -n $TESTMODE ]]; then
               nr+=1
               echo -e "$nr) $app:\n\t ==> ${cmd:5}"
            else
               run="( sleep 0.1 && ("${cmd:5}"&) )&"
               eval "$run"
            fi
         fi
      fi
   done
}


runmode() {
   [[ -z $1 ]] && usage

   local file="$1"
   local cmd term run

   [[ $file == ${file%.desktop} ]] && file+=".desktop"

   if [[ ${file##*/} == $file ]]; then
      if [[ -f ${XDG_DATA_HOME:-$HOME/.local/share}/applications/$file ]]; then
         file="${XDG_DATA_HOME:-$HOME/.local/share}/applications/$file"
      elif [[ -f /usr/share/applications/$file ]]; then
         file="/usr/share/applications/$file"
      fi
   fi

   if [[ -f $file ]]; then
      cmd="$(grep -iw 'exec=.*' "$file"|grep -m1 -iv "#.*exec")"
      cmd="${cmd:5}" ; cmd="${cmd%%\%*}"
      term="$(grep -i 'terminal=true' "$file")"
      if [[ -n $term ]]; then
         term="xterm -e "
      fi
      if [[ -n $TESTMODE ]]; then
         echo -e "${file##*/}:\n\t ==> ${term}${cmd}"
      else
         run="( sleep 0.1 && ("${term}${cmd}"&) )&"
         eval "$run"
      fi
   fi
}



[[ -z $1 ]] && usage

while [[ -n $1 ]]; do
   case "$1" in
      -t) TESTMODE=1 ;;
      -a) autostart "$2" ; break ;;
      -r) runmode "$2" ; break ;;
      *)  usage ;;
   esac
   shift
done


# vim: set et sts=3 sw=3 ts=3 :

