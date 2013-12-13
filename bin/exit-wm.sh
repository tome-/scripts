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

TEST="$([ "$1" == "test" ] && echo 1 || echo "")"

ZENITY="$(type -pf zenity)"
if [ -z "$ZENITY" ]; then
  XDIALOG="$(type -pf Xdialog)"
fi
if [ -z "$XDIALOG" ]; then
  DIALOG="$(type -pf dialog)"
  XTERM="$(type -pf xterm)"
  if [ -z "$DIALOG" ] || [ -z "$XTERM" ]; then
    echo "$ERXD" ; exit 1
  fi
fi



killwm() {
  local len=${#WMTAB[@]} wm=() oi="$IFS" IFS
  if [ $TEST == 1 ] ; then
    echo ">>> in killwm"
  else
    while [ $len -gt 0 ]; do
      let len-=1
      IFS=":" wm=(${WMTAB[$len]}) && IFS="$oi"
      [ -n "$(pidof ${wm[0]})" ] && break
    done
    [ -n "${wm[1]}" ] && (${wm[1]} &)
    sleep 2 && pkill -SIGKILL ${wm[0]}
  fi
}


kill4user() {
  if [ $TEST == 1 ]; then
    echo ">>> in kill4user"
  else
    if [ "$USER" != "root" ]; then
      ps --user $USER | grep -Ev "ssh|tmux|PID" | cut -b1-5 | xargs -t pkill -SIGKILL
      #pkill -SIGKILL -u $USER
    fi
  fi
}


haltsys() {
  local PTAB=()
  if [ -n "$(type -pf pkaction)" ] && [ -n "$(type -pf systemctl)" ]; then
    PTAB=($(pkaction|grep -e "org.freedesktop.login$XDG_SESSION_ID.power-off"))
  fi
  (sleep 0.5 && kill4user)&
  if [ ${#PTAB[@]} != 0 ] && [ "${PTAB[0]##*.}" == "power-off" ]; then
    if [ $TEST == 1 ]; then
      echo "systemctl poweroff"
    else
      systemctl poweroff
    fi
  elif [ -n "$(sudo -n -l poweroff)" ]; then
    if [ $TEST == 1 ]; then
      echo "sudo poweroff"
    else
      sudo poweroff
    fi
  elif [ -n "$(sudo -n -l shutdown -h now)" ]; then
    if [ $TEST == 1 ]; then
      echo "sudo shutdown -h now"
    else
      sudo shutdown -h now
    fi
  fi
}


rebootsys() {
  local PTAB=()
  if [ -n "$(type -pf pkaction)" ] && [ -n "$(type -pf systemctl)" ]; then
    PTAB=($(pkaction|grep -e "org.freedesktop.login$XDG_SESSION_ID.reboot"))
  fi
  (sleep 0.5 && kill4user)&
  if [ ${#PTAB[@]} != 0 ] && [ "${PTAB[0]##*.}" == "reboot" ]; then
    if [ $TEST == 1 ]; then
      echo "systemctl reboot"
    else
      systemctl reboot
    fi
  elif [ -n "$(sudo -n -l reboot)" ]; then
    if [ $TEST == 1 ]; then
      echo "sudo reboot"
    else
      sudo reboot
    fi
  elif [ -n "$(sudo -n -l shutdown -r now)" ]; then
    if [ $TEST == 1 ]; then
      echo "sudo shutdown -r now"
    else
      sudo shutdown -r now
    fi
  fi
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


# vim:set ts=2 sw=2 sts=2 et:

