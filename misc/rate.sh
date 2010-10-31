#!/bin/zsh

if [ "$#" -ne 1 ] ; then
  echo "Usage; $0 logfile"
  exit 1
fi
logfile="$1"

pid=$(ps -u $USER -f | awk '/bin.logstash -[f]/ {print $2}')
fileno=$(lsof -nPp $pid | grep -F "$logfile" |  awk '{ print int($4) }')
pos=$(awk '/pos:/ {print $2}' /proc/$pid/fdinfo/$fileno)
size=$(ls -ld "$logfile" | awk '{print $5}')
starttime=$(awk '{print $22}' /proc/$pid/stat)
curtime=$(awk '{print $1}' /proc/uptime)
lines=$(dd if="$logfile" bs=$pos count=1 2> /dev/null | wc -l)
percent=$(printf "%.2f%%" $(( ($pos / ($size + 0.0)) * 100 )))

duration=$(($curtime - ($starttime / 100.)))
rate=$(( $lines / (0.0 + $duration) ))

ps --no-header -o "pid user args" -p $pid
echo "Duration: $duration"
echo "Lines: $lines (position: $pos, $percent)"
echo "Rate: $rate" 

