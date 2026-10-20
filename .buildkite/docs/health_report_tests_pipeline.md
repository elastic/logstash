# Logstash Health Report tests pipeline

Builds Logstash and validates Health Report API responses across configured integration-test scenarios.

## At a glance

| | |
| --- | --- |
| Platform | Buildkite |
| Pipeline | [`logstash-health-report-tests-pipeline`](https://buildkite.com/elastic/logstash-health-report-tests-pipeline) |
| Source | [`health_report_tests_pipeline.yml`](../health_report_tests_pipeline.yml) |
| Trigger | Not specified in the checked-in YAML; live provider settings disable GitHub code-trigger builds. |

## Purpose

The pipeline runs the Health Report API integration test package. Its runner builds Logstash, installs the failure-injector integration plugin, starts Logstash for each YAML scenario, and compares Health Report output with expected values.

## When it runs

No branch, pull-request, or schedule trigger is defined by the checked-in YAML. The live GitHub provider has branch, pull-request, and tag builds disabled. Other Buildkite invocation paths are not available in the checked-in sources.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| Health API integration tests | Pipeline start | None declared | Runs the test shell wrapper, installs Python dependencies, and executes all scenario files under `scripts/health-report-tests/tests/`. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | Optional `LS_BRANCH` selects the Logstash branch; without it, the current checkout is used. |
| Outputs | Scenario assertions and test logs; no Buildkite artifact paths are declared. |
| Retry | The test step retries automatically up to three times. |
| Agents | GCP Ubuntu 22.04 family image, `n2-standard-4`, 64 GB disk. |

## Operational notes

Scenarios are validated before execution. They cover normal and abnormal termination, slow startup, one- and five-minute backpressure, recovery after a crash, and combined pipeline states. Each scenario configures a Logstash pipeline and checks the Health Report API; a failed scenario is retried internally before the overall runner fails. The checked-in `config/pipelines.yml` is intentionally empty because the bootstrap writes scenario configuration there.

## Sources

- Pipeline: [`health_report_tests_pipeline.yml`](../health_report_tests_pipeline.yml)
- Runner and scenarios: [`scripts/health-report-tests`](../scripts/health-report-tests/)
- Package README: [`health-report-tests README`](../scripts/health-report-tests/README.md)
- Live pipeline: [Buildkite](https://buildkite.com/elastic/logstash-health-report-tests-pipeline)
