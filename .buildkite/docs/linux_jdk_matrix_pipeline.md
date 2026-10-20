# Logstash Linux JDK matrix pipeline

Generates a matrix of Linux operating systems and JDKs and runs Logstash unit, integration, and X-Pack tests for each pair.

## At a glance

| | |
| --- | --- |
| Platform | Buildkite |
| Pipeline | [`logstash-linux-jdk-matrix-pipeline`](https://buildkite.com/elastic/logstash-linux-jdk-matrix-pipeline) |
| Source | [`linux_jdk_matrix_pipeline.yml`](../linux_jdk_matrix_pipeline.yml) |
| Trigger | Scheduled through the Logstash pipeline scheduler; other Buildkite invocations are not specified in checked-in YAML. |

## Purpose

The live pipeline describes testing Logstash across JDKs and Linux distributions. Static YAML provides defaults and uploads steps generated for every requested OS/JDK pair.

## When it runs

The scheduler targets this pipeline alongside the Windows matrix. See [Logstash pipeline scheduler](https://buildkite.com/elastic/logstash-pipeline-scheduler) for current scheduling configuration; exact timing is omitted. The live GitHub provider disables branch, pull-request, and tag builds.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| Generate matrix | Pipeline start | None declared | Expands `MATRIX_OSES` and `MATRIX_JDKS` into OS/JDK groups and uploads the generated steps. |
| Initialize annotation | Once per OS/JDK pair | None declared | Creates a Buildkite annotation table for test status. |
| Java, Ruby, integration, persistent-queue, and X-Pack tests | Once per OS/JDK pair | Annotation initialization | Runs Java and Ruby units, three integration splits, three persistent-queue splits, and X-Pack unit/integration suites. Results update the group annotation. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | `MATRIX_OSES` and `MATRIX_JDKS` are space-separated. Defaults are `ubuntu-2204` and `adoptiumjdk_21 openjdk_21 zulu_21`. |
| Outputs | Dynamically uploaded Buildkite steps and per-matrix annotation results. |
| Retry | Generated test jobs retry automatically up to three times. |
| Agents | GCP multi-JDK images, with AWS agents for Amazon Linux selections. |

## Operational notes

The static file is only the generator/uploader. The generator builds image names from each requested OS/JDK pair; the pipeline comment requires a matching multi-JDK VM image before adding an operating system.

## Sources

- Pipeline: [`linux_jdk_matrix_pipeline.yml`](../linux_jdk_matrix_pipeline.yml)
- Generator: [`generate-steps.py`](../scripts/jdk-matrix-tests/generate-steps.py)
- VM image definitions: [ci-agent-images multi-JDK configuration](https://github.com/elastic/ci-agent-images/blob/main/vm-images/platform-ingest/logstash-multi-jdk.yml)
- Live pipeline: [Buildkite](https://buildkite.com/elastic/logstash-linux-jdk-matrix-pipeline)
- Scheduler: [Buildkite](https://buildkite.com/elastic/logstash-pipeline-scheduler)
