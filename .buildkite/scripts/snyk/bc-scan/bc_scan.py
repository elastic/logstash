#!/usr/bin/env python3
"""
Snyk SBOM scanning for active Logstash build candidates (BCs).

A BC is active when the unified-release staging pointer
(https://staging.elastic.co/latest/<version>.json) exists for a version that
has not shipped yet (its tarball is not on artifacts.elastic.co). Each BC is
monitored in Snyk under its own target with target_reference set to the
staging build id (for example 9.5.7-29c32e8e), so respins are tracked
separately.

Subcommands:
  generate  Print Buildkite steps that scan every active BC not already in Snyk.
  cleanup   Delete BC projects whose build id is no longer active (shipped or
            superseded by a respin).

Environment variables:
  SNYK_TOKEN  Snyk API token (required)
  FORCE_SCAN  If "true", generate rescans BCs that already exist in Snyk (default: "false")
  DRY_RUN     If "true", cleanup only logs what it would delete (default: "false")
"""

import os
import re
import subprocess
import sys

import requests
import yaml
from requests.adapters import HTTPAdapter, Retry

YAML_HEADER = '# yaml-language-server: $schema=https://raw.githubusercontent.com/buildkite/pipeline-schema/main/schema.json\n'
VERSIONS_URL = "https://raw.githubusercontent.com/logstash-plugins/.ci/1.x/logstash-versions.yml"
STAGING_LATEST_URL = "https://staging.elastic.co/latest/{version}.json"
GA_ARTIFACT_URL = "https://artifacts.elastic.co/downloads/logstash/logstash-{version}-linux-aarch64.tar.gz"
BC_ARTIFACT_NAME = "logstash-{version}-linux-aarch64.tar.gz"

SNYK_REST_BASE = "https://api.snyk.io"
SNYK_REST_VERSION = "2024-10-15"
SNYK_ORG_SLUG = "logstash"
BC_REMOTE_REPO_URL = "logstash-artifact-bc"
IN_BUILDKITE = os.environ.get("BUILDKITE") == "true"


def http_session(token: str = None) -> requests.Session:
    session = requests.Session()
    retries = Retry(total=5, backoff_factor=1, status_forcelist=[429, 500, 502, 503, 504],
                    allowed_methods=None)
    session.mount("https://", HTTPAdapter(max_retries=retries))
    if token:
        session.headers.update({
            "Authorization": f"token {token}",
            "Content-Type": "application/vnd.api+json",
        })
    return session


def env_flag(name: str) -> bool:
    return os.environ.get(name, "false").lower() == "true"


def snyk_token() -> str:
    token = os.environ.get("SNYK_TOKEN")
    if not token:
        print("Error: SNYK_TOKEN environment variable is required", file=sys.stderr)
        sys.exit(1)
    return token


# --- BC discovery ---

def candidate_versions(http: requests.Session) -> list:
    """Versions that may have a BC: next patch of each release plus each snapshot version.

    Both sources are used because logstash-versions.yml can lag behind a release.
    """
    resp = http.get(VERSIONS_URL, timeout=30)
    resp.raise_for_status()
    data = yaml.safe_load(resp.text)

    candidates = set()
    for version in data.get("releases", {}).values():
        m = re.fullmatch(r"(\d+)\.(\d+)\.(\d+)", str(version))
        if m:
            candidates.add(f"{m[1]}.{m[2]}.{int(m[3]) + 1}")
    for version in data.get("snapshots", {}).values():
        m = re.fullmatch(r"(\d+\.\d+\.\d+)-SNAPSHOT", str(version))
        if m:
            candidates.add(m[1])

    return sorted(candidates, key=lambda v: tuple(int(p) for p in v.split(".")))


def is_shipped(http: requests.Session, version: str) -> bool:
    resp = http.head(GA_ARTIFACT_URL.format(version=version), timeout=30, allow_redirects=True)
    if resp.status_code == 200:
        return True
    if resp.status_code == 404:
        return False
    resp.raise_for_status()
    raise RuntimeError(f"Unexpected status {resp.status_code} checking GA artifact for {version}")


def staging_build(http: requests.Session, version: str):
    """Return the latest staging build for version, or None when no BC exists."""
    resp = http.get(STAGING_LATEST_URL.format(version=version), timeout=30)
    if resp.status_code == 404:
        return None
    resp.raise_for_status()
    latest = resp.json()

    manifest_resp = http.get(latest["manifest_url"], timeout=60)
    manifest_resp.raise_for_status()
    packages = manifest_resp.json()["projects"]["logstash"]["packages"]
    artifact = BC_ARTIFACT_NAME.format(version=version)
    if artifact not in packages:
        raise RuntimeError(f"{artifact} not found in {latest['manifest_url']}")

    return {
        "version": version,
        "build_id": latest["build_id"],
        "summary_url": latest["summary_url"],
        "artifact_url": packages[artifact]["url"],
    }


def active_bcs(http: requests.Session) -> list:
    """All active BCs. Any unexpected HTTP error aborts so cleanup never acts on partial data."""
    bcs = []
    for version in candidate_versions(http):
        build = staging_build(http, version)
        if build is None:
            print(f"{version}: no staging build", file=sys.stderr)
            continue
        if is_shipped(http, version):
            print(f"{version}: {build['build_id']} already shipped", file=sys.stderr)
            continue
        print(f"{version}: active BC {build['build_id']}", file=sys.stderr)
        bcs.append(build)
    return bcs


# --- Snyk ---

def resolve_org_id(snyk: requests.Session) -> str:
    resp = snyk.get(f"{SNYK_REST_BASE}/rest/orgs", params={"version": SNYK_REST_VERSION, "slug": SNYK_ORG_SLUG})
    resp.raise_for_status()
    for org in resp.json().get("data", []):
        if org.get("attributes", {}).get("slug") == SNYK_ORG_SLUG:
            return org["id"]
    print(f"Error: Could not find Snyk org '{SNYK_ORG_SLUG}'", file=sys.stderr)
    sys.exit(1)


def resolve_target_id(snyk: requests.Session, org_id: str):
    """Target id for BC projects, or None before the first BC has been monitored."""
    resp = snyk.get(f"{SNYK_REST_BASE}/rest/orgs/{org_id}/targets", params={
        "version": SNYK_REST_VERSION,
        "display_name": BC_REMOTE_REPO_URL,
        "source_types": "cli",
    })
    resp.raise_for_status()
    for target in resp.json().get("data", []):
        if target.get("attributes", {}).get("display_name") == BC_REMOTE_REPO_URL:
            return target["id"]
    return None


def list_bc_projects(snyk: requests.Session, org_id: str) -> list:
    target_id = resolve_target_id(snyk, org_id)
    if target_id is None:
        print(f"Snyk target '{BC_REMOTE_REPO_URL}' does not exist yet", file=sys.stderr)
        return []

    projects = []
    url = f"{SNYK_REST_BASE}/rest/orgs/{org_id}/projects"
    params = {"version": SNYK_REST_VERSION, "limit": 100, "target_id": target_id}
    while url:
        resp = snyk.get(url, params=params)
        resp.raise_for_status()
        body = resp.json()
        projects.extend(body.get("data", []))
        next_link = body.get("links", {}).get("next")
        url = f"{SNYK_REST_BASE}{next_link}" if next_link and next_link.startswith("/") else next_link
        params = None
    return projects


def target_reference(project: dict) -> str:
    return project.get("attributes", {}).get("target_reference", "")


def annotate(context: str, message: str, style: str) -> None:
    if IN_BUILDKITE:
        subprocess.run(["buildkite-agent", "annotate", message, "--context", context, "--style", style])


# --- Subcommands ---

def scan_step(bc: dict) -> dict:
    return {
        "label": f":mag: BC {bc['build_id']}",
        "key": f"scan-bc-{bc['build_id']}".replace(".", "-"),
        "command": (".buildkite/scripts/snyk/artifact-scan/scan-artifact.sh "
                    f"'{bc['build_id']}' '{bc['artifact_url']}' '{BC_REMOTE_REPO_URL}'"),
        "artifact_paths": [
            ".buildkite/scripts/snyk/artifact-scan/output*.csv",
            ".buildkite/scripts/snyk/artifact-scan/output*.json",
        ],
    }


def generate() -> None:
    bcs = active_bcs(http_session())

    snyk = http_session(snyk_token())
    org_id = resolve_org_id(snyk)
    scanned = {target_reference(p) for p in list_bc_projects(snyk, org_id)}

    force = env_flag("FORCE_SCAN")
    to_scan = [bc for bc in bcs if force or bc["build_id"] not in scanned]
    for bc in bcs:
        if bc not in to_scan:
            print(f"{bc['build_id']}: already in Snyk, skipping", file=sys.stderr)

    if not to_scan:
        print("No new active BC builds to scan", file=sys.stderr)
        return

    annotate("bc_scans", "BC builds scanned:<br>" + "<br>".join(
        f"<a href=\"{bc['summary_url']}\">{bc['build_id']}</a>" for bc in to_scan), "info")

    pipeline = {
        "agents": {
            "provider": "gcp",
            "imageProject": "elastic-images-prod",
            "image": "family/platform-ingest-logstash-ubuntu-2204",
            "machineType": "n2-standard-2",
            "diskSizeGb": 20,
        },
        "steps": [scan_step(bc) for bc in to_scan],
    }
    print(YAML_HEADER + yaml.dump(pipeline, default_flow_style=False, sort_keys=False))


def cleanup() -> None:
    dry_run = env_flag("DRY_RUN")

    # List projects before discovery so a project created by an overlapping run
    # after discovery is never judged against an older view of active BCs.
    snyk = http_session(snyk_token())
    org_id = resolve_org_id(snyk)
    projects = list_bc_projects(snyk, org_id)
    active = {bc["build_id"] for bc in active_bcs(http_session())}

    stale = [p for p in projects if target_reference(p) not in active]
    print(f"Stale BC projects to delete: {len(stale)}")

    deleted, failed = [], []
    for project in stale:
        label = f"{project.get('attributes', {}).get('name', 'unknown')} (build: {target_reference(project)})"
        if dry_run:
            print(f"  [DRY RUN] Would delete: {label}")
            continue
        resp = snyk.delete(f"{SNYK_REST_BASE}/rest/orgs/{org_id}/projects/{project['id']}",
                           params={"version": SNYK_REST_VERSION})
        if resp.status_code == 204:
            print(f"  Deleted: {label}")
            deleted.append(label)
        else:
            print(f"  Failed to delete: {label}: HTTP {resp.status_code}", file=sys.stderr)
            failed.append(label)

    if deleted:
        annotate("bc_deleted_projects", "Deleted BC projects:<br>" + "<br>".join(deleted), "success")
    if failed:
        annotate("bc_failed_deletions", "BC projects failed to delete:<br>" + "<br>".join(failed), "error")
        sys.exit(1)


if __name__ == "__main__":
    commands = {"generate": generate, "cleanup": cleanup}
    if len(sys.argv) != 2 or sys.argv[1] not in commands:
        print(f"Usage: {sys.argv[0]} {{{'|'.join(commands)}}}", file=sys.stderr)
        sys.exit(1)
    commands[sys.argv[1]]()
