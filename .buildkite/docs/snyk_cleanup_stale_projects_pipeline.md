# Logstash Snyk stale-project cleanup pipeline

Removes Snyk artifact-scan projects whose version references are no longer active in the Logstash version manifest.

## At a glance

| | |
| --- | --- |
| Platform | Buildkite |
| Pipeline | [`logstash-artifact-snyk-cleanup-ci`](https://buildkite.com/elastic/logstash-artifact-snyk-cleanup-ci) |
| Source | [`snyk_cleanup_stale_projects_pipeline.yml`](../snyk_cleanup_stale_projects_pipeline.yml) |
| Trigger | Not specified in the checked-in YAML; live provider settings disable GitHub code-trigger builds. |

## Purpose

The cleanup script scopes its query to the `logstash-artifact` Snyk target, compares project target references with active release and snapshot versions, and deletes stale projects.

## When it runs

No event or schedule appears in the checked-in YAML. Live provider settings disable GitHub branch, pull-request, and tag builds; the available sources do not establish other Buildkite invocation paths.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| Cleanup stale Snyk projects | Pipeline start | None declared | Bootstraps the VM agent, installs Python dependencies, obtains `SNYK_TOKEN` through Vault, and runs the cleanup script. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | Remote active release/snapshot version manifest; optional `DRY_RUN=true` makes the script report rather than delete. |
| Outputs | Logs and Buildkite annotations for successful or failed deletions; no artifact paths are declared. |
| Secrets | `SNYK_TOKEN` is required by the script and populated from Vault. Its value is not included. |
| Access | The token must permit the script's Snyk organization/target/project API operations. |

## Operational notes

The script exits on failures to load active versions or resolve the Snyk organization/target. Project deletion failures are reported through a separate annotation from successful deletions.

## Sources

- Pipeline: [`snyk_cleanup_stale_projects_pipeline.yml`](../snyk_cleanup_stale_projects_pipeline.yml)
- Cleanup script: [`cleanup-stale-projects.py`](../scripts/snyk/cleanup-artifact-stale-projects/cleanup-stale-projects.py)
- Version source: [logstash-versions.yml](https://github.com/logstash-plugins/.ci/blob/1.x/logstash-versions.yml)
- VM bootstrap: [`vm-agent.sh`](../scripts/common/vm-agent.sh)
- Live pipeline: [Buildkite](https://buildkite.com/elastic/logstash-artifact-snyk-cleanup-ci)
