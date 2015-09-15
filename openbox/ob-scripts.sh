#!/bin/bash -
#===============================================================================
#
#          FILE:  ob-scripts.sh
#
#         USAGE:  ob-scripts.sh
#
#   DESCRIPTION:  openbox pipe menu generator, to edit openbox config
#
#       OPTIONS:  ---
#  REQUIREMENTS:  some  editor
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  grimi
#       COMPANY:
#       CREATED:  01.02.2011 08:02:48 CET
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error


EDITOR="xterm -g 100x30 -e vim"
OBHOME="${XDG_CONFIG_HOME:-$HOME/.config}/openbox"

SHOWCONFIGS=1
SHOWSCRIPTS=1



item() {
   # $1 = script
   echo " <item label=\"${1##*/}\">"
   echo "  <action name=\"Execute\">"
   echo "   <execute>$EDITOR \"$1\"</execute>"
   echo "  </action>"
   echo " </item>"
}

configs() {
   if [ -f "$OBHOME/autostart" ]; then
      item "$OBHOME/autostart"
   else
      item "$OBHOME/autostart.sh"
   fi
   item "$OBHOME/menu.xml"
   item "$OBHOME/rc.xml"
   item "$OBHOME/environment"
}

scripts() {
   local f
   if [ -d "$OBHOME/scripts" ]; then
      [ -n "$SHOWCONFIGS" ] && echo "<separator/>"
      echo "<menu id=\"ob-scripts-menu\" label=\"scripts\">"
      for f in "$OBHOME"/scripts/*;do
         if [ "$f" == "$OBHOME/scripts/*" ]; then
            echo " <separator label=\"empty\"/>"
            break
         fi
         item "$f"
      done
      echo "</menu>"
   fi
}


main() {
   echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
   echo "<openbox_pipe_menu>"
   [ -n "$SHOWCONFIGS" ] && configs
   [ -n "$SHOWCONFIGS" ] && scripts
   echo "</openbox_pipe_menu>"
}


### run main function ###
main


