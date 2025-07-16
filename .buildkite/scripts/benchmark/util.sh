#!/usr/bin/env bash

arch() {
  # standardize docker name starting from Logstash 7.17.30, 8.17.9, 8.18.4 and 9.0.4
  local major=$(echo "$LS_VERSION" | cut -d. -f1)
  local minor=$(echo "$LS_VERSION" | cut -d. -f2)
  local patch=$(echo "$LS_VERSION" | cut -d. -f3 | cut -d- -f1)

  if [[ ( "$major" -eq 7 && "$minor" -eq 17 && "$patch" -ge 30 ) || \
    ( "$major" -eq 8 && "$minor" -eq 17 && "$patch" -ge 9 ) || \
    ( "$major" -eq 8 && "$minor" -eq 18 && "$patch" -ge 4 ) || \
    ( "$major" -eq 8 && "$minor" -ge 19 ) || \
    ( "$major" -eq 9 && "$minor" -eq 0 && "$patch" -ge 4 ) || \
    ( "$major" -eq 9 && "$minor" -ge 1 ) || \
    ( "$major" -ge 10 ) ]]; then

    case $(uname -m) in
        x86_64|amd64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            echo "Unsupported architecture: $(uname -m)"
            exit 1
            ;;
    esac
  else
    # old versions docker name use x86_64 or aarch prefix
    uname -m | sed -e "s|amd|x86_|" -e "s|arm|aarch|"
  fi
}

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