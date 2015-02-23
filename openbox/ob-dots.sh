#!/bin/bash -
#===============================================================================
#
#          FILE:  ob-dots.sh
#
#         USAGE:  ob-dots.sh
#
#   DESCRIPTION:  openbox pipe menu generator, to edit dots configs
#
#       OPTIONS:  ---
#  REQUIREMENTS:  some  editor
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  grimi
#       COMPANY:
#       CREATED:  24.02.2013
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error


EDITOR="xterm -g 100x30 -e vim"

DOTS=(bashrc xinitrc Xdefaults Xresources xprofile xsession vimrc asoundrc conkyrc tmux.conf)
BINS="${XDG_DATA_HOME:-$HOME/.local/share}/bin"

SUBDMENU=0
SHOWBINS=1
BINSTAB=()
MAXBINS=20
STEPBINS=$MAXBINS
IBIN=0


if [[ -d $BINS ]]; then
   if [[ $SHOWBINS -eq 1 ]]; then
      for f in "$BINS"/*; do
         [[ $f == "$BINS/*" ]] && break
         BINSTAB+=("$f")
      done
      unset f
   fi
fi



item() {
   # $1 = script
   echo " <item label=\"${1##*/}\">"
   echo "  <action name=\"Execute\">"
   echo "   <execute>$EDITOR \"$1\"</execute>"
   echo "  </action>"
   echo " </item>"
}


dots() {
   local f
   if [ "$SUBDMENU" == 1 ]; then
      echo "<menu id=\"ob-dots-menu\" label=\"scripts\">"
   fi
   if [ ${#DOTS[@]} -eq 0 ]; then
      echo " <separator label=\"empty\"/>"
   else
      for f in ${DOTS[@]}; do
         [[ -f $HOME/.$f ]] && item "$HOME/.$f"
      done
   fi
   if [ "$SUBDMENU" == 1 ]; then
      echo "</menu>"
   fi
}


bins() {
   local mb=${#BINSTAB[@]} l="===&gt;"
   if [[ $mb -gt 0 ]]; then
      if [[ $IBIN -eq 0 ]]; then
         echo " <separator/>"
         l="bin"
      fi
      echo "<menu id=\"ob-dots-bin-$IBIN-menu\" label=\"$l\">"
      while [[ $IBIN -lt $mb ]]; do
         item "${BINSTAB[$IBIN]}"
         let IBIN+=1
         if [[ $IBIN -eq $STEPBINS ]]; then
            let STEPBINS+=$MAXBINS
            bins
         fi
      done
      echo "</menu>"
   fi
}


main() {
   echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
   echo "<openbox_pipe_menu>"
   dots
   if [ "$SHOWBINS" == 1 ]; then
      bins
   fi
   echo "</openbox_pipe_menu>"
}


### run main function ###
main


