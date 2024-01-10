#!/usr/bin/env bash

# **********************************************************
# Returns true if current checkout compared to parent commit
# has changes ONLY matching the argument regexp
#
# Used primarily to skip running the exhaustive pipeline
# when only docs changes have happened.
# ********************************************************

if [[ -z "$1" ]]; then
  echo "Usage: $0 <regexp>"
  exit 1
fi

previous_commit=$(git rev-parse HEAD^)
changed_files=$(git diff --name-only $previous_commit)

if [[ -n "$changed_files" ]] && [[ -z "$(echo "$changed_files" | grep -vE "$1")" ]]; then
    echo "All files compared to the previous commit [$previous_commit] match the specified regex: [$1]"
    echo "Files changed:"
    git diff --name-only HEAD^
  exit 0
else
  exit 1
fi
