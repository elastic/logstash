#!/usr/bin/env bash

arch() { uname -m | sed -e "s|amd|x86_|" -e "s|arm|aarch|"; }

# return the min value
# usage: 
#  g: float; h: human; d: dictionary; M: month
#  min -g 3 2 5 1
#  max -g 1.5 5.2 2.5 1.2 5.7
#  max -g "null" "0"
#  min -h 25M 13G 99K 1098M
min() { printf "%s\n" "${@:2}" | sort "$1" | head -n1 ; }

max() { min ${1}r ${@:2} ; }

# return the average of values
# usage:
#   jqavg '.process.cpu.percent' m_w8b1000_*.json
#   $1: jq field
#   $2: file path in glob pattern
jqavg() {
  jq -r "$1 | select(. != null)" $2 | jq -s . | jq 'add / length'
}

# return the maximum of values
# usage:
#   jqmax '.process.cpu.percent' m_w8b1000_*.json
#   $1: jq field
#   $2: file path in glob pattern
jqmax() {
  jq -r "$1  | select(. != null)" $2 | jq -s . | jq 'max'
}

# return true if $1 is non empty and not "null"
not_empty() {
  if [[ -n "$1" && "$1" != "null" ]]; then
    return 0
  else
    return 1
  fi
}