#!/bin/bash
# Scans a Logstash artifact for dependencies and reports to Snyk
# Usage: ./scan-artifact.sh <version> <artifact_url>

set -euo pipefail

VERSION="$1"
ARTIFACT_URL="$2"

source .buildkite/scripts/common/vm-agent.sh

export SNYK_TOKEN=$(vault read -field=token secret/ci/elastic-logstash/snyk-creds)

echo "--- Downloading Logstash ${VERSION}"
wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 5 \
  -O logstash.tar.gz "${ARTIFACT_URL}" || {
  echo "Failed to download ${VERSION}, skipping..."
  exit 0
}

echo "--- Extracting tarball"
tar -xzf logstash.tar.gz
extracted_dir=$(tar -tzf logstash.tar.gz 2>/dev/null | head -1 | cut -f1 -d"/" || true)
if [[ -z "$extracted_dir" ]]; then
  extracted_dir="logstash-${VERSION}"
fi

echo "--- Running extraction via Gradle"
./gradlew extractArtifactVersions -PartifactDir="$PWD/${extracted_dir}" -PoutputFile="$PWD/.buildkite/scripts/snyk/artifact-scan/output.csv"

echo "--- Downloading snyk..."
cd .buildkite/scripts/snyk/artifact-scan
curl -sL --retry-max-time 60 --retry 3 --retry-delay 5 https://static.snyk.io/cli/latest/snyk-linux -o snyk
chmod +x ./snyk

echo "--- Running Snyk monitor for Logstash ${VERSION}"
./snyk sbom monitor --experimental --file=output_sbom.json --org=logstash --target-reference="${VERSION}" --project-name="logstash-artifact-${VERSION}"

echo "--- Uploading artifacts"
buildkite-agent artifact upload "output*.csv"
buildkite-agent artifact upload "output*.json"

echo "--- Cleanup"
cd ../../../..
rm -rf "${extracted_dir}" logstash.tar.gz
cd .buildkite/scripts/snyk/artifact-scan
rm -f snyk output*.csv output*.json
