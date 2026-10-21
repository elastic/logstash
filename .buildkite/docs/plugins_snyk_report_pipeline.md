# Logstash plugin Snyk report pipeline

Generates Snyk monitoring jobs for configured Logstash plugin and branch combinations.

## At a glance

| | |
| --- | --- |
| Platform | Buildkite |
| Pipeline | [`logstash-plugins-snyk-report-ci`](https://buildkite.com/elastic/logstash-plugins-snyk-report-ci) |
| Source | [`plugins_snyk_report_pipeline.yml`](../plugins_snyk_report_pipeline.yml) |
| Trigger | Not specified in the checked-in YAML; live provider settings disable GitHub code-trigger builds. |

## Purpose

The pipeline scans the plugin repositories listed in the checked-in matrix and submits dependency monitoring snapshots to the Logstash Snyk organization. Some entries use explicit plugin/Logstash branch pairs; entries configured to follow release branches are expanded using the active branch list.

## When it runs

No event or schedule is declared in the checked-in YAML. Live provider settings disable GitHub branch, pull-request, and tag builds. Other Buildkite invocation paths are not specified by the available source.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| Generate scan steps | Pipeline start | None declared | Installs Python dependencies, loads the plugin matrix, and uploads one Snyk scan step for each resolved plugin/branch pair. |
| Plugin scan | Once per generated pair | Generated | Checks out the configured plugin branch, optionally checks out/builds the matching Logstash branch, then runs Snyk monitoring for runtime dependency configurations. Missing plugin branches are skipped. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | [`plugins-snyk-scan-matrix.yaml`](../scripts/snyk/plugins-scan/plugins-snyk-scan-matrix.yaml); release-branch entries are resolved from the remote artifacts API. |
| Outputs | Snyk monitoring records; no Buildkite artifact paths are declared. |
| Secrets | Generated scan commands use `SNYK_TOKEN`, retrieved from Vault; its value is not included. |
| Agents | GCP multi-JDK Ubuntu 22.04 family image, `n2-standard-4`, 32 GB disk. |

## Operational notes

The YAML contains only the generator/uploader. Generated commands clone plugin repositories and may clone and bootstrap Logstash for entries that specify a Logstash branch.

## Sources

- Pipeline: [`plugins_snyk_report_pipeline.yml`](../plugins_snyk_report_pipeline.yml)
- Generator: [`generate-steps.py`](../scripts/snyk/plugins-scan/generate-steps.py)
- Plugin matrix: [`plugins-snyk-scan-matrix.yaml`](../scripts/snyk/plugins-scan/plugins-snyk-scan-matrix.yaml)
- Live pipeline: [Buildkite](https://buildkite.com/elastic/logstash-plugins-snyk-report-ci)
