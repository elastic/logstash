#!/usr/bin/env bash
##
##  Downloads build artifacts from Buildkite storage and stages them into
##  artifacts/ for the elastic/dra-prep plugin.
##
##  Each run of logstash-dra-snapshot-pipeline / logstash-dra-staging-pipeline
##  builds packages for exactly one workflow (WORKFLOW_TYPE is fixed per
##  pipeline slug), so no snapshot/staging filename filtering is needed here.
##

set -euo pipefail

source ./$(dirname "$0")/common.sh

echo "--- Restoring artifacts"
buildkite-agent artifact download "build/logstash*" .
buildkite-agent artifact download "build/distributions/**/*" .

echo "--- Normalizing artifact permissions"
sudo chown -R :1000 build
chmod -R a+r build/*
chmod -R a+w build

FINAL_VERSION="$(./$(dirname "$0")/../common/qualified-version.sh)"
mv "build/distributions/dependencies-reports/logstash-${FINAL_VERSION}.csv" "build/distributions/dependencies-${FINAL_VERSION}.csv"

echo "--- Preparing artifacts"
mkdir -p artifacts
find build -maxdepth 1 -type f -name "logstash-*" -exec cp {} artifacts/ \;
find build/distributions -maxdepth 1 -type f -exec cp {} artifacts/ \;

if ! ls artifacts/* >/dev/null 2>&1; then
  echo "ERROR: no artifacts found in artifacts/" >&2
  exit 1
fi

echo "Staged artifacts:"
ls -1 artifacts/
