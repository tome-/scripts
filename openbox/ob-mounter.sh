#!/bin/bash
# Name:     ob-mounter.sh
# About:    mounting volumes support for openbox
# Author:   grimi <grimi at poczta dot fm>
# License:  GNU GPL v3
# Requires: grep
# Requires: pmount,eject,[udisks: for usb detaching]
# Requires: or udisks
# Note:     mounting partions by pmount is posible,
# Note:     after adding to /etc/pmount.allow 4x: /dev/sda[1-9]

set -o nounset
shopt -s nullglob


# file managers ... ----------------------------------------
# ',' = set label  ; ':' = cd to mount point
FILEMANS=(pcmanfm "xterm -e mc","midnight commander" ":xterm")

# --- some configs -----------------------------------------
UDISKS=$(type -p udisks)
NOTIFY=$(type -p notify-send)
NICON="/usr/share/icons/gnome/32x32/devices/"
NISUFF=".png"
SHOWPARTS=1
SHOWSYSPARTS=0
USEUDISKS=1
# ----------------------------------------------------------



# --- messages ---
case ${LANG%_*} in
   pl)
      OPWITHMSG="Otwórz w"
      UMOUNTMSG="Odmountuj"
      MOUNTMSG="Montuj"
      EJECTMSG="Wysuń"
      PARTMSG="partycja"
      UMOUNTEDMSG="został odmontowany"
      EJECTEDMSG="został wysunięty"
   ;;
   *)
      OPWITHMSG="Open with"
      UMOUNTMSG="UnMount"
      MOUNTMSG="Mount"
      EJECTMSG="Eject"
      PARTMSG="partition"
      UMOUNTEDMSG="was unmounted"
      EJECTEDMSG="was ejected"
   ;;
esac



# --- variables ---
declare -a USBTAB CDTAB PARTAB

# --- constans ---
declare -r DTYPE_USB=0 DTYPE_CDROM=1 DTYPE_PART=2
declare -r DINF_TYPE=0 DINF_LABEL=1 DINF_DEV=2 DINF_MPATH=3 DINF_SYS=4
declare -r DTYPETAB=(usb cdrom $PARTMSG)
declare -r ICONTAB=(${NICON}drive-removable-media${NISUFF} ${NICON}drive-cdrom${NISUFF} ${NICON}drive-harddisk${NISUFF})




# --- functions ---
mounter() {
   # $1 = devinfo
   if [[ $USEUDISKS == 1 && -n "$UDISKS" ]]; then
      echo "udisks --mount \"$(getinfo "$1" $DINF_DEV)\""
   else
      echo "pmount -e \"$(getinfo "$1" $DINF_DEV)\" \"$(getinfo "$1" $DINF_LABEL)\""
   fi
}
umounter() {
   # $1 = devinfo
   if [[ $USEUDISKS == 1 && -n "$UDISKS" ]]; then
      echo "udisks --unmount \"$(getinfo "$1" $DINF_DEV)\"|grep -iq \"failed\" ; [[ \$? != 0 ]]"
   else
      echo "pumount \"$(getinfo "$1" $DINF_DEV)\""
   fi
}
ejecter() {
   # $1 = dev , $2 = dtype
   local tab=(eject eject)
   if [[ $USEUDISKS == 1 && -n "$UDISKS" ]]; then
      tab=("udisks --detach" "udisks --eject")
   else
      if  [[ -n "$UDISK" ]]; then
         tab[$DTYPE_USB]="udisks --detach"
      fi
   fi
   echo "${tab[$2]} \"$1\""
}
makeinfo() {
   # $1 = dev
   local medi typ=$DTYPE_PART lab dev mnt dm sys=0
   medi="$(udevadm info --query=property --name="$1"|grep -e "ID_BUS=usb" -e "ID_TYPE=cd" \
      -e "PARTITION=" -e "FS_TYPE=swap" -e "LABEL_ENC=" -e "UUID_ENC=" -e "DEVNAME=")" || return
   lab="${medi/*LABEL_ENC=/}" ; [[ "${lab}" == "${medi}" ]] && {
      lab="${medi/*UUID_ENC=/}" ; [[ "${lab}" == "${medi}" ]] && return ; }
   lab=(${lab}) ; dev=(${medi/*DEVNAME=/})
   mnt=($(grep -w -e "${dev[0]}" -e "/dev/disk/by-label/${lab[0]}" /etc/mtab))
   [[ ${#mnt[@]} != 6 ]] && mnt="" || mnt="${mnt[1]//\\040/ }"
   [[ "${medi}" != "${medi/=usb/}" ]] && typ=$DTYPE_USB
   [[ "${medi}" != "${medi/=cd/}" ]] && typ=$DTYPE_CDROM
   [[ "${medi}" != "${medi/=swap/}" ]] && return
   if [[ $typ -eq $DTYPE_PART ]]; then
      [[ $SHOWPARTS -ne 1 ]] && return
      if [[ -n "$mnt" ]]; then
         for dm in / /boot /home /tmp /usr /var; do
            [[ "$mnt" == "$dm" ]] && {
               [[ $SHOWSYSPARTS -ne 1 ]] && return
               sys=1; break; }
         done
      fi
   fi
   echo -e "${typ}:${lab[0]}:${dev[0]}:${mnt}:${sys}"
}
getinfo() {
   # $1 = devinfo , $2 = info type
   local IFS=":" ; local tab=($1)
   echo "${tab[$2]}"
}
ejectableusb() {
   # $1 = devinfo usb
   local ejdev ejdevp ejdevm dev noeject=0
   ejdevp="$(getinfo "$1" $DINF_DEV)" ; ejdev="${ejdevp/[1-9]/}"
   if [[ "$ejdev" != "$ejdevp" ]]; then
      for dev in "${USBTAB[@]}"; do
         if [[ -n "$(getinfo "$dev" $DINF_MPATH)" ]]; then
            ejdevm="$(getinfo "$dev" $DINF_DEV)"
            [[ "$ejdev" == "${ejdevm/[1-9]/}" ]] && { noeject=1 ; break; }
         fi
      done
   fi
   return $noeject
}
mountitem() {
   # $1 = devinfo
   echo "  <item label=\"$MOUNTMSG\">"
   echo "   <action name=\"execute\">"
   echo "    <execute>$(mounter "$1")</execute>"
   echo "   </action>"
   echo "  </item>"
}
umountitem() {
   # $1 = devinfo
   local cmd="$(umounter "$1")"
   if [[ -n "$NOTIFY" ]]; then
      cmd="sh -c '$cmd &amp;&amp; notify-send -t 2000 -i \"${ICONTAB[$(getinfo "$1" $DINF_TYPE)]}\" \"$(getinfo "$1" $DINF_LABEL):  $UMOUNTEDMSG.\"'"
   fi
   echo "  <item label=\"$UMOUNTMSG\">"
   echo "   <action name=\"execute\">"
   echo "    <execute>$cmd</execute>"
   echo "   </action>"
   echo "  </item>"
}
ejectitem() {
   # $1 = devinfo
   local medi="$(getinfo "$1" $DINF_DEV)"
   local cmd dtype=$(getinfo "$1" $DINF_TYPE)
   if [[ $dtype == $DTYPE_USB ]]; then
      medi="${medi/[1-9]/}"
   fi
   cmd="$(ejecter "$medi" $dtype)"
   if [[ -n "$NOTIFY" ]]; then
      cmd="sh -c '$cmd &amp;&amp; notify-send -t 2000 -i \"${ICONTAB[$dtype]}\" \"$(getinfo "$1" $DINF_LABEL):  $EJECTEDMSG.\"'"
   fi
   echo "  <item label=\"$EJECTMSG\">"
   echo "   <action name=\"execute\">"
   echo "    <execute>$cmd</execute>"
   echo "   </action>"
   echo "  </item>"
}
devi2menu() {
   # $1 = devinfo
   local cmd fmn fm title cdir x
   local l=${#FILEMANS[@]} dtype=$(getinfo "$1" $DINF_TYPE)
   local lab="$(getinfo "$1" $DINF_LABEL)"
   [[ "${lab/__/}" ==  "$lab" ]] && title="${lab//_/__}" || title="$lab"
   local mntpath="$(getinfo "$1" $DINF_MPATH)"
   [[ -n "$mntpath" ]] && title="[${title}]"
   echo " <menu id=\"$lab-menu\" label=\"$title\">"
   echo "  <separator label=\"$(getinfo "$1" $DINF_DEV): $lab\"/>"
   for (( x=0 ; $x < $l ; x++ )); do
      cdir=0 ; fm="${FILEMANS[$x]}" ; fmn="$fm"
      if [[ "${fm}" != "${fm/*,/}" ]]; then
         fmn="${fm/*,/}" ; fm="${fm/,*/}"
      fi
      if [[ "${fm:0:1}" == ":" ]]; then
         fm="${fm:1}" ; fmn="${fmn:1}" ; cdir=1
      fi
      echo "  <item label=\"$OPWITHMSG $fmn\">"
      if [[ -z "$mntpath" ]]; then
         cmd="sh -c '$(mounter "$1") &amp;&amp; "
         if [[ $cdir == 1 ]]; then
            cmd+="cd \"/media/$lab\" &amp;&amp; exec $fm'"
         else
            cmd+="exec $fm \"/media/$lab\"'"
         fi
      else
         if [[ $cdir == 1 ]]; then
            cmd="sh -c 'cd \"$mntpath\" &amp;&amp; exec $fm'"
         else
            cmd="$fm \"$mntpath\""
         fi
      fi
      echo "   <action name=\"execute\">"
      echo "    <execute>$cmd</execute>"
      echo "   </action>"
      echo "  </item>"
   done
   if [[ $(getinfo "$1" $DINF_SYS) -eq 0 ]]; then
      echo "  <separator/>"
      if [[ -n "$mntpath" ]]; then
         umountitem "$1"
      else
         mountitem "$1"
         if [[ $dtype == $DTYPE_CDROM ]]; then
            ejectitem "$1"
         elif [[ $dtype == $DTYPE_USB ]]; then
            ejectableusb "$1" && ejectitem "$1"
         fi
      fi
   fi
   echo " </menu>"
}
devsmenu() {
   local numofdevs devi
   (( numofdevs=${#USBTAB[@]}+${#CDTAB[@]}+${#PARTAB[@]} ))
   if [[ $numofdevs == 0 ]];  then
      echo "<separator label=\"ob-pmount\"/>"
   fi
   if [[ ${#USBTAB[@]} != 0 ]]; then
      echo " <separator label=\"usb\"/>"
      for devi in "${USBTAB[@]}"; do
          devi2menu "$devi" $DTYPE_USB
      done
   fi
   if [[ ${#CDTAB[@]} != 0 ]]; then
      echo " <separator label=\"cdrom\"/>"
      for devi in "${CDTAB[@]}"; do
          devi2menu "$devi" $DTYPE_CDROM
      done
   fi
   if [[ ${#PARTAB[@]} != 0 ]]; then
      echo " <separator label=\"$PARTMSG\"/>"
      for devi in "${PARTAB[@]}"; do
          devi2menu "$devi" $DTYPE_PART
      done
   fi
}
splitdevs() {
   local dev dtype dinf
   for dev in /dev/{sr[0-9],disk/by-uuid/*}; do
      dinf="$(makeinfo "$dev")"
      if [[ -n "$dinf" ]]; then
         dtype="$(getinfo "$dinf" "$DINF_TYPE")"
         case $dtype in
            $DTYPE_CDROM)
               CDTAB[${#CDTAB[@]}]="$dinf" ;;
            $DTYPE_USB)
               USBTAB[${#USBTAB[@]}]="$dinf" ;;
            $DTYPE_PART)
               PARTAB[${#PARTAB[@]}]="$dinf" ;;
         esac
      fi
   done
}



########## Begin menu gen ####################################

splitdevs
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
echo "<openbox_pipe_menu>"
devsmenu
echo "</openbox_pipe_menu>"


