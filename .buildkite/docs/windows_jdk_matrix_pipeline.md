# Logstash Windows JDK matrix pipeline

Generates a matrix of Windows releases and JDKs and runs Logstash Java and Ruby unit tests for each pair.

## At a glance

| | |
| --- | --- |
| Platform | Buildkite |
| Pipeline | [`logstash-windows-jdk-matrix-pipeline`](https://buildkite.com/elastic/logstash-windows-jdk-matrix-pipeline) |
| Source | [`windows_jdk_matrix_pipeline.yml`](../windows_jdk_matrix_pipeline.yml) |
| Trigger | Scheduled through the Logstash pipeline scheduler; other Buildkite invocations are not specified in checked-in YAML. |

## Purpose

The live pipeline describes testing Logstash across Windows releases and JDKs. The checked-in entry point supplies the default Windows/JDK pair and uploads dynamically generated test jobs.

## When it runs

The scheduler targets this pipeline alongside the Linux matrix. See [Logstash pipeline scheduler](https://buildkite.com/elastic/logstash-pipeline-scheduler) for current scheduling configuration; exact timing is omitted. The live GitHub provider disables branch, pull-request, and tag builds.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| Generate matrix | Pipeline start | None declared | Expands the requested OS/JDK pairs into groups and uploads the steps. |
| Initialize annotation | Once per OS/JDK pair | None declared | Starts a Buildkite annotation table for the pair. |
| Java and Ruby unit tests | Once per OS/JDK pair | Annotation initialization | Runs the Windows unit-test scripts through the PowerShell launcher, updates status annotations, and archives test reports on failure. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | Space-separated `MATRIX_OSES` and `MATRIX_JDKS`; defaults are `windows-2022` and `adoptiumjdk_21 openjdk_21 zulu_21`. |
| Outputs | Dynamically uploaded steps, Buildkite annotations, and `build_reports.zip` on generated test jobs. |
| Retry | Generated unit-test jobs retry automatically up to three times. |
| Agents | Windows multi-JDK agent images selected by each generated matrix pair. |

## Operational notes

Static YAML is the generator/uploader, not the full matrix. `launch-command.ps1` configures the selected JDK and creates pass/fail annotations; on test failure it archives the test report directory.

## Sources

- Pipeline: [`windows_jdk_matrix_pipeline.yml`](../windows_jdk_matrix_pipeline.yml)
- Generator: [`generate-steps.py`](../scripts/jdk-matrix-tests/generate-steps.py)
- Windows launcher: [`launch-command.ps1`](../scripts/jdk-matrix-tests/launch-command.ps1)
- Live pipeline: [Buildkite](https://buildkite.com/elastic/logstash-windows-jdk-matrix-pipeline)
- Scheduler: [Buildkite](https://buildkite.com/elastic/logstash-pipeline-scheduler)
