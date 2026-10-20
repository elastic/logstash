# Logstash aarch64 pipeline

Runs Logstash unit, integration, persistent-queue, X-Pack, and Docker acceptance tests on ARM64 agents.

## At a glance

| | |
| --- | --- |
| Platform | Buildkite |
| Pipeline | [`logstash-aarch64-pipeline`](https://buildkite.com/elastic/logstash-aarch64-pipeline) |
| Source | [`aarch64_pipeline.yml`](../aarch64_pipeline.yml) |
| Trigger | Scheduled through the Logstash pipeline scheduler; other Buildkite invocations are not described in the checked-in YAML. |

## Purpose

The live pipeline description identifies this as the ARM64 exhaustive test pipeline. Its checked-in steps exercise Ruby and Java units, standard and persistent-queue integration tests, X-Pack tests, and Docker acceptance tests on an ARM64 worker.

## When it runs

The live scheduler targets this pipeline. See [Logstash pipeline scheduler](https://buildkite.com/elastic/logstash-pipeline-scheduler) for current scheduling configuration; timing is intentionally omitted here. The live pipeline provider has GitHub branch and pull-request builds disabled. The YAML does not define other triggers.

## Execution flow

The two declared groups contain independent test steps; every step requests up to three automatic retries. Docker acceptance runs for both `full` and `oss` flavors.

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| Testing Phase | Group step | None declared | Ruby and Java unit tests; three-way regular integration tests; three-way persistent-queue integration tests; X-Pack unit and integration tests. |
| Acceptance Phase | Group step | None declared | Runs Docker acceptance tests for `full` and `oss` with `ARCH=aarch64`. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | Buildkite checkout; ARM64 agent image `platform-ingest-logstash-ubuntu-2204-aarch64`. |
| Outputs | Test results; no artifact paths are declared. |
| Retry | Each active test step retries automatically up to three times. |
| Trigger access | Live provider settings disable GitHub branch, pull-request, and tag builds. |

## Operational notes

All active tests source the VM bootstrap helper before running. An older Vagrant-based acceptance matrix is commented out and is not part of the uploaded steps.

## Sources

- Pipeline: [`aarch64_pipeline.yml`](../aarch64_pipeline.yml)
- Agent bootstrap: [`vm-agent.sh`](../scripts/common/vm-agent.sh)
- Live pipeline: [Buildkite](https://buildkite.com/elastic/logstash-aarch64-pipeline)
- Scheduler: [Buildkite](https://buildkite.com/elastic/logstash-pipeline-scheduler)
