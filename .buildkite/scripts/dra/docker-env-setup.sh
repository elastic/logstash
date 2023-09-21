#!/bin/bash

set -euo pipefail

DOCKER_REGISTRY="docker.elastic.co"
DOCKER_REGISTRY_SECRET_PATH="kv/ci-shared/platform-ingest/docker_registry_prod"
CI_DRA_ROLE_PATH="kv/ci-shared/release/dra-role"


function docker_login {
  DOCKER_USERNAME_SECRET=$(retry -t 5 -- vault kv get -field user "${DOCKER_REGISTRY_SECRET_PATH}")
  DOCKER_PASSWORD_SECRET=$(retry -t 5 -- vault kv get -field password "${DOCKER_REGISTRY_SECRET_PATH}")
  docker login -u "${DOCKER_USERNAME_SECRET}" -p "${DOCKER_PASSWORD_SECRET}" "${DOCKER_REGISTRY}" 2>/dev/null
  unset DOCKER_USERNAME_SECRET DOCKER_PASSWORD_SECRET
}

function release_manager_login {
  DRA_CREDS_SECRET=$(retry -t 5 -- vault kv get -field=data -format=json ${CI_DRA_ROLE_PATH})
  VAULT_ADDR_SECRET=$(echo ${DRA_CREDS_SECRET} | jq -r '.vault_addr')
  VAULT_ROLE_ID=$(echo ${DRA_CREDS_SECRET} | jq -r '.role_id')
  VAULT_SECRET_ID=$(echo ${DRA_CREDS_SECRET} | jq -r '.secret_id')
  export VAULT_ADDR_SECRET VAULT_ROLE_ID VAULT_SECRET_ID
}
