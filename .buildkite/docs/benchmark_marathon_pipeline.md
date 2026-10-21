# Logstash benchmark marathon pipeline

Runs the Logstash benchmark harness repeatedly against a configurable list of Logstash versions.

## At a glance

| | |
| --- | --- |
| Platform | Buildkite |
| Pipeline | [`logstash-benchmark-marathon-pipeline`](https://buildkite.com/elastic/logstash-benchmark-marathon-pipeline) |
| Source | [`benchmark_marathon_pipeline.yml`](../benchmark_marathon_pipeline.yml) |
| Trigger | Not specified in the checked-in YAML; the live GitHub provider has code-trigger builds disabled. |

## Purpose

The live pipeline description identifies this as a multi-version benchmark marathon. Its script runs the same ingestion benchmark for each version in `STACK_VERSIONS`, allowing results across versions to be compared using the same benchmark harness.

## When it runs

No event or schedule is declared in the YAML. The live provider settings disable GitHub branch, pull-request, and tag builds. Other Buildkite invocation paths are not available in the checked-in sources.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| Benchmark Marathon | Pipeline step | None declared | Runs `marathon.sh`, which loads the default or supplied version list, provisions benchmark data and images, then calls the common benchmark routines for each version. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | `STACK_VERSIONS` selects comma-separated Logstash versions; benchmark tuning variables include `FB_CNT`, `QTYPE`, `CPU`, `MEM`, `MULTIPLIERS`, `BATCH_SIZES`, `FB_VERSION`, and `TAGS`. The runner reads `BENCHMARK_ES_HOST`, `BENCHMARK_ES_USER`, `BENCHMARK_ES_PW`, `MONITOR_ES_HOST`, `MONITOR_ES_USER`, and `MONITOR_ES_PW` from the selected Vault record; only names are listed. |
| Outputs | Benchmark measurements and summaries are sent to the Elasticsearch endpoints configured through Vault; no Buildkite artifact paths are declared. |
| Secrets | `VAULT_PATH` selects the Vault record; the benchmark helper reads credential fields for benchmark and monitoring Elasticsearch destinations. Values are not documented here. |
| Agents | GCP Ubuntu 22.04 family image, `n2-standard-16`, 100 GB SSD. |

## Operational notes

The default version list and benchmark mechanics are in `marathon.sh` and `core.sh`. The harness generates logs, runs Filebeat and Logstash containers, records throughput and resource metrics, and submits benchmark summaries. The script does not declare a per-step retry policy.

## Sources

- Pipeline: [`benchmark_marathon_pipeline.yml`](../benchmark_marathon_pipeline.yml)
- Runner: [`marathon.sh`](../scripts/benchmark/marathon.sh)
- Shared benchmark implementation: [`core.sh`](../scripts/benchmark/core.sh)
- Benchmark setup notes: [`benchmark README`](../scripts/benchmark/README.md)
- Live pipeline: [Buildkite](https://buildkite.com/elastic/logstash-benchmark-marathon-pipeline)
