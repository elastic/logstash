#!/usr/bin/env python3
"""
Cleanup stale Snyk projects created by the Logstash artifact scan pipeline.

Queries the Snyk REST API for projects imported by the service account that
haven't been monitored recently, and performs either deactivation or deletion.

Usage:
  python3 cleanup.py --action deactivate
  python3 cleanup.py --action delete

Environment variables:
  SNYK_TOKEN       - Snyk API token (required)
  STALENESS_DAYS   - Number of days before a project is considered stale (default: 2)
  DRY_RUN          - If "true", only log actions without performing them (default: "false")
"""

import argparse
import os
import subprocess
import sys
from datetime import datetime, timedelta, timezone

import requests
from requests.adapters import HTTPAdapter, Retry

SNYK_REST_BASE = "https://api.snyk.io"
SNYK_REST_VERSION = "2024-10-15"
# Only clean up projects created by the artifact scan pipeline
ARTIFACT_SCAN_REMOTE_REPO_URL = "logstash-artifact"
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

    staleness_days = int(os.environ.get("STALENESS_DAYS", "2"))
    dry_run = os.environ.get("DRY_RUN", "false").lower() == "true"

    return token, staleness_days, dry_run


def create_session(token: str) -> requests.Session:
    session = requests.Session()
    retries = Retry(total=5, backoff_factor=1, status_forcelist=[429, 500, 502, 503, 504])
    session.mount("https://", HTTPAdapter(max_retries=retries))
    session.headers.update({
        "Authorization": f"token {token}",
        "Content-Type": "application/vnd.api+json",
    })
    return session


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
    """List all projects with pagination."""
    url = f"{SNYK_REST_BASE}/rest/orgs/{org_id}/projects"
    query = {
        "version": SNYK_REST_VERSION,
        "limit": 100,
        "expand": "target",
    }
    query.update(params)

    projects = []
    while url:
        resp = session.get(url, params=query)
        resp.raise_for_status()
        data = resp.json()
        projects.extend(data.get("data", []))

        next_link = data.get("links", {}).get("next")
        if next_link:
            url = f"{SNYK_REST_BASE}{next_link}" if next_link.startswith("/") else next_link
            query = {}
        else:
            url = None

    return projects


def list_stale_artifact_projects(session: requests.Session, org_id: str,
                                 cutoff_str: str) -> list:
    """List active artifact-scan projects monitored before the cutoff date."""
    projects = list_projects(session, org_id, cli_monitored_before=cutoff_str)
    print(f"Total projects monitored before cutoff: {len(projects)}")
    return [
        p for p in projects
        if p.get("attributes", {}).get("status") == "active"
        and (p.get("relationships", {}).get("target", {}).get("data", {})
             .get("attributes", {}).get("display_name", "")) == ARTIFACT_SCAN_REMOTE_REPO_URL
    ]


def list_inactive_artifact_projects(session: requests.Session, org_id: str,
                                     cutoff_str: str) -> list:
    """List inactive artifact-scan projects monitored before the cutoff date."""
    projects = list_projects(session, org_id, cli_monitored_before=cutoff_str)
    return [
        p for p in projects
        if p.get("attributes", {}).get("status") == "inactive"
        and (p.get("relationships", {}).get("target", {}).get("data", {})
             .get("attributes", {}).get("display_name", "")) == ARTIFACT_SCAN_REMOTE_REPO_URL
    ]


def deactivate_project(session: requests.Session, org_id: str, project_id: str, project_name: str, dry_run: bool) -> bool:
    """Deactivate a single project. Returns True on success, False on failure."""
    if dry_run:
        print(f"  [DRY RUN] Would deactivate: {project_name} ({project_id})")
        return True

    url = f"{SNYK_REST_BASE}/v1/org/{org_id}/project/{project_id}/deactivate"
    try:
        resp = session.post(url)
        if resp.status_code in (200, 422):
            print(f"  Deactivated: {project_name} ({project_id})")
            return True
        resp.raise_for_status()
    except requests.HTTPError as e:
        print(f"  Failed to deactivate: {project_name} ({project_id}): {e}", file=sys.stderr)
    return False


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


def delete_target(session: requests.Session, org_id: str, target_id: str, dry_run: bool) -> bool:
    """Delete an empty target. Returns True on success, False on failure."""
    if dry_run:
        print(f"  [DRY RUN] Would delete target: {target_id}")
        return True

    url = f"{SNYK_REST_BASE}/rest/orgs/{org_id}/targets/{target_id}"
    try:
        resp = session.delete(url, params={"version": SNYK_REST_VERSION})
        if resp.status_code == 204:
            print(f"  Deleted target: {target_id}")
            return True
        resp.raise_for_status()
    except requests.HTTPError as e:
        print(f"  Failed to delete target: {target_id}: {e}", file=sys.stderr)
    return False


def parse_args():
    parser = argparse.ArgumentParser(description="Cleanup stale Snyk artifact-scan projects")
    parser.add_argument("--action", required=True, choices=["deactivate", "delete"],
                        help="Action to perform: deactivate stale projects or delete inactive projects")
    return parser.parse_args()


def action_deactivate(session: requests.Session, org_id: str, staleness_days: int, dry_run: bool):
    """Find and deactivate stale active artifact-scan projects."""
    cutoff_str = (datetime.now(timezone.utc) - timedelta(days=staleness_days)).isoformat()
    print(f"Cutoff date: {cutoff_str}")

    stale_projects = list_stale_artifact_projects(session, org_id, cutoff_str)
    print(f"Found {len(stale_projects)} stale active artifact-scan project(s)")

    success = Annotation("successfully_deactivated_projects",
                              "<details><summary>Deactivated projects:</summary>", "success")
    failure = Annotation("unsuccessfully_deactivated_projects",
                              "<details><summary>Projects failed to deactivate:</summary>", "error")

    for project in stale_projects:
        project_id = project["id"]
        project_name = project.get("attributes", {}).get("name", "unknown")
        if deactivate_project(session, org_id, project_id, project_name, dry_run):
            success.add(f"{project_name} ({project_id})<br>")
        else:
            failure.add(f"{project_name} ({project_id})<br>")


def action_delete(session: requests.Session, org_id: str, staleness_days: int, dry_run: bool):
    """Find and delete inactive artifact-scan projects, then clean up empty targets."""
    cutoff_str = (datetime.now(timezone.utc) - timedelta(days=staleness_days)).isoformat()
    inactive_projects = list_inactive_artifact_projects(session, org_id, cutoff_str)
    print(f"Found {len(inactive_projects)} inactive artifact-scan project(s) to delete")

    proj_success = Annotation("successfully_deleted_projects",
                                   "<details><summary>Deleted projects:</summary>", "success")
    proj_failure = Annotation("unsuccessfully_deleted_projects",
                                   "<details><summary>Projects failed to delete:</summary>", "error")
    tgt_success = Annotation("successfully_deleted_targets",
                                  "<details><summary>Deleted targets:</summary>", "success")
    tgt_failure = Annotation("unsuccessfully_deleted_targets",
                                  "<details><summary>Targets failed to delete:</summary>", "error")

    # Delete projects and collect target IDs for cleanup
    target_ids = set()
    for project in inactive_projects:
        project_id = project["id"]
        project_name = project.get("attributes", {}).get("name", "unknown")
        target_ref = project.get("relationships", {}).get("target", {}).get("data", {}).get("id")
        if delete_project(session, org_id, project_id, project_name, dry_run):
            proj_success.add(f"{project_name} ({project_id})<br>")
            if target_ref:
                target_ids.add(target_ref)
        else:
            proj_failure.add(f"{project_name} ({project_id})<br>")

    # Clean up empty targets
    for target_id in target_ids:
        if delete_target(session, org_id, target_id, dry_run):
            tgt_success.add(f"{target_id}<br>")
        else:
            tgt_failure.add(f"{target_id}<br>")


def main():
    args = parse_args()
    token, staleness_days, dry_run = get_env()
    session = create_session(token)

    mode_label = "[DRY RUN] " if dry_run else ""
    print(f"{mode_label}Action: {args.action} | Staleness threshold: {staleness_days} days")

    org_id = resolve_org_id(session)

    if args.action == "deactivate":
        action_deactivate(session, org_id, staleness_days, dry_run)
    elif args.action == "delete":
        action_delete(session, org_id, staleness_days, dry_run)


if __name__ == "__main__":
    main()
