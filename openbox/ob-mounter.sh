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
declare -r ICONTAB=(drive-removable-media drive-cdrom drive-harddisk)
declare -r MTYPETAB=(usb cdrom $PARTMSG)




# --- functions ---
mounter() {
   # $1 = media
   if [[ $USEUDISKS == 1 && -n "$UDISKS" ]]; then
      echo "udisks --mount \"$1\""
   else
      echo "pmount -e \"$1\" \"$(fixlabel "$1")\""
   fi
}
umounter() {
   # $1 = media
   if [[ $USEUDISKS == 1 && -n "$UDISKS" ]]; then
      echo "udisks --unmount \"$1\"|grep -iq \"failed\" ; [[ \$? != 0 ]]"
   else
      echo "pumount \"$1\""
   fi
}
ejecter() {
   # $1 = media , $2 = mtype
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
disktype() {
   # $1 = dev name
   local info="$(udevadm info --query=property --name="$1")"
   if [ "$info" != "${info/USB/}" ]; then
      return $MTYPE_USB
   elif [ "$info" != "${info/CDROM/}" ]; then
      return $MTYPE_CDROM
   elif [ "$info" != "${info/swap/}" ]; then
      return 10
   fi
   return $MTYPE_PART
}
ismounted() {
   # $1 = media
   grep -qw -e "$1" -e "$(readlink -f "$1")" /etc/mtab
}
fixlabel() {
   # $1 = media
   local info tab=()
   info="$(udevadm info --query=property --name="$1"|grep -e "LABEL" -e "UUID")"
   if [ "${info/LABEL=/}" != "$info" ]; then
      tab=(${info/*LABEL_ENC=/})
   else
      tab=(${info/*UUID_ENC=/})
   fi
   echo -e ${tab[0]}
}
ejectableusb() {
   # $1 = media usb
   local ejdev ejdevp ejdevm medi noeject=0
   ejdevp="$(readlink -f "$1")" ; ejdev="${ejdevp/[1-9]/}"
   if [ "$ejdev" != "$ejdevp" ]; then
      if [ ${#MUSBTAB[@]} != 0 ]; then
         for medi in "${MUSBTAB[@]}"; do
            ejdevm="$(readlink -f "$medi")"
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
   # $1 = media , $2 = media type
   local cmd="$(umounter "$1")"
   if [ -n "$NOTIFY" ]; then
      cmd="sh -c '$cmd &amp;&amp; notify-send -t 2000 -i \"${ICONTAB[$2]}\" \"$(fixlabel "$1"):  $UMOUNTEDMSG.\"'"
   fi
   echo "  <item label=\"$UMOUNTMSG\">"
   echo "   <action name=\"execute\">"
   echo "    <execute>$cmd</execute>"
   echo "   </action>"
   echo "  </item>"
}
ejectitem() {
   # $1 = media , $2 = media type
   local medi="$1" cmd
   if [ $2 == $MTYPE_USB ]; then
      medi="$(readlink -f "$1")" ; medi="${medi/[1-9]/}"
   fi
   cmd="$(ejecter "$medi" $2)"
   if [ -n "$NOTIFY" ]; then
      cmd="sh -c '$cmd &amp;&amp; notify-send -t 2000 -i \"${ICONTAB[$2]}\" \"$(fixlabel "$1"):  $EJECTEDMSG.\"'"
   fi
   echo "  <item label=\"$EJECTMSG\">"
   echo "   <action name=\"execute\">"
   echo "    <execute>$cmd</execute>"
   echo "   </action>"
   echo "  </item>"
}
mountpath() {
   # $1 = media
   local mnt="$(grep -w -e "$1" -e "$(readlink -f "$1")" /etc/mtab)"
   mnt="${mnt##*/}" ; mnt="${mnt%% *}"
   [ "$mnt" != "" ] && mnt="/media/$mnt"
   echo -e "$mnt"
}
ismountedsys() {
   # $1 = dev
   for d in / /boot /home /tmp /usr /var; do
      if (grep -qw -e "$1 $d" -e "$(readlink -f "$1") $d" /etc/mtab); then
         return 0
      fi
   done
   return 1
}
media2menu() {
   # $1 = media , $2 = mediatype
   local cmd fmn fm x=0 title cdir
   local l=${#FILEMANS[@]}
   local lab="$(fixlabel "$1")"
   [ "${lab/__/}" ==  "$lab" ] && title="${lab//_/__}" || title="$lab"
   local mntpath="$(mountpath "$1")"
   echo " <menu id=\"$lab-menu\" label=\"$title\">"
   echo "  <separator label=\"${MTYPETAB[$2]}: $lab\"/>"
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
      umountitem "$1" $2
   else
      mountitem "$1"
      if [ $2 == $MTYPE_CDROM ]; then
         ejectitem "$1" $2
      elif [ $2 == $MTYPE_USB ]; then
         if ( ejectableusb "$1" ); then
            ejectitem "$1" $2
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
   local uidev nonew devtab=() medias=()
   local i=0 media medi dtype
   for media in /dev/disk/by-label/*; do
      devtab[$i]="$(readlink -f "$media")"
      medias[$i]="$media" ; ((i++))
   done
   for media in /dev/disk/by-uuid/*; do
      uidev=$(readlink -f "$media") ; nonew=
      for medi in ${devtab[@]}; do
         if [ "$uidev" == "$medi" ]; then
            nonew=1 ; break
         fi
      done
      if [ -z "$nonew" ] ; then
         medias[$i]="$uidev" ; ((i++))
      fi
   done
   for media in ${medias[@]}; do
      disktype "$media" ; dtype=$?
      if ( ismounted "$media" ); then
         case $dtype in
            $MTYPE_USB)
               MUSBTAB[${#MUSBTAB[@]}]="$media" ;;
            $MTYPE_CDROM)
               MCDTAB[${#MCDTAB[@]}]="$media" ;;
            $MTYPE_PART)
               if (! ismountedsys "$media" ); then
                  MPARTAB[${#MPARTAB[@]}]="$media"
               fi ;;
         esac
      else
         case $dtype in
            $MTYPE_USB)
               USBTAB[${#USBTAB[@]}]="$media" ;;
            $MTYPE_CDROM)
               CDTAB[${#CDTAB[@]}]="$media" ;;
            $MTYPE_PART)
               PARTAB[${#PARTAB[@]}]="$media" ;;
         esac
      fi
   done
}



########## Begin menu gen ####################################

splitmedias
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
echo "<openbox_pipe_menu>"
mediamenu
echo "</openbox_pipe_menu>"

