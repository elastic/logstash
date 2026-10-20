# Observability Agentic Workflow — Status

Forwards Buildkite-related failure status events to the shared Observability Agentic Workflow handler.

## At a glance

| | |
| --- | --- |
| Platform | GitHub Actions |
| Source | [`trigger-obs-aw-status.yml`](../trigger-obs-aw-status.yml) |
| Trigger | Commit status event, filtered at job level |

## Purpose

Routes failed status events whose context identifies Buildkite into the reusable status event handler, passing a Buildkite API token under the reusable workflow's expected secret name.

## When it runs

The `status` event can trigger the workflow; the job only runs when `github.event.state` is `failure` and the event context contains `buildkite`.

## Execution flow

| Job or step | Runs when | Depends on | What it does |
| --- | --- | --- | --- |
| `run-obs-aw-status` | Failed status with a context containing `buildkite` | None declared | Calls `elastic/oblt-aw/.github/workflows/obs-aw-event-status.yml@v0` and maps `BUILDKITE_LOGS_API_TOKEN` to `BUILDKITE_API_TOKEN`. |

## Inputs, outputs, and access

| Item | Details |
| --- | --- |
| Permissions | Caller defaults to `contents: read`; job grants `actions: read`, `contents: read`, `copilot-requests: write`, `id-token: write`, `issues: write`, and `pull-requests: write`. |
| Secrets | `BUILDKITE_LOGS_API_TOKEN` is passed to the reusable workflow as `BUILDKITE_API_TOKEN`. |
| Outputs | No caller outputs or artifacts are declared; reusable workflow internals are unavailable here. |

## Operational notes

The external reusable workflow was not inspected. Secret values are not documented here.

## Sources

- Workflow: [`trigger-obs-aw-status.yml`](../trigger-obs-aw-status.yml)
- Reusable workflow reference: [`elastic/oblt-aw/.github/workflows/obs-aw-event-status.yml@v0`](https://github.com/elastic/oblt-aw/blob/v0/.github/workflows/obs-aw-event-status.yml)
