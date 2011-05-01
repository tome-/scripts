#!/bin/sh
# Name:    shterm
# About:   run program in terminal
# Author:  grimi <grimi at poczta dot fm>
# License: GNU GPL v3


usage() {
  echo "USAGE: $(basename $0) [options] <command> [filearg] [args...]"
  echo "Options:
        -g <geometry>    terminal geometry WxH
        -a <cmd & args>  run after main prog exit
        -w               don't close term, wait for hit Enter
        -n               no terminal (and ignore term specific options)
        -d               debug mode (don't run, just show cmd line)"

  exit 1
}

[ -z "$1" ] && usage

while getopts "a:g:wnd" opt; do
   case $opt in
      g) geom="-g $OPTARG";;
      a) after="$OPTARG";;
      w) wait4="echo -e '\n::: Enter :::' ; read";;
      n) noterm=1;;
      d) debug=1;;
   esac
done

shift $((OPTIND-1)); OPTIND=1

[[ -z "$1" ]] && usage

app="$1" && shift

cd "$(dirname "$app")"

if [[ -n "${1%-*}" ]]; then
   cd "$(dirname "$1")"
   arg="$(basename "$app")"
   [[ -x "$arg" ]] && app="./$arg"
   arg="$(basename "$1")"
   title="$app $(basename "$1")"
   shift
else
   title="$app"
fi


cmdline="\"$app\""
[[ -n "$arg" ]] && cmdline+=" \"$arg\""
while [[ -n "$1" ]]; do
   cmdline+=" \"$1\""
   shift
done

[[ -n "$after" ]] && cmdline+=" ; eval '$after'"

if [ -n "$debug" ]; then
   echo "$(pwd): $cmdline"
   exit
fi

if [[ -z $noterm ]]; then
  [[ -z "$wait4" ]] && wait4="sleep 5"
  xterm -T "$title" $geom -e "echo ; $cmdline ; $wait4"
else
  sh -c "$cmdline"
fi


