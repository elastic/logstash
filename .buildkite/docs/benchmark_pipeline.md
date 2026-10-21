# Logstash benchmark pipeline

Runs a Logstash snapshot performance benchmark and publishes its measurements to Elasticsearch.

## At a glance

| | |
| --- | --- |
| Platform | Buildkite |
| Pipeline | [`logstash-benchmark-pipeline`](https://buildkite.com/elastic/logstash-benchmark-pipeline) |
| Source | [`benchmark_pipeline.yml`](../benchmark_pipeline.yml) |
| Trigger | Not specified in the checked-in YAML; the live GitHub provider has code-trigger builds disabled. |

## Purpose

The live pipeline description identifies this as the snapshot-version benchmark. The benchmark script measures ingestion throughput and Logstash resource use with Filebeat feeding Logstash, then submits summary measurements to Elasticsearch.

## When it runs

The checked-in YAML has no event or schedule declaration. Live provider settings disable GitHub branch, pull-request, and tag builds; other Buildkite invocation paths are not described by the checked-in sources.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| Benchmark Snapshot | Pipeline step | None declared | Runs `main.sh`; by default it resolves and downloads the latest main-branch snapshot image, generates benchmark input, exercises queue/worker/batch combinations, records metrics, and cleans up. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | Benchmark tuning variables include `FB_CNT`, `QTYPE`, `CPU`, `MEM`, `MULTIPLIERS`, `BATCH_SIZES`, `FB_VERSION`, `LS_VERSION`, `LS_JAVA_OPTS`, `FLOG_FILE_CNT`, and `TAGS`. The runner reads `BENCHMARK_ES_HOST`, `BENCHMARK_ES_USER`, `BENCHMARK_ES_PW`, `MONITOR_ES_HOST`, `MONITOR_ES_USER`, and `MONITOR_ES_PW` from the selected Vault record; only names are listed. |
| Outputs | Benchmark data and summary documents are sent to Elasticsearch; no Buildkite artifact paths are declared. |
| Secrets | `VAULT_PATH` selects the Vault record from which the script reads destination credentials. Values are not documented here. |
| Agents | GCP Ubuntu 22.04 family image, `n2-standard-16`, 100 GB SSD. |
| Retry | The step retries automatically up to three times. |

## Operational notes

The shared harness creates a synthetic log corpus, runs Filebeat and Logstash containers, samples node statistics, and reports throughput and resource measurements. Its `node_stats` pipeline polls the Logstash node-stats API and publishes monitoring data separately from benchmark events. Benchmark results should be compared only across equivalent hardware, as noted in the local benchmark README.

## Sources

- Pipeline: [`benchmark_pipeline.yml`](../benchmark_pipeline.yml)
- Runner: [`main.sh`](../scripts/benchmark/main.sh)
- Shared benchmark implementation: [`core.sh`](../scripts/benchmark/core.sh)
- Benchmark configuration: [`config`](../scripts/benchmark/config/)
- Setup notes: [`benchmark README`](../scripts/benchmark/README.md)
- Live pipeline: [Buildkite](https://buildkite.com/elastic/logstash-benchmark-pipeline)
