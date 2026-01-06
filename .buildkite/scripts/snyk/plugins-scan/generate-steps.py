#!/usr/bin/env python3
"""
Generates Buildkite pipeline steps for Snyk plugin scans.
Reads plugin configuration from plugins-snyk-scan-matrix.yaml and generates
a step for each plugin/branch combination to run snyk monitor.
"""

import os
import sys

import requests
from requests.adapters import HTTPAdapter, Retry
import yaml

YAML_HEADER = '# yaml-language-server: $schema=https://raw.githubusercontent.com/buildkite/pipeline-schema/main/schema.json\n'
DEFAULT_BRANCH = "main"
RELEASE_BRANCHES_URL = "https://storage.googleapis.com/artifacts-api/snapshots/branches.json"

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
MATRIX_FILE = os.path.join(SCRIPT_DIR, "plugins-snyk-scan-matrix.yaml")

# Cache for release branches to avoid multiple fetches
_release_branches_cache = None


def slugify_bk_key(key: str) -> str:
    mapping_table = str.maketrans({'.': '_', '/': '-'})
    return key.translate(mapping_table)


def call_url_with_retry(url: str, max_retries: int = 5, delay: int = 1) -> requests.Response:
    schema = "https://" if "https://" in url else "http://"
    session = requests.Session()
    retries = Retry(total=max_retries, backoff_factor=delay, status_forcelist=[408, 502, 503, 504])
    session.mount(schema, HTTPAdapter(max_retries=retries))
    return session.get(url)


def fetch_release_branches() -> list:
    """
    Fetch release branches from artifacts-api.
    Returns list of branch names (e.g., ["7.17", "8.19", "9.1", "9.2", "9.3", "main"]).
    """
    global _release_branches_cache
    if _release_branches_cache is not None:
        return _release_branches_cache

    try:
        response = call_url_with_retry(RELEASE_BRANCHES_URL)
        response.raise_for_status()
        data = response.json()
        _release_branches_cache = data.get('branches', [])
        return _release_branches_cache
    except Exception as e:
        print(f"Warning: Failed to fetch release branches: {e}", file=sys.stderr)
        return []


def load_plugin_matrix() -> list:
    with open(MATRIX_FILE, 'r') as f:
        config = yaml.safe_load(f)
    return config.get('plugins', [])


def parse_plugin_entry(entry) -> list:
    """
    Parse a plugin entry from the matrix.
    Returns a list of (plugin_name, branch, logstash_branch) tuples.
    Entries can be either:
    - A simple string: "logstash-filter-date" -> uses default branch, no logstash
    - A dict with scan_branches: explicit list of {branch, logstash} pairs
    - A dict with branches: list of plugin branches
    """
    if isinstance(entry, str):
        return [(entry, DEFAULT_BRANCH, None)]

    if isinstance(entry, dict):
        scan_branches = None

        for key, value in entry.items():
            plugin_name = key
            if isinstance(value, dict):
                scan_branches = value.get('scan_branches')

        # If scan_branches is defined, use it directly (explicit branch pairs)
        if scan_branches:
            result = []
            for pair in scan_branches:
                branch = str(pair.get('branch', DEFAULT_BRANCH))
                logstash_branch = str(pair.get('logstash')) if pair.get('logstash') else None
                result.append((plugin_name, branch, logstash_branch))
            return result

        # Convert branch values to strings
        branches = [str(branch) for branch in branches]

        # Handle 'use-release-branches' special case
        resolved_branches = []
        for branch in branches:
            if branch == 'use-release-branches':
                release_branches = fetch_release_branches()
                resolved_branches.extend(release_branches)
            else:
                resolved_branches.append(branch)

        # Build result for each branch
        result = []
        for branch in set(resolved_branches):
            result.append((plugin_name, branch, None))
        return result

    return []


def generate_snyk_step(plugin_name: str, branch: str, logstash_branch: str = None) -> dict:
    """Generate a Buildkite step for running snyk monitor on a plugin."""
    step_key = slugify_bk_key(f"snyk-{plugin_name}-{branch}")
    if plugin_name == 'logstash-filter-elastic_integration':
        repo_url = f"https://github.com/elastic/{plugin_name}.git"
    else:
        repo_url = f"https://github.com/logstash-plugins/{plugin_name}.git"

    work_dir = "/opt/buildkite-agent/ls-plugins-snyk-scan"

    # Build logstash clone and bootstrap command if logstash_branch is specified
    logstash_clone_cmd = ""
    if logstash_branch:
        logstash_clone_cmd = f"""
echo "--- Cloning logstash (branch: {logstash_branch})"
git clone --depth 1 --branch {logstash_branch} https://github.com/elastic/logstash.git

echo "--- Building logstash"
cd logstash && ./gradlew clean bootstrap installDefaultGems && cd ..

export LOGSTASH_PATH="{work_dir}/logstash"

# Export Gradle property for plugins that need logstashCoreGemPath
export ORG_GRADLE_PROJECT_logstashCoreGemPath="{work_dir}/logstash/logstash-core"
"""

    command = f"""#!/bin/bash
set -euo pipefail

source .buildkite/scripts/common/vm-agent-multi-jdk.sh
export SNYK_TOKEN=$(vault read -field=token secret/ci/elastic-logstash/snyk-creds)

# Use isolated directory to avoid settings.gradle conflicts
rm -rf {work_dir}
mkdir -p {work_dir}
cd {work_dir}
{logstash_clone_cmd}
echo "--- Cloning {plugin_name} (branch: {branch})"
if ! git clone --depth 1 --branch {branch} {repo_url}; then
    echo "Branch {branch} not found in {plugin_name}, skipping..."
    rm -rf {work_dir}
    exit 0
fi
cd {plugin_name}

echo "--- Downloading snyk..."
curl -sL --retry-max-time 60 --retry 3 --retry-delay 5 https://static.snyk.io/cli/latest/snyk-linux -o snyk
chmod +x ./snyk

echo "--- Running Snyk monitor for {plugin_name} on branch {branch}"
# LS core resolves the gems so Gemfile needs to be excluded
# .buildkite, .ci path may contain python/other projects not necessary to scan
# eventually using --all-projects is good because snyk may detect CVEs through other package managers like maven, gradle, (ruby excluded) etc.. 
./snyk monitor --all-projects --exclude=Gemfile,.buildkite,.ci,vendor.json --org=logstash --target-reference={branch}

# Cleanup
rm -rf {work_dir}
"""

    return {
        "label": f":snyk: {plugin_name} ({branch})",
        "key": step_key,
        "command": command
    }


def generate_pipeline() -> dict:
    """Generate the complete Buildkite pipeline structure."""
    plugins = load_plugin_matrix()

    steps = []
    for entry in plugins:
        plugin_branches = parse_plugin_entry(entry)
        for plugin_name, branch, logstash_branch in plugin_branches:
            step = generate_snyk_step(plugin_name, branch, logstash_branch)
            steps.append(step)


    return {
        "agents": {
            "provider": "gcp",
            "imageProject": "elastic-images-prod",
            "image": "family/platform-ingest-logstash-multi-jdk-ubuntu-2204",
            "machineType": "n2-standard-4",
            "diskSizeGb": 32
        },
        "steps": steps
    }


if __name__ == "__main__":
    pipeline = generate_pipeline()
    print(YAML_HEADER + yaml.dump(pipeline, default_flow_style=False, sort_keys=False))
