# Logstash supported plugins test pipeline

Runs plugin tests across supported Tier 1 and Tier 2 plugin categories and a limited unsupported-plugin input set.

## At a glance

| | |
| --- | --- |
| Platform | Buildkite |
| Pipeline | [`logstash-supported-plugins-test-pipeline`](https://buildkite.com/elastic/logstash-supported-plugins-test-pipeline) |
| Source | [`supported_plugins_test_pipeline.yml`](../supported_plugins_test_pipeline.yml) |
| Trigger | Not specified in the checked-in YAML; live provider settings disable GitHub code-trigger builds. |

## Purpose

The pipeline exercises Logstash plugins using the repository's `ci/test_plugins.sh` wrapper, partitioned by support tier and plugin type.

## When it runs

The checked-in YAML does not specify an event or schedule. Live provider settings disable GitHub branch, pull-request, and tag builds. Other Buildkite invocation paths are not exposed in the checked-in source.

## Execution flow

Groups run their listed tests; no inter-group or step dependencies are declared.

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| Tier 1 group | Pipeline step | None declared | Tests the file input, selected remaining Tier 1 inputs, and Tier 1 filters, codecs, outputs, and integrations. |
| Tier 2 group | Pipeline step | None declared | Tests Tier 2 inputs, filters, codecs, and outputs. |
| Unsupported group | Pipeline step | None declared | Tests unsupported inputs. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Inputs | Repository plugin configuration and `ci/test_plugins.sh` selector flags. |
| Outputs | Plugin test results; no artifact paths or explicit retry policy are declared. |
| Agents | Shared Buildkite CI container; several steps override with a GCP Ubuntu 22.04 agent and 120 GB disk. |

## Operational notes

The file input, selected Tier 1 inputs, Tier 1 integrations, and Tier 2 codecs explicitly source the VM-agent bootstrap. Some steps carry comments describing agent-image workarounds; the configuration does not define a separate failure-handling path.

## Sources

- Pipeline: [`supported_plugins_test_pipeline.yml`](../supported_plugins_test_pipeline.yml)
- Plugin test wrapper: [`ci/test_plugins.sh`](../../ci/test_plugins.sh)
- VM bootstrap: [`vm-agent.sh`](../scripts/common/vm-agent.sh)
- Live pipeline: [Buildkite](https://buildkite.com/elastic/logstash-supported-plugins-test-pipeline)
