# Logstash Serverless integration pipeline

Runs integration tests for Logstash features and plugins in an Elasticsearch Serverless environment.

## At a glance

| | |
| --- | --- |
| Platform | Buildkite |
| Pipeline | [`logstash-serverless-integration-testing`](https://buildkite.com/elastic/logstash-serverless-integration-testing) |
| Source | [`serverless_integration_pipeline.yml`](../serverless_integration_pipeline.yml) |
| Trigger | Not specified in the checked-in YAML; the live GitHub provider has code-trigger builds disabled. |

## Purpose

This pipeline exercises Logstash integrations against Serverless, including dead-letter queues, Elasticsearch input/output, filters, and central pipeline management.

## When it runs

No branch, pull-request, or schedule trigger appears in the checked-in YAML. Live provider settings disable GitHub branch, pull-request, and tag builds. Other Buildkite invocation paths are not exposed by the checked-in sources.

## Execution flow

All declared steps are independent and use the GCP `core-ubuntu-2204` agent. Each active test sets up Java first and retries automatically up to three times.

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| DLQ rspec integration test | Active step | None declared | Runs `ci/serverless/dlq_rspec_tests.sh`. |
| Elasticsearch output/input/filter tests | Active steps | None declared | Runs the corresponding `es_output_tests.sh`, `es_input_tests.sh`, and `es_filter_tests.sh` scripts. |
| Elastic integration filter test | Active step | None declared | Runs `elastic_integration_filter_tests.sh`. |
| Central pipeline management test | Active step | None declared | Runs `cpm_tests.sh`; the adjacent comment notes legacy monitoring is disabled because the required monitoring endpoint is unsupported in Serverless. |
| Legacy monitoring, Kibana API, and Metricbeat tests | Skipped in YAML | None declared | Not run; comments state that the required endpoints/APIs are unavailable or unsupported in the current QA setup. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | Buildkite checkout and Java 21 installed by `setup_java.sh`. |
| Outputs | Test results; no artifact paths are declared. |
| Retry | Each test step, including the skipped entries if enabled later, declares up to three automatic retries. |
| Environment and secrets | Shared test helpers load `ES_ENDPOINT`, `ES_USER`, `ES_PW`, `KB_ENDPOINT`, `MB_API_KEY`, `PLUGIN_API_KEY`, `INTEGRATION_API_KEY_ENCODED`, `TESTER_API_KEY_ENCODED`, and `CPM_API_KEY` from Vault. Names only; values are not documented. |

## Operational notes

Three steps have `skip: true`; their commands remain in the YAML but are not active. The live pipeline's remote bootstrap uploads this checked-in definition.

## Sources

- Pipeline: [`serverless_integration_pipeline.yml`](../serverless_integration_pipeline.yml)
- Java setup: [`setup_java.sh`](../scripts/setup_java.sh)
- Referenced tests: [`ci/serverless`](../../ci/serverless/)
- Live pipeline: [Buildkite](https://buildkite.com/elastic/logstash-serverless-integration-testing)
