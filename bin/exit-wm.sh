#!/bin/bash
# Name:     exit-wm
# About:    simple "logout" gui for wms
# Author:   grimi <grimi at poczta dot fm>
# License:  GNU GPL v3
# Required: grep,procps(pidof,pkill)
# Required: zenity or Xdialog or xterm+dialog
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
    MESG="Select correct option:"
    MOPT="Option"
    MSEL="Select"
    LOGO="Logout"
    REST="Reboot"
    HALT="Halt"
  ;;
esac


WMTAB=("openbox:openbox --exit")



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
  local len=${#WMTAB[@]} wm=() oi="$IFS" IFS
  while [ $len -gt 0 ]; do
    let len-=1
    IFS=":" wm=(${WMTAB[$len]}) && IFS="$oi"
    [ -n "$(pidof ${wm[0]})" ] && break
  done
  [ -n "${wm[1]}" ] && ${wm[1]} || pkill -SIGKILL ${wm[0]}
}


kill4user() {
  [ "$USER" != "root" ] && pkill -SIGKILL -u $USER
}


haltsys() {
  (sleep 0.5 && kill4user)&
  dbus-send --system --print-reply --dest=org.freedesktop.ConsoleKit \
       /org/freedesktop/ConsoleKit/Manager org.freedesktop.ConsoleKit.Manager.Stop || {
    if [ -n "$(sudo -n -l poweroff)" ]; then
      sudo poweroff
    elif [ -n "$(sudo -n -l shutdown -h now)" ]; then
      sudo shutdown -h now
    fi
  }
}


rebootsys() {
  (sleep 0.5 && kill4user)&
  dbus-send --system --print-reply --dest=org.freedesktop.ConsoleKit \
       /org/freedesktop/ConsoleKit/Manager org.freedesktop.ConsoleKit.Manager.Restart || {
    if [ -n "$(sudo -n -l reboot)" ]; then
      sudo reboot
    elif [ -n "$(sudo -n -l shutdown -r now)" ]; then
      sudo shutdown -r now
    fi
  }
}


if [ -n "$ZENITY" ]; then
  OPTIO="$(zenity --title "$NAME" --text "$MESG" --list --radiolist --column "$MSEL" --column "$MOPT" TRUE "$LOGO" FALSE "$REST" FALSE "$HALT")"
elif [ -n "$XDIALOG" ]; then
  OPTIO="$(Xdialog --stdout --no-tags --title "$NAME" --radiolist "$MESG" 14 43 9  "$LOGO" "$LOGO" ON "$REST" "$REST" OFF "$HALT" "$HALT" OFF)"
else
  export MESG LOGO REST HALT
  xterm -T "$NAME" -g 43x10 -e 'echo $(dialog --no-shadow --stdout --radiolist "$MESG" 10 43 9 "$LOGO" "" ON "$REST" "" OFF "$HALT" "" OFF) >/dev/shm/exit-wm.cmd'
  OPTIO="$(</dev/shm/exit-wm.cmd)"
  rm -f /dev/shm/exit-wm.cmd
fi

case "$OPTIO" in
  "$LOGO")  killwm ;;
  "$REST")  rebootsys ;;
  "$HALT")  haltsys ;;
esac


