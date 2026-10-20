# Buildkite pipelines

This index covers the checked-in Buildkite pipeline definitions in `.buildkite/`. Each page describes the local YAML and referenced scripts; generated-step pipelines include a specific note that the YAML is only the uploader and does not show the complete runtime flow. Live Buildkite links identify the corresponding configured pipelines. Trigger details are described only where available from the repository's pull-request integration file or the live scheduler/provider configuration.

## Pipelines

| Definition | Documentation |
| --- | --- |
| [`aarch64_pipeline.yml`](aarch64_pipeline.yml) | [Logstash aarch64 pipeline](docs/aarch64_pipeline.md) |
| [`benchmark_marathon_pipeline.yml`](benchmark_marathon_pipeline.yml) | [Benchmark marathon](docs/benchmark_marathon_pipeline.md) |
| [`benchmark_pipeline.yml`](benchmark_pipeline.yml) | [Snapshot benchmark](docs/benchmark_pipeline.md) |
| [`dra_pipeline.yml`](dra_pipeline.yml) | [DRA pipeline](docs/dra_pipeline.md) |
| [`exhaustive_tests_pipeline.yml`](exhaustive_tests_pipeline.yml) | [Exhaustive tests](docs/exhaustive_tests_pipeline.md) |
| [`health_report_tests_pipeline.yml`](health_report_tests_pipeline.yml) | [Health Report tests](docs/health_report_tests_pipeline.md) |
| [`linux_jdk_matrix_pipeline.yml`](linux_jdk_matrix_pipeline.yml) | [Linux JDK matrix](docs/linux_jdk_matrix_pipeline.md) |
| [`logstash_artifact_scan_pipeline.yml`](logstash_artifact_scan_pipeline.yml) | [Artifact Snyk scan](docs/logstash_artifact_scan_pipeline.md) |
| [`plugins_snyk_report_pipeline.yml`](plugins_snyk_report_pipeline.yml) | [Plugin Snyk report](docs/plugins_snyk_report_pipeline.md) |
| [`pull_request_pipeline.yml`](pull_request_pipeline.yml) | [Pull request pipeline](docs/pull_request_pipeline.md) |
| [`serverless_integration_pipeline.yml`](serverless_integration_pipeline.yml) | [Serverless integration](docs/serverless_integration_pipeline.md) |
| [`smart_exhaustive_tests_pipeline.yml`](smart_exhaustive_tests_pipeline.yml) | [Smart exhaustive tests](docs/smart_exhaustive_tests_pipeline.md) |
| [`snapshot_release_acceptance_pipeline.yml`](snapshot_release_acceptance_pipeline.yml) | [Snapshot and release artifact acceptance](docs/snapshot_release_acceptance_pipeline.md) |
| [`snyk_cleanup_stale_projects_pipeline.yml`](snyk_cleanup_stale_projects_pipeline.yml) | [Snyk stale-project cleanup](docs/snyk_cleanup_stale_projects_pipeline.md) |
| [`supported_plugins_test_pipeline.yml`](supported_plugins_test_pipeline.yml) | [Supported plugins tests](docs/supported_plugins_test_pipeline.md) |
| [`trigger_pipelines.yml`](trigger_pipelines.yml) | [Pipeline scheduler](docs/trigger_pipelines.md) |
| [`version_bump_pipeline.yml`](version_bump_pipeline.yml) | [Version bump](docs/version_bump_pipeline.md) |
| [`windows_jdk_matrix_pipeline.yml`](windows_jdk_matrix_pipeline.yml) | [Windows JDK matrix](docs/windows_jdk_matrix_pipeline.md) |

## Source coverage

This directory contains 18 root-level `.buildkite/*.yml` pipeline definitions, and each is linked above. Nested YAML files under `.buildkite/scripts/` are scenario or runtime configuration, not additional pipeline definitions. Buildkite schedules are maintained remotely; current scheduled targets are linked from the relevant pages, without copying schedule timings. The remote version/branch manifests used by some generators are linked in the corresponding source sections.
