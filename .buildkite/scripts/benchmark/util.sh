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
