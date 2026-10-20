# openapi-lint

Lints the Logstash OpenAPI specification when that specification changes in a pull request.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`openapi-lint.yml`](../openapi-lint.yml) |
| Trigger | Pull request changing `docs/static/spec/openapi/logstash-api.yaml` |

## Purpose

Validates the checked-in Logstash API specification using the shared Elastic Docs OpenAPI linter.

## When it runs

On pull requests with a change to `docs/static/spec/openapi/logstash-api.yaml`. No branch or event-type filter is declared.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `lint` | Matching pull request | None declared | Runs on `ubuntu-latest`, checks out the repository, and calls `elastic/docs-actions/openapi/lint@v1` with the spec path. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Permissions | `contents: read`. |
| Outputs | No workflow outputs, artifacts, or caches are declared. |

## Operational notes

The linter action is maintained externally and was not inspected. The referenced specification is [`logstash-api.yaml`](../../../docs/static/spec/openapi/logstash-api.yaml).

## Sources

- Workflow: [`openapi-lint.yml`](../openapi-lint.yml)
- OpenAPI specification: [`logstash-api.yaml`](../../../docs/static/spec/openapi/logstash-api.yaml)
