#!/bin/bash

set -euo pipefail

# Unset all variables ending with _SECRET or _TOKEN
for var in $(printenv | sed 's;=.*;;' | sort); do
  if [[ $var != "VAULT_ADDR" && ("$var" == *_SECRET || "$var" == *_TOKEN || "$var" == *VAULT* ) ]]; then
      unset "$var"
  fi
done

if command -v docker &>/dev/null; then
  DOCKER_REGISTRY="docker.elastic.co"
  docker logout $DOCKER_REGISTRY
fi
