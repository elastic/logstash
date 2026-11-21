# Logstash BC artifact Snyk scan pipeline

Monitors active Logstash build candidates (BCs) in Snyk and removes them once they ship or are superseded.

## At a glance

| | |
| --- | --- |
| Platform | Buildkite |
| Pipeline | [`logstash-bc-artifacts-snyk-report-ci`](https://buildkite.com/elastic/logstash-bc-artifacts-snyk-report-ci) |
| Source | [`logstash_bc_artifact_scan_pipeline.yml`](../logstash_bc_artifact_scan_pipeline.yml) |
| Trigger | Schedule declared in [`catalog-info.yaml`](../../catalog-info.yaml); GitHub code-trigger builds are disabled. |

## Purpose

The release and snapshot scan in the [artifact Snyk scan pipeline](logstash_artifact_scan_pipeline.md) does not cover build candidates. This pipeline generates an SBOM for the Logstash Linux ARM64 tarball of each active BC and monitors it in Snyk, so the components of a BC can be assessed before it ships. BC projects are deleted as soon as the BC ships or is replaced by a respin, so they do not linger as stale findings.

## How active BCs are found

1. Candidate versions are the next patch of each `releases` entry and each `snapshots` entry (without `-SNAPSHOT`) in `logstash-versions.yml`.
2. For each candidate, `https://staging.elastic.co/latest/<version>.json` gives the current staging `build_id` (for example `9.5.7-29c32e8e`) and its manifest. A missing pointer means there is no BC for that version.
3. A candidate whose tarball is already on `artifacts.elastic.co` has shipped and is not active.
4. The tarball URL comes from the `logstash` project in the BC manifest, for example `https://staging.elastic.co/9.5.7-29c32e8e/downloads/logstash/logstash-9.5.7-linux-aarch64.tar.gz`.

Any unexpected HTTP error during discovery fails the step, so cleanup never runs against a partial view of active BCs.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| Logstash BC Artifact Scan | Pipeline start | None | Finds active BCs, skips any `build_id` already monitored in Snyk, and uploads one scan step per remaining BC. Uploads nothing when there is no new BC. |
| Scan BC | Once per new active BC | Generated | Runs [`scan-artifact.sh`](../scripts/snyk/artifact-scan/scan-artifact.sh) against the staged tarball with Snyk target `logstash-artifact-bc` and target reference set to the `build_id`. |
| Cleanup | After scans, even if a scan failed | Wait step | Deletes `logstash-artifact-bc` projects whose `build_id` is not an active BC. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | Remote `logstash-versions.yml`; staging `latest` pointers and BC manifests; GA artifact existence on `artifacts.elastic.co`. `FORCE_SCAN=true` rescans BCs already in Snyk. `DRY_RUN=true` makes cleanup report rather than delete. |
| Outputs | Snyk projects under target `logstash-artifact-bc`; Buildkite artifacts matching `output*.csv` and `output*.json`; annotations for scanned BCs and deleted projects. |
| Secrets | `SNYK_TOKEN` populated from Vault. Its value is not included. |
| Agents | GCP Ubuntu 22.04 family image, `n2-standard-2`, 20 GB disk for generated scan steps. |

## Operational notes

BC projects use a separate Snyk target from release and snapshot scans, so the [stale-project cleanup](snyk_cleanup_stale_projects_pipeline.md) does not touch them. Because already scanned build ids are skipped, a frequent schedule only does work when a new BC or respin appears.

## Sources

- Pipeline: [`logstash_bc_artifact_scan_pipeline.yml`](../logstash_bc_artifact_scan_pipeline.yml)
- Discovery, step generation and cleanup: [`bc_scan.py`](../scripts/snyk/bc-scan/bc_scan.py)
- Scan runner: [`scan-artifact.sh`](../scripts/snyk/artifact-scan/scan-artifact.sh)
- Version source: [logstash-versions.yml](https://github.com/logstash-plugins/.ci/blob/1.x/logstash-versions.yml)
- Live pipeline: [Buildkite](https://buildkite.com/elastic/logstash-bc-artifacts-snyk-report-ci)
