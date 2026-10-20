# openapi-publish

Lints and uploads the Logstash OpenAPI specification after changes are pushed to a supported branch.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`openapi-publish.yml`](../openapi-publish.yml) |
| Trigger | Push to `main` or a matching numeric release branch, changing the OpenAPI spec |

## Purpose

Ensures the specification is linted before the shared upload action publishes it under the name `logstash`.

## When it runs

On pushes to `main` or branches matching `[0-9]+.[0-9]+` when `docs/static/spec/openapi/logstash-api.yaml` changes.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `publish` | Matching push | None declared | Checks out the repository, lints the spec, then invokes the OpenAPI upload action with the same spec path and `spec-name: logstash`. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Permissions | Workflow grants `contents: read`; the job explicitly grants `contents: read` and `id-token: write` for OIDC to the upload action. |
| Outputs | Upload result is not declared as a workflow output; no artifact or cache is configured. |

## Operational notes

Both lint and upload are external actions and were not inspected. The upload step requires the declared OIDC token permission; the destination and environment are not identified in this workflow.

## Sources

- Workflow: [`openapi-publish.yml`](../openapi-publish.yml)
- OpenAPI specification: [`logstash-api.yaml`](../../../docs/static/spec/openapi/logstash-api.yaml)
