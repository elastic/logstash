# Logstash artifact Snyk scan pipeline

Removes stale Snyk artifact-scan projects, then generates Snyk monitoring steps for active Logstash release and snapshot artifacts.

## At a glance

| | |
| --- | --- |
| Platform | Buildkite |
| Pipeline | [`logstash-artifacts-snyk-report-ci`](https://buildkite.com/elastic/logstash-artifacts-snyk-report-ci) |
| Source | [`logstash_artifact_scan_pipeline.yml`](../logstash_artifact_scan_pipeline.yml) |
| Trigger | Not specified in the checked-in YAML; live provider settings disable GitHub code-trigger builds. |

## Purpose

The pipeline discovers Logstash versions from the Logstash plugins CI version manifest and scans their Linux ARM64 tarball artifacts with Snyk. The generated monitor records an SBOM target reference for each version.

Before the scan, it deletes the projects under the `logstash-artifact` Snyk target whose version is no longer in the manifest. Snyk keeps testing every stored project against new advisories, so a project for a removed version can open new issues until it is deleted. Running the cleanup in the daily scan keeps that window to one day.

## When it runs

No event or schedule is declared in the checked-in YAML. Live provider settings disable GitHub branch, pull-request, and tag builds; other Buildkite invocation paths are not exposed in the checked-in source.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| Cleanup stale Snyk projects | Pipeline start | None declared | Bootstraps the VM agent, installs Python dependencies, obtains `SNYK_TOKEN` through Vault, and deletes `logstash-artifact` projects whose version is not in the manifest. |
| Generate scan steps | After cleanup, also when cleanup fails | `wait` with `continue_on_failure` | Fetches release/snapshot versions from the remote `.ci` manifest and uploads one generated step per unique version. |
| Scan artifact | Once per generated version | Generated | Downloads the Linux ARM64 tarball, extracts dependency versions, runs Snyk SBOM monitoring, and uploads CSV/JSON scan artifacts. A failed download is logged and treated as a successful skip. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | The remote `logstash-versions.yml` releases and snapshots list. For the cleanup step, an optional `DRY_RUN=true` makes the script report rather than delete. |
| Outputs | Buildkite artifacts matching `output*.csv` and `output*.json`. Buildkite annotations for deleted projects and failed deletions. |
| Secrets | The cleanup step and the scan helper use the `SNYK_TOKEN` environment variable populated from Vault; its value is not included. |
| Agents | GCP Ubuntu 22.04 family image, `n2-standard-2`, 20 GB disk for generated scan steps. |

## Operational notes

The checked-in YAML runs the cleanup, then installs Python dependencies and uploads generated steps; scan jobs are not statically enumerated. The generator processes Linux ARM64 tarballs, not every distribution artifact.

The cleanup script exits on failures to load active versions or resolve the Snyk organization/target, so it does not delete projects when the manifest is unavailable. A cleanup failure fails the build but does not stop the scan.

## Sources

- Pipeline: [`logstash_artifact_scan_pipeline.yml`](../logstash_artifact_scan_pipeline.yml)
- Cleanup script: [`cleanup-stale-projects.py`](../scripts/snyk/cleanup-artifact-stale-projects/cleanup-stale-projects.py)
- VM bootstrap: [`vm-agent.sh`](../scripts/common/vm-agent.sh)
- Generator: [`generate-steps.py`](../scripts/snyk/artifact-scan/generate-steps.py)
- Scan runner: [`scan-artifact.sh`](../scripts/snyk/artifact-scan/scan-artifact.sh)
- Dependency extraction: [`extract_versions.rb`](../scripts/snyk/artifact-scan/extract_versions.rb)
- Version source: [logstash-versions.yml](https://github.com/logstash-plugins/.ci/blob/1.x/logstash-versions.yml)
- Live pipeline: [Buildkite](https://buildkite.com/elastic/logstash-artifacts-snyk-report-ci)
