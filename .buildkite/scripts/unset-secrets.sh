#!/bin/bash

set -euo pipefail
# Unset all variables ending with _SECRET or _TOKEN
for var in $(printenv | sed 's;=.*;;' | sort); do
  if [[ "$var" == *_SECRET || "$var" == *_TOKEN ]]; then
      unset "$var"
  fi
done