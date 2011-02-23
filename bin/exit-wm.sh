#!/bin/bash
# Name:     exit-wm
# About:    simple "logout" gui for wms
# Author:   grimi <grimi at poczta dot fm>
# License:  GNU GPL v3
# Required: grep,zenity or xterm+dialog
# Required: consolekit+dbus or sudo


case ${LANG%.*} in
  "pl_PL")
    USAG="Składnia: <nazwa menadżera okien>"
    USSD="  > Nie zapomnij dodać komendy shutdown do /etc/sudoers <"
    ERXD=">>> Uwaga: zainstaluj aplikacje Zenity, lub dialog+xterm. <<<"
    MESG="Wybierz właściwą opcję:"
    MOPT="Opcja"
    MSEL="Wybór"
    LOGO="Wyloguj"
    REST="Uruchom ponownie"
    HALT="Wyłącz"
  ;;
  *)
    USAG="Usage: <wm name>"
    USSD="  > Don't forget add shutdown command to /etc/sudoers <"
    ERXD=">>> Warning: install Zenity or dialog+xterm. <<<"
    MESG="Select right option:"
    MOPT="Option"
    MSEL="Select"
    LOGO="Logout"
    REST="Reboot"
    HALT="Shutdown"
  ;;
esac


zenity="$(type -p zenity)"
if [ -z "$zenity" ]; then
  dial="$(type -p dialog)"
  xtrm="$(type -p xterm)"
  if [ -z "$dial" ] || [ -z "$xtrm" ]; then
    echo "$ERXD" ; exit 1
  fi
fi



findwm() {
  for x in openbox fluxbox awesome; do
    if [ ! -z "$(pidof $x)" ]; then
       WM="$x" ; break
    fi
  done
}


if [ -z "$1" ]; then
  findwm
  if [ -z "$WM" ]; then
    echo -e "$USAG\n"
    exit
  fi
elif [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo -e "$USAG\n"
  echo -e "$USSD\n"
  exit
else
  WM="$1"
fi


killwm() {
  case $WM in
    openbox) openbox --exit;;
    fluxbox)
      if grep -i allowremoteactions ~/.fluxbox/init|grep -q true; then
        fluxbox-remote exit
      else
        kill -KILL &>/dev/null `pidof fluxbox`
      fi
    ;;
    awesome) echo "awesome.quit()"|awesome-client;;
    *) kill -KILL &>/dev/null `pidof $WM`;;
  esac
}

haltsys() {
  sleep 0.5
  dbus-send --system --print-reply --dest=org.freedesktop.ConsoleKit \
       /org/freedesktop/ConsoleKit/Manager org.freedesktop.ConsoleKit.Manager.Stop || \
  sudo shutdown -h now
  killwm
}


rebootsys() {
  sleep 0.5
  dbus-send --system --print-reply --dest=org.freedesktop.ConsoleKit \
       /org/freedesktop/ConsoleKit/Manager org.freedesktop.ConsoleKit.Manager.Restart || \
  sudo shutdown -r now
  killwm
}


if [ -n "$zenity" ]; then
  optio="$($zenity --title "$WM" --text "$MESG" --list --radiolist --column "$MSEL" --column "$MOPT" TRUE "$LOGO" FALSE "$REST" FALSE "$HALT")"
else
  export MESG LOGO REST HALT dial
  $xtrm -T "$WM" -g 43x10 -e 'echo $($dial --no-shadow --stdout --menu "$MESG" 10 43 9 "$LOGO" "" "$REST" "" "$HALT" "") >/dev/shm/exit-wm.cmd'
  cat /dev/shm/exit-wm.cmd
  optio="$(cat /dev/shm/exit-wm.cmd)"
  rm -f /dev/shm/exit-wm.cmd
fi


case "$optio" in
  "$LOGO")  killwm ;;
  "$REST")  rebootsys ;;
  "$HALT")  haltsys ;;
esac


