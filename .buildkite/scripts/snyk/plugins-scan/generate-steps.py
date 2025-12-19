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


def should_ignore_branch(branch: str, ignore_branches: list) -> bool:
    """
    Check if a branch should be ignored based on ignore_branches patterns.
    Patterns like "7.x" will match branches starting with "7." (major version 7).
    """
    for pattern in ignore_branches:
        pattern_str = str(pattern)
        if pattern_str.endswith('.x'):
            # Extract major version from pattern like "7.x" -> "7"
            major_version = pattern_str[:-2]
            if branch.startswith(f"{major_version}."):
                return True
        elif branch == pattern_str:
            return True
    return False


def load_plugin_matrix() -> list:
    with open(MATRIX_FILE, 'r') as f:
        config = yaml.safe_load(f)
    return config.get('plugins', [])


def parse_plugin_entry(entry) -> list:
    """
    Parse a plugin entry from the matrix.
    Returns a list of (plugin_name, branch, logstash_branch) tuples.
    Entries can be either:
    - A simple string: "logstash-filter-date" -> uses default branch
    - A dict with branches as sibling key:
      {"logstash-input-http": None, "branches": ["main", "3.x"]}
    - If branches contains "use-release-branches", fetches branches from artifacts-api
    - If logstash_branch is "match-with-plugin-branches", uses same branch as plugin
    - If logstash_branch is a specific branch (e.g., "main"), uses that branch for Logstash
    """
    if isinstance(entry, str):
        return [(entry, DEFAULT_BRANCH, None)]

    if isinstance(entry, dict):
        plugin_name = None
        branches = entry.get('branches', [DEFAULT_BRANCH])
        ignore_branches = entry.get('ignore_branches', [])
        logstash_branch_config = entry.get('logstash_branch')

        for key, value in entry.items():
            if key not in ('branches', 'ignore_branches', 'logstash_branch'):
                plugin_name = key
                break

        if plugin_name is None:
            return []

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

        # Filter out ignored branches
        if ignore_branches:
            resolved_branches = [
                b for b in resolved_branches
                if not should_ignore_branch(b, ignore_branches)
            ]

        # Determine logstash branch for each plugin branch
        result = []
        for branch in set(resolved_branches):
            if logstash_branch_config == 'match-with-plugin-branches':
                logstash_branch = branch
            elif logstash_branch_config:
                logstash_branch = str(logstash_branch_config)
            else:
                logstash_branch = None
            result.append((plugin_name, branch, logstash_branch))
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
if ! git clone --depth 1 --branch {logstash_branch} https://github.com/elastic/logstash.git; then
    echo "Branch {logstash_branch} not found in logstash, skipping..."
    rm -rf {work_dir}
    exit 0
fi

echo "--- Building logstash"
cd logstash && ./gradlew clean bootstrap installDefaultGems && cd ..

export LOGSTASH_PATH="{work_dir}/logstash"

# Export Gradle property for plugins that need logstashCoreGemPath
export ORG_GRADLE_PROJECT_logstashCoreGemPath="{work_dir}/logstash/logstash-core"
"""

    command = f"""#!/bin/bash
set -euo pipefail

export JAVA_HOME="/opt/buildkite-agent/.java/adoptiumjdk_21"
export PATH="/opt/buildkite-agent/.java/bin:$JAVA_HOME:$PATH"
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
./snyk monitor --gradle --package-manager=gradle --org=logstash --project-name={plugin_name} --target-reference={branch}

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
