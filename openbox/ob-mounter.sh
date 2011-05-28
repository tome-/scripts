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
MOUNTPART=1
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
declare -a MUSBTAB MCDTAB MPARTAB


# --- constans ---
declare -r MTYPE_USB=0 MTYPE_CDROM=1 MTYPE_PART=2
declare -r DINF_TYPE=0 DINF_LABEL=1 DINF_DEV=2
declare -r ICONTAB=(drive-removable-media drive-cdrom drive-harddisk)
declare -r MTYPETAB=(usb cdrom $PARTMSG)




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
      if  [ -n "$UDISK" ]; then
         tab[$MTYPE_USB]="udisks --detach"
      fi
   fi
   echo "${tab[$2]} \"$1\""
}
makeinfo() {
   # $1 = dev
   local medi typ=$MTYPE_PART lab dev
   medi="$(udevadm info --query=property --name="$1"|grep -e "ID_BUS=usb" -e "ID_TYPE=cd" \
      -e "PARTITION=" -e "FS_TYPE=swap" -e "LABEL_ENC=" -e "UUID_ENC=" -e "DEVNAME=")" || return
   lab="${medi/*LABEL_ENC=/}" ; [[ "${lab}" == "${medi}" ]] && {
      lab="${medi/*UUID_ENC=/}" ; [[ "${lab}" == "${medi}" ]] && return ; }
   lab=(${lab}) ; dev=(${medi/*DEVNAME=/})
   #[[ "${medi}" != "${medi/PARTITION=/}" ]] && typ=$MTYPE_PART
   [[ "${medi}" != "${medi/=usb/}" ]] && typ=$MTYPE_USB
   [[ "${medi}" != "${medi/=cd/}" ]] && typ=$MTYPE_CDROM
   [[ "${medi}" != "${medi/=swap/}" ]] && return
   echo -e "${typ}:${lab[0]}:${dev[0]}"
}
getinfo() {
   # $1 = devinfo , $2 = info type
   local IFS=":" tab
   tab=($1) ; echo ${tab[$2]}
}
ismounted() {
   # $1 = devinfo
   local lab="$(getinfo "$1" $DINF_LABEL)"
   grep -qw -e "/dev/disk/by-label/$lab" -e "$(getinfo "$1" $DINF_DEV)" -e "/media/$lab" /etc/mtab
}
ejectableusb() {
   # $1 = devinfo usb
   local ejdev ejdevp ejdevm medi noeject=0
   ejdevp="$(getinfo "$1" $DINF_DEV)" ; ejdev="${ejdevp/[1-9]/}"
   if [ "$ejdev" != "$ejdevp" ]; then
      if [ ${#MUSBTAB[@]} != 0 ]; then
         for medi in "${MUSBTAB[@]}"; do
            ejdevm="$(getinfo "$medi" $DINF_DEV)"
            if [ "$ejdev" == "${ejdevm/[1-9]/}" ]; then
               noeject=1 ; break
            fi
         done
      fi
   fi
   return $noeject
}
mountitem() {
   # $1 = media
   echo "  <item label=\"$MOUNTMSG\">"
   echo "   <action name=\"execute\">"
   echo "    <execute>$(mounter "$1")</execute>"
   echo "   </action>"
   echo "  </item>"
}
umountitem() {
   # $1 = devinfo
   local cmd="$(umounter "$1")"
   if [ -n "$NOTIFY" ]; then
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
   if [ $dtype == $MTYPE_USB ]; then
      medi="${medi/[1-9]/}"
   fi
   cmd="$(ejecter "$medi" $dtype)"
   if [ -n "$NOTIFY" ]; then
      cmd="sh -c '$cmd &amp;&amp; notify-send -t 2000 -i \"${ICONTAB[$dtype]}\" \"$(getinfo "$1" $DINF_LABEL):  $EJECTEDMSG.\"'"
   fi
   echo "  <item label=\"$EJECTMSG\">"
   echo "   <action name=\"execute\">"
   echo "    <execute>$cmd</execute>"
   echo "   </action>"
   echo "  </item>"
}
mountpath() {
   # $1 = devinfo
   local mnt="$(grep -w -e "$(getinfo "$1" $DINF_DEV)" /etc/mtab)"
   mnt="${mnt##*/}" ; mnt="${mnt%% *}"
   [ "$mnt" != "" ] && mnt="/media/$mnt"
   echo -e "$mnt"
}
ismountedsys() {
   # $1 = devinfo
   for d in / /boot /home /tmp /usr /var; do
      grep -qw -e "/dev/disk/by-label/$(getinfo "$1" $DINF_LABEL) $d" \
         -e "$(getinfo "$1" $DINF_DEV) $d" /etc/mtab && return 0
   done
   return 1
}
media2menu() {
   # $1 = devinfo
   local cmd fmn fm title cdir dtype=$(getinfo "$1" $DINF_TYPE)
   local l=${#FILEMANS[@]} x=0
   local lab="$(getinfo "$1" $DINF_LABEL)"
   [ "${lab/__/}" ==  "$lab" ] && title="${lab//_/__}" || title="$lab"
   local mntpath="$(mountpath "$1")"
   echo " <menu id=\"$lab-menu\" label=\"$title\">"
   echo "  <separator label=\"${MTYPETAB[$dtype]}: $lab\"/>"
   while [[ $x < $l ]]; do
      cdir=0 ; fm="${FILEMANS[$x]}" ; fmn="$fm"
      if [ "${fm}" != "${fm/*,/}" ]; then
         fmn="${fm/*,/}" ; fm="${fm/,*/}"
      fi
      if [ "${fm:0:1}" == ":" ]; then
         fm="${fm:1}" ; fmn="${fmn:1}" ; cdir=1
      fi
      echo "  <item label=\"$OPWITHMSG $fmn\">"
      if [ -z "$mntpath" ]; then
         cmd="sh -c '$(mounter "$1") &amp;&amp; "
         if [ $cdir == 1 ]; then
            cmd+="cd \"/media/$lab\" &amp;&amp; exec $fm'"
         else
            cmd+="exec $fm \"/media/$lab\"'"
         fi
      else
         if [ $cdir == 1 ]; then
            cmd="sh -c 'cd \"/media/$lab\" &amp;&amp; exec $fm'"
         else
            cmd="$fm \"$mntpath\""
         fi
      fi
      echo "   <action name=\"execute\">"
      echo "    <execute>$cmd</execute>"
      echo "   </action>"
      echo "  </item>"
      ((x++))
   done
   echo "  <separator/>"
   if [ -n "$mntpath" ]; then
      umountitem "$1"
   else
      mountitem "$1"
      if [ $dtype == $MTYPE_CDROM ]; then
         ejectitem "$1"
      elif [ $dtype == $MTYPE_USB ]; then
         if ( ejectableusb "$1" ); then
            ejectitem "$1"
         fi
      fi
   fi
   echo " </menu>"
}
mediamenu() {
   local numofmedias media
   (( numofmedias=${#USBTAB[@]}+${#MUSBTAB[@]}+${#CDTAB[@]}+${#MCDTAB[@]}+${#PARTAB[@]}+${#MPARTAB[@]} ))
   if [ $numofmedias == 0 ];  then
      echo "<separator label=\"ob-pmount\"/>"
   fi
   if [ ${#USBTAB[@]} != 0 -o ${#MUSBTAB[@]} != 0 ]; then
      echo " <separator label=\"usb\"/>"
      if [ ${#MUSBTAB[@]} != 0 ]; then
         for media in "${MUSBTAB[@]}"; do
            media2menu "$media" $MTYPE_USB
         done
      fi
      if [ ${#USBTAB[@]} != 0 ]; then
         if [ ${#MUSBTAB[@]} != 0 ]; then
            echo " <separator/>"
         fi
         for media in "${USBTAB[@]}"; do
            media2menu "$media" $MTYPE_USB
         done
      fi
   fi
   if [ ${#CDTAB[@]} != 0 -o ${#MCDTAB[@]} != 0 ]; then
      echo " <separator label=\"cdrom\"/>" 
      if [ ${#MCDTAB[@]} != 0 ]; then
         for media in "${MCDTAB[@]}"; do
            media2menu "$media" $MTYPE_CDROM
         done
      fi
      if [ ${#CDTAB[@]} != 0 ]; then
         if [ ${#MCDTAB[@]} != 0 ]; then
            echo " <separator/>"
         fi
         for media in "${CDTAB[@]}"; do
            media2menu "$media" $MTYPE_CDROM
         done
      fi
   fi
   if [ $MOUNTPART == 1 ] && [ ${#PARTAB[@]} != 0 -o ${#MPARTAB[@]} != 0 ]; then
      echo " <separator label=\"$PARTMSG\"/>"
      if [ ${#MPARTAB[@]} != 0 ]; then
         for media in "${MPARTAB[@]}"; do
            media2menu "$media" $MTYPE_PART
         done
      fi
      if [ ${#PARTAB[@]} != 0 ]; then
         if [ ${#MPARTAB[@]} != 0 ]; then
            echo " <separator/>"
         fi
         for media in "${PARTAB[@]}"; do
            media2menu "$media" $MTYPE_PART
         done
      fi
   fi
}
splitmedias() {
   local media dtype dinf
   for media in /dev/{sr[0-9],disk/by-uuid/*}; do
      dinf="$(makeinfo "$media")"
      if [ -n "$dinf" ]; then
         dtype="$(getinfo "$dinf" "$DINF_TYPE")"
         if ( ismounted "$dinf" ); then
            case $dtype in
               $MTYPE_CDROM)
                  MCDTAB[${#MCDTAB[@]}]="$dinf" ;;
               $MTYPE_USB)
                  MUSBTAB[${#MUSBTAB[@]}]="$dinf" ;;
               $MTYPE_PART)
                  if (! ismountedsys "$dinf" ); then
                     MPARTAB[${#MPARTAB[@]}]="$dinf"
                  fi ;;
            esac
         else
            case $dtype in
               $MTYPE_CDROM)
                  CDTAB[${#CDTAB[@]}]="$dinf" ;;
               $MTYPE_USB)
                  USBTAB[${#USBTAB[@]}]="$dinf" ;;
               $MTYPE_PART)
                  PARTAB[${#PARTAB[@]}]="$dinf" ;;
            esac
         fi
      fi
   done
}



########## Begin menu gen ####################################

splitmedias
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
echo "<openbox_pipe_menu>"
mediamenu
echo "</openbox_pipe_menu>"


