#!/usr/bin/env python3
"""
Cleanup stale Snyk projects created by the Logstash artifact scan pipeline.

Fetches the current active Logstash versions from logstash-versions.yml and
deletes any Snyk artifact-scan projects whose version is no longer tracked.

Environment variables:
  SNYK_TOKEN  - Snyk API token (required)
  DRY_RUN     - If "true", only log actions without performing them (default: "false")
"""

import os
import subprocess
import sys

import requests
import yaml
from requests.adapters import HTTPAdapter, Retry

SNYK_REST_BASE = "https://api.snyk.io"
SNYK_REST_VERSION = "2024-10-15"
# Only clean up projects created by the artifact scan pipeline
ARTIFACT_SCAN_REMOTE_REPO_URL = "logstash-artifact"
VERSIONS_URL = "https://raw.githubusercontent.com/logstash-plugins/.ci/1.x/logstash-versions.yml"
IN_BUILDKITE = os.environ.get("BUILDKITE") == "true"

class Annotation:
    """Lazily creates a Buildkite annotation on first item; skips entirely if unused."""

    def __init__(self, context: str, header: str, style: str):
        self._context = context
        self._header = header
        self._style = style
        self._initialized = False

    def add(self, message: str):
        if not self._initialized:
            annotate_build(self._context, f"{self._header}\n{message}",
                           self._style, append=False)
            self._initialized = True
        else:
            annotate_build(self._context, message, self._style, append=True)

def annotate_build(context: str, message: str, style: str, append: bool) -> None:
    if IN_BUILDKITE:
        cmd = ["buildkite-agent", "annotate", message, "--context", context, "--style", style]
        if append:
            cmd.append("--append")
        subprocess.run(cmd)

def get_env():
    token = os.environ.get("SNYK_TOKEN")
    if not token:
        print("Error: SNYK_TOKEN environment variable is required", file=sys.stderr)
        sys.exit(1)

    dry_run = os.environ.get("DRY_RUN", "false").lower() == "true"

    return token, dry_run


def create_session(token: str) -> requests.Session:
    session = requests.Session()
    retries = Retry(total=5, backoff_factor=1, status_forcelist=[429, 500, 502, 503, 504])
    session.mount("https://", HTTPAdapter(max_retries=retries))
    session.headers.update({
        "Authorization": f"token {token}",
        "Content-Type": "application/vnd.api+json",
    })
    return session


def fetch_active_versions() -> set:
    """Fetch current active versions from logstash-versions.yml."""

    try:
        resp = requests.get(VERSIONS_URL, timeout=30)
        resp.raise_for_status()
        data = yaml.safe_load(resp.text)
    except Exception as e:
        print(f"Error: Failed to fetch logstash versions: {e}", file=sys.stderr)
        sys.exit(1)

    versions = set()
    for section in ("releases", "snapshots"):
        if section in data:
            for version in data[section].values():
                versions.add(version)

    print(f"Active versions from logstash-versions.yml: {sorted(versions)}")
    return versions


def resolve_org_id(session: requests.Session) -> str:
    """Resolve the org UUID from the slug 'logstash' via GET /rest/orgs."""
    url = f"{SNYK_REST_BASE}/rest/orgs"
    resp = session.get(url, params={"version": SNYK_REST_VERSION})
    resp.raise_for_status()
    data = resp.json()

    for org in data.get("data", []):
        if org.get("attributes", {}).get("slug") == "logstash":
            org_id = org["id"]
            print(f"Resolved org 'logstash' UUID: {org_id}")
            return org_id

    print("Error: Could not find logstash org", file=sys.stderr)
    sys.exit(1)


def list_projects(session: requests.Session, org_id: str, **params) -> list:
    """List projects for the given org."""
    url = f"{SNYK_REST_BASE}/rest/orgs/{org_id}/projects"
    query = {
        "version": SNYK_REST_VERSION,
        "limit": 100,
    }
    query.update(params)

    resp = session.get(url, params=query)
    resp.raise_for_status()
    return resp.json().get("data", [])


def resolve_target_id(session: requests.Session, org_id: str) -> str:
    """Find the target ID for the 'logstash-artifact' target."""
    url = f"{SNYK_REST_BASE}/rest/orgs/{org_id}/targets"
    resp = session.get(url, params={
        "version": SNYK_REST_VERSION,
        "display_name": ARTIFACT_SCAN_REMOTE_REPO_URL,
        "source_types": "cli",
    })
    resp.raise_for_status()
    data = resp.json()

    for target in data.get("data", []):
        if target.get("attributes", {}).get("display_name") == ARTIFACT_SCAN_REMOTE_REPO_URL:
            target_id = target["id"]
            print(f"Resolved target '{ARTIFACT_SCAN_REMOTE_REPO_URL}' UUID: {target_id}")
            return target_id

    print(f"Error: Could not find target '{ARTIFACT_SCAN_REMOTE_REPO_URL}'", file=sys.stderr)
    sys.exit(1)


def list_artifact_projects(session: requests.Session, org_id: str) -> list:
    """List artifact-scan projects by target ID."""
    target_id = resolve_target_id(session, org_id)
    return list_projects(session, org_id, target_id=[target_id])


def delete_project(session: requests.Session, org_id: str, project_id: str, project_name: str, dry_run: bool) -> bool:
    """Delete a single project. Returns True on success, False on failure."""
    if dry_run:
        print(f"  [DRY RUN] Would delete: {project_name} ({project_id})")
        return True

    url = f"{SNYK_REST_BASE}/rest/orgs/{org_id}/projects/{project_id}"
    try:
        resp = session.delete(url, params={"version": SNYK_REST_VERSION})
        if resp.status_code == 204:
            print(f"  Deleted: {project_name} ({project_id})")
            return True
        resp.raise_for_status()
    except requests.HTTPError as e:
        print(f"  Failed to delete: {project_name} ({project_id}): {e}", file=sys.stderr)
    return False


def main():
    token, dry_run = get_env()
    session = create_session(token)

    mode_label = "[DRY RUN] " if dry_run else ""
    print(f"{mode_label}Starting cleanup of stale Snyk artifact-scan projects")

    active_versions = fetch_active_versions()
    org_id = resolve_org_id(session)

    all_projects = list_artifact_projects(session, org_id)
    print(f"Total artifact-scan projects in Snyk: {len(all_projects)}")

    stale_projects = [
        p for p in all_projects
        if p.get("attributes", {}).get("target_reference", "") not in active_versions
    ]
    print(f"Stale projects to delete (version not in logstash-versions.yml): {len(stale_projects)}")

    if not stale_projects:
        print("No stale projects found. Nothing to do.")
        return

    proj_success = Annotation("successfully_deleted_projects",
                              "<details><summary>Deleted projects:</summary>", "success")
    proj_failure = Annotation("unsuccessfully_deleted_projects",
                              "<details><summary>Projects failed to delete:</summary>", "error")

    for project in stale_projects:
        project_id = project["id"]
        project_name = project.get("attributes", {}).get("name", "unknown")
        target_ref = project.get("attributes", {}).get("target_reference", "unknown")
        label = f"{project_name} (version: {target_ref})"
        if delete_project(session, org_id, project_id, label, dry_run):
            proj_success.add(f"{label}<br>")
        else:
            proj_failure.add(f"{label}<br>")


if __name__ == "__main__":
    main()
