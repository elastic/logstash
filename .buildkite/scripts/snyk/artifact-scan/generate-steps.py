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

    return {
        "label": f":mag: {version}",
        "key": step_key,
        "command": f".buildkite/scripts/snyk/artifact-scan/scan-artifact.sh '{version}' '{artifact_url}'",
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
            "image": "family/platform-ingest-logstash-ubuntu-2204",
            "machineType": "n2-standard-2",
            "diskSizeGb": 20
        },
        "steps": steps
    }


if __name__ == "__main__":
    pipeline = generate_pipeline()
    print(YAML_HEADER + yaml.dump(pipeline, default_flow_style=False, sort_keys=False))
