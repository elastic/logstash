# Logstash snapshot and release artifact acceptance pipeline

Generates acceptance tests for Logstash snapshot or released package versions.

## At a glance

| | |
| --- | --- |
| Platform | Buildkite |
| Pipeline | [`logstash-artifacts-acceptance`](https://buildkite.com/elastic/logstash-artifacts-acceptance) |
| Source | [`snapshot_release_acceptance_pipeline.yml`](../snapshot_release_acceptance_pipeline.yml) |
| Trigger | Not specified in the checked-in YAML; live provider settings disable GitHub code-trigger builds. |

## Purpose

The generator reads the Logstash versions manifest maintained in the plugins CI repository, then creates package-acceptance tests across supported architectures and operating systems.

## When it runs

No event or schedule is declared in the checked-in YAML. Live provider settings disable GitHub branch, pull-request, and tag builds. Other Buildkite invocation paths are not visible in the checked-in source.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| Generate acceptance steps | Pipeline start | None declared | Fetches release/snapshot versions and uploads a group of generated steps for each version and fixed package/architecture combination. |
| Generated artifact acceptance | Once per version and matrix entry | Generated | Downloads the configured deb/rpm from snapshot or release storage, bootstraps Logstash, and runs Gradle acceptance tests against the downloaded artifact. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | `ARTIFACT_TYPE` selects `snapshot` by default or release versions for other values; the remote manifest supplies versions. |
| Outputs | Acceptance results; generated steps do not declare Buildkite artifact paths. |
| Matrix | x86_64 deb on Ubuntu 22.04; x86_64 rpm on AlmaLinux 8; ARM64 deb on Ubuntu 22.04 ARM64; ARM64 rpm on AlmaLinux 8 ARM64. |
| Agents | GCP Ubuntu or multi-JDK images and AWS ARM64 images as selected by the generated matrix. |

## Operational notes

The static YAML is only the generator/uploader. The generator's version manifest is remote and can change independently of this checkout; exact version membership is therefore not reproduced here.

## Sources

- Pipeline: [`snapshot_release_acceptance_pipeline.yml`](../snapshot_release_acceptance_pipeline.yml)
- Generator: [`generate-snapshot-release-steps.py`](../scripts/exhaustive-tests/generate-snapshot-release-steps.py)
- Acceptance runner: [`run-acceptance-from-artifact.sh`](../scripts/exhaustive-tests/run-acceptance-from-artifact.sh)
- Version source: [logstash-versions.yml](https://github.com/logstash-plugins/.ci/blob/1.x/logstash-versions.yml)
- Live pipeline: [Buildkite](https://buildkite.com/elastic/logstash-artifacts-acceptance)
