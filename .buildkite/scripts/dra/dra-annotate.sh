#!/usr/bin/env bash
##
##  Downloads the DRA manifest from the dra-prep step, extracts build_id
##  and version, and annotates the build with a link to the workflow's
##  published summary.
##
##  The rendered summary only exists once unified-release-dra-processing
##  publishes it to the final location.
##
##  Invoked from the generated DRA sub-pipeline (generatesteps.py). Kept as a
##  standalone script because Buildkite interpolates inline command:'s ${VAR}
##  references at job pickup, which would eat local variables set inside the
##  command block.
##

set -euo pipefail

WORKFLOW="${1:?workflow required}"

buildkite-agent artifact download "artifacts/dra/logstash/*/manifest-*.json" . --step "logstash_dra_prep"
manifest=$(find artifacts/dra/logstash -name "manifest-*.json" | head -1)
prefix=$(jq -er '.prefix' "${manifest}")
prefix="${prefix#/}"
prefix="${prefix%/}"
build_id=$(jq -er '.build_id' "${manifest}")
version=$(jq -er '.version' "${manifest}")
url="https://artifacts-${WORKFLOW}.elastic.co/${prefix}/${build_id}/summary-${version}.html"

printf "**%s summary link:** [%s](%s)\n" "${WORKFLOW}" "${url}" "${url}" | buildkite-agent annotate --style=success --append
