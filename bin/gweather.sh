#!/bin/sh
# Name:     gweather
# About:    extract weather from google, to use with conky
# Author:   grimi <grimi at poczta dot fm>
# License:  GNU GPL v3
# Required: wget,sed and conky :)

lng=${LANG%_*}

([ -z "$lng" ] || [ "${lng/C/c}" == "c" ]) && lng="en"

if [ -z "$1" ]; then
   case $lng in
      pl) echo "Składnia: ${0##*/} <miejscowość>";;
       *) echo "Usage: ${0##*/} <city name>";;
   esac
   exit 1
fi

url="http://www.google.com/ig/api?weather=${1}&hl=${lng}&oe=UTF-8"

weather=$(wget -U="Mozilla Firefox 1.0" -w 3 -o /dev/null -q -O /dev/stdout "$url"| \
         sed 's|.*<current_conditions><condition data="||g;s|<humidity.*||g')

if [ -z "$weather" ]; then
   case $lng in
      pl) echo "serwis niedostępny";;
      *) echo "servis unavailable";;
   esac
   exit 1
fi

temp=$(echo $weather|sed 's|.*temp_c data="||g;s|"/>||g')
aura=$(echo $weather|sed 's|"/><.*||g')

echo $aura": "$temp"°C"

