# Logstash exhaustive tests pipeline

Generates and uploads a broad operating-system, architecture, packaging, Docker, and acceptance test matrix.

## At a glance

| | |
| --- | --- |
| Platform | Buildkite |
| Pipeline | [`logstash-exhaustive-tests-pipeline`](https://buildkite.com/elastic/logstash-exhaustive-tests-pipeline) |
| Source | [`exhaustive_tests_pipeline.yml`](../exhaustive_tests_pipeline.yml) |
| Trigger | Branch builds for `main`, numeric `major.minor`, and `major.x` branches; also targeted by the scheduler. |

## Purpose

The live pipeline description identifies cross-operating-system exhaustive testing. The checked-in entry point generates test steps rather than enumerating the runtime matrix in static YAML.

## When it runs

Live Buildkite provider settings enable branch builds only when the branch matches `^main$`, `^[0-9]+\.[0-9]+$`, or `^[0-9]+\.x$`; GitHub pull-request builds are disabled. The scheduler targets this pipeline, excluding `main` in that scheduled invocation. See the [scheduler configuration](https://buildkite.com/elastic/logstash-pipeline-scheduler) for current timing. The entry step skips successfully when all changed files match `^docs/.*`.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| Exhaustive tests pipeline | Pipeline start | None declared | Checks docs-only changes, installs YAML tooling, runs `generate-steps.py`, and uploads its output. |
| Generated pull-request suite | Generated | None declared | Reuses steps from `pull_request_pipeline.yml`. |
| Generated compatibility tests | Generated | None declared | Chooses one random Linux image per OS family and one Windows image from `vm-images.json`, unless `LINUX_OS` or `WINDOWS_OS` overrides selection; runs unit tests. |
| Generated Linux packaging acceptance | Generated | Build step before OS tests | Builds deb/rpm/tar artifacts, then runs acceptance tests on the configured Linux distribution set. `ACCEPTANCE_LINUX_OSES` can replace the default list. |
| Generated Docker, SRE, and ARM64 acceptance | Generated | ARM64 tests depend on cross-build artifact step | Tests Docker flavors, Observability SRE acceptance, and ARM64 packages built on x86_64 and tested on ARM64 workers. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | Branch name and checkout diff; optional `LINUX_OS`, `WINDOWS_OS`, and comma-separated `ACCEPTANCE_LINUX_OSES`. |
| Outputs | Buildkite-uploaded steps; package artifacts passed between generated build and acceptance steps. |
| Artifacts | Generated build steps publish package files required by downstream tests. |
| Retry | The static step reports rendering errors and exits; generated test steps generally retry automatically up to three times. |

## Operational notes

The static YAML is only the generator/uploader, not the full matrix. The generator reads the checked-in `vm-images.json` and `pull_request_pipeline.yml`; it also retrieves prerequisites at runtime. The DRA snapshot acceptance pipeline is separate.

## Sources

- Pipeline: [`exhaustive_tests_pipeline.yml`](../exhaustive_tests_pipeline.yml)
- Generator: [`generate-steps.py`](../scripts/exhaustive-tests/generate-steps.py)
- Image matrix: [`vm-images.json`](../scripts/common/vm-images.json)
- Docs-only check: [`check-files-changed.sh`](../scripts/common/check-files-changed.sh)
- Shared PR steps: [`pull_request_pipeline.yml`](../pull_request_pipeline.yml)
- Live pipeline: [Buildkite](https://buildkite.com/elastic/logstash-exhaustive-tests-pipeline)
- Scheduler: [Buildkite](https://buildkite.com/elastic/logstash-pipeline-scheduler)
