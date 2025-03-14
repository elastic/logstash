#!/bin/bash

# partition_files returns a consistent partition of the filenames given on stdin
# Usage: partition_files <partition_index> <partition_count=2> < <(ls files)
# partition_index: the zero-based index of the partition to select `[0,partition_count)`
# partition_count: the number of partitions `[2,#files]`
partition_files() (
    set -e

    local files
    # ensure files is consistently sorted and distinct
    IFS=$'\n' read -ra files -d '' <<<"$(cat - | sort | uniq)" || true

    local partition_index="${1:?}"
    local partition_count="${2:?}"

    _error () { >&2 echo "ERROR: ${1:-UNSPECIFIED}"; exit 1; }

    # safeguard against nonsense invocations
    if (( ${#files[@]} < 2 )); then
      _error "#files(${#files[@]}) must be at least 2 in order to partition"
    elif ( ! [[ "${partition_count}" =~ ^[0-9]+$ ]] ) || (( partition_count < 2 )) || (( partition_count > ${#files[@]})); then
      _error "partition_count(${partition_count}) must be a number that is at least 2 and not greater than #files(${#files[@]})"
    elif ( ! [[ "${partition_index}" =~ ^[0-9]+$ ]] ) || (( partition_index < 0 )) || (( partition_index >= $partition_count )) ; then
      _error "partition_index(${partition_index}) must be a number that is greater 0 and less than partition_count(${partition_count})"
    fi

    # round-robbin emit those in our selected partition
    for index in "${!files[@]}"; do
      partition="$(( index % partition_count ))"
      if (( partition == partition_index )); then
        echo "${files[$index]}"
      fi
    done
)

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
  if [[ "$1" == "test" ]]; then
    status=0

    SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
    file_list="$( cd "${SCRIPT_DIR}"; find . -type f )"

    # for any legal partitioning into N partitions, we ensure that
    # the combined output of `partition_files I N` where `I` is all numbers in
    # the range `[0,N)` produces no repeats and no omissions, even if the
    # input list is not consistently ordered.
    for n in $(seq 2 $(wc -l <<<"${file_list}")); do
      result=""
      for i in $(seq 0 $(( n - 1 ))); do
        for file in $(partition_files $i $n <<<"$( shuf <<<"${file_list}" )"); do
          result+="${file}"$'\n'
        done
      done

      repeated="$( uniq --repeated <<<"$( sort <<<"${result}" )" )"
      if (( $(printf "${repeated}" | wc -l) > 0 )); then
        status=1
        echo "[n=${n}]FAIL(repeated):"$'\n'"${repeated}"
      fi

      missing=$( comm -23 <(sort <<<"${file_list}") <( sort <<<"${result}" ) )
      if (( $(printf "${missing}" | wc -l) > 0 )); then
        status=1
        echo "[n=${n}]FAIL(omitted):"$'\n'"${missing}"
      fi
    done

    if (( status > 0 )); then
      echo "There were failures. The input list was:"
      echo "${file_list}"
    fi

    exit "${status}"
  else
    partition_files $@
  fi
fi