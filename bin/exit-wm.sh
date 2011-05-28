#!/bin/bash
# Name:     exit-wm
# About:    simple "logout" gui for wms
# Author:   grimi <grimi at poczta dot fm>
# License:  GNU GPL v3
# Required: grep,procps(pkill)
# Required: zenity or Xdialog or xterm+dialog+cat
# Required: consolekit+dbus or sudo


case ${LANG%.*} in
  "pl_PL")
    USSD="  > Nie zapomnij dodać komendy shutdown do /etc/sudoers <"
    ERXD=">>> Uwaga: zainstaluj zenity albo xdialog albo dialog+xterm. <<<"
    MESG="Wybierz właściwą opcję:"
    MOPT="Opcja"
    MSEL="Wybór"
    LOGO="Wyloguj"
    REST="Uruchom ponownie"
    HALT="Wyłącz"
  ;;
  *)
    USSD="  > Don't forget add shutdown command to /etc/sudoers <"
    ERXD=">>> Warning: install zenity or xdialog or dialog+xterm. <<<"
    MESG="Select right option:"
    MOPT="Option"
    MSEL="Select"
    LOGO="Logout"
    REST="Reboot"
    HALT="Shutdown"
  ;;
esac


NAME="${0##*/}"

ZENITY="$(type -p zenity)"
if [ -z "$ZENITY" ]; then
   XDIALOG="$(type -p Xdialog)"
fi
if [ -z "$XDIALOG" ]; then
  DIALOG="$(type -p dialog)"
  XTERM="$(type -p xterm)"
  if [ -z "$DIALOG" ] || [ -z "$XTERM" ]; then
    echo "$ERXD" ; exit 1
  fi
fi


killwm() {
  pkill -SIGKILL -u $USER
}


haltsys() {
  sleep 0.5
  dbus-send --system --print-reply --dest=org.freedesktop.ConsoleKit \
       /org/freedesktop/ConsoleKit/Manager org.freedesktop.ConsoleKit.Manager.Stop || {
    if [ "$(sudo -n -l shutdown -h now)" != "" ]; then
      sudo shutdown -h now
    fi
  }
  killwm
}


rebootsys() {
  sleep 0.5
  dbus-send --system --print-reply --dest=org.freedesktop.ConsoleKit \
       /org/freedesktop/ConsoleKit/Manager org.freedesktop.ConsoleKit.Manager.Restart || {
    if [ "$(sudo -n -l shutdown -r now)" != "" ]; then
      sudo shutdown -r now
    fi
  }
  killwm
}


if [ -n "$ZENITY" ]; then
  OPTIO="$(zenity --title "$NAME" --text "$MESG" --list --radiolist --column "$MSEL" --column "$MOPT" TRUE "$LOGO" FALSE "$REST" FALSE "$HALT")"
elif [ -n "$XDIALOG" ]; then
  OPTIO="$(Xdialog --stdout --no-tags --title "$NAME" --radiolist "$MESG" 14 43 9  "$LOGO" "$LOGO" ON "$REST" "$REST" OFF "$HALT" "$HALT" OFF)"
else
  export MESG LOGO REST HALT
  xterm -T "$NAME" -g 43x10 -e 'echo $(dialog --no-shadow --stdout --radiolist "$MESG" 10 43 9 "$LOGO" "" ON "$REST" "" OFF "$HALT" "" OFF) >/dev/shm/exit-wm.cmd'
  OPTIO="$(cat /dev/shm/exit-wm.cmd)"
  rm -f /dev/shm/exit-wm.cmd
fi

case "$OPTIO" in
  "$LOGO")  killwm ;;
  "$REST")  rebootsys ;;
  "$HALT")  haltsys ;;
esac


