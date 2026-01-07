#!/usr/bin/env python3

import sys
import requests
import yaml

YAML_HEADER = '# yaml-language-server: $schema=https://raw.githubusercontent.com/buildkite/pipeline-schema/main/schema.json\n'
VERSIONS_URL = "https://raw.githubusercontent.com/logstash-plugins/.ci/1.x/logstash-versions.yml"


def fetch_logstash_versions() -> dict:
    try:
        response = requests.get(VERSIONS_URL, timeout=30)
        response.raise_for_status()
        return yaml.safe_load(response.text)
    except Exception as e:
        print(f"Error: Failed to fetch logstash versions: {e}", file=sys.stderr)
        sys.exit(1)


def generate_extraction_step(version: str, version_type: str) -> dict:
    base_url = "https://snapshots.elastic.co/downloads/logstash" if version_type == 'snapshot' else "https://artifacts.elastic.co/downloads/logstash"
    artifact_url = f"{base_url}/logstash-{version}-linux-aarch64.tar.gz"
    step_key = f"extract-{version}".replace('.', '-')

    command = f"""#!/bin/bash
set -euo pipefail

export SNYK_TOKEN=$(vault read -field=token secret/ci/elastic-logstash/snyk-creds)

echo "--- Downloading Logstash {version}"
wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 5 \\
  -O logstash.tar.gz "{artifact_url}" || {{
  echo "Failed to download {version}, skipping..."
  exit 0
}}

echo "--- Extracting tarball"
tar -xzf logstash.tar.gz
extracted_dir=$(tar -tzf logstash.tar.gz | head -1 | cut -f1 -d"/")

echo "--- Running extraction via Gradle"
./gradlew extractArtifactVersions -PartifactDir="$PWD/${{extracted_dir}}" -PoutputFile="$PWD/.buildkite/scripts/snyk/artifact-scan/output.csv"

echo "--- Downloading snyk..."
cd .buildkite/scripts/snyk/artifact-scan
curl -sL --retry-max-time 60 --retry 3 --retry-delay 5 https://static.snyk.io/cli/latest/snyk-linux -o snyk
chmod +x ./snyk

echo "--- Running Snyk monitor for Logstash {version}"
# NOTE: we may need to check if our enterprise account allows SBOM yet... There may be some other options if not
./snyk monitor --experimental --file=output_sbom.json --org=logstash --target-reference={version} --project-name="logstash-artifact-{version}"

echo "--- Uploading artifacts"
buildkite-agent artifact upload "output*.csv"
buildkite-agent artifact upload "output*.json"

echo "--- Cleanup"
cd ../../../..
rm -rf "${{extracted_dir}}" logstash.tar.gz
cd .buildkite/scripts/snyk/artifact-scan
rm -f snyk output*.csv output*.json
"""

    return {
        "label": f":mag: {version}",
        "key": step_key,
        "command": command,
        "artifact_paths": [
            ".buildkite/scripts/snyk/artifact-scan/output*.csv",
            ".buildkite/scripts/snyk/artifact-scan/output*.json"
        ]
    }


def generate_pipeline() -> dict:
    versions_data = fetch_logstash_versions()
    steps = []

    if 'releases' in versions_data:
        for version in versions_data['releases'].values():
            steps.append(generate_extraction_step(version, 'release'))

    if 'snapshots' in versions_data:
        for version in versions_data['snapshots'].values():
            steps.append(generate_extraction_step(version, 'snapshot'))

    return {
        "agents": {
            "provider": "gcp",
            "imageProject": "elastic-images-prod",
            "image": "family/platform-ingest-logstash-multi-jdk-ubuntu-2204",
            "machineType": "n2-standard-2",
            "diskSizeGb": 20
        },
        "steps": steps
    }


if __name__ == "__main__":
    pipeline = generate_pipeline()
    print(YAML_HEADER + yaml.dump(pipeline, default_flow_style=False, sort_keys=False))
