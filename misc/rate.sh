#!/bin/zsh

if [ "$#" -ne 1 ] ; then
  echo "Usage; $0 logfile"
  exit 1
fi
logfile="$1"

pid=$(ps -u $USER -f | awk '/bin.logstash -[f]/ {print $2}')
fileno=$(lsof -nPp $pid | grep -F "$logfile" |  awk '{ print int($4) }')
pos=$(awk '/pos:/ {print $2}' /proc/$pid/fdinfo/$fileno)
starttime=$(awk '{print $22}' /proc/$pid/stat)
curtime=$(awk '{print $1}' /proc/uptime)
lines=$(dd if="$logfile" bs=$pos count=1 | wc -l)

duration=$(($curtime - ($starttime / 100.)))
rate=$(( $lines / (0.0 + $duration) ))

echo "Duration: $duration"
echo "Rate: $rate" 

